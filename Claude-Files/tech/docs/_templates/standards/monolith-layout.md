# Monolith Layout (tech)

> **Documentation placement.** Cross-repo standard defining the canonical project layout for the backend monolith (see [`documentation.md`](./documentation.md) §5). Applies to that one repo.

## Scope

Canonical directory layout for the {{PROJECT_NAME}} backend monolith. One repo, one FastAPI app, **seven or more internal modules** under `src/modules/`, an optional in-process worker, all sharing one Postgres database.

Out of scope: HTTP contract specifics — [`api-and-data-contracts.md`](./api-and-data-contracts.md); macro architecture — [`../project-architecture/v1.md`](../project-architecture/v1.md); Postgres and MinIO conventions — [`infrastructure.md`](./infrastructure.md); error class and observability — [`errors-and-observability.md`](./errors-and-observability.md).

Reading conventions: **CURRENT** = today. **v1 STANDARD** = required for v1, in force now. Applicability: **[BE]**.

---

## 1. Versioning rules [BE] — v1 STANDARD

Version anything that is part of an external (wire) contract; share everything else.

| Layer | Versioned? |
|---|---|
| `src/api/v1/…`, `src/api/v2/…` (routes + schemas + deps) | yes (URL path) |
| `src/worker/handlers/*_v1.py` | yes (per-message) if the message enters the process from outside; not versioned if it is a purely in-process trigger. |
| `src/modules/<module>/…` | no |
| `src/modules/shared/…` | no |

Rules:

- Versioning lives only inside `src/api/vN/` and per-message `*_vN.py` in `src/worker/handlers/`.
- **No `src/domain/` folder** — that vocabulary is µsvc-only. Domain logic lives inside each module under `src/modules/<module>/`.
- No `src/v1/` umbrella above modules.
- Version names are bare `v1`, `v2`, … — never `v1.YYYY.MM.DD` or any dated form.

See also: API path versioning in [`api-and-data-contracts.md`](./api-and-data-contracts.md).

---

## 2. Canonical layout [BE] — v1 STANDARD

