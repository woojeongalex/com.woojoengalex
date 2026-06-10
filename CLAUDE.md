`# CLAUDE.md — Cursor / Claude 에이전트 인수인계

본 문서는 저장소 작업 시 **클로드(또는 Cursor 에이전트)가 바로 이어받을 수 있도록** 정리한 정본이다.  
행동 하네스·클린 아키텍처·헥사고날·SOLID·FastAPI·디자인 패턴·앱별 현황을 한곳에 모았다.

**트레이드오프:** 속도보다 신중함. 사소한 작업은 상황에 맞게 판단한다.

---

## 0. 문서 읽는 순서 (필수)

| 순서 | 문서 | 역할 |
|------|------|------|
| 1 | `AGENTS.md` | 행동 하네스 본문 — 가정 명시, 범위 준수, 검증 후 완료 |
| 2 | **본 파일** `CLAUDE.md` | 인수인계·패턴 정본 (백엔드 포함) |
| 3 | `docs/DevOPs/README.md` | DevOps 진입점 |
| 4 | `docs/DevOPs/Backend/BACKEND_RULES.md` | FastAPI·DB·로깅·API 경로 |
| 5 | `docs/DevOPs/Backend/CLEAN_ARCHITECTURE.md` | 클린 아키텍처·SOLID·ISP 상세 |
| 6 | `docs/DevOPs/Backend/ENTITY_RULE.md` | ORM PK·`id`·refresh 규칙 |

**우선순위 (충돌 시):** 사용자 지시 > `docs/DevOPs/` > `AGENTS.md` / 본 문서 > `.cursor/rules/*.mdc` > `.cursorrules`

---

## 1. 행동 하네스 (AGENTS.md 요약)

코딩 **전에** 반드시 지킬 것:

### Think Before Coding
- 가정을 말로 밝힌다. 모호하면 질문 후 구현.
- 해석이 여러 개면 임의 선택하지 말고 대안을 제시한다.
- 더 단순한 해법이 있으면 제안한다.

### Simplicity First
- 요청 범위 밖 기능·추상화·설정 금지.
- 일회용 추상화, 불가능한 경로 방어 코드 금지.

### Surgical Changes
- 요청과 무관한 리팩터·포맷 정리 금지. diff는 요청과 직결.
- 본인 변경으로 불필요해진 import·변수·함수만 제거.

### Goal-Driven Execution
- 검증 가능한 성공 기준 후 구현 (`import main`, API 호출, 테스트 출력).

**금지:** `.env`·비밀 커밋, 사용자 요청 없는 `git commit`/`push`/`git config` 변경.

**언어:** 사용자가 한국어로 말하면 한국어로 답한다. 코드·식별자·로그 문구는 원문 유지.

---

## 2. 저장소 레이아웃

```
woojeongai/
  main.py                      # FastAPI 앱 · include_router · init_db
  apps/
    friday13th/                # 인증 (signup/login)
    music/                     # 보컬·MR·악기·스피치·비디오
    titanic/                   # James(업로드) / Walter(조회) 레퍼런스
  core/
    database.py                # get_db · init_db · AsyncSession
  logging_setup.py             # 도메인별 로거 등록
```

- 작업 루트: `woojeongai/apps/<앱명>/`
- `PYTHONPATH`에 `woojeongai/apps` 포함 (`uvicorn main:app`, `python main.py`)
- 로컬: `cd backend` → `python main.py` (포트 8000, reload)

---

## 3. 클린 아키텍처 + 헥사고날 (Ports & Adapters)

### 3.1 의존성 규칙

- 의존성은 **안쪽(도메인·Use Case)** 으로만 향한다.
- **Use Case / Interactor** 는 `adapter/`·ORM·FastAPI Request/Response **import 금지**.
- HTTP·DB 변환은 **Adapter 경계에서 1회** (mapper / parser / handler).

### 3.2 4계층

| 계층 | 위치 | 책임 |
|------|------|------|
| **Entities** | `domain/entities/`, `domain/value_objects/` | 순수 비즈니스 (프레임워크 무관) |
| **Use Cases** | `app/use_cases/*_interactor.py` | 오케스트레이션, Port만 의존 |
| **Interface Adapters** | `adapter/inbound/`, `adapter/outbound/` | HTTP·ORM·외부 I/O |
| **Frameworks** | FastAPI, SQLAlchemy, SQLModel, Neon PG | `main.py`, `core/database.py` |

### 3.3 프렉탈(Fractal) 디렉터리 — 모든 앱 공통

```
<app>/
  domain/
    entities/
    value_objects/
  app/
    dtos/                      # Use Case 입출력 (dataclass)
    ports/
      input/                   # *UseCase (ABC) — inbound Port
      output/                  # *RepositoryPort (ABC) — outbound Port
    use_cases/
      *_interactor.py          # input Port 구현 (구 명칭 *Service 지양)
  dependencies/
    *_director.py              # DIP 조립소 (FastAPI Depends 팩토리)
  adapter/
    inbound/
      api/
        deps/                  # get_*_use_case re-export
        v1/                    # *_router.py (thin)
        schemas/               # Pydantic Request/Response
        mappers/               # schema ↔ dto
        parsers/               # UploadFile → 내부 타입 (무상태)
        handlers/              # HTTP 예외·DB 오류 매핑
    outbound/
      orm/                     # SQLModel table=True
      pg/                      # *PgRepository
```

**헥사고날 관점**

- **Inbound Port** = `app/ports/input/*_use_case.py`
- **Outbound Port** = `app/ports/output/*_repository_port.py`
- **Driving Adapter** = router, parser, mapper, handler
- **Driven Adapter** = `*_pg_repository`, ORM

---

## 4. SOLID — 저장소 적용 규칙

### S — Single Responsibility (단일 책임)

| 모듈 | 변경 이유 하나 |
|------|----------------|
| `*_router.py` | HTTP 경로·스키마·Use Case 위임 |
| `*_interactor.py` | 애플리케이션 규칙·흐름 |
| `*_pg_repository.py` | 영속화 (INSERT/SELECT/commit) |
| `*_inbound_mapper.py` | schema ↔ dto 변환 |
| `*_csv_parser.py` / `video_upload_parser.py` | 파일 파싱만 |
| `*_inbound_handlers.py` | ValueError/SQLAlchemyError → HTTPException |

**금지:** 라우터에 `select`, `commit`, 비즈니스 `if` 분기, Repository 직접 생성.

**KISS:** 한 줄만 위임하는 Interactor/Service는 만들지 않거나, 검증·매핑 역할이 있을 때만.

### O — Open/Closed (개방-폐쇄)

- **확장에 열려 있고, 수정에 닫혀 있어야 한다.** 새 "타입"을 추가할 때 기존 코드를 고치지 않고 새 클래스·데이터만 추가해야 한다.
- 새 저장소·외부 API → **새 Adapter** (`InMemoryXxxPgRepository` 등). 기존 Interactor 수정 금지.
- Use Case·Interactor 내부 `if db_type == "neon"` / `if source == "csv"` 등 타입 분기 **금지**.

**OCP 위반의 전형적 신호 (하지 말 것)**

```python
# ❌ if/elif 타입 분기 — 새 케이스 추가 시 이 함수를 수정해야 함
def map_error(exc):
    if "429" in str(exc):
        return HTTPException(429, "...")
    if "404" in str(exc):
        return HTTPException(502, "...")

# ❌ 조건별 분기로 추천 로직 구현 — 규칙 추가 시 함수 본체를 수정해야 함
def recommend(pitch, rhythm):
    if pitch >= 88 and rhythm >= 88:
        return ["발라드", ...]
    elif pitch >= 75:
        return ["팝", ...]

# ❌ 특정 컬럼 하드코딩 — 새 별칭 컬럼 추가 시 함수를 수정해야 함
def has_column(col, headers):
    if col == "gender":
        return any(h in headers for h in ("gender", "Sex"))
    return col in headers
```

**OCP 준수 패턴 (이렇게 할 것)**

```python
# ✅ 규칙 테이블 — 새 케이스는 테이블에 항목만 추가
@dataclass(frozen=True)
class _ErrorRule:
    keywords: tuple[str, ...]
    status_code: int
    detail: str

_ERROR_RULES: tuple[_ErrorRule, ...] = (
    _ErrorRule(keywords=("429", "quota"), status_code=429, detail="..."),
    _ErrorRule(keywords=("404", "not found"), status_code=502, detail="..."),
)

# ✅ 별칭 딕셔너리 — 새 컬럼 별칭은 딕셔너리에만 추가
COLUMN_ALIASES: dict[str, tuple[str, ...]] = {
    "gender": ("gender", "Sex"),
}

# ✅ URL prefix 딕셔너리 — 새 드라이버는 딕셔너리에만 추가
_SYNC_TO_ASYNC_PREFIX: dict[str, str] = {
    "postgresql://": "postgresql+asyncpg://",
    "postgres://":   "postgresql+asyncpg://",
}
```

**핵심 질문:** "새 케이스를 추가할 때 이 함수/클래스를 열어야 하는가?" → Yes면 OCP 위반.

### L — Liskov Substitution (리스코프)

- Port 구현체(Mock·PG)를 바꿔도 Use Case 동작·반환 의미 동일.

### I — Interface Segregation (ISP) — **핵심**

- 클라이언트가 쓰는 메서드만 Port에 둔다.
- **Fat Interface 금지** — `pass`, `NotImplemented`, 항상 `[]` 반환 메서드 = 분리 신호.
- **James ↔ Walter 분리** (Titanic 정본):

| Port | 메서드 | 하지 않는 것 |
|------|--------|--------------|
| `JamesUseCase` | `upload` | 조회·페이지네이션 |
| `WalterUseCase` | `read_passengers` | 업로드 |
| `JamesRepositoryPort` | `upload` | read |
| `WalterRepositoryPort` | `read_passengers` | upload |

- 메서드명은 **짧은 동사** (`upload`, `read`, `search`, `analyze`).  
  ❌ `receive_uploaded_records`, `search_and_persist`, `create_from_saved_evaluation`

### D — Dependency Inversion (DIP) — **Director 패턴**

- Use Case → **Port(Protocol)** 만 의존.
- 구체 클래스 조립은 `dependencies/*_director.py` 또는 `adapter/inbound/api/deps/`.

```python
# dependencies/james_director.py (정본)
def get_james_use_case(db: AsyncSession = Depends(get_db)) -> JamesUseCase:
    repository: JamesRepositoryPort = JamesPgRepository(session=db)
    return JamesInteractor(repository=repository)
```

```python
# adapter/inbound/api/deps/titanic_deps.py — re-export만
from titanic.dependencies.james_director import get_james_use_case
from titanic.dependencies.walter_roaster import get_walter_use_case
```

**라우터 규칙**

- `Depends(get_*_use_case)` 사용.
- 타입 힌트는 **Port** (`JamesUseCase`, `EvaluationUseCase`).
- `get_db`, `*PgRepository`, `*Interactor` **import 금지**.

---

## 5. FastAPI 패턴 (Thin Router)

### 5.1 완성형 — James (업로드 + 파서)

```python
@james_router.post("/upload", response_model=JamesUploadResponse)
async def upload_titanic_csv(
    file: UploadFile = File(...),
    james: JamesUseCase = Depends(get_james_use_case),
) -> JamesUploadResponse:
    file_name, rows = await read_james_upload(file)
    result = await james.upload(james_schemas_to_person_commands(rows), file_name)
    return JamesUploadResponse(**result)
```

- 파싱: `adapter/inbound/api/parsers/` (무상태)
- 매핑: `adapter/inbound/api/mappers/`
- Use Case: `upload` 한 메서드

### 5.2 완성형 — Walter (조회)

```python
@walter_router.get("/passengers", response_model=WalterPassengerPageResponse)
async def read_passengers(
    source_file: str | None = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=200),
    walter: WalterUseCase = Depends(get_walter_use_case),
) -> WalterPassengerPageResponse:
    page_dto = await walter.read_passengers(source_file, page, size)
    return walter_page_dto_to_response(page_dto)
```

### 5.3 Music — Handler로 예외 분리

DB·검증 오류가 있으면 router 대신 `handlers/`:

```python
@evaluation_router.post("/api/music/sing-evaluation", ...)
async def post_sing_evaluation(
    body: SingEvaluationCreateRequest,
    evaluation: EvaluationUseCase = Depends(get_evaluation_use_case),
) -> SingEvaluationResponse:
    result = await pass_sing_evaluation(evaluation, from_evaluation_create(body))
    return to_evaluation_response(result)
```

### 5.4 데이터 흐름 (한 요청)

```
HTTP Request
  → router (스키마 바인딩)
  → parser (파일 업로드 시)
  → mapper (schema → Command/DTO)
  → handler (선택: DB/검증 예외)
  → UseCase/Interactor (Port 타입)
  → Repository Port 구현 (*PgRepository)
  → ORM Entity → DB
  → mapper (Result DTO → Response schema)
  → HTTP Response
```

---

## 6. 디자인 패턴 정리

| 패턴 | 저장소에서의 형태 | 위치 |
|------|-------------------|------|
| **Hexagonal / Ports & Adapters** | `ports/input`, `ports/output`, `adapter/*` | 앱 전체 |
| **Interactor** | `*_interactor.py` | `app/use_cases/` |
| **Repository** | `*PgRepository` | `adapter/outbound/pg/` |
| **DTO** | `app/dtos/*` (frozen dataclass) | Use Case 경계 |
| **Mapper** | `*_inbound_mapper.py` | inbound adapter |
| **Parser** | `read_james_upload`, `read_video_upload` | inbound adapter |
| **Handler** | `pass_*`, HTTPException 매핑 | inbound adapter |
| **Director / DI Factory** | `get_*_use_case` | `dependencies/` |
| **Abstract Factory** (Titanic 레거시) | `TitanicUseCaseFactory`, `PgTitanicUseCaseFactory` | 점진적 `dependencies/` 로 이전 |
| **Catalog (인메모리)** | `catalog.py`, `instrument_catalog.py` | DB 미저장 참조 데이터 |

---

## 7. 앱별 현황

### 7.1 Titanic — 레퍼런스 앱

| 역할 | 파일 | 비고 |
|------|------|------|
| 업로드 (James) | `james_router`, `james_interactor`, `james_pg_repository` | CSV → `upload` |
| 조회 (Walter) | `walter_router`, `walter_interactor`, `walter_pg_repository` | `read_passengers` |
| DIP | `dependencies/james_director.py`, `walter_roaster.py` | |
| deps | `adapter/inbound/api/deps/titanic_deps.py` | |

**ORM:** `person_orm`, `booking_orm` — James 업로드 시 person+booking INSERT.  
**Alembic:** `woojeongai/alembic/versions/20260604_0001_titanic_person_booking_tables.py`

**레거시·주의**

- `PgTitanicUseCaseFactory` — 구형 조립, `dependencies/*_director`가 정본.
- 다수 스텁 PG repo (`@staticmethod`) — 미완성 캐릭터 라우터용.
- `walter.introduce_myself` — router에 있으나 Port 미정의 가능 (잠재 버그).

### 7.2 Music — Titanic 패턴 이식 완료 (1·2차)

**프렉탈 구조 + Director + Interactor + Thin Router 적용.**

| 도메인 | James(쓰기) | Walter(읽기) | Director |
|--------|-------------|--------------|----------|
| Evaluation | `upload` | — | `evaluation_director` |
| Search (MR) | — | `search` | `search_director` |
| Suggest | `upload` | `read` | `suggest_director` |
| Instrument | `upload` | `search` (카탈로그) | `instrument_director` |
| Speech | `upload` | `read_topics` | `speech_director` |
| Video | `analyze` (+ parser) | — (DB 없음) | `video_director` |

**deps:** `music/adapter/inbound/api/deps/music_deps.py` — 6개 `get_*_use_case` re-export.

**PG Repository 명명:** `EvaluationPgRepository`, `ListPgRepository`, `SuggestPgRepository`, `InstrumentPgRepository`, `SpeechPgRepository` — `__init__(self, session: AsyncSession)`, `self._session`.

**API 요약**

| 메서드 | 경로 | Use Case |
|--------|------|----------|
| GET | `/api/songs/search?q=` | SearchUseCase.search |
| POST | `/api/music/sing-evaluation` | EvaluationUseCase.upload |
| POST/GET | `/api/music/vocal-recommendations` | SuggestUseCase.upload / read |
| GET | `/api/music/instrument-catalog` | InstrumentUseCase.search |
| POST | `/api/music/instrument-evaluation` | InstrumentUseCase.upload |
| GET | `/api/music/speech-topics` | SpeechUseCase.read_topics |
| POST | `/api/music/speech-evaluation` | SpeechUseCase.upload |
| POST | `/api/music/analyze-video` | VideoAnalysisUseCase.analyze |

**스키마·ERD:** `docs/DevOPs/Backend/music.md`, `music_erd_v2.dbml`

**레거시**

- `sing_service.py` — 호환 래퍼, `EvaluationInteractor`에 위임. 신규 코드는 router+director 사용.
- `evaluation_service` / `list_service` 등 구 `*Service` — **삭제·Interactor로 대체**가 정본 (워크스페이스에 잔존 파일 있으면 정리 대상).

**DB 스키마 drift (미해결 — 3차 마이그레이션 예정)**

- `sing_evaluations.user_id` — ORM에는 있으나 Neon DB에 컬럼 없음 → POST sing-evaluation 503.
- `song_mr_search_lists.updated_at` — ORM 추가 시 DB 미반영 시 503 (필요 시 migration 또는 ORM에서 제거).
- ERD v2: `user_vocal_recordings.catalog_song_id` 제거 방향 — ORM·마이그레이션 정합 필요.

### 7.3 Friday13th — 인증

- `signup_router` / `login_router` → `SignupInteractor` / `LoginInteractor`
- `UserEntity` — `users` 테이블, bcrypt
- `role`은 서버에서 `"user"` 고정

---

## 8. ORM · DB 규칙

- **ORM 스타일: SQLAlchemy 2.0** — `Mapped`, `mapped_column` 사용 (`Field`, `SQLModel` 방식 금지)
- **코드 출력 규칙: 설명 없이 코드만 출력**
- **수정 범위: 지시한 파일·부분만 수정, 임의 파일 변경 금지**
- PK: 정수 `id` 자동 증가 (`ENTITY_RULE.md`)
- INSERT 후 `await session.refresh(entity)` 로 `id` 반영
- `init_db` + `SQLModel.metadata` / `Base.metadata` `create_all` (`main.py`)
- 세션: 요청 단위 `Depends(get_db)`, Repository에서 commit/rollback
- Windows: event loop 정책은 `main.py` 또는 `database.py`에서 **한 번만**

**Repository 번들 (Music 3NF)**

- Evaluation: `sing_evaluations` → `user_vocal_recordings` → `ai_vocal_analyses` 한 트랜잭션
- Instrument/Speech: `pg_bundle_repository.save_three_part_bundle` 공통

---

## 9. 로깅

- 도메인 흐름: **레이어당 1줄** INFO (동일 요청 10줄 이상 금지)
- 로거 등록: `logging_setup.py`
- `print` 디버그 커밋 금지
- Titanic: `titanic_flow_log` — adapter·usecase·outbound만 (`ports`는 로그 태그 금지)

---

## 10. 코딩·리뷰 체크리스트

작업 전·PR 전 확인:

- [ ] Use Case가 `adapter.inbound` 스키마를 import 하지 않는가?
- [ ] Router가 Repository / `get_db` / Interactor 구현을 import 하지 않는가?
- [ ] Port 메서드가 **한 역할·짧은 동사**인가? (ISP)
- [ ] Fat Interface / 미사용 abstract 메서드 없는가?
- [ ] 조립이 `dependencies/*_director.py` 또는 `deps/`에만 있는가? (DIP)
- [ ] schema ↔ dto 변환이 mapper에서 1회인가?
- [ ] `[Layer: …]` 인지하고 리뷰 설명에 명시했는가?
- [ ] `import main` 또는 API 호출로 검증했는가?
- [ ] diff가 사용자 요청 범위만 포함하는가?

---

## 11. 안티패턴 (하지 말 것)

```python
# ❌ 라우터에서 Repository 직접 조립
def _use_case(db):
    return EvaluationService(EvaluationRepository(db))

# ❌ Use Case에서 ORM Entity를 HTTP body로 직접 수신
async def save_evaluation(self, body: VocalEvaluationCreateRequest):

# ❌ Port에 쓰기+읽기+통계 한꺼번에
class TitanicRepository(ABC):
    async def upload(...): ...
    async def read_passengers(...): ...
    async def train_model(...): ...

# ❌ 장황한 Port 메서드명
async def receive_uploaded_records(...): ...
async def search_and_persist(...): ...
```

---

## 12. 신규 기능 추가 절차 (권장)

1. **Port** 정의 — `app/ports/input/`, `app/ports/output/` (ISP: 메서드 최소)
2. **DTO** — `app/dtos/`
3. **Interactor** — `app/use_cases/*_interactor.py`
4. **PgRepository** — `adapter/outbound/pg/*_pg_repository.py` (`session=`, `_session`)
5. **ORM** — `adapter/outbound/orm/` (+ `main.py` import register)
6. **Director** — `dependencies/*_director.py`
7. **deps re-export** — `adapter/inbound/api/deps/`
8. **schemas + mapper** (+ **parser** if upload, **handler** if DB errors)
9. **thin router** — `adapter/inbound/api/v1/`
10. **`main.py`** `include_router`
11. **Alembic migration** (테이블/컬럼 변경 시)
12. **검증** — `import main`, curl/requests, 필요 시 `check_neon_music.py`

---

## 13. 참고 링크 (저장소 내)

| 주제 | 경로 |
|------|------|
| **인수인계 (본 문서)** | `CLAUDE.md` |
| 행동 하네스 | `AGENTS.md` |
| 백엔드 공통 | `docs/DevOPs/Backend/BACKEND_RULES.md` |
| 클린·SOLID·ISP | `docs/DevOPs/Backend/CLEAN_ARCHITECTURE.md` |
| 엔티티 PK | `docs/DevOPs/Backend/ENTITY_RULE.md` |
| Music ERD | `docs/DevOPs/Backend/music.md` |
| Titanic ERD | `docs/DevOPs/Backend/TITANIC_ERD.md` |
| IDE 규칙 | `.cursorrules` |

---

## 14. 변경 이력 (인수인계 스냅샷)

- **Titanic:** James/Walter thin router, `dependencies/*_director`, ISP `upload`/`read_passengers`, `*_interactor`, `*_pg_repository`.
- **Music 1차:** evaluation(search MR) + evaluation(upload) — Director, Interactor, handler, `catalog.py`, `list_model.py`.
- **Music 2차:** suggest, instrument, speech, video — 동일 프렉탈 패턴, `*Service` → `*Interactor`, `*PgRepository`.
- **미완:** Music DB Alembic v2, `sing_service` 제거, Titanic 레거시 Factory·스텁 repo 정리.

---

*세부 규칙 변경 시 `docs/DevOPs/Backend/`를 먼저 갱신하고, 본 파일의 §7·§14를 맞춰 업데이트한다.*



# CLAUDE.md — Master Engineering Rules

## 🧠 Project Overview
This project implements **Karpathy's Harness Engineering** paradigm,
integrating **Wiki + LLM** to build a **Personal Knowledge System (PKS)**.

---

## 🏛️ Architecture Mandates

You MUST strictly follow all of the rules below in every file, module, and decision.

### 1. Architectural Pattern
- Implement **Hexagonal Architecture** (Ports & Adapters)
- Implement **Clean Architecture** (Dependency Rule: dependencies point inward only)
- Implement **Domain-Driven Design (DDD)** (Entities, Value Objects, Aggregates, Repositories, Domain Services, Application Services)
- These three patterns MUST coexist and complement each other at all times.

### 2. SOLID Principles (Non-Negotiable)
- **S** — Single Responsibility Principle: every class/module has exactly one reason to change.
- **O** — Open/Closed Principle: open for extension, closed for modification.
- **L** — Liskov Substitution Principle: subtypes must be substitutable for their base types.
- **I** — Interface Segregation Principle: no client should be forced to depend on methods it does not use.
- **D** — Dependency Inversion Principle: depend on abstractions, never on concretions.

---

## 📁 Module Path Conventions

### Internal App Paths (`woojeongai`)
- The `woojeongai` prefix and `apps` segment are **omitted** from all internal import paths.
- All internal module paths start **directly from the feature or domain name**.
- ✅ Correct: `from domain.wiki.entity import WikiPage`
- ❌ Wrong:   `from woojeongai.apps.domain.wiki.entity import WikiPage`

### Core Library Paths (`woojeong.core`)
- All shared core modules MUST begin with the `woojeong.core.` prefix.
- ✅ Correct: `from woojeong.core.ports.repository import BaseRepository`
- ❌ Wrong:   `from core.repository import BaseRepository`

---

## 🔒 Enforcement Rules

- Never violate the Dependency Rule: inner layers must never import from outer layers.
- Domain layer MUST NOT depend on any framework, ORM, or infrastructure concern.
- All external dependencies (DB, LLM API, Wiki API) MUST be accessed through **Ports (interfaces)**, with **Adapters** as the only concrete implementations.
- Every new module MUST be placed in the correct architectural layer before implementation begins.

---

## ✅ Layer Reference
[Domain Layer]        → woojeong.core.domain.*
[Application Layer]   → woojeong.core.application.*
[Port Interfaces]     → woojeong.core.ports.*
[Adapters / Infra]    → adapters.*  (woojeongai internal, apps prefix omitted)
[Entry Points / UI]   → entrypoints.*  (woojeongai internal, apps prefix omitted)

---

> These rules are absolute. Apply them to every response, code generation,
> refactoring suggestion, and architectural decision throughout this project.


## Language Rules
- Always respond and generate all output in **Korean** unless explicitly told otherwise.
- Code comments must be written in **English**.
- Never use Japanese in any output, file, or response.