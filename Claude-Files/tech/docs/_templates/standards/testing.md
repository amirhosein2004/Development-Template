# Testing Standards (tech)

> **Documentation placement.** Cross-repo standard — referenced by every engineering repo (see [`documentation.md`](./documentation.md) §5).

## Scope

Canonical testing rules for every {{PROJECT_NAME}} backend {{OWNER_TERM}} and the frontend apps. **[BE]** = backend (pytest + pytest-asyncio + pytest-cov). **[FE]** = frontends (Vitest + React Testing Library + Playwright). **[SHARED]** = both.

**Backend stack:** Python 3.13, `uv`, `asyncpg` (raw SQL via `DbAction`), FastAPI, Pydantic v2, `pydantic-settings`, Alembic with raw SQL.

**Frontend stack:** Astro 5 (SSG) + Vite 6 + React 19 (SPA), Tailwind, OpenAPI-generated client (`openapi-typescript`), Vitest + RTL, MSW, Playwright, pnpm.

Reading conventions: **MUST** = non-negotiable. **SHOULD** = strong default; deviate only with a written reason. **v1 STANDARD** = required for v1. **STANDARD GOING FORWARD** = agreed target.

**Frontend status: GREENFIELD.** [FE] sections are the agreed target.

---

## 1. Test taxonomy

| Layer | Scope | BE tool | FE tool |
|-------|-------|---------|---------|
| Unit | One function / class, deps mocked | `pytest` | Vitest |
| Component | Unit + closest collaborators | Pydantic + validator | RTL + provider tree |
| Integration | Multiple modules, real I/O | FastAPI TestClient + real Postgres (Testcontainers) | App route + MSW |
| Contract | Wire-format compatibility | OpenAPI ↔ Pydantic round-trip | OpenAPI ↔ generated client |
| E2E | Real browser + real backend | — | Playwright |
| Property-based | Search bug space | Hypothesis | fast-check |
| Mutation | Test the tests | `mutmut` | Stryker |
| Performance | Latency / throughput | `pytest-benchmark`, `k6` | Lighthouse CI, Playwright traces |
| Security | Vulns | `pip-audit`, `bandit` | `pnpm audit`, `semgrep` |
| Visual regression | UI drift | — | Playwright snapshots |
| Accessibility | WCAG | — | `@axe-core/playwright`, `jest-axe` |

Pyramid policy: most coverage at unit; moderate integration; few E2E.

### 1.1 Required test virtues

Tests MUST be: **Fast** (seconds per layer), **Isolated** (order-independent, no shared mutable state), **Repeatable** (deterministic), **Self-validating** (no manual inspection), **Timely** (written with the code).

### 1.2 What tests assert

- Assert observable behavior: return values, raised exceptions, persisted state, HTTP responses, rendered DOM, network calls made.
- Never assert on internal implementation.

### 1.3 Banned patterns

- Snapshot tests of large opaque blobs (deliberate exceptions must be documented).
- Mocking what you own (mock the boundary, not your own service layer).
- Asserting on logs as the primary outcome.
- One giant `test_everything` function.
- **`time.sleep` for synchronization** — use explicit awaits / polling.
- Conditional logic in tests (`if / else`, `try / except`) — use `parametrize`.
- Mocking the DB driver in code that exists to talk to the DB.
- **Live-network calls** — mock every third-party HTTP integration.
- **Test order dependency** — every test runs standalone.
- **Shared mutable fixtures across tests** — a fixture that mutates and is reused across tests is a review block.

---

## 2. Backend testing (Python 3.13 / FastAPI / asyncpg / Pydantic)

### 2.1 Required toolchain