```
backend-monolithic/
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
│   ├── Dockerfile.api                # the FastAPI process
│   ├── Dockerfile.worker             # the in-process background worker (see §5) [when needed]
│   ├── Dockerfile.cronjob            # scheduled maintenance jobs (see §6) [optional]
│   └── docker-compose.yml            # local dev stack (app + Postgres + MinIO)
│
├── deploy/
│   ├── compose/
│   │   ├── docker-compose.develop.yml
│   │   ├── docker-compose.staging.yml
│   │   └── docker-compose.production.yml
│   └── nginx/                        # reference nginx configs (real ones live in infra-nginx)
│
├── migrations/                       # Alembic with RAW SQL (no SQLAlchemy)
│   ├── env.py
│   ├── script.py.mako
│   └── versions/                     # YYYYMMDD_HHMM__<module>__<description>.py
│
├── scripts/
│   ├── seed.py                       # seed development data
│   ├── bootstrap_admin.py            # first-admin bootstrapper (see security-and-auth §5)
│   └── healthcheck.sh
│
├── tests/
│   ├── conftest.py
│   ├── unit/
│   │   └── modules/
│   ├── integration/
│   │   ├── api/
│   │   ├── worker/
│   │   └── cronjob/
│   └── e2e/
│
├── docs/
│   └── v1/PRD-TDD.md
│
└── src/
    ├── __init__.py
    │
    ├── api/                          # ── HTTP entrypoint (URL-versioned) ──
    │   ├── main.py                   # FastAPI app, mounts v1
    │   ├── lifespan.py               # startup: DB pool, config load, key load; shutdown: pool close
    │   ├── middleware/
    │   │   ├── x_request_id.py        # reads inbound X-Request-Id (nginx-issued), echoes on response
    │   │   ├── request_logging.py     # one INFO log per request outcome (NOT error handling; see §4.9)
    │   │   └── locale.py              # locale detection: URL prefix > Accept-Language > default
    │   └── v1/
    │       ├── router.py              # top-level router; includes per-module sub-routers
    │       ├── routes/                # one file per exposed resource — thin adapters
    │       │   └── <module>.py        # /api/v1/<module>/*
    │       ├── schemas/               # HTTP wire contracts for v1 (frozen with v1)
    │       │   └── <module>.py
    │       └── deps/                  # FastAPI Depends() builders for v1 (transport-only)
    │           ├── auth.py            # bearer JWT extraction, current_user
    │           ├── pagination.py      # page/size/sort parsing
    │           └── locale.py          # dep that returns Locale enum from URL / header
    │
    ├── worker/                       # ── Background worker entrypoint (NOT URL-versioned) ──   [when background work is needed]
    │   ├── main.py                   # long-running process that drains the outbox
    │   ├── registry.py               # task_type → handler mapping
    │   ├── handlers/
    │   │   └── <task>.py
    │   └── schemas/                  # per-task payload contracts (versioned per-task)
    │       └── <task>_v1.py
    │
    ├── cronjob/                      # ── Scheduled entrypoint ── [optional]
    │   ├── main.py
    │   └── jobs/
    │       └── <name>.py
    │
    └── modules/                      # ── Business modules ──
        │
        ├── shared/                   # cross-module foundations (NOT a domain module) — three buckets:
        │   ├── platform/             # ── bucket 1: internal infra + pure helpers ──
        │   │   ├── config/
        │   │   │   ├── envs.py           # pydantic-settings
        │   │   │   ├── directories.py    # path constants
        │   │   │   └── configurations.py # <settings__configurations> reader
        │   │   ├── database/
        │   │   │   ├── pool.py           # asyncpg pool factory (per lifespan)
        │   │   │   ├── action.py         # DbAction base class
        │   │   │   └── filter_engine.py  # canonical filter/pagination compiler
        │   │   ├── logging/
        │   │   │   └── logger.py         # JSON formatter + context-var wiring
        │   │   ├── security/
        │   │   │   ├── jwt.py            # sign (auth only) + verify (every request path)
        │   │   │   ├── password.py       # bcrypt wrap
        │   │   │   └── otp.py            # random-code generator + bcrypt hash
        │   │   ├── correlation/
        │   │   │   └── request_id.py     # ContextVar for X-Request-Id propagation
        │   │   ├── exceptions/
        │   │   │   ├── project_base.py   # ProjectBaseException
        │   │   │   └── handler.py        # global handler registration (FastAPI add_exception_handler)
        │   │   ├── i18n/                 # optional (locale-dependent projects only)
        │   │   │   ├── locale.py
        │   │   │   ├── jalali.py         # Jalali <-> Gregorian conversion
        │   │   │   └── digits.py         # Persian numeral conversion
        │   │   └── outbox/
        │   │       ├── enqueue.py        # transactional-outbox insert helper
        │   │       └── drain.py          # worker-side batch drainer
        │   ├── integrations/         # ── bucket 2: external third-party clients ──
        │   │   ├── object_storage.py # MinIO adapter
        │   │   ├── circuit_breaker.py # per-provider CLOSED/OPEN/HALF_OPEN state
{{#IF CAPTCHA_PROVIDER}}        │   │   ├── {{CAPTCHA_PROVIDER}}.py           # captcha server-side verify
{{/IF}}{{#IF OTP_PROVIDER}}        │   │   ├── {{OTP_PROVIDER}}.py           # OTP SMS provider
{{/IF}}{{#IF CDN_PROVIDER}}        │   │   ├── {{CDN_PROVIDER}}.py           # CDN purge
{{/IF}}        │   │   └── smtp.py           # SMTP outbound
        │   └── services/             # ── bucket 3: shared's own service classes (only for shared__* tables) ──
        │       ├── configurations.py # ConfigurationsService — admin CRUD for settings__configurations
        │       ├── outbox.py         # OutboxService — DLQ inspection surface for admin
        │       └── frontend_errors.py # FrontendErrorsService — frontend error log bridge
        │
        └── <module>/                 # one folder per module (seven or more)
            ├── constants/            # TABLE_NAME, ALL_COLUMNS_NAMES, filter sets, enums
            ├── data_models/          # INTERNAL DTOs (commands, results, events, entities) — not wire
            ├── database/
            │   ├── sql/              # numbered 0N1…0N8 raw-SQL files (reference)
            │   └── action/           # <Entity>DbAction subclass + module-level singleton
            ├── services/             # ONE file per entity; class <Entity>Service exposes perform_* methods
            │   └── <entity>.py       # class <Entity>Service: perform_create / _fetch / _fetch_by_filter / _update / _delete + domain verbs
            ├── consumers/            # in-process listeners (see §5) [optional]
            └── worker/               # module-local background handlers [optional, when outbox pattern is in play]
```

