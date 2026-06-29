# CLAUDE.md — 모노레포 루트 (woojeongalex.cloud)

이 저장소는 **woojeongai(FastAPI 백엔드)** 와 **alexview(Next.js 프론트엔드)** 로 구성된 모노레포다.

---

## 문서 구조

| 문서 | 역할 |
|------|------|
| [[woojeongai/CLAUDE\|woojeongai/CLAUDE.md]] | 백엔드 — FastAPI·클린 아키텍처·앱별 현황 |
| [[alexview/CLAUDE\|alexview/CLAUDE.md]] | 프론트엔드 — Next.js·컴포넌트·상태관리 |

---

## 하네스 엔지니어링 (Karpathy Harness)

코드 작성 후 **반드시** 아래 명령을 실행하고, 오류가 없을 때만 완료 선언한다.

### Flutter 작업 후 (`alexthegreat/`)
```bash
cd alexthegreat
dart analyze --fatal-infos
dart format --set-exit-if-changed .
```

### Python 작업 후 (`woojeongai/`)
```bash
cd woojeongai
ruff check . --fix
ruff format .
mypy . --ignore-missing-imports
```

### Next.js 작업 후 (`alexview/`)
```bash
cd alexview
pnpm lint:fix
pnpm format
pnpm type-check
```

### 온톨로지 노드(MD) 작업 후
```bash
python scripts/validate-harness.py --strict
```

> **린터 에러는 절대 무시하지 말 것. 에러 발생 시 반드시 수정 후 완료 보고.**

### 커밋 전 자동 게이트 (pre-commit)
```bash
# 최초 1회 설치
pip install pre-commit
pre-commit install

# 수동 전체 실행
pre-commit run --all-files
```

---

## MD 파일 배치 규칙

| 위치 | 대상 |
|------|------|
| `_docs/` | 모노레포 전체에 공통으로 적용되는 문서 |
| `woojeongai/_docs/` | 백엔드(FastAPI) 관련 문서 |
| `alexview/_docs/` | 프론트엔드(Next.js) 관련 문서 |
| `alexthegreat/_docs/` | Flutter 관련 문서 |
