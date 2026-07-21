# Code & Style Standards (tech)

> **Documentation placement.** Cross-repo standard — referenced by every engineering repo (see [`documentation.md`](./documentation.md) §5).

## Scope

Canonical code- and style-standards reference for the {{PROJECT_NAME}} platform.

- **Part 1 — Backend [BE]**: Python 3.13 / FastAPI / `asyncpg` / raw-SQL `DbAction`{{#IF ARCH_SHAPE=microservices}} / `backend-shared-logic`{{/IF}}.
- **Part 2 — Frontend [FE]**: Astro 5 landing (SSG) + Vite 6 + React 19 SPA(s) — see [`frontend.md`](./frontend.md) §2.

Rules marked **[SHARED]** apply to both. Per-{{OWNER_TERM}} layout, request lifecycle, and anatomy: {{#IF ARCH_SHAPE=microservices}}[`microservice-layout.md`](./microservice-layout.md){{#ELSE}}[`monolith-layout.md`](./monolith-layout.md){{/IF}}. Macro architecture: [`../project-architecture/v1.md`](../project-architecture/v1.md). API / data contracts: [`api-and-data-contracts.md`](./api-and-data-contracts.md).

Reading conventions: **CURRENT** = today. **v1 STANDARD** = required for v1, in force now. **STANDARD GOING FORWARD** = required target, not yet fully in place. **Frontend status: GREENFIELD** — Part 2 is prescriptive.

## Source of truth & precedence

| Source | Role |
|--------|------|
| `tech/backend-<{{OWNER_TERM}}>/pyproject.toml` | Authoritative ruff / mypy / pytest / coverage config. |
| `tech/backend-<{{OWNER_TERM}}>/.pre-commit-config.yaml` | Enforced local gate. |
| `tech/backend-<{{OWNER_TERM}}>/.gitlab-ci.yml` | MR-pipeline CI gates: `ruff` + `mypy` + `pytest` (+ coverage){{#IF ARCH_SHAPE=microservices}} + shared-logic version-lock{{/IF}}. |
| This document, **Part 2** | Frontend spec until a reference `frontend-*` app exists. |

---

# Part 1 — Backend [BE]

## 1. Structure & brevity limits [BE] — v1 STANDARD

| Limit | Target | Hard rule | Action if exceeded |
|-------|--------|-----------|--------------------|
| Lines per function | **< 10** | **≤ 30** | Extract private `_step()` methods on the same class. |
| Lines per method | **< 5** | — | Decompose. |
| Methods per class | **< 10** | — | Split responsibilities or move helpers to private `_step()` methods. Public surface stays small even when private helpers grow. |
| Modules per package | **< 10** | — | Introduce sub-packages. |
| Responsibility | **One per function / module; one entity per service class** | — | One service module exposes one `<Entity>Service` whose public surface is the `perform_<verb>` operation set on that entity. |

- **One service class per entity.** {{#IF ARCH_SHAPE=microservices}}`src/domain/<entity>/services/<entity>.py`{{#ELSE}}`src/modules/<module>/services/<entity>.py`{{/IF}} defines `<Entity>Service`. Public surface is a fixed `perform_<verb>` vocabulary — `perform_create`, `perform_fetch`, `perform_fetch_by_filter`, `perform_update`, `perform_delete`, plus any operation-specific verbs the entity needs. Each `perform_<verb>` takes a canonical `Command` DTO and returns a `Result` DTO from `data_models/`. See {{#IF ARCH_SHAPE=microservices}}[`microservice-layout.md`](./microservice-layout.md){{#ELSE}}[`monolith-layout.md`](./monolith-layout.md){{/IF}} §4.1.
- **Private helpers stay on the same class.** If a `perform_<verb>` needs to break out of the 10 / 30-line budget, extract `_validate_…` / `_fetch_…` / `_insert_…` / `_prepare_…` methods on the same class. There is no `perform()` orchestrator and no `self.record` accumulator — every public entry point owns its own flow and returns its own result.
- **All imports at the top of the file.** No deferred / function-local imports; no "import sub-app inside lifespan" workarounds. A genuine circular import is a layering bug — fix the layering, not the import site.
- Line length is **120** characters (§9). Target Python version is **3.13**.

---

## 2. Naming [BE] — v1 STANDARD

| Element | Convention | Example |
|---------|-----------|---------|
| Modules, functions, variables | `snake_case` | `get_recipient_phone`, `prepare_filter.py` |
| Private helpers | `_leading_underscore` | `_insert_<entity>_in_db` |
| Constants, enum values | `UPPER_SNAKE_CASE` | `ALL_COLUMNS_NAMES`, `PENDING` |
| Classes | `PascalCase` | `<Entities>Service`, `<Entities>DbAction` |
| Enum classes | `PascalCase` (suffix `Enum`) | `<Concept>Enum` |
| Database tables | `{{#IF ARCH_SHAPE=microservices}}<service>__<table>{{#ELSE}}<module>__<table>{{/IF}}` (double underscore) | see [`infrastructure.md`](./infrastructure.md) §2 |
| URL path segments | `camelCase` | `/{{OWNER_TERM}}Segment` |
| Service repos | `kebab-case`, prefixed by tier | `backend-<name>`, `frontend-<name>`, `infra-<name>` |
{{#IF ARCH_SHAPE=microservices}}| Shared packages | `kebab-case` (dist) / `snake_case` (import) | `backend-shared-logic` / `backend_shared_logic` |
{{/IF}}

- **Banned vague names:** `data`, `obj`, `info`, `thing`, `temp`, `val`, `res`, `ret`. (The framework-level `data` envelope key in [`api-and-data-contracts.md`](./api-and-data-contracts.md) §2 is the only exception, and only at the wire boundary.)
- Don't substitute numbers for words (`to`, not `2`).
- **Plural for collections, singular for the entity.** Hold the line at every layer.

  | Layer | Plural (collection) | Singular (one entity) |
  |-------|---------------------|------------------------|
  | DB | table `{{OWNER_TERM}}__<entities>` | a row of `{{OWNER_TERM}}__<entities>` |
  | REST | collection path `/v1/<entities>` | item path `/v1/<entities>/{id}` |
  | Folder | {{#IF ARCH_SHAPE=microservices}}`src/domain/<entities>/`{{#ELSE}}`src/modules/<module>/data_models/<entities>/`{{/IF}} | — |
  | Service class | `<Entities>Service` (operates on the collection; `perform_fetch_by_filter` is collection-shaped, `perform_fetch` reads one) | — |
  | DbAction class | `<Entities>DbAction` (operates on the table) | — |
  | Pydantic / data-model class | — | `<Entity>` |
  | Variable | `record_<entities>` (list), `command_create_<entities>` (batch) | `record_<entity>`, `command_create_<entity>`{{#IF HAS_KAFKA}}, `event_<entity>_registered`{{/IF}} |
  | Git repo | doc-collection repo `tech/docs`, `business/docs`, `product/docs` | service / app / component repo `backend-<name>`, `frontend-<name>`, `infra-<name>` |

  Load-bearing rule: **consistency within each layer**. A folder named `users/` whose service class is `UserService` (singular) is non-compliant.

### 2.1 Attribute prefixes — where the value came from [BE] — v1 STANDARD

Every attribute on an `<Entity>Service` (instance attribute, local in `perform_<verb>`, or argument inside the {{#IF ARCH_SHAPE=microservices}}domain{{#ELSE}}module{{/IF}} ring) carries a fixed prefix that names **where the value came from**. Reading a method top-to-bottom should immediately tell you what each name is.

| Prefix | Source | Examples |
|---|---|---|
| `record_` | A row (or list of rows) fetched from **this {{OWNER_TERM}}'s own Postgres** via its `DbAction`. Plural means a list. | `record_<entity>`, `record_<entities>` |
| `response_` | A parsed payload returned from an **outbound integration** ({{#IF ARCH_SHAPE=microservices}}sibling service via a `backend-shared-logic` agent, {{/IF}}3rd-party SaaS: {{OTP_PROVIDER}}, {{CAPTCHA_PROVIDER}}, {{CDN_PROVIDER}}, {{PSP_PROVIDER}}). | `response_<provider>` |
{{#IF HAS_KAFKA}}| `event_` | An **inbound Kafka event** payload (only inside `src/consumers/handlers/<event>.py`). | `event_<entity>_<action>` |
| `message_` | An **outbound Kafka message** about to be published. | `message_<entity>_<action>` |
{{/IF}}{{#IF ARCH_SHAPE=monolith}}| `task_` | An **inbound outbox task** payload (only inside `src/worker/handlers/<task>.py`). | `task_send_<channel>`, `task_generate_<artefact>` |
{{/IF}}| `command_` | The canonical **input `Command`** DTO passed into a `perform_<verb>`. | `command_create_<entity>`, `command_fetch_by_filter` |
| `result_` | The **`Result`** DTO returned from a `perform_<verb>`. | `result_create_<entity>`, `result_<verb>` |
{{#IF HAS_REDIS}}| `cache_` | A value read from / written to **Redis**. | `cache_<key>` |
{{/IF}}| `payload_` | A **wire request body** (only set inside transport adapters: `src/api/v{N}/routes/`{{#IF HAS_KAFKA}}, `src/consumers/handlers/`{{/IF}}). Never leaks into the {{#IF ARCH_SHAPE=microservices}}`domain/`{{#ELSE}}`modules/<module>/`{{/IF}} ring. | `payload_create_<entity>` |
| `filter_` | A prepared **filter dict / model** for `perform_fetch_by_filter`. | `filter_<entities>` |
{{#IF HAS_MEILISEARCH}}| `search_` | A value read from / written to **Meilisearch** (only inside `backend-search`). | `search_hits`, `search_index_document` |
{{/IF}}

Rules:

- One value, one prefix. Don't rename across the same scope (`payload_create_<entity> → command_create_<entity>` happens **at** the adapter → domain boundary and that's the only conversion point).
- Plural follows §2: `record_<entities>` is the list, `record_<entity>` is one row.
- The banned-vague-name list is still in force; an unprefixed `<entity>` variable is unprefixed, not magically a `record_<entity>`.
- Module-level constants keep their `UPPER_SNAKE` shape (no prefix); these prefixes apply only to mutable / per-call values.

---

## 3. Type hints [BE] — CURRENT

- **Every parameter, return value, and (where practical) variable MUST be annotated.** Enforced by ruff `ANN` and mypy `disallow_untyped_defs = true`.
- **Use modern union syntax `X | None` — NOT `Optional[X]`.** Do not import `Optional`.

  ```python
  async def perform(self) -> dict[str, Any]: ...
  <entity>_id: str | None = None
  ```

- Prefer `Annotated[...]` for FastAPI params and bounded fields: `Annotated[str, Field(min_length=1, max_length=255)]`, `Annotated[CurrentUser, Depends(check_auth)]`.
- **Avoid `Any`.** mypy runs with `warn_return_any = true`. Keep `Any` local; narrow it as soon as possible. `dict[str, Any]` for a freshly-fetched DB row is acceptable; an `Any` return from a public method is not.
- **Prefer keyword arguments** over positional.
- **No `*args` / `**kwargs` in application logic.** Every `perform_<verb>` (including `perform_fetch_by_filter`) takes an explicit, typed `Command` model. Filter payloads are Pydantic models under `data_models/`, not loose dicts. `*args` / `**kwargs` are reserved for framework hooks and decorator passthrough.

---

## 4. Imports [BE] — CURRENT

- **Import specific names**, not modules: `from os import getenv` → `getenv(...)`, not `import os` → `os.getenv(...)`.
- **Three groups, blank-line separated, alphabetised within each** (ruff `I` / isort):
  1. Standard library
  2. Third-party
  3. Internal
- Remove unused imports — **except** in `__init__.py` (`per-file-ignores` sets `__init__.py = ["F401", "F403"]`). Module-level `F401` is not auto-removed (`ignore = ["F401"]`).

---

## 5. No hardcoding [BE] — CURRENT

| What | Where it goes |
|------|---------------|
| Boot-critical / process-level settings (Uvicorn, pool size, CORS, {{OWNER_TERM}} identity, log level) | **`ENVS`** (`pydantic-settings`); missing required → boot fails |
| Rotatable secrets & runtime tunables (JWT public key, API keys{{#IF OTP_PROVIDER}}, {{OTP_PROVIDER}} API key{{/IF}}{{#IF CAPTCHA_PROVIDER}}, {{CAPTCHA_PROVIDER}} secret{{/IF}}{{#IF CDN_PROVIDER}}, {{CDN_PROVIDER}} API token{{/IF}}, OTP TTLs, peer base URLs) | **`{{#IF ARCH_SHAPE=microservices}}<service>__configurations{{#ELSE}}settings__configurations{{/IF}}`** table, read at request time |
| Status values, fixed sets | `StrEnum` in `constants/` |
| Business limits / thresholds | Named `UPPER_SNAKE` constants |
| Repeated string literals | Module-level constant |

- **Never commit credentials.** Env-var names carry no special prefix; secrets and non-secrets share the same naming, and secret handling (vault / CI masked variables) is out-of-band of the variable name. `detect-private-key` pre-commit hook is the backstop. Keep `.env.example` synced with the real contract (secret-free).

---

## 6. Enums [BE] — v1 STANDARD

- Use **`StrEnum`** (not `(str, Enum)`) for every fixed-value set, paired with a generated `Literal`:

  ```python
  class <Concept>Enum(StrEnum):
      A = "A"
      B = "B"

  <CONCEPT>_SET = {c.value for c in <Concept>Enum}
  <Concept>Literal: TypeAlias = Literal[*<CONCEPT>_SET]
  ```

- **Compare against the enum member, never a string literal** — `if state == <Concept>Enum.A`, not `== "A"`.
- One enum module per {{OWNER_TERM}} ({{#IF ARCH_SHAPE=microservices}}`src/domain/<entity>/constants/enums.py`{{#ELSE}}`src/modules/<module>/constants/enums.py`{{/IF}}). Roles are per-{{OWNER_TERM}} — no shared cross-{{OWNER_TERM}} role enum. See [`security-and-auth.md`](./security-and-auth.md) §4.

---

## 7. Async [BE] — CURRENT

- **`async def` for everything on the request path**, especially all DB-touching code. Blocking I/O on the event loop is prohibited.
- **`asyncio.sleep`, never `time.sleep`.** Background-task backoff uses `await asyncio.sleep(2 ** attempt)`.
- Synchronous / CPU-bound work runs in a worker process or `run_in_executor(...)` with a bounded pool, not on the API event loop.
- **Async HTTP only** — outbound calls go through {{#IF ARCH_SHAPE=microservices}}`backend-shared-logic` agents{{#ELSE}}`httpx.AsyncClient` inside `src/modules/shared/integrations/`{{/IF}}; never `requests`.

---

## 8. Error handling, comments & patterns [BE]

### 8.1 Exceptions — CURRENT

- Raise **only** `ProjectBaseException` (or subclass) from {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic.exception`{{#ELSE}}`src.modules.shared.platform.exceptions`{{/IF}}. Canonical args: **required** `status_code, message, error_code`; **optional** `data=None, extra=None`. `success` is not a constructor arg — the global handler hardcodes `success=False` in the envelope. **Never** raise bare Python or `fastapi.HTTPException` from a service. Full constructor contract: [`errors-and-observability.md`](./errors-and-observability.md) §2.
- `error_code` is set at the raise site (stable `<{{OWNER_TERM_UPPER}}>_<DETAIL>` UPPER_SNAKE). `extra` is **log-only** — never serialised into the HTTP body.
- Log the **full stack trace** with `traceback.format_exc()` — never `str(e)`.
- Create a **specific exception class per failure mode** instead of branching on exception state. The global handler maps to HTTP + an ERROR-level structured log line (see [`errors-and-observability.md`](./errors-and-observability.md) §3, §11).

### 8.2 Comments & docstrings — v1 STANDARD

- Code is self-documenting. Comments explain **WHY**, not WHAT.
- Docstrings are checked by ruff `D` (pydocstyle) with `D100`, `D104`, `D203`, `D212` ignored.

### 8.3 Architecture patterns — CURRENT

- **Adapter pattern** for every third-party / external-service integration ({{#IF ARCH_SHAPE=microservices}}`backend-shared-logic` agents in `src/infra/integrations/`{{#ELSE}}adapters in `src/modules/<module>/integrations/` if module-local; `src/modules/shared/integrations/` if shared{{/IF}}).
- **Retry with `tenacity` only — for third-party / external-service API calls.** Use `tenacity.retry` with `wait_exponential_jitter` / `stop_after_attempt` / `retry_if_exception_type`. No hand-written `for attempt in range(...)` retry loops; no `time.sleep`.
{{#IF ARCH_SHAPE=microservices}}- **Circuit-breaker around every internal / inter-service agent call.** Trip on consecutive failures, half-open after a cooldown; while open the agent raises a dependency error mapped to `502` / `504` by the global handler. Implemented once in `backend-shared-logic`'s agent base.
{{/IF}}{{#IF ARCH_SHAPE=monolith}}- **Circuit-breaker around outbound integrations** ({{OTP_PROVIDER}}, {{CAPTCHA_PROVIDER}}, SMTP, etc.). Trip on consecutive failures, half-open after a cooldown; while open the adapter raises a dependency error mapped to `502` / `504` by the global handler. Implement once as a `tenacity`-compatible decorator in `src/modules/shared/integrations/circuit_breaker.py`.
{{/IF}}- **Post-response work runs {{#IF HAS_KAFKA}}on the shared-logic Kafka worker template{{#ELSE}}through the transactional outbox → worker{{/IF}}, not FastAPI `BackgroundTasks` for anything durable.** See {{#IF ARCH_SHAPE=microservices}}[`microservice-layout.md`](./microservice-layout.md){{#ELSE}}[`monolith-layout.md`](./monolith-layout.md){{/IF}} §4.4.
- **YAGNI / explicit-over-clever / no feature flags / no speculative back-compat shims** unless explicitly required.

---

## 9. Ruff / Mypy / Pre-commit configuration [BE] — v1 STANDARD (exact)

Authoritative source: each {{OWNER_TERM}}'s `pyproject.toml` + `.pre-commit-config.yaml`.

### 9.1 Ruff

| Setting | Value |
|---------|-------|
| `line-length` | **120** |
| `target-version` | **`py313`** |
| `[format] indent-style` | `space` |
| `[format] quote-style` | `double` |
| `[format] skip-magic-trailing-comma` | `false` |

**`[lint] select`:** `E`, `W`, `F`, `I`, `B`, `C4`, `UP`, `ARG`, `SIM`, `RUF`, `D`, `S`, `T20`, `ANN`.

**`[lint] ignore`:** `E501` (formatter handles wrapping), `ARG001` / `ARG002` (unused arg — intentional in interfaces / overrides), `D100` / `D104` (module / package docstring optional), `D203` / `D212` (conflict with `D211` / `D213`), `F401` (don't auto-remove unused imports).

**`per-file-ignores`:** `"__init__.py" = ["F401", "F403"]`.
**`exclude`:** `.git`, `__pycache__`, `venv`, `.venv`, `build`, `dist`, `.vscode`, `*.pyc`, `*.pyo`, `scripts`, `migrations`, `tests/**`.

### 9.2 Mypy

| Setting | Value |
|---------|-------|
| `python_version` | `3.13` |
| `disallow_untyped_defs` | `true` |
| `warn_return_any` | `true` |
| `warn_unused_configs` | `true` |
| `ignore_missing_imports` | `true` |
| `explicit_package_bases` | `true` |
| `exclude` | `scripts/`, `migrations/`, `tests/` |

### 9.3 Pytest / coverage

- `asyncio_mode = "auto"`; `testpaths = ["tests"]`; markers **`unit` / `integration` / `e2e`** (`--strict-markers`).
- Coverage `source = ["src"]`, omitting `tests`, `__init__.py`, `scripts`, `migrations`. **Unit-test coverage target ≥ {{BE_COVERAGE_FLOOR}}%** (branch coverage on); the MR pipeline gates with `--cov-fail-under={{BE_COVERAGE_FLOOR}}` and fails the build on any regression (`--cov-fail-under` ratchets up, never down). Per-layer aspirations in [`testing.md`](./testing.md) §2.15.

### 9.4 Pre-commit (local gate) — CURRENT

| Hook | Source | Args |
|------|--------|------|
| `ruff` | `ruff-pre-commit` **v0.14.10** | `--fix` |
| `ruff-format` | same | — |
| `mypy` | `mirrors-mypy` **v1.19.1** | `src/`, `pass_filenames: false` |
| `trailing-whitespace`, `end-of-file-fixer` | `pre-commit-hooks` **v6.0.0** | — |
| `check-json`, `check-yaml` (`--unsafe`), `check-toml` | same | — |
| `detect-private-key` | same | — |
| `gitleaks` | `gitleaks` **v8.18.0** | — |

Global `exclude: ^scripts/`; `default_stages: [pre-commit]`; `fail_fast: false`. The same set runs as MR CI gates. See [`ci-cd.md`](./ci-cd.md) §1.

### 9.5 `# noqa` suppression reference [BE] — STANDARD

Use suppressions sparingly, always with the specific rule code and an inline reason. No bare `# noqa`; no file-wide `# noqa` headers outside `scripts/` and dev tooling.

```python
SECRET_KEY = "dev_default_only"           # noqa: S105 — dev fallback, override in env
query = f"SELECT * FROM {table}"          # noqa: S608 — table name from allow-list, not request data
```

**Security (`S`) codes legitimate in service code:** `S104` (`0.0.0.0` bind), `S105` (dev-default secret), `S311` (insecure RNG in test helpers), `S608` (table-name interpolation from allow-lists). Others require strong written justification.

**Common non-security suppressions:** `F401` / `F403` / `F405` for `__init__.py` re-exports, `E501` (formatter owns wrapping), `E701`, `B008`.

---

## 10. Editor configuration — VS Code [BE] — v1 STANDARD

Every `backend-*` repo ships `.vscode/{extensions,settings,launch}.json`. Committed so every developer gets the same edit-time experience.

- Recommended extensions: `ms-python.python`, `ms-python.vscode-pylance`, `charliermarsh.ruff`, `ms-python.mypy-type-checker`, `ms-python.debugpy`, `tamasfe.even-better-toml`, `redhat.vscode-yaml`, `ms-azuretools.vscode-docker`, `GitLab.gitlab-workflow`, `eamodio.gitlens`, `njpwerner.autodocstring`, `EditorConfig.EditorConfig`.
- `.vscode/settings.json` — anchor on `.venv/`, Ruff format-on-save, Mypy on save, Pytest discovery on `tests/`, `editor.rulers: [120]`.
- `.vscode/launch.json` — one debug config per role: `API` (`python __main__.py api`){{#IF HAS_KAFKA}}, `Consumer` (`python __main__.py consumer`){{/IF}}, `Cronjob` (`python __main__.py cronjob`), `Pytest: current file`, `Pytest: full suite`. Each launches under debugpy with `.env.local` injected.

Frontend repos use the equivalent extensions (`dbaeumer.vscode-eslint`, `esbenp.prettier-vscode`, `bradlc.vscode-tailwindcss`, `astro-build.astro-vscode` for Astro) with `.vscode/settings.json` setting `eslint.format.enable: true`, `editor.defaultFormatter: esbenp.prettier-vscode`, and `editor.formatOnSave: true`.

---

# Part 2 — Frontend [FE]

> **GREENFIELD / target standard.** All of Part 2 is prescriptive.

## F0. The stack [FE] — STANDARD

The frontend list, per-repo stack, and build modes are pinned in [`frontend.md`](./frontend.md) §2. Both Astro 5 (landing, SSG) and Vite 6 + React 19 (SPAs) produce **pure static output** served by platform nginx — no SSR, no Node at the edge, no server logic.

Cross-repo picks:

| Concern | Choice | Notes |
|---------|--------|-------|
| Language | **TypeScript, strict mode** | `strict: true`; **no `any`** (F3). |
| Typed API client | **openapi-typescript** | Generated per {{OWNER_TERM}} from each backend's OpenAPI document. |
| Styling | **Tailwind CSS** | Bound to design-system tokens under `product/docs/uiux/v1/design-system/`. |
{{#IF LOCALE_MODE=bilingual}}| Bilingual (fa + en) | **path-prefixed URLs** | `/fa/...` and `/en/...` — parallel path trees. `<html lang dir>` set at build time per route. |
{{/IF}}{{#IF LOCALE_MODE=farsi-only}}| Internationalization | **not used** | Farsi-only. Centralise copy in `src/copy/`; no i18n runtime. `<html lang="fa" dir="rtl">` set once. |
{{/IF}}| Fonts | **{{FONT_STACK}} self-hosted** | `.woff2` in-repo `public/fonts/`, local `@font-face`. **No third-party font origin.** |
| Calendar | {{#IF CALENDAR=jalali}}**date-fns-jalali** on human surfaces; `Intl.DateTimeFormat` for machine feeds{{/IF}}{{#IF CALENDAR=gregorian}}**`Intl.DateTimeFormat`** everywhere{{/IF}}{{#IF CALENDAR=dual}}**date-fns-jalali** on `/fa/`; `Intl.DateTimeFormat('en-US', …)` on `/en/`{{/IF}} | |
| Number formatting | **`Intl.NumberFormat('fa-IR')`** on Persian surfaces{{#IF LOCALE_MODE=bilingual}}; `en-US` on English{{/IF}} | Persian digits in Persian copy; ASCII digits in machine feeds; never auto-convert on render. |
{{#IF BLOCK_EDITOR}}| Rich-text editor (SPA) | **{{BLOCK_EDITOR}}** | Serializes to / from the canonical JSON block tree; pinned in the SPA repo's `docs/v1/PRD-TDD.md`. |
{{/IF}}| Testing — unit | **Vitest + React Testing Library** | See [`testing.md`](./testing.md) §3. |
| Testing — E2E | **Playwright** | |
| Package manager | **pnpm** | Never `npm` / `yarn`. Commit `pnpm-lock.yaml`. |
| Tooling | **ESLint + Prettier + `tsc`**, **Husky + lint-staged** | See F9. |

Per-repo libraries are pinned in each repo's own `docs/v1/PRD-TDD.md`, not here.

---

## F1. Project structure [FE] — STANDARD

Canonical directory layout for every frontend repo lives in [`frontend-layout.md`](./frontend-layout.md): vertical-slice feature-folder pattern, two-ring boundary (feature ring vs shared ring), per-feature file vocabulary (`<Page>.tsx`, `<kebab>.route.tsx`, `forms.schema.ts`, `queries.ts` / `mutations.ts`, `copy.ts`, `errors.ts`, `types.ts`, `__tests__/`), path aliases (`@shared/`, `@features/`, `@lib/`, `@components/`, …), decision diagram, compliance checklist.

Three coding-layer reminders:

- **Co-locate** every piece of a feature inside its folder — never split components, hooks, schemas, copy, or tests into top-level horizontal directories.
- Use a **path alias** for every cross-folder import — **no deep relative imports** (`../../../`).
- **No frontend repo contains server code.** No SSR runtime, no API routes inside any frontend.

---

## F2. Static output & client / server boundary [FE] — STANDARD

- **No server code in any frontend repo.** No API routes (`api/`), no server actions, no edge functions, no per-request rendering.
- **Astro pages render to HTML at build time.** Dynamic surfaces use **React islands** (`client:load` / `client:idle` / `client:visible`) — pushed as far down the tree as possible.
- **SPA runs entirely in the browser** after first paint. All data fetching is client-side against the backend (through nginx), authenticated with the user's JWT — never a build-time secret.
- **Only bundler-public env vars reach the browser.** Astro: `PUBLIC_*` (via `import.meta.env.PUBLIC_*`); Vite: `VITE_*` (via `import.meta.env.VITE_*`). **Never put a token, API key, or any secret behind those prefixes.**

---

## F3. TypeScript & typing [FE] — STANDARD

- **`strict: true`** plus `noUncheckedIndexedAccess`, `noUnusedLocals`, `noUnusedParameters`, `noFallthroughCasesInSwitch`.
- **No `any`.** Use `unknown` + a zod parse (or type guard) at every untrusted boundary (API responses, `searchParams`, form input, `localStorage`). ESLint `@typescript-eslint/no-explicit-any: "error"`.
- **Modern unions** `X | null` / `X | undefined`. Model fixed sets as TS union types or `as const` objects.
- Props are typed interfaces / `type` aliases in `PascalCase`; component files default-export the component, named-export its prop type when shared.
- **`tsc --noEmit`** is a required gate (F9). Each repo's build script runs `tsc --noEmit` first (or in parallel) and aborts on failure.

---

## F4. Naming & file conventions [FE] — STANDARD

| Element | Convention | Example |
|---------|-----------|---------|
| Components (file + name) | `PascalCase` | `<Component>.tsx` (React) / `<Component>.astro` (Astro) |
| Framework-fixed files | follow framework convention | Astro pages: `src/pages/<route>.astro`. Vite / React: `main.tsx`, `index.html`. |
| Hooks | `use`-prefixed `camelCase` | `use<Behavior>.ts` |
| Client-state stores | `use<Name>Store` | `use<Concept>Store` |
| zod schemas | `camelCase` + `Schema` suffix | `<concept>Schema` |
| Inferred schema types | `PascalCase` (via `z.infer`) | `type <Concept>Input = z.infer<typeof <concept>Schema>` |
| Query keys / hooks | `camelCase`; keys centralised in `lib/query-keys.ts` (landing) / `shared/api/query-keys.ts` (SPA) | `<entity>Keys.list(filters)` |
| Types / interfaces | `PascalCase` | `<Entity>` |
| Constants | `SCREAMING_SNAKE_CASE` | `MAX_UPLOAD_SIZE` |
| Non-component files / dirs | `kebab-case` | `query-keys.ts`, `format-currency.ts` |

- **Never hardcode design values** (colors, spacing, breakpoints, radii) — use Tailwind tokens from `tailwind.config.ts`. No raw hex in JSX / CSS.
- Design tokens, page mockups, and brand assets are authored and stored under `product/docs/uiux/v1/` and `business/docs/brand/`. Never reference a hosted-design-tool asset URL in code.
- Use **`clsx`** (or `cn()` from shadcn) for conditional class names, not string concatenation; use **`tailwind-merge`** to dedupe conflicting utilities.

---

## F5. State management [FE] — STANDARD

Applies to the SPA repo(s). Landing has minimal client state — mostly form-local and theme / locale in `localStorage`. Specific libraries pinned per repo in `docs/v1/PRD-TDD.md`.

| Concern | Pattern | Rule |
|---------|---------|------|
| Server state (remote data) | Server-state library (TanStack Query) | Query keys centralised; `staleTime` / `gcTime` set deliberately; mutations invalidate by key. Never duplicate server data into the client store. |
| Global client state | Lightweight client store (Zustand) | One store slice per concern; session / role slice persisted (versioned, with migration). Keep persisted shape minimal. |
| Local UI state | `useState` / `useReducer` | Don't lift to a store unless genuinely shared. |
| URL state | URL `searchParams` / route segments | Filters, tabs, pagination belong in the URL when shareable. |

- **Never store secrets / tokens in `localStorage`** if a httpOnly cookie is viable; if a token must be in the persisted client store, scope it tightly. Coordinate with [`api-and-data-contracts.md`](./api-and-data-contracts.md) / [`security-and-auth.md`](./security-and-auth.md).

---

## F6. Forms & validation [FE] — STANDARD

- A **form library** (react-hook-form) drives all forms; a **schema-validation library** (zod) is the source of truth. One schema in `forms.schema.ts` drives the resolver **and** API request parsing.
- Derive the TS type with `z.infer` — never hand-write a parallel interface.
- The **backend re-validates** with its own Pydantic v2 schema. See [`api-and-data-contracts.md`](./api-and-data-contracts.md).
{{#IF CAPTCHA_PROVIDER}}- **{{CAPTCHA_PROVIDER}} on public forms** — the client injects the challenge; the backend server-side verifies the token before persist. Missing / invalid captcha → `400` / `403`.
{{/IF}}

---

## F7. Styling & UI [FE] — STANDARD

- **Tailwind CSS** utility-first in every frontend repo; design tokens live in `tailwind.config.ts` bound to `product/docs/uiux/v1/design-system/` and are the only source of those values.
- For the SPA, an accessible primitive set (shadcn/ui on Radix) is the recommended pattern — pinned in the SPA repo's `docs/v1/PRD-TDD.md`. Compose accessible primitives over hand-rolling interactive widgets.
- Accessibility is required: every interactive element is reachable and labelled; respect `prefers-reduced-motion`; meet WCAG AA contrast using the token palette.
- Global styles minimal (`globals.css` Tailwind layers only); no ad-hoc global CSS or inline `style={{…}}` for themeable values.

---

## F8. Copy & errors [FE] — STANDARD

- **Copy / language**: {{#IF LOCALE_MODE=bilingual}}bilingual by parity. Persian and English copy is centralised in `src/copy/fa/*.ts` and `src/copy/en/*.ts` (mirroring folder structure); no strings inlined throughout JSX or `.astro` markup. Root layout sets `<html lang="{locale}" dir="{rtl|ltr}">` at build time per route.{{/IF}}{{#IF LOCALE_MODE=farsi-only}}Farsi-only. No i18n runtime, no locale-keyed routes. Centralise user-facing strings in `src/copy/`; do not inline Farsi strings throughout JSX or `.astro` markup. Root layout sets `<html lang="fa" dir="rtl">` once.{{/IF}}
- **Error tracking**: v1 has no browser-side error SDK (no Sentry / Bugsnag). Wrap React routes with error boundaries (`react-error-boundary`) and surface a fallback that respects the design system's error states. Surface unhandled errors and unhandled promise rejections by `POST`-ing a small structured event (route, message, `X-Request-Id` from the last response, optional stack) {{#IF FE_ERROR_ENDPOINT}}to `POST {{FE_ERROR_ENDPOINT}}`{{#ELSE}}to a single backend endpoint{{/IF}} that emits a normal ERROR-level structured log line.

---

## F9. Tooling, linting & gates [FE] — STANDARD

| Tool | Config | Rule |
|------|--------|------|
| **pnpm** | `package.json` + `pnpm-lock.yaml` | Only pnpm. Lockfile committed; CI uses `--frozen-lockfile`. |
| **ESLint** | flat config (`eslint.config.mjs`) — `@typescript-eslint/recommended` + `eslint-plugin-react` / `eslint-plugin-react-hooks` (SPA) or `eslint-plugin-astro` (landing) | Lint must pass clean. No disabled rules without inline justification. |
| **Prettier** | `.prettierrc.json` + `prettier-plugin-tailwindcss` (+ `prettier-plugin-astro` in landing) | Formatting non-negotiable; Tailwind class order auto-sorted. |
| **TypeScript** | `tsc --noEmit` | Strict; type errors fail the build. `pnpm build` runs `tsc --noEmit` before `astro build` / `vite build`. |
| **Husky + lint-staged** | `.husky/` + `lint-staged` config | Pre-commit: ESLint + Prettier (+ `tsc`) on staged files. |

- **CI gates:** `eslint`, `prettier --check`, `tsc --noEmit`, `pnpm test`, `pnpm build` run as gates on pull requests. See [`ci-cd.md`](./ci-cd.md) §8.
- **Commit convention is [SHARED]** with the backend — vocabulary lives in [`git.md`](./git.md); commitlint wires enforcement. Husky's `commit-msg` hook runs commitlint.
- Required scripts: `pnpm dev`, `pnpm build`, `pnpm lint`, `pnpm typecheck`, `pnpm format`, `pnpm codegen`.

---

## How this is enforced

### Backend [BE]

| Standard | Enforcement |
|----------|-------------|
| Line length 120, double quotes, space indent, magic trailing comma | `ruff format` (`pyproject.toml [tool.ruff.format]`) |
| Import sorting / grouping, unused imports, bugbear, comprehensions, simplify, pyupgrade, security, no-print | `ruff check` (`select = E,W,F,I,B,C4,UP,ARG,SIM,RUF,D,S,T20,ANN`) |
| `X \| None` style (not `Optional`) | live convention + reviewer rule |
| Type hints on every def; no silent `Any` return | `mypy` (`disallow_untyped_defs`, `warn_return_any`) |
| Async correctness (`asyncio.sleep`, no blocking I/O) | reviewer rule + integration adapter conventions |
| Only `ProjectBaseException`; `traceback.format_exc()` | reviewer rule; global exception handler |
| No secrets in code | `detect-private-key` hook + `gitleaks` + `ENVS` / config-table convention |
| Structure / brevity limits, naming (incl. §2.1 attribute prefixes), `<Entity>Service` shape, no-hardcoding, `StrEnum`, DRY, patterns, no feature flags, retries via `tenacity` only | reviewer rule |
| `ruff` + `mypy` + `pytest` (+ coverage ≥ {{BE_COVERAGE_FLOOR}}%) on every MR | GitLab MR pipeline — [`ci-cd.md`](./ci-cd.md) §6 |

Local commands: `ruff check src/`, `ruff format src/`, `mypy src/`, `pytest --cov=src --cov-fail-under={{BE_COVERAGE_FLOOR}}`. All wired into `pre-commit`; the MR pipeline re-runs them as merge-blocking gates.

### Frontend [FE] — STANDARD (greenfield)

| Standard | Enforcement |
|----------|-------------|
| Formatting + Tailwind class order | `prettier --check` + `prettier-plugin-tailwindcss`; Husky / lint-staged |
| Lint (TS, React hooks rules, Astro rules, no-`any`) | `eslint` (`@typescript-eslint/recommended` + framework plugin) |
| Strict typing; no `any`; type errors block build | `tsc --noEmit` (run by `pnpm build` before `astro build` / `vite build`) |
| No SSR / no Node at the edge; secrets never bundled | reviewer rule + env-var prefix convention (`PUBLIC_*` / `VITE_*`) |
| Server state via dedicated cache, client state via small store (no duplication) | reviewer rule |
| Forms = form library + one schema (single source of truth) | reviewer rule |
| No hardcoded colors / strings; design tokens + centralised copy | reviewer rule + Tailwind config tokens + `src/copy/` |
| pnpm only; frozen lockfile in CI | `packageManager` field + CI `--frozen-lockfile` |
| Commit format ([SHARED]) | Husky `commit-msg` hook (commitlint) |

Local commands: `pnpm lint`, `pnpm typecheck`, `pnpm format`, `pnpm build`, `pnpm codegen`. These are wired as CI gates on every MR (see [`ci-cd.md`](./ci-cd.md) §8).
