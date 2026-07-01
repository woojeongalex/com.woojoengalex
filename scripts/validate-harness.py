"""
validate-harness.py — 스타 토폴로지 온톨로지 하네스 검증 스크립트

[카파시 하네스 엔지니어링 철학 적용]
- MD 파일을 온톨로지 노드로 간주하고, 각 노드의 구조적 무결성을 검증한다.
- Hub-Spoke 토폴로지 위반(스포크→스포크 직접 링크, 고립 노드, 순환 참조)을 탐지한다.
- 링크 형식: Obsidian WikiLink [[NodeName]] 또는 [[path/to/node|Alias]] 지원.

[사용법]
  python scripts/validate-harness.py                    # 전체 vault 검증
  python scripts/validate-harness.py --path vault/      # 특정 디렉터리
  python scripts/validate-harness.py --strict           # 경고도 오류로 처리
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict, deque
from pathlib import Path
from typing import Any

import yaml  # pip install pyyaml


# ─────────────────────────────────────────
# 설정
# ─────────────────────────────────────────
DEFAULT_VAULT_DIRS = [
    "vault",
    "woojeongai/apps/star_craft",
    "_docs",
]

REQUIRED_FRONTMATTER_FIELDS = ["type", "name"]
VALID_NODE_TYPES = {"hub", "spoke", "doc", "reference"}

# WikiLink 패턴: [[target]] 또는 [[target|alias]]
WIKILINK_RE = re.compile(r"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]")
# 표준 MD 링크: [text](target)
MD_LINK_RE = re.compile(r"\[(?:[^\]]+)\]\(([^)]+)\)")


# ─────────────────────────────────────────
# 파서
# ─────────────────────────────────────────

def parse_frontmatter(content: str) -> tuple[dict[str, Any], str]:
    """YAML frontmatter와 본문을 분리하여 반환."""
    if not content.startswith("---"):
        return {}, content
    end = content.find("\n---", 3)
    if end == -1:
        return {}, content
    yaml_block = content[3:end].strip()
    body = content[end + 4:].strip()
    try:
        meta = yaml.safe_load(yaml_block) or {}
    except yaml.YAMLError:
        meta = {}
    return meta, body


def extract_links(body: str) -> list[str]:
    """본문에서 WikiLink와 표준 MD 링크 대상을 모두 추출."""
    targets = []
    for m in WIKILINK_RE.finditer(body):
        # [[path/to/node]] → 파일명만 추출 (확장자 제거)
        raw = m.group(1).strip()
        targets.append(Path(raw).stem)
    for m in MD_LINK_RE.finditer(body):
        raw = m.group(1).strip()
        if not raw.startswith("http"):
            targets.append(Path(raw).stem)
    return targets


# ─────────────────────────────────────────
# 그래프 빌더
# ─────────────────────────────────────────

class OntologyNode:
    def __init__(self, path: Path, meta: dict, links: list[str]):
        self.path = path
        self.name = meta.get("name") or path.stem
        self.node_type = meta.get("type", "unknown")
        self.meta = meta
        self.links = links  # 이 노드가 참조하는 노드 이름 목록

    def __repr__(self) -> str:
        return f"<{self.node_type}:{self.name}>"


def build_graph(vault_dirs: list[Path]) -> tuple[dict[str, OntologyNode], list[str]]:
    """MD 파일을 파싱하여 노드 딕셔너리와 파싱 경고 목록을 반환."""
    nodes: dict[str, OntologyNode] = {}
    warnings: list[str] = []

    for vault_dir in vault_dirs:
        if not vault_dir.exists():
            continue
        for md_file in vault_dir.rglob("*.md"):
            content = md_file.read_text(encoding="utf-8", errors="replace")
            meta, body = parse_frontmatter(content)
            links = extract_links(body)
            node = OntologyNode(md_file, meta, links)

            if not meta:
                warnings.append(f"[WARN] Frontmatter 없음: {md_file}")
            if node.name in nodes:
                warnings.append(
                    f"[WARN] 중복 노드명 '{node.name}': {md_file} ↔ {nodes[node.name].path}"
                )
            nodes[node.name] = node

    return nodes, warnings


# ─────────────────────────────────────────
# 검증 규칙
# ─────────────────────────────────────────

class ValidationResult:
    def __init__(self):
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, msg: str) -> None:
        self.errors.append(f"[ERROR] {msg}")

    def warn(self, msg: str) -> None:
        self.warnings.append(f"[WARN] {msg}")

    @property
    def passed(self) -> bool:
        return len(self.errors) == 0


def validate_frontmatter(nodes: dict[str, OntologyNode], result: ValidationResult) -> None:
    """필수 Frontmatter 필드 및 타입 유효성 검사."""
    for name, node in nodes.items():
        for field in REQUIRED_FRONTMATTER_FIELDS:
            if field not in node.meta:
                result.error(
                    f"필수 frontmatter 누락 '{field}': {node.path}"
                )
        if node.node_type not in VALID_NODE_TYPES and node.node_type != "unknown":
            result.error(
                f"유효하지 않은 type '{node.node_type}': {node.path} "
                f"(허용값: {', '.join(VALID_NODE_TYPES)})"
            )


def validate_star_topology(nodes: dict[str, OntologyNode], result: ValidationResult) -> None:
    """스타 토폴로지 규칙 검증: 스포크→스포크 직접 링크 금지."""
    spoke_names = {n for n, node in nodes.items() if node.node_type == "spoke"}
    hub_names = {n for n, node in nodes.items() if node.node_type == "hub"}

    if not hub_names:
        result.warn("Hub 노드가 없습니다. star_craft/hub/ 에 type: hub MD 파일을 추가하세요.")

    for name, node in nodes.items():
        if node.node_type != "spoke":
            continue
        for link in node.links:
            if link in spoke_names and link != name:
                result.error(
                    f"스포크→스포크 직접 참조 금지: [{name}] → [{link}] "
                    f"(허브를 통해 라우팅해야 합니다)"
                )


def validate_isolated_nodes(nodes: dict[str, OntologyNode], result: ValidationResult) -> None:
    """고립 노드(inbound 링크가 0개인 노드) 탐지."""
    referenced: set[str] = set()
    for node in nodes.values():
        for link in node.links:
            referenced.add(link)

    for name, node in nodes.items():
        if node.node_type in {"hub", "doc", "reference"}:
            continue  # Hub와 문서 노드는 고립 허용
        if name not in referenced:
            result.warn(f"고립 노드 (어떤 노드도 참조하지 않음): {node.path}")


def validate_circular_dependency(nodes: dict[str, OntologyNode], result: ValidationResult) -> None:
    """DFS 기반 순환 참조 탐지 (Spoke 노드 그래프 대상)."""
    # 스포크 노드만 대상으로 순환 검사 (허브-스포크 간 방향성은 허용)
    spoke_nodes = {n: node for n, node in nodes.items() if node.node_type == "spoke"}

    visited: set[str] = set()
    in_stack: set[str] = set()
    cycle_found: list[list[str]] = []

    def dfs(current: str, path: list[str]) -> None:
        if current not in nodes:
            return
        if current in in_stack:
            cycle_start = path.index(current)
            cycle_found.append(path[cycle_start:] + [current])
            return
        if current in visited:
            return
        visited.add(current)
        in_stack.add(current)
        path.append(current)
        for link in nodes[current].links:
            if link in spoke_nodes:
                dfs(link, path[:])
        in_stack.discard(current)

    for name in spoke_nodes:
        if name not in visited:
            dfs(name, [])

    seen_cycles: set[frozenset] = set()
    for cycle in cycle_found:
        key = frozenset(cycle)
        if key not in seen_cycles:
            seen_cycles.add(key)
            result.error(f"순환 참조 탐지: {' → '.join(cycle)}")


def validate_link_integrity(nodes: dict[str, OntologyNode], result: ValidationResult) -> None:
    """링크 무결성: 존재하지 않는 노드를 참조하는 링크 탐지."""
    all_names = set(nodes.keys())
    for name, node in nodes.items():
        for link in node.links:
            if link and link not in all_names:
                result.warn(
                    f"존재하지 않는 노드 참조 (깨진 링크): [{name}] → [[{link}]]"
                )


# ─────────────────────────────────────────
# 메인
# ─────────────────────────────────────────

def run(vault_dirs: list[Path], strict: bool = False) -> int:
    print("=" * 60)
    print("  Harness Validator — Star Topology Ontology Check")
    print("=" * 60)

    nodes, parse_warnings = build_graph(vault_dirs)
    print(f"\n총 {len(nodes)}개 노드 로드됨")

    result = ValidationResult()

    # 파싱 경고 등록
    for w in parse_warnings:
        result.warn(w.replace("[WARN] ", ""))

    # 검증 실행
    validate_frontmatter(nodes, result)
    validate_star_topology(nodes, result)
    validate_isolated_nodes(nodes, result)
    validate_circular_dependency(nodes, result)
    validate_link_integrity(nodes, result)

    # 결과 출력
    print()
    if result.warnings:
        print("── 경고 ──────────────────────────────────────────────")
        for w in result.warnings:
            print(f"  {w}")

    if result.errors:
        print("\n── 오류 ──────────────────────────────────────────────")
        for e in result.errors:
            print(f"  {e}")

    print("\n── 요약 ──────────────────────────────────────────────")
    print(f"  오류: {len(result.errors)}  경고: {len(result.warnings)}")

    if result.passed and not (strict and result.warnings):
        print("  ✓ 하네스 검증 통과\n")
        return 0
    else:
        print("  ✗ 하네스 검증 실패\n")
        return 1


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Star Topology Ontology Harness Validator"
    )
    parser.add_argument(
        "--path",
        nargs="*",
        default=DEFAULT_VAULT_DIRS,
        help="검증할 디렉터리 경로 (복수 지정 가능)",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="경고도 오류로 처리하여 비정상 종료",
    )
    args = parser.parse_args()

    vault_dirs = [Path(p) for p in args.path]
    sys.exit(run(vault_dirs, strict=args.strict))


if __name__ == "__main__":
    main()