| Concern | Tool |
|---------|------|
| Runner | `pytest` |
| Async | `pytest-asyncio` (`mode=auto`) |
| HTTP | `httpx.AsyncClient` + `ASGITransport` |
| DB integration | `testcontainers[postgres]` + `asyncpg` |
| Fixtures | `pytest-factoryboy` or `polyfactory` |
| Property-based | `hypothesis` |
| Time control | `freezegun` or `time-machine` |
| HTTP mocking | `respx` |
| Coverage | `coverage[toml]` + `pytest-cov` |
| Mutation | `mutmut` |
| Parallel | `pytest-xdist` |
| Snapshot (sparingly) | `syrupy` |
| Benchmarks | `pytest-benchmark` |
| Coverage gate | `--cov-fail-under` |
{{#IF HAS_KAFKA}}| Kafka test broker | Testcontainers Kafka (real broker; consumer wiring exercised end-to-end) |
{{/IF}}{{#IF HAS_MEILISEARCH}}| Meilisearch integration | Testcontainers Meilisearch (only inside `backend-search`) |
{{/IF}}

### 2.2 `pyproject.toml` reference

Required choices: `asyncio_mode = "auto"` with function-scoped fixture loop, `--strict-markers`, `unit` / `integration` / `e2e` markers, branch coverage on `src/` with `tests` / `__init__.py` / `migrations` omitted.

### 2.3 Layer rules

**Unit tests**

- Mock every external dependency at its **full module path where it is used**, not where it is defined.
- `AsyncMock` for awaitables; `MagicMock` for sync.
- Use `pytest.parametrize` with `ids=[...]` for table-driven cases.

**Integration tests (real Postgres via Testcontainers)**

- {{#IF ARCH_SHAPE=microservices}}Per-{{OWNER_TERM}} testcontainer setup: session-scoped `PostgresContainer("postgres:17.10-bookworm")`; run migrations once; create one `asyncpg.create_pool`.{{#ELSE}}Module-scoped testcontainer: session-scoped `PostgresContainer("postgres:17.10-bookworm")`; run migrations once; create one `asyncpg.create_pool`.{{/IF}}
- Per-test isolation via `await tx.rollback()` in the connection fixture.
- For code that must commit: `TRUNCATE ... CASCADE` at session end + parallelize via xdist with separate template DBs.

**E2E (HTTP) tests**

- Use `AsyncClient(transport=ASGITransport(app=app))` in-process.
- Swap pool / fakes via `app.dependency_overrides`; clear in teardown.

### 2.4 Mocking asyncpg — canonical fixtures

Three distinct fixtures at three distinct layers — never a tuple-returning helper:

```python
@pytest.fixture
def mock_db_connection() -> AsyncMock:
    """asyncpg.Connection — stub fetch/fetchrow/fetchval/execute return values here."""
    conn = AsyncMock()
    conn.fetchrow.return_value = None
    conn.fetch.return_value = []
    conn.fetchval.return_value = None
    conn.execute.return_value = "INSERT 0 1"
    return conn


@pytest.fixture
def mock_db_pool(mock_db_connection: AsyncMock) -> MagicMock:
    """asyncpg.Pool — its acquire() yields mock_db_connection inside async with."""
    pool = MagicMock()
    pool.acquire.return_value.__aenter__ = AsyncMock(return_value=mock_db_connection)
    pool.acquire.return_value.__aexit__ = AsyncMock(return_value=None)
    return pool


@pytest.fixture
def mock_db_action() -> AsyncMock:
    """<Entity>DbAction subclass — stub insert_one/update/fetch_many here."""
    return AsyncMock()
```

Use the right layer:

| Fixture | Mocks | Use when |
|---|---|---|
| `mock_db_pool` | `asyncpg.Pool` | Wiring tests. |
| `mock_db_connection` | `asyncpg.Connection` | Stubbing return values. |
| `mock_db_action` | `<Entity>DbAction` subclass instance | Service-layer tests. |

### 2.5 FastAPI rules

- Use `app.dependency_overrides` as the canonical seam; reset in fixture teardown.
- Provide a `fixture_app()` factory returning a fresh app per test when middleware / state must be isolated.
- Test lifespan events explicitly with `LifespanManager`.
- Every protected route MUST have `401 unauthenticated`, `403 wrong role`, `404 not owned`, and `409 conflict` tests where applicable.

### 2.6 Pydantic v2 rules

- Validate both directions: input validation and output serialization.
- Test `field_validator` and `model_validator` boundaries with parametrized cases.
- Test `model_dump(exclude_unset=True)` semantics for PATCH endpoints.
- Cover discriminated unions exhaustively — one test per discriminant value.
{{#IF BLOCK_EDITOR}}- **JSON block-tree discriminated union** — one test per declared block type asserting parse + serialize round-trip; one test per unknown block type asserting `422 <CONTENT_UNKNOWN_BLOCK_TYPE>`.
{{/IF}}

### 2.7 pydantic-settings rules

- Set env vars **before importing** any module that constructs a `Settings()` at import time.
- Prefer dependency-injected settings (`get_settings()`-as-dependency).
- Verify `.env` precedence and process-env precedence with `monkeypatch`.

### 2.8 Property-based testing — required scope

Hypothesis MUST be used for: Pydantic validators (phone, slug, URL); Persian slug generation (no percent-encoded output, no double dashes, no leading / trailing dash); serialization round-trips.
{{#IF CALENDAR=jalali}}
- **Jalali round-trip.** For every Jalali date in a valid Persian calendar range, `to_utc(to_jalali(utc)) == utc` and `to_jalali(to_utc(jalali)) == jalali`.
- **ZWNJ / character-fold normalization.** Canonicalized form of a string equals canonicalized form of every equivalent variant (ی ↔ ي, ک ↔ ك, ZWNJ present / absent for word-final joiners).
- **Persian digit boundary** — `persian_to_ascii(ascii_to_persian(s))` and vice versa are identity on digit strings.
{{/IF}}

### 2.9 Time, randomness, IDs, IO

- **Time:** inject a `Clock` protocol; or use `freezegun` / `time-machine`. Never call `datetime.utcnow()` in domain code without an override seam.{{#IF CALENDAR=jalali}} Freeze at `Asia/Tehran` boundaries in tests that exercise scheduled work — the DST-adjacent minutes matter.{{/IF}}
- **Randomness:** inject a `Random` instance; for ULIDs take an `id_factory: Callable[[], str]` dependency.
- **External HTTP:** use `respx`; assert method, URL, headers, body.
- **Filesystem:** use `tmp_path`; never write to repo paths.

### 2.10 Async correctness

- Pair `asyncio_mode = "auto"` with explicit `@pytest.mark.asyncio` where clarity helps.
- Pin `asyncio_default_fixture_loop_scope = "function"`.
- When using `asyncio.gather(...)`, assert on individual results.

### 2.11 Migrations testing (Alembic with raw SQL)

- Run `alembic upgrade head` against a clean Testcontainers Postgres in CI; assert the final schema matches the declared baseline by introspecting `information_schema`.
- Test `alembic downgrade -1` on representative data for every destructive migration.
- Reject any migration file that imports SQLAlchemy models or uses `op.create_table()` — only `op.execute("<raw SQL>")` is allowed.
{{#IF CALENDAR=jalali}}- **Jalali sidecar sanity check** — every migration that creates a human-observed date column also creates the matching `jalali_year` / `_month` / `_day` integer columns.
{{/IF}}

{{#IF HAS_KAFKA}}### 2.12 Background tasks / queues (shared-logic Kafka worker template)

- Test the handler function with all deps mocked.
- Test wiring (produce → consume → handle → offset commit) against Testcontainers Kafka.
- Test retry (`tenacity` — exponential jitter, bounded attempts), routing to the per-topic `<topic>-dlq`, idempotency keys, and poison-pill handling.
{{/IF}}

### 2.13 Performance & benchmarks

- `pytest-benchmark` for hot loops; commit baselines; fail PRs that regress by more than the configured threshold.
- `k6` run in a nightly job, not on every PR.

### 2.14 Security testing

- `pip-audit` in CI for dependency CVEs.
- `bandit` for static security smells.
- `semgrep` rulesets for FastAPI.
- Dedicated authn / authz boundary suite.

### 2.15 Coverage policy — v1 STANDARD

Branch coverage on. **Unit-test coverage target ≥ {{BE_COVERAGE_FLOOR}}%** overall; per-layer floors:

| Layer | Floor | Aspiration |
|-------|:-----:|:----------:|
| Services (`<Entity>Service.perform_*`) | {{BE_COVERAGE_FLOOR}}% | > 98% |
| Database actions (`<Entity>DbAction`) | {{BE_COVERAGE_FLOOR}}% | > 98% |
| Validators | {{BE_COVERAGE_FLOOR}}% | > 98% |
| Utils | {{BE_COVERAGE_FLOOR}}% | > 98% |
| Data models | 90% | > 95% |
| **Overall** | **{{BE_COVERAGE_FLOOR}}%** | **> 97%** |

Enforce via `pytest --cov=src --cov-fail-under={{BE_COVERAGE_FLOOR}}` on every MR. **Coverage regressions fail the build.** The gate ratchets up, never down.

---

## 3. Frontend testing (Astro 5 / Vite 6 + React 19 + TS)

### 3.1 Required toolchain

| Concern | Tool |
|---------|------|
| Unit / component | Vitest |
| DOM matchers | `@testing-library/jest-dom` |
| Component | React Testing Library |
| User interaction | `@testing-library/user-event` v14 |
| API mocking | MSW v2 |
| E2E | Playwright |
| Accessibility | `@axe-core/playwright`, `jest-axe` |
| Visual regression | Playwright `toHaveScreenshot` |
| Coverage | Vitest V8 provider |
| Property-based | `fast-check` |
| Mutation | Stryker |
| Perf | Lighthouse CI, Playwright traces |

### 3.2 Required Vitest config sketch

```ts
export default defineConfig({
  plugins: [react()],
  resolve: { alias: { "@": path.resolve(__dirname, "./src") } },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test/setup.ts"],
    css: true,
    restoreMocks: true,
    clearMocks: true,
    mockReset: true,
    coverage: {
      provider: "v8",
      reporter: ["text", "html", "lcov"],
      {{#IF FE_COVERAGE_FLOOR}}thresholds: { lines: {{FE_COVERAGE_FLOOR}}, branches: {{FE_COVERAGE_FLOOR}}, functions: {{FE_COVERAGE_FLOOR}}, statements: {{FE_COVERAGE_FLOOR}} },
      {{/IF}}exclude: ["**/*.stories.tsx", "**/*.config.*", "src/test/**", "src/shared/api/generated/**"],
    },
  },
});
```

`onUnhandledRequest: "error"` in `src/test/setup.ts` is mandatory.

### 3.3 Testing Library rules

- Query by role first (`getByRole("button", { name: /save/i })`), then label, then text. Test-ids are a last resort.
- `findBy*` for async appearance, `getBy*` for sync required, `queryBy*` for asserting absence.
- Use `userEvent` v14 (async), not `fireEvent`.
- Never assert on CSS classes / inline styles.

### 3.4 MSW rules

- One handler module per resource; merged into `server.ts` and `browser.ts`.
- Per-test failure cases via `server.use(http.post(...))`.
- `onUnhandledRequest: "error"` is mandatory.
- For TanStack Query: never stub `useQuery` / `useMutation`; exercise the real wiring through MSW.

### 3.5 Library-specific rules

- **TanStack Query:** fresh `QueryClient` per test (`retry: false`, `gcTime: Infinity`); prefer `findByRole` over `waitFor`; test error / loading / empty states explicitly.
- **Zustand:** reset stores in `beforeEach(() => useStore.setState(initial, true))`; test selectors as plain reducer functions.
- **React Hook Form + Zod:** test the schema as a pure unit (`schema.safeParse(input)`) and the form end-to-end through the rendered DOM.

### 3.6 Playwright (E2E) rules

- Pin to user-critical journeys. No E2E-everything.
- Deterministic backend: seeded test env or `docker compose` local stack.
- Use `storageState` for auth reuse. Retries: `2` on PR, `0` on `main`.
- `trace: "on-first-retry"`, `screenshot: "only-on-failure"`, `video: "retain-on-failure"`{{#IF LOCALE_MODE=farsi-only}}; **locale `fa-IR`, timezone `Asia/Tehran`**{{/IF}}{{#IF LOCALE_MODE=bilingual}}; locale `fa-IR` or `en-US`, timezone `Asia/Tehran`{{/IF}}.
- Prefer `getByRole` / `getByLabel`; use `page.route` to stub specific endpoints.

### 3.7 Accessibility, i18n, visual, performance

- **Accessibility:** `axe(container)` in component tests; `AxeBuilder({ page })` in E2E. {{#IF LOCALE_MODE=farsi-only}}RTL is mandatory — every test runs with `dir="rtl"`, logical properties, mirrored icons.{{/IF}}{{#IF LOCALE_MODE=bilingual}}Both RTL and LTR runs required.{{/IF}}
- **i18n / locale:** tests run with production locale; assert via rendered output, not hard-coded strings. Assert Persian numerals where relevant.
- **Visual regression:** Playwright snapshots; pin font loading (await `document.fonts.ready`); never auto-accept diffs.
- **Performance:** Lighthouse CI on PRs (LCP, INP, CLS, TTFB, JS size) with budget regressions failing.

### 3.8 Frontend coverage

{{#IF FE_COVERAGE_FLOOR}}Vitest `coverage.provider: 'v8'` with `--coverage-target={{FE_COVERAGE_FLOOR}}`. Ratcheting gate: never lower the number; bump it in a maintenance MR whenever the natural coverage is comfortably above.{{#ELSE}}No global floor pinned for v1; each MR is reviewed for adequate coverage of the new surface. Ratchet-up-never-down applies whenever a floor lands.{{/IF}}

---

## 4. Critical-path journey tests [SHARED]

Backend E2E tests + Playwright specs exercise the platform's critical user journeys end-to-end. Journey list per project:

{{CRITICAL_JOURNEYS}}

Each journey has both a backend `tests/e2e/test_<flow>.py` (drives via `httpx.AsyncClient` against the running compose stack) and a Playwright spec `tests/e2e/<flow>.spec.ts` (drives the browser).

---

## 5. Cross-cutting rules

- **Contract testing.** Backend publishes OpenAPI from FastAPI (`app.openapi()`); FE regenerates the typed client in CI; the contract-drift job diffs old vs new OpenAPI and fails breaking changes without a version bump.
- **Test data.** Factories (`polyfactory` for Pydantic, custom for FE) — return fresh objects.
- **Determinism.** No `Math.random()` / `random.random()` / `new Date()` without a seam. No hard-coded "today" dates{{#IF CALENDAR=jalali}}; TZ pinned to `Asia/Tehran` in CI{{/IF}}; no network ever (MSW for FE, `respx` + dependency overrides for BE).
- **Flaky tests — zero tolerance.** Quarantine on first observed flake, then fix or delete within one sprint.
- **Parallelization.** BE: `uv run pytest -n auto` with `pytest-xdist` (template-DB-per-worker). FE: Vitest parallel by default; Playwright `--workers=N`.
- **Local DX.** One command: `make test` / `pnpm test:all`. Pre-commit runs lint + unit-on-changed.

### 5.1 CI gates — required matrix

| Stage | Backend | Frontend | Block merge? |
|-------|---------|----------|--------------|
| Lint | `ruff` + `mypy` | `eslint` + `tsc --noEmit` | yes |
| Format | `ruff format` | `prettier --check` | yes |
| Unit | `pytest -m unit` | `vitest run` | yes |
| Integration | `pytest -m integration` (Testcontainers Postgres{{#IF HAS_KAFKA}} + Kafka{{/IF}}{{#IF HAS_MEILISEARCH}} + optional Meilisearch{{/IF}}) | — | yes |
| Contract | OpenAPI diff | regen client, no diff | yes |
| E2E smoke | — | Playwright `--grep @smoke` | yes |
| Full E2E | — | Playwright (all) | nightly |
| Coverage gate | `--cov-fail-under={{BE_COVERAGE_FLOOR}}` | Vitest thresholds | yes |
| Mutation | `mutmut` nightly | Stryker nightly | no |
| Sec audit | `pip-audit`, `bandit` | `pnpm audit`, `semgrep` | yes (on PR) |
| Perf | benchmarks (nightly) | Lighthouse CI | yes (regress) |
| Visual | — | Playwright snapshots | yes |
{{#IF ARCH_SHAPE=microservices}}| Shared-logic version-lock (BE) | `.gitlab-ci.yml` gate | — | yes |
{{/IF}}

---

## 6. Project conventions

### 6.1 Required directory skeleton (mirror `src/`)

```
tests/
├── conftest.py                         # global fixtures
├── fixtures/                           # canonical fixture library (project-specific)
├── unit/
│   ├── conftest.py
│   └── {{#IF ARCH_SHAPE=microservices}}domain{{#ELSE}}modules{{/IF}}/
│       └── <entity>/                   # mirrors src/{{#IF ARCH_SHAPE=microservices}}domain{{#ELSE}}modules/<module>{{/IF}}/<entity>/
│           ├── conftest.py
│           ├── test_services/
│           │   └── test_<entity>.py    # one file per entity — tests every perform_<verb>
│           ├── test_database/
│           │   └── test_action/
│           ├── test_data_models/
│           └── test_validators/
├── integration/
│   ├── api/
│   │   └── <entity>/
│   │       └── test_<route>.py
{{#IF HAS_KAFKA}}│   ├── consumers/
│   │   └── <event>/
│   │       └── test_<handler>.py
{{/IF}}│   └── cronjobs/
│       └── test_<job>.py
└── e2e/
    └── test_<flow>.py
```

Rules:

- **One test file per entity**. Functions inside follow `test_perform_<verb>_<condition>`.
- Use `pytest.mark.parametrize` for many cases.
- `src/api/` routes are not mirrored under `tests/unit/` — HTTP glue lives under `tests/integration/api/`.

### 6.2 Fixture hierarchy (global → tier → entity)

| Tier | File | Owns |
|------|------|------|
| Global | `tests/conftest.py` | env vars; mock toolkit. |
| Tier | `tests/{unit,integration,e2e}/conftest.py` | tier-wide shared fixtures. |
| Entity | `tests/unit/{{#IF ARCH_SHAPE=microservices}}domain{{#ELSE}}modules{{/IF}}/<entity>/conftest.py` | entity-specific sample payloads and records. |

- Never re-declare a parent fixture in a child `conftest.py`.
- Duplicate names across `conftest.py` files are a review block.

### 6.3 Required global fixtures

`tests/conftest.py` MUST expose this toolkit with these exact names:

| Fixture | Provides |
|---------|----------|
| `mock_db_pool` | `MagicMock` pool. |
| `mock_db_connection` | `AsyncMock` connection. |
| `mock_db_action` | `AsyncMock` standing in for `<Entity>DbAction`. |
| `mock_datetime_now` | Frozen `datetime(..., tzinfo=UTC)` returned by the project's `now()` seam. |
{{#IF CALENDAR=jalali}}| `mock_jalali_now` | Frozen Jalali components returned by `jalali_lib.now(tz="Asia/Tehran")`. |
{{/IF}}| `sample_ulid` | Stable ULID string. |
| `mock_logger` | `MagicMock` standing in for the project logger. |
| `mock_httpx_client` | `AsyncMock` `httpx.AsyncClient`. |
| `mock_bcrypt` | `MagicMock` for the password hasher. |
{{#IF CAPTCHA_PROVIDER}}| `mock_{{CAPTCHA_PROVIDER}}_agent` | `AsyncMock` returning verified-token by default. |
{{/IF}}{{#IF OTP_PROVIDER}}| `mock_{{OTP_PROVIDER}}_agent` | `AsyncMock` returning success by default. |
{{/IF}}{{#IF CDN_PROVIDER}}| `mock_{{CDN_PROVIDER}}_agent` | `AsyncMock` returning success by default. |
{{/IF}}{{#IF HAS_KAFKA}}| `mock_kafka_producer` | `AsyncMock` — for asserting outbound event emission. |
{{/IF}}

Module fixtures MUST be named `sample_<noun>` / `sample_<noun>_record`.

### 6.4 Test-env vars MUST be set before `src` import

```python
# tests/conftest.py — the very first lines
import os

os.environ.setdefault("POSTGRES_DATABASE_URI", "postgresql://test:test@localhost:5432/test")
os.environ.setdefault("JWT_PUBLIC_KEY", "-----BEGIN PUBLIC KEY-----\n<test-only RSA key>\n-----END PUBLIC KEY-----")
# ... any other required env vars per project

# Only AFTER the env is primed may we import anything from src
from src.config import settings  # noqa: E402
```

- Use `setdefault`, not assignment.
- Every new secret env var added to settings adds a matching `setdefault` in the same PR.

### 6.5 Required cases for every `perform_<verb>` operation

| Case | Required assertions |
|------|---------------------|
| Happy path | `result_<verb>` fields correct; each collaborator called once with expected args. |
| Not found | `pytest.raises(ProjectBaseException) as exc` → `exc.value.status_code == 404` **and** `exc.value.error_code == "<EXPECTED_CODE>"`. |
| Invalid input | `exc.value.status_code == 400` **and** `exc.value.error_code == "<EXPECTED_CODE>"`. |
| Conflict | `exc.value.status_code == 409` **and** `exc.value.error_code == "<EXPECTED_CODE>"`. |
| Dependency error | Collaborator `side_effect = httpx.HTTPError(...)` → wrapped as `exc.value.status_code in (502, 504)`. Never asserts 500 for a dependency failure. |
| PATCH semantics | Input passed to `update` matches `command.model_dump(exclude_unset=True)`. |
{{#IF HAS_KAFKA}}| Kafka handoff | Assert the Kafka producer mock was called once with the expected topic + serialised event. |
{{/IF}}

Hard rules:

- Verify exception details — `status_code` **and** `error_code`.
- On every failure case, assert side effects did NOT happen.
- Assert observable outcomes only.

### 6.6 Naming conventions

**Backend**

- Test files: `test_<entity>.py` mirroring `src/{{#IF ARCH_SHAPE=microservices}}domain{{#ELSE}}modules/<module>{{/IF}}/<entity>/services/<entity>.py`.
- Test functions: `test_perform_<verb>_<condition>`.
- Markers: every test carries `@pytest.mark.unit` / `@pytest.mark.integration` / `@pytest.mark.e2e`.

**Frontend**

- Unit / component tests: `<unit>.test.ts` or `<unit>.test.tsx`, co-located next to the unit (grouped under `__tests__/`).
- E2E tests: `<journey>.spec.ts` under `tests/e2e/`.

---

## 7. Reviewer checklists

### 7.1 PR reviewer (BE)

- [ ] New `feature:` adds at least one test.
- [ ] Tests mirror `src/` layer.
- [ ] All deps mocked in unit tests; integration covers real DB.
- [ ] Every error path (4xx, 5xx) tested with `status_code` + `error_code` assertion.
- [ ] No `time.sleep`, no real network, no real filesystem outside `tmp_path`.
- [ ] `--cov-fail-under` floor met or raised.

### 7.2 PR reviewer (FE)

- [ ] New component / hook has a test next to it.
- [ ] MSW handlers updated; `onUnhandledRequest: "error"` still passes.
- [ ] Queries use roles / labels; no test-id reach unless justified.
- [ ] Error / loading / empty states all asserted.
- [ ] `axe` clean on rendered tree.
- [ ] If user-facing, a Playwright smoke spec covers the journey.
- [ ] Vitest coverage thresholds met.

### 7.3 AI-written tests — anti-hallucination rule

Mandatory workflow:

1. Read the source completely before generating anything.
2. List the real symbols you intend to test.
3. Generate tests only for symbols that exist with the real signatures.
4. Run the suite and check coverage.
5. Review every generated test like hand-written code.

Reviewer cue: if a test references a name `grep` cannot find in `src/`, the test is hallucinated.
