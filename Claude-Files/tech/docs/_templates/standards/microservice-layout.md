# Microservice Layout (tech)

> **Documentation placement.** Cross-repo standard defining the canonical project layout for every {{PROJECT_NAME}} backend microservice (see [`documentation.md`](./documentation.md) §5).

## Scope

Canonical directory layout for a {{PROJECT_NAME}} backend microservice. A service ships one or more entrypoints — commonly an HTTP API, a queue consumer, and a cronjob runner; additional roles (worker, gRPC, WebSocket, stream, webhook) follow the same pattern. All entrypoints in a service share one codebase, one database, one set of business logic. Ship only the entrypoints the service uses; each has its own `src/<role>/` folder and `docker/Dockerfile.<role>`.

Out of scope: HTTP contract specifics (envelope, pagination, status codes) — [`api-and-data-contracts.md`](./api-and-data-contracts.md); macro architecture and inter-service comms — [`../project-architecture/v1.md`](../project-architecture/v1.md); database / migration mechanics{{#IF HAS_REDIS}}, Redis{{/IF}}{{#IF HAS_KAFKA}}, Kafka{{/IF}}, MinIO{{#IF HAS_MEILISEARCH}}, Meilisearch{{/IF}} conventions — [`infrastructure.md`](./infrastructure.md).

Reading conventions: **CURRENT** = today. **v1 STANDARD** = required for v1. Applicability: **[BE]**.

---

## 1. Versioning rules [BE] — v1 STANDARD

Version anything that is part of an external (wire) contract; share everything else.

| Layer | Versioned? |
|---|---|
| `src/api/v1/…`, `src/api/v2/…` (routes + schemas + deps) | yes (URL path) |
{{#IF HAS_KAFKA}}| `src/consumers/schemas/*_v1.py` | yes (per-event) |
{{/IF}}| `src/cronjob/…` | no |
| `src/<role>/…` (worker, grpc, websocket, stream, …) | only its wire contract, per message |
| `src/domain/…` | no |
| `src/infra/platform/…`, `src/infra/integrations/…` | no |

Rules:

- Versioning lives only inside `src/api/vN/` and per-event / per-message `*_vN.py` in outer folders.
- No `src/v1/` umbrella above domain / infra.
- Version names are bare `v1`, `v2`, … — never `v1.YYYY.MM.DD` or any dated form.

See also: API path versioning in [`api-and-data-contracts.md`](./api-and-data-contracts.md).

---

## 2. Canonical layout [BE] — v1 STANDARD

```
backend-<service>/
├── .env.example
├── .gitignore
├── .dockerignore
├── pyproject.toml                    # uv-managed; deps + ruff/mypy/pytest config
├── uv.lock                           # committed; full transitive tree
├── Makefile
│
├── __main__.py                       # ROOT dispatcher; sits next to src/, NOT inside
│
├── docker/                           # one Dockerfile per entrypoint the service ships
│   ├── Dockerfile.api                # omit if no HTTP API
{{#IF HAS_KAFKA}}│   ├── Dockerfile.consumer           # omit if no consumer
{{/IF}}│   ├── Dockerfile.cronjob            # omit if no cronjob
│   ├── Dockerfile.<role>             # any other entrypoint (worker, grpc, websocket, stream, …)
│   └── docker-compose.yml
│
├── migrations/                       # Alembic with RAW SQL (no SQLAlchemy)
│   ├── env.py
│   ├── script.py.mako
│   └── versions/                     # YYYYMMDD_HHMM__<service>__<description>.py
│
├── scripts/
│   ├── seed.py
│   └── healthcheck.sh
│
├── tests/
│   ├── conftest.py
│   ├── unit/
│   │   └── domain/
│   ├── integration/
│   │   ├── api/
{{#IF HAS_KAFKA}}│   │   ├── consumers/
{{/IF}}│   │   ├── cronjobs/
│   │   └── <role>/
│   └── e2e/
│
└── src/
    ├── __init__.py
    │
    ├── api/                          # ── HTTP entrypoint (URL-versioned) ──
    │   ├── main.py                   # FastAPI app, mounts v1/v2
    │   ├── lifespan.py
    │   ├── middleware/
    │   │   ├── x_request_id.py        # reads inbound X-Request-ID (nginx-issued), echoes on response
    │   │   └── error_handler.py       # (registration only; ACTUAL global handler is via app.add_exception_handler, see §4.9)
    │   ├── v1/
    │   │   ├── router.py
    │   │   ├── routes/                # one file per resource — thin adapters
    │   │   ├── schemas/               # HTTP wire contracts for v1 (frozen with v1)
    │   │   ├── deps/                  # FastAPI Depends() builders for v1 (transport-only)
    │   │   └── responses/             # custom response classes [optional]
    │   └── v2/
    │       └── ...                    # only when a v2 exists
    │
{{#IF HAS_KAFKA}}    ├── consumers/                    # ── Queue entrypoint (NOT URL-versioned) ──   [optional]
    │   ├── main.py
    │   ├── registry.py               # topic → handler mapping
    │   ├── handlers/
    │   │   └── <event>.py
    │   └── schemas/                  # per-event versioning
    │       └── <event>_v1.py
    │
{{/IF}}    ├── cronjob/                      # ── Scheduled entrypoint (NOT versioned) ──   [optional]
    │   ├── main.py
    │   └── jobs/
    │       └── <name>.py
    │
    ├── domain/                       # ── Domain entities (shared, NOT versioned) ──
    │   ├── <entity>/                 # one folder per entity
    │   │   ├── constants/            # TABLE_NAME, ALL_COLUMNS_NAMES, filter sets, enums
    │   │   ├── data_models/          # INTERNAL domain DTOs (commands, results, events, entities) — not wire
    │   │   ├── database/
    │   │   │   ├── sql/              # numbered 0N1…0N8 raw-SQL files (reference)
    │   │   │   └── action/           # <Entity>DbAction subclass + module-level singleton
    │   │   ├── services/             # ONE file per entity (= the entity name); class <Entity>Service exposes perform_* methods
    │   │   │   └── <entity>.py
{{#IF HAS_KAFKA}}    │   │   └── consumers/            # entity-local in-process listeners (see §4.8) [optional]
{{/IF}}    │   └── system/                   # /healthCheck, /readiness, /warmup logic (tiny)
    │       └── services/
    │           └── system.py
    │
    └── infra/                        # ── Infrastructure ring ──
        ├── platform/                 # internal foundations we own
        │   ├── config.py             # pydantic-settings
        │   ├── directories.py        # path constants (project root, src, tests, scripts)
        │   ├── database.py           # asyncpg pool
{{#IF HAS_REDIS}}        │   ├── cache.py              # redis (per-service namespace; caching only) [optional — omit if no Redis]
{{/IF}}{{#IF HAS_KAFKA}}        │   ├── messaging.py          # kafka client [optional — omit if no Kafka]
{{/IF}}        │   ├── logging.py            # JSON formatter via SERVICE_LOG_IN_JSON_FORMAT
        │   ├── security.py           # JWT verify (public key only; signing only in auth)
        │   ├── correlation.py        # X-Request-ID propagation
        │   └── exceptions.py         # global handler registration
        │
        └── integrations/             # external clients (sibling services, 3rd-party SaaS)
            ├── object_storage.py     # thin wrapper over shared-logic MinIO adapter
            ├── auth.py               # inter-service agent to backend-auth
{{#IF OTP_PROVIDER}}            ├── {{OTP_PROVIDER}}.py           # OTP SMS client (in the SMS_CLIENT_LOCATION)
{{/IF}}{{#IF CAPTCHA_PROVIDER}}            ├── {{CAPTCHA_PROVIDER}}.py           # captcha verify
{{/IF}}{{#IF CDN_PROVIDER}}            ├── {{CDN_PROVIDER}}.py           # CDN purge
{{/IF}}{{#IF PSP_PROVIDER}}            ├── {{PSP_PROVIDER}}.py           # payment gateway
{{/IF}}            └── ...                   # service-specific external integrations only
```

---

## 3. Multiple entrypoints, one shared core [BE]

Each entrypoint is its own process / container; every entrypoint imports from the same `domain/` and `infra/`. A service ships only the entrypoints (and matching Dockerfiles) it uses.

Every role is launched through a single root-level dispatcher, `__main__.py` (alongside `src/`, not inside it). The role is passed as the first positional argument:

```bash
python __main__.py api          # API process (delegates to src/api/main.py)
{{#IF HAS_KAFKA}}python __main__.py consumer     # Consumer process (delegates to src/consumers/main.py)
{{/IF}}python __main__.py cronjob      # Cronjob process (delegates to src/cronjob/main.py)
python __main__.py <role>       # Any other entrypoint
```

`uvicorn src.api.main:app` and `python -m src.<role>.main` are **not** used — every container goes through `python __main__.py <role>` so there is one invocation shape across every role and every service.

Containerisation — one `Dockerfile.<role>` per entrypoint, every one using the dispatcher.

### 3.1 Dispatcher — root `__main__.py`

`__main__.py` sits at the repo root next to `src/`, not inside `src/`. It is a thin dispatcher that picks one role from `sys.argv[1]` and delegates to that role's `main.py`. It never runs more than one role per process — one container per role.

```python
# __main__.py  (at repo root, NOT under src/)
import sys
from src.api import main as api
{{#IF HAS_KAFKA}}from src.consumers import main as consumer
{{/IF}}from src.cronjob import main as cron

ROLES = {
    "api": api.run,
{{#IF HAS_KAFKA}}    "consumer": consumer.run,
{{/IF}}    "cronjob": cron.run,
}

def main() -> None:
    role = sys.argv[1] if len(sys.argv) > 1 else "api"
    ROLES[role]()

if __name__ == "__main__":
    main()
```

Deploy as separate workloads, same image, different `CMD` / `command`.

---

## 4. Layering rules [BE] — REQUIRED IN v1

These rules are **non-negotiable for every v1 backend microservice**. A new service that violates any rule below is a review-blocking defect.

The layout is **three concentric rings**. Inner rings know nothing about outer rings.

- **Transport ring** — `api/`{{#IF HAS_KAFKA}}, `consumers/`{{/IF}}, `cronjob/`, `worker/`. Thin adapters; own their wire schemas and any transport-specific dependency wiring.
- **Domain ring** — `domain/<entity>/`. All business logic. No framework imports. One service per entity.
- **Infrastructure ring** — `infra/platform/` (we own it) + `infra/integrations/` (external clients).

### 4.0 Two invariants

1. **Inner rings never import from outer rings.** `from src.api...` inside `src/domain/...` is a review-blocking defect; same for `from src.domain...` inside `src/infra/...`.
2. **A new transport adds one outer-ring folder** + thin adapters. It never duplicates `domain/`, `infra/`, or `migrations/`.

### 4.1 `domain/` is the single source of truth — one service class per entity

API routes{{#IF HAS_KAFKA}}, consumer handlers{{/IF}}, and cron jobs are thin adapters that call **one method on the entity's service class**, `domain/<entity>/services/<entity>.py`. Business logic never lives in `api/v1/routes/*`{{#IF HAS_KAFKA}}, `consumers/handlers/*`{{/IF}}, or `cronjob/jobs/*` — push it into the `<Entity>Service` class.

**One service class per entity. One file per entity. One public method per operation.** Public surface: fixed `perform_<verb>` vocabulary — `perform_create`, `perform_fetch`, `perform_fetch_by_filter`, `perform_update`, `perform_delete`, plus domain-specific verbs (`perform_publish`, `perform_schedule`, `perform_rollback`, `perform_login`, …).

```python
# src/domain/<entity>/services/<entity>.py
class <Entity>Service:
    """All business logic for the <entity>."""

    def __init__(self, current_user: CurrentUser) -> None:
        self.current_user = current_user

    async def perform_create(self, command: CommandCreate<Entity>) -> ResultCreate<Entity>: ...
    async def perform_fetch(self, command: CommandFetch<Entity>) -> ResultFetch<Entity>: ...
    async def perform_fetch_by_filter(self, command: CommandFetch<Entities>ByFilter) -> ResultFetch<Entities>ByFilter: ...
    async def perform_update(self, command: CommandUpdate<Entity>) -> ResultUpdate<Entity>: ...
    async def perform_delete(self, command: CommandDelete<Entity>) -> ResultDelete<Entity>: ...

    async def _validate_<invariant>(self, ...) -> None: ...
    async def _fetch_<related>(self, ...) -> ...: ...
```

Attribute / local-variable names follow the prefix vocabulary in [`coding.md`](./coding.md) §2.1.

### 4.2 Wire schemas ≠ internal DTOs

| File | Purpose | Lifecycle |
|---|---|---|
| `src/api/v1/schemas/<entity>.py` | Public HTTP request / response | Frozen for v1's lifetime |
{{#IF HAS_KAFKA}}| `src/consumers/schemas/<event>_v1.py` | Inbound Kafka event | Frozen per event version |
{{/IF}}| `src/domain/<entity>/data_models/` | Internal domain DTOs (commands, results, events, entities) | Free to refactor |

The transport adapter (route function, handler, job) translates between the two. **No internal DTO leaks through a wire response.**

### 4.3 Transport dependencies stay in the transport ring

FastAPI `Depends()` builders{{#IF HAS_KAFKA}} and consumer registration{{/IF}} are *transport-layer wiring* — they import framework primitives. They live where the framework lives:

- `src/api/v{N}/deps/<topic>.py` — FastAPI `Depends()` builders.
- `src/api/middleware/<topic>.py` — REST middleware only (`X-Request-Id`, request logging).
{{#IF HAS_KAFKA}}- `src/consumers/registry.py` — topic → handler mapping.
{{/IF}}

### 4.4 Post-response work → {{#IF HAS_KAFKA}}Celery-on-Kafka / shared-logic Kafka worker template{{#ELSE}}outbox + worker{{/IF}}

**Never FastAPI `BackgroundTasks` for durable work.** {{#IF HAS_KAFKA}}Producer (request path) calls the entity's service for the synchronous work, then emits a Kafka event. A Celery worker (or the shared-logic Kafka worker template) consumes the event on its own process; Celery / template owns retry / backoff / DLQ per [`errors-and-observability.md`](./errors-and-observability.md) §8.{{#ELSE}}The producer inserts a task row into `shared__outbox_tasks` inside the same DB transaction as the entity write. If the transaction rolls back, the task never exists.{{/IF}}

### 4.5 Cross-entity calls go through services, not data-access classes

A service class calls **another entity's service**, never the other entity's `database/action/` directly. From inside `<Entity>Service.perform_<verb>`, fetching related data looks like `await <Other>Service(self.current_user).perform_fetch(command_fetch_other)` — not `other_db_action.fetch(...)`.

### 4.6 No ORM — raw SQL via `DbAction`

No SQLAlchemy. Every entity owns `database/action/action.py` containing a `<Entity>DbAction` subclass of `backend_shared_logic.database.DbAction` plus a module-level singleton. All SQL is parameterised raw SQL; column / filter / sort allow-lists live in `constants/db.py`. See [`infrastructure.md`](./infrastructure.md) §3.

### 4.7 Shared infrastructure adapters

How services consume the shared data-plane components lives in [`infrastructure.md`](./infrastructure.md). Postgres = §3{{#IF HAS_REDIS}}, Redis = §4{{/IF}}{{#IF HAS_KAFKA}}, Kafka = §5{{/IF}}, MinIO ={{#IF HAS_MEILISEARCH}} §6, Meilisearch = §7{{#ELSE}} §5{{/IF}}.

{{#IF HAS_MIRROR_TABLES}}### 4.8 Mirror tables — cross-service replication via Kafka — v1 STANDARD

Several services keep a **read-only mirror** of an entity owned by another service so they can join locally without a synchronous inter-service call on the request path.

#### Roles

| Role | What it owns | What it does |
|---|---|---|
| **Origin** | The source-of-truth table (`<owner_service>__<entity>`). | On every create / update / delete, publishes the change as a Kafka event. Also exposes a resync route. |
| **Mirror** | A read-only mirror table `<consumer_service>__mirror_of_<origin_service>__<origin_entity>`. | Subscribes to the topic; upserts events into the mirror table. Never writes via any other path. |

#### Topic

- Topic name follows `<owner>-<consumer(s)>-<entity>-mirror`.
- **Partition key = `record_id`** so updates for the same row are processed in order.
- Payload: `{schema_version, op ("upsert" | "delete"), record_id, updated_at, row}`.
- DLQ per source: `<topic>-dlq`.

#### Mirror-side idempotency

- The mirror schema **always** carries `record_id` (PK), `updated_at TIMESTAMPTZ NOT NULL`, and an `INDEX` on `record_id`.
- Upsert uses `INSERT … ON CONFLICT (record_id) DO UPDATE … WHERE EXCLUDED.updated_at > <mirror_table>.updated_at`.

#### Sync route — full-table replay

Every origin service exposes an **admin-gated sync route**: `POST /<owner_prefix>/v1/admin/mirrors/<entity>:resync`. Publishes a `resync_started` sentinel, then normal `upsert` events, then a `resync_complete` sentinel. Idempotent on `resync_id`.

#### Mirror-side resync — shadow-swap (atomic, zero read outage)

Consumer creates `<mirror>_new` under the sentinel, routes resync events into it, and on `resync_complete` takes a Postgres advisory lock and atomically swaps via three `ALTER TABLE … RENAME` statements inside one transaction. **RPO = 0.**

#### Constraints

- A mirror is **read-only to the rest of the consuming service**.
- A mirror table is **not the source of truth for any decision that affects another service's state**.
- Sync route is **admin-gated and idempotent**.
{{/IF}}

### 4.9 Global exception handling — FastAPI `add_exception_handler`, **not** middleware

Every raised exception (`ProjectBaseException` subclasses, `pydantic.ValidationError`, `RequestValidationError`, bare `Exception`) becomes an envelope through **FastAPI's `app.add_exception_handler(...)` mechanism** — not a middleware.

- Handler definitions + `register(app)` — {{#IF ARCH_SHAPE=microservices}}exported by `backend_shared_logic.fastapi_exception_handler`{{/IF}}.
- Wired from the API app factory — `src/api/main.py:create_app` calls `register_exception_handlers(app)` right after middleware wiring.
- A middleware-style error handler, or a `try/except` inside a route function that swallows errors and builds an envelope by hand, is a review-blocking defect.

---

## 5. Shared-logic library rule — v1 STANDARD

`backend-shared-logic` is a **git-tag pinned Python package** — a library, not a service (no app, no DB, no container). Modules include: exception + envelope; raw-asyncpg `DbAction` base; JWT verify (RS256 public key); MinIO adapter{{#IF HAS_REDIS}}; Redis wrapper{{/IF}}{{#IF HAS_KAFKA}}; Kafka producer / consumer bases{{/IF}}; circuit-breaker agent base; OTel bootstrap; PII-scrubbing `JsonFormatter`; `tenacity` retry base; ULID helpers.

- Distributed by tag; each consumer pins the version in `pyproject.toml` + `uv.lock`.
- **CI shared-logic version-lock gate blocks a stale pin in every consumer** — see [`ci-cd.md`](./ci-cd.md).
- Never fork per service; never re-implement a shared primitive per service.

---

## 6. Adding and retiring an API version [BE]

Adding `v2`:

1. Add `src/api/v2/routes/<entity>.py` for routes that change.
2. Add `src/api/v2/schemas/<entity>.py` for shapes that change.
3. Add `src/api/v2/deps/<topic>.py` for FastAPI deps that change.
4. Leave `src/domain/<entity>/` untouched — or grow new methods on the same service; never fork the domain folder.

Retiring `v1`: delete `src/api/v1/`. If retiring v1 would require touching `domain/` or `infra/`, the version boundary has leaked — fix the leak.

---

## 7. "Where does X go?" — decision tree [BE]

- **Business logic** → `src/domain/<entity>/services/<entity>.py`. Extend `<Entity>Service` with a new `perform_<verb>` method.
- **Wire contract** — REST request/response → `src/api/v{N}/schemas/<entity>.py`; {{#IF HAS_KAFKA}}Kafka event payload → `src/consumers/schemas/<event>_v{N}.py`; {{/IF}}otherwise a domain DTO → `src/domain/<entity>/data_models/`.
- **Transport adapter** — REST endpoint → `src/api/v{N}/routes/<entity>.py` (3-5 lines: build Command, call service, return ResponseModel; ZERO business logic); {{#IF HAS_KAFKA}}consumer handler → `src/consumers/handlers/<event>.py`; {{/IF}}scheduled job → `src/cronjob/jobs/<name>.py` (one-liner: call the domain service).
- **Transport-layer deps** — FastAPI `Depends()` → `src/api/v{N}/deps/<topic>.py`; middleware (`X-Request-Id`, request logging) → `src/api/middleware/<topic>.py`.
- **Infrastructure plumbing** — config / pool / logger / JWT verify / correlation → `src/infra/platform/`; external client (sibling service or 3rd-party SaaS) → `src/infra/integrations/`.
- **Persistence** — new entity / column / index → `migrations/versions/<YYYYMMDD_HHMM>__<service>__<desc>.py` (raw SQL via `op.execute(...)`) + reference files under `src/domain/<entity>/database/sql/`. New query for an existing entity → `src/domain/<entity>/database/action/action.py`. Cross-service SQL → don't; call the other service.
- **Test** → mirrored `tests/{unit,integration,e2e}/` tree.

---

## 8. New microservice compliance checklist [BE] — v1 STANDARD

A new backend microservice is compliant when every item below is true.

- [ ] Root-level `__main__.py` (next to `src/`, not inside it) is a dispatcher that picks one role from `sys.argv[1]` and delegates to `src/<role>/main.py`. Every container's entrypoint is `python __main__.py <role>`.
- [ ] `src/` has the canonical horizontal split: `api/` (always for services){{#IF HAS_KAFKA}}, optional `consumers/`{{/IF}}, optional `cronjob/` / `<role>/`, `domain/`, `infra/{platform,integrations}/`. No `src/v1/` umbrella.
- [ ] `src/api/main.py`, `src/api/lifespan.py`, and `src/api/middleware/` are in place; each version's router is included via `app.include_router(v{N}_router, prefix="/<SERVICE_ENDPOINT_PREFIX>/v{N}")` — no `app.mount()` sub-apps.
- [ ] Each REST version is one self-contained folder: `src/api/v{N}/{router.py, routes/, schemas/, deps/}`.
- [ ] `src/infra/platform/` contains `config.py`, `directories.py`, `database.py`, `logging.py`, `security.py`, `correlation.py`, `exceptions.py`. Add `cache.py` if the service uses Redis; add `messaging.py` if it produces or consumes Kafka.
- [ ] `src/infra/integrations/` holds every external client (sibling-service and 3rd-party); routes and services never import an HTTP client directly.
- [ ] Every business entity is a folder under `src/domain/<entity>/` with: `constants/`, `data_models/`, `database/{sql,action}/`, `services/`.
- [ ] **One service class per entity.** `src/domain/<entity>/services/<entity>.py` defines `<Entity>Service` with `perform_<verb>` methods. Attribute / local-variable names follow the prefix vocabulary in [`coding.md`](./coding.md) §2.1.
{{#IF HAS_MIRROR_TABLES}}- [ ] Mirror tables (if any) follow §4.8 — shadow-swap resync, RPO = 0, admin-gated resync route.
{{/IF}}- [ ] Wire-contract models live at `src/api/v1/schemas/<entity>.py` (and per-role `<role>/schemas/`); internal DTOs stay under `src/domain/<entity>/data_models/`. No internal DTO leaks through FastAPI `response_model`.
- [ ] Cross-entity access goes through the other entity's `services/`, never through its `database/action/` directly.
- [ ] Every table named `<service>__<entity>` with ULID PK (or natural-key PK for code-seeded lookup tables), `created_at` / `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()` UTC.
- [ ] Schema changes run via Alembic, not at startup. Migrations use raw SQL only (`op.execute(…)`); no `op.create_table()`, no SQLAlchemy model imports.
- [ ] CI/CD pipeline runs the **pre-deploy migration gate** — `alembic upgrade head` + drift check — against the target environment's database before the new app revision serves; non-zero exit on either fails the deploy.
- [ ] Versioning lives only inside `src/api/v{N}/` (plus per-event / per-message `*_v{N}.py`). Bare `v1` — no dated form.
- [ ] `pyproject.toml` declares all deps (runtime + dev group); `uv.lock` committed and pins the full transitive tree. **`backend-shared-logic` pinned to the current release** — the CI shared-logic version-lock gate fails otherwise.
- [ ] `docker/Dockerfile.<role>` files match the canonical per-role template; `.gitlab-ci.yml` matches the canonical pipeline.
- [ ] `.pre-commit-config.yaml` matches the canonical hooks; `pyproject.toml` ruff / mypy / pytest / coverage configs match — see [`coding.md`](./coding.md) §9.
- [ ] `.env.example` lists every `EnvLoader` field with safe defaults; no real secrets committed.
- [ ] `<service>__configurations` table seeded with required runtime rows.
- [ ] `/healthCheck` (liveness), `/readiness` (asyncpg `SELECT 1`), and `/warmup` (parallel dependency wake-up) all exposed. `/warmup` is unauthenticated and returns 200 with a per-dependency status map.
- [ ] Auth, error, CORS, logging wiring all go through `backend-shared-logic`; no service-local re-implementations.
- [ ] Tests live under `tests/unit/domain/<entity>/` + `tests/integration/api/<entity>/` + `tests/e2e/`, use shared `mock_db_pool` / `mock_current_user` fixtures, and meet per-area coverage targets.
- [ ] Branch + commit format and the three-branch `develop → staging → main` promotion model match — see [`git.md`](./git.md).