---

## 3. The one-process story [BE] — v1 STANDARD

Every entrypoint is its own process / container; every entrypoint imports from the same `src/modules/`. The dispatcher `__main__.py` at the repo root (alongside `src/`, not inside it) picks one role from `sys.argv[1]` and delegates:

```bash
python __main__.py api          # API process (delegates to src/api/main.py)
python __main__.py worker       # Worker process (delegates to src/worker/main.py)
python __main__.py cronjob      # Cronjob process (delegates to src/cronjob/main.py)
```

`uvicorn src.api.main:app` and `python -m src.worker.main` are **not** used — every container goes through `python __main__.py <role>` so there is one invocation shape across every role.

Containerisation — one `Dockerfile.<role>` per entrypoint, every one using the dispatcher.

### 3.1 Dispatcher — root `__main__.py`

```python
# __main__.py  (at repo root, NOT under src/)
import sys
from src.api import main as api
from src.worker import main as worker
from src.cronjob import main as cronjob

ROLES = {
    "api": api.run,
    "worker": worker.run,
    "cronjob": cronjob.run,
}

def main() -> None:
    role = sys.argv[1] if len(sys.argv) > 1 else "api"
    ROLES[role]()

if __name__ == "__main__":
    main()
```

Deploy as separate compose services, same image, different `command`:

- `api` — bound to port 8080; probed by nginx upstream health check.
- `worker` — no port bound; probed by `docker exec scripts/healthcheck.sh`.
- `cronjob` — single-shot; scheduled by host cron or a `docker compose run` wrapper.

All three processes share the same `pyproject.toml` / `uv.lock`, the same `migrations/` history, and the same database.

---

## 4. Layering rules [BE] — REQUIRED IN v1

These rules are **non-negotiable for v1**. A new module or endpoint that violates any rule below is a review-blocking defect.

The layout is **three concentric rings**. Inner rings know nothing about outer rings.

- **Transport ring** — `src/api/`, `src/worker/`, `src/cronjob/`. Thin adapters; own their wire schemas and any transport-specific dependency wiring.
- **Module ring** — `src/modules/<module>/` (excluding `shared/`). All business logic. No framework imports. One service per entity.
- **Infrastructure ring** — `src/modules/shared/` — split into three buckets: `platform/` (internal infra + pure helpers), `integrations/` (external third-party clients), `services/` (shared's own tiny business surface — `shared__configurations` + `shared__outbox_tasks` admin CRUD).

Two invariants:

1. **Inner rings never import from outer rings.** `from src.api...` inside `src/modules/...` is a review-blocking defect; same for `from src.modules.<module>...` inside `src/modules/shared/...`.
2. **A new transport adds one outer-ring folder** + thin adapters. It never duplicates `src/modules/`, `src/modules/shared/`, or `migrations/`.

### 4.1 `src/modules/<module>/` is the single source of truth — one service class per entity

API routes, worker handlers, and cron jobs are thin adapters that call **one method on the entity's service class**, `src/modules/<module>/services/<entity>.py`. Business logic never lives in `src/api/v1/routes/*`, `src/worker/handlers/*`, or `src/cronjob/jobs/*` — push it into the `<Entity>Service` class.

**One service class per entity. One file per entity. One public method per operation.** The class is named `<Entity>Service`; the file is named after the entity. Public surface is the fixed `perform_<verb>` vocabulary:

- `perform_create`, `perform_fetch`, `perform_fetch_by_filter`, `perform_update`, `perform_delete`.
- Domain-specific verbs as the entity needs (`perform_publish`, `perform_login`, `perform_submit_<form>`, …).

Each `perform_<verb>` takes a canonical `Command` DTO and returns a `Result` DTO from `data_models/`. **No shared `perform()` orchestrator, no `self.record` accumulator** — every public entry point owns its own flow. Private helpers (`_validate_…`, `_fetch_…`, `_insert_…`) live on the same class. Attribute / local-variable names follow the prefix vocabulary in [`coding.md`](./coding.md) §2.1.

```python
# src/modules/<module>/services/<entity>.py
class <Entity>Service:
    """All business logic for the <entity>."""

    def __init__(self, current_user: CurrentUser) -> None:
        self.current_user = current_user

    async def perform_create(self, command: CommandCreate<Entity>) -> ResultCreate<Entity>: ...
    async def perform_fetch(self, command: CommandFetch<Entity>) -> ResultFetch<Entity>: ...
    async def perform_fetch_by_filter(self, command: CommandFetch<Entities>ByFilter) -> ResultFetch<Entities>ByFilter: ...
    async def perform_update(self, command: CommandUpdate<Entity>) -> ResultUpdate<Entity>: ...
    async def perform_delete(self, command: CommandDelete<Entity>) -> ResultDelete<Entity>: ...
```

### 4.2 Wire schemas ≠ internal DTOs

| File | Purpose | Lifecycle |
|---|---|---|
| `src/api/v1/schemas/<module>.py` | Public HTTP request / response | Frozen for v1's lifetime |
| `src/worker/schemas/<task>_v1.py` | Task payload contract | Frozen per task version |
| `src/modules/<module>/data_models/` | Internal domain DTOs (commands, results, events, entities) | Free to refactor |

The transport adapter (route function, worker handler, cron job) translates between the two. **No internal DTO leaks through a wire response.**

### 4.3 Transport dependencies stay in the transport ring

FastAPI `Depends()` builders, worker registry entries, cron scheduler wiring are *transport-layer wiring* — they import framework primitives (`fastapi.Depends`, `fastapi.Header`). They live where the framework lives:

- `src/api/v{N}/deps/<topic>.py` — FastAPI `Depends()` builders.
- `src/api/middleware/<topic>.py` — REST middleware only (`X-Request-Id`, request logging, locale detection). **Global exception handling does NOT live here** (see §4.9).
- `src/worker/registry.py` — task-type → handler mapping.

### 4.4 Post-response work → outbox → worker

FastAPI's `BackgroundTasks` is **allowed only for pure, side-effect-free response-time work** — computing derived data, warming a cache — because it dies with the process. Anything durable (email send, SMS send, media variant generation, search index rebuild) goes through the transactional outbox:

1. Route handler inserts a task row into `shared__outbox_tasks` (`task_type`, `payload_json`, `attempts`, `status`, `created_at`) inside the same DB transaction as the entity write. If the transaction rolls back, the task never exists.
2. The worker process (`python __main__.py worker`) polls `shared__outbox_tasks WHERE status = 'PENDING' ORDER BY created_at LIMIT N` on a short interval (500 ms default), executes each task's handler from `src/worker/handlers/`, and marks the row `SUCCEEDED` or bumps `attempts` and sets `FAILED` after N retries.
3. Retry policy is on the handler, not on the row — `tenacity.retry(wait_exponential_jitter, stop_after_attempt=5, retry_if_exception_type=ExternalServiceError)`.
4. Failed rows past the retry cap move to `shared__outbox_tasks_dlq` for manual inspection. Alert on DLQ growth in the observability stack.

**No Kafka in the default monolith.** The outbox table is the durable message queue. If Kafka is added later, this section grows accordingly — the module-local `worker/` folder migrates to a `consumers/` folder consuming Kafka topics.

### 4.5 Cross-module calls go through services, not `DbAction`

Cross-module calls go through the target module's **Service class**, never its `DbAction`. `<ModuleA>Service` calls `<ModuleB>Service.perform_<verb>`, never `moduleb_db_action.fetch(...)`. Each module owns its own persistence and exposes only the `<Entity>Service` class through `services/`.

**Cross-module SQL is forbidden.** A query in `src/modules/<module_a>/database/action/*.py` never references a `<module_b>__*` table. If a compound response needs both, the transport adapter builds it by calling both services.

### 4.6 No ORM — raw SQL via `DbAction`

No SQLAlchemy. Every entity owns `database/action/action.py` containing a `<Entity>DbAction` subclass of `shared.platform.database.action.DbAction` plus a module-level singleton. All SQL is parameterised raw SQL; column / filter / sort allow-lists live in `constants/db.py`. See [`infrastructure.md`](./infrastructure.md) §3.

### 4.7 Shared infrastructure — Postgres, MinIO{{#IF HAS_REDIS}}, Redis{{/IF}}

How modules consume the shared data-plane components — naming conventions, permitted vs forbidden uses, required adapters — lives in [`infrastructure.md`](./infrastructure.md).

### 4.8 Module-owned tables and configurations

Each module **owns its tables** (`<module>__<entity>`) and a section of the shared `settings__configurations` table under the `<module>.` key prefix. Runtime code reads via `ConfigurationsService.perform_fetch(key)` (cached in-process for 60 s); editors update via the admin panel; the change takes effect at the cache expiry.

### 4.9 Global exception handling — FastAPI `add_exception_handler`, **not** middleware

Every raised exception (`ProjectBaseException` subclasses, `pydantic.ValidationError`, `RequestValidationError`, bare `Exception`) becomes an envelope through **FastAPI's `app.add_exception_handler(...)` mechanism** — not a middleware. Rationale:

1. Middleware runs outside the FastAPI route-resolution boundary; an exception raised inside a route would have to bubble through middleware layers to reach the handler.
2. `add_exception_handler` gives the handler clean access to `exc.status_code`, `exc.error_code`, `exc.message`, `exc.data`, and the `Request` object — no per-layer unwrapping.
3. Handlers are matched by exception type, not by ordering.

Layout:

- Handler definitions + `register(app)` — `src/modules/shared/platform/exceptions/handler.py`.
- Wired from the API app factory — `src/api/main.py:create_app` calls `register_exception_handlers(app)` right after middleware wiring.
- The one middleware slot that IS at `src/api/middleware/` (`request_logging.py`) logs the outcome — it does not translate errors.

A misnamed file, an error middleware, or a `try/except` inside a route function that swallows errors and builds an envelope by hand is a review-blocking defect.

---

## 5. When to split a module into a service — v1 STANDARD

**Deferred to v.next by default.** Splitting a module out of the monolith into its own service is a design decision that happens when the module has one of the following properties AND removing it from the monolith is a positive-ROI change:

- **Independent scaling profile** — the module's request rate or resource footprint is bounded to it (bursty ingest, heavy CPU / GPU, dedicated hardware).
- **Independent release cadence** — the module ships hot-fixes at a rate that couples poorly with the monolith's release train.
- **Independent runtime dependency** — the module wants a runtime the rest of the monolith doesn't (a different Python version, a Node process, a gRPC-only wire protocol).
- **Team boundary** — a distinct team owns end-to-end operation, and the coordination cost of the monolith release train dominates.

None of these should be assumed at v1 kickoff. Ship as a module first; extract later if the invariants above materialize. **Do not pre-split.**

Extraction path when it happens:

1. Freeze the module's public surface as an internal HTTP contract (still called through `<Module>Service` from the rest of the monolith — a thin `Service` shim that speaks HTTP instead of Python calls).
2. Move the module's tables to a new database owned by the new service; introduce a mirror table (or REST call) for any cross-module read that used to be a direct SQL join.
3. Move the module's `services/` + `database/` + `constants/` + `data_models/` into the new service repo. Wire its own `__main__.py`, `docker/`, `.gitlab-ci.yml`.
4. Delete the module folder from the monolith; the `<Module>Service` shim stays as an HTTP client until the callers are updated.

---

## 6. "Where does X go?" — decision tree [BE]

- **Business logic** → `src/modules/<module>/services/<entity>.py`. Extend `<Entity>Service` with a new `perform_<verb>` method.
- **Wire contract** — REST → `src/api/v{N}/schemas/<module>.py`; outbox task payload → `src/worker/schemas/<task>_v{N}.py`; otherwise a domain DTO → `src/modules/<module>/data_models/`.
- **Transport adapter** — REST endpoint → `src/api/v{N}/routes/<module>.py` (3-5 lines: build Command, call service, return ResponseModel); outbox task handler → `src/worker/handlers/<task>.py`; scheduled job → `src/cronjob/jobs/<name>.py`.
- **Transport-layer deps** — FastAPI `Depends()` → `src/api/v{N}/deps/<topic>.py`; middleware (`X-Request-Id`, request logging, locale) → `src/api/middleware/<topic>.py` (global exception handling is NOT here — see §4.9); post-response work → insert a row into `shared__outbox_tasks` from the route in the same TX as the write.
- **Shared / infrastructure plumbing** — config, DB pool, logger, JWT verify, correlation, exceptions, i18n, outbox helpers → `src/modules/shared/platform/`; object-storage / captcha / SMS / SMTP → `src/modules/shared/integrations/`.
- **Persistence** — new entity / column / index → `migrations/versions/<YYYYMMDD_HHMM>__<module>__<desc>.py` (raw SQL via `op.execute(...)`) + reference files under `src/modules/<module>/database/sql/`.
- **Cross-module** — go through the other module's `services/`, never its `database/action/` (§4.5).
- **Test** → mirrored `tests/{unit,integration,e2e}/` tree.

---

## 7. New module compliance checklist [BE] — v1 STANDARD

A new module inside `backend-monolithic` is compliant when every item below is true.

- [ ] Root-level `__main__.py` still lists every role in `ROLES` — a new module does not add a new role; roles are `api`, `worker`, `cronjob` only.
- [ ] `src/modules/<module>/` has the canonical horizontal split: `constants/`, `data_models/`, `database/{sql,action}/`, `services/`. Optional: `consumers/` (in-process listeners), `worker/` (module-local background handlers), `integrations/` (module-local external clients — global integrations live in `shared/integrations/`).
- [ ] `src/api/v1/routes/<module>.py` is included in `src/api/v1/router.py` with prefix `/api/v1/<module>` (or a resource path per [`api-and-data-contracts.md`](./api-and-data-contracts.md) §1).
- [ ] Every business entity is a folder under `src/modules/<module>/data_models/` and has a matching `services/<entity>.py` with `<Entity>Service`.
- [ ] Every table named `<module>__<entity>` (plural for collections, singular for explicit singletons), with ULID `id VARCHAR(50)` PK (or natural-key PK for code-seeded lookup tables) and `created_at` / `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()` UTC. SQL split into idempotent `0N1 … 0N8` files per entity — see [`infrastructure.md`](./infrastructure.md) §3.
- [ ] Schema changes run via Alembic, not at startup. Migrations use raw SQL only (`op.execute(…)`); no `op.create_table()`, no SQLAlchemy model imports.
- [ ] Cross-module access goes through the other module's `services/`, never through its `database/action/` directly (§4.5). No cross-module SQL.
- [ ] Post-response side effects go through `shared__outbox_tasks` + `src/worker/handlers/` (§4.4).
- [ ] Wire-contract models live at `src/api/v1/schemas/<module>.py`; internal DTOs stay under `src/modules/<module>/data_models/` (§4.2).
- [ ] `settings__configurations` seeded with any required runtime rows (`<module>.<key>` prefix). No cross-module writes to the config table.
- [ ] Auth, error, logging, i18n wiring all go through `src/modules/shared/platform/`; MinIO / captcha / SMS / SMTP / circuit-breaker wiring goes through `src/modules/shared/integrations/`; no module-local re-implementations.
- [ ] Tests live under `tests/unit/modules/<module>/` + `tests/integration/api/<module>/`, use shared `mock_db_pool` / `mock_current_user` fixtures, and meet coverage targets — see [`testing.md`](./testing.md).
- [ ] Branch + commit format matches [`git.md`](./git.md).
