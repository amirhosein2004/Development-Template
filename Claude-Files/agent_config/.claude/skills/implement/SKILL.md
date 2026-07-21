---
name: implement
description: |
  implement — backend-service|backend-library|backend-tests|frontend-bootstrap|frontend-page|frontend-tests|infra-scaffold. Routed implementation skill for the backend, library, frontend, and infra repos declared in the workspace's `tech/docs/project-architecture/v<N>.md`. Every stack pin, provider name, locale rule, and repo list is read from the architecture doc + the applicable layout standard — nothing about the target stack lives in this skill body. Writes files only — no stage/commit/push/MR/migration/tests-run/install.

  - `backend-service <repo>[::full|gap|section=<n>]` — generate the v<N> implementation of one backend {{OWNER_TERM}} from its `docs/v<N>/PRD-TDD.md` + the applicable layout standard (`microservice-layout.md` when `ARCH_SHAPE=microservices`, `monolith-layout.md` when `ARCH_SHAPE=monolith`, both for `hybrid`) + every other standard except `testing.md`. When `ARCH_SHAPE=microservices`, `<repo>` is one of the `tech/backend-*` repos discovered in architecture §1.1 (excluding the shared-library repo). When `ARCH_SHAPE=monolith`, there is one backend repo (the single backend deployable discovered in §1.1) and `<repo>` names one internal module under `src/modules/<module>/`. When `ARCH_SHAPE=hybrid`, both forms are accepted based on whether the target path is a module in the monolithic core or a standalone service repo. Writes the domain ring per entity (`constants/` allow-lists + `StrEnum`s, `data_models/` Command / Result / event DTOs with the `coding.md` §2.1 prefix vocabulary, `database/sql/0N1…0N8` idempotent raw DDL, `<Entity>DbAction` raw-driver action layer via the shared `DbAction` base, `<Entity>Service.perform_<verb>` service layer); the transport ring (`src/api/v<N>/{router,routes,schemas,deps}`, optional consumers / cronjobs / worker roles per the applicable layout standard, per-event `*_v<N>.py` when `HAS_KAFKA`); the infra ring (`src/infra/platform/` + `src/infra/integrations/` — the platform integrations `OTP_PROVIDER` / `CDN_PROVIDER` / `CAPTCHA_PROVIDER` / `PSP_PROVIDER` from architecture §3 are the ONLY external clients scaffolded, one per declared provider); the root `__main__.py` dispatcher (`python __main__.py <role>` — never bare uvicorn); `migrations/versions/*.py` (Alembic per architecture §3, `op.execute` only, no ORM import); ops scaffolds (`docker/Dockerfile.<role>` per shipped role on the architecture-declared `CONTAINER_BASE` multi-stage, `docker/docker-compose.yml` with the architecture-declared Postgres image tag, `.gitlab-ci.yml` with MR gates `LINTER` + `TYPE_CHECKER` + `TEST_RUNNER --cov-fail-under=<BE_COVERAGE_FLOOR>` + `HAS_SHARED_LIBRARY` version-lock + `gitleaks` secret scan + the pre-deploy migration gate, `.pre-commit-config.yaml`, `pyproject.toml` skeleton with the `SHARED_LIBRARY_NAME` git-tag pin when `HAS_SHARED_LIBRARY`, `Makefile`, `.env.example`); **bare test scaffolds only** — empty shells raising `NotImplementedError`, filled later by `backend-tests`. Naming code-pinned per `infrastructure.md` §2: `<{{OWNER_TERM}}>__<entity>` tables (+ `<consumer>__mirror_of_<origin>__<entity>` mirrors when `HAS_MIRROR_TABLES`), `<{{OWNER_TERM}}>:…` Redis keys (when `HAS_REDIS`), `<sender>-<receiver(s)>-<event>` Kafka topics (when `HAS_KAFKA`; receivers sorted alphabetically joined by `_`; DLQ `<topic>-dlq`; priority by topic), `<{{OWNER_TERM}}>-<purpose>` MinIO buckets (when `HAS_MINIO`), `search_<type>` indexes (when `HAS_MEILISEARCH`). ULID `VARCHAR(50)` app-side; `publication_id` on every business table when a tenant noun is declared; when `CALENDAR=jalali`, Jalali sidecar columns on every human-observed date (locked decision — `jalali_lib` only, never a Gregorian round-trip); when `BLOCK_EDITOR` locked-decision is set, `body JSONB` block tree (any hook-blocked HTML column name is the per-project write-edit-guard's job, not this skill's); schema-as-code sole source of truth for `CONTENT_OWNER`; `ProjectBaseException` only; `{success, message, data}` envelope; camelCase paths; 404-not-403 on ownership; RS256 (or the code-pinned `JWT_ALG` from architecture §3) with `AUTH_OWNER` the sole private-key holder and `check_auth` the single resolver; Kafka the only broker when `HAS_KAFKA`, Redis cache only when `HAS_REDIS`, post-response work per `microservice-layout.md` §4.4 (`Celery-on-Kafka` when `HAS_KAFKA`, else outbox + worker); `/healthCheck` + `/readiness` + `/warmup` probes. **Money-column refusal:** if `PSP_PROVIDER` is empty in architecture, any migration adding a currency-shaped column (`amount_*`, `price_*`, `*_cents`, `*_toman`, `*_rial`, `*_usd`, `*_eur`, plus every code-declared currency locale) is refused. Silent-skip when present: `pyproject.toml`, `.pre-commit-config.yaml`, `Makefile`, `.env.example`, `.gitignore`, `.dockerignore`, `docker/`, `.gitlab-ci.yml`. Never generated: `uv.lock`, editor configs. Refuses if `<repo>` is `SHARED_LIBRARY_NAME` (use `backend-library`) or a frontend / infra repo, if `<repo>` names a role owner whose PRD-TDD has not materialized (e.g. a reserved-slot backend), if the PRD-TDD is missing, or if it has unresolved TBD / TODO markers in §6 / §7 / §8 / §9 / §11.

  - `backend-library [::full|gap|patch=<module>]` — generate the shared backend library named `SHARED_LIBRARY_NAME` in architecture §1.1. Refuses with "no shared library in this project's architecture" when `HAS_SHARED_LIBRARY=false`. Library, not a service: no FastAPI app, no routes, no `__main__.py`, no per-role Dockerfiles, no DB, no `migrations/`. Writes `src/<SHARED_LIBRARY_PACKAGE>/` module by module in dependency order: `exception` (`ProjectBaseException`) + `fastapi_exception_handler` (envelope + ERROR log line), logging / OTel bootstrap when `HAS_OBSERVABILITY_STACK`, **`jalali_lib`** only when `CALENDAR=jalali` (`to_jalali` / `to_utc` / `persian_slugify` + the boundary rule — the single implementation site for the calendar locked decision), **`persian_normalization`** only when `LOCALE_MODE=farsi-only OR LOCALE_MODE=bilingual` (ZWNJ, ی/ي, ک/ك, diacritic fold, digit fold), shared validators + ULID helpers, `DbAction` base per `infrastructure.md` §3.6 (full method table + filter engine + keyset pagination), `security` (`JWT_ALG` verify-only, `check_auth` primitives + `CurrentUser`), the MinIO adapter only when `HAS_MINIO`, Kafka producer / consumer bases only when `HAS_KAFKA`, Redis wrapper (cache-only posture) only when `HAS_REDIS`, the agent base (circuit breaker + retry for third-party calls), the SMS client only when `OTP_PROVIDER` is set (v<N> home, called by `AUTH_OWNER`; migrates when a notification owner materializes), plus packaging (`pyproject.toml`, `.gitlab-ci.yml` with the release-tag job that opens automated pin-bump MRs into every consumer per `ci-cd.md` §3.2, `.pre-commit-config.yaml`, `Makefile`) and bare test scaffolds. Release tags cut on `PROD_ENV_NAME`; semver discipline (breaking public-surface change = major); the library ships no pytest fixtures for consumers. Refuses if pointed at any other repo, if `HAS_SHARED_LIBRARY=false`, if `<SHARED_LIBRARY_NAME>/docs/v<N>/PRD-TDD.md` is missing / placeholder, or if `patch=<module>` names an undeclared module.

  - `backend-tests <repo>[::full|gap|unit|integration|e2e|entity=<entity>[.<verb>]|path=<rel-path>]` — generate the **full** test suite for one backend repo (any backend service or the shared library) — real assertions, fixtures, mocks — unit + integration + e2e. Fills the `NotImplementedError` shells left by `backend-service` / `backend-library`. Follows `tech/docs/standards/testing.md` (`TEST_RUNNER` from architecture §3; coverage floor `BE_COVERAGE_FLOOR` from architecture §3). Anti-hallucination mandatory: read the source completely, list real symbols, `grep -RIn '<symbol>' src/` — zero hits ⇒ hallucinated ⇒ rewrite or delete. `asyncio_mode = "auto"` — no `@pytest.mark.asyncio`. Markers `unit` / `integration` / `e2e` under `--strict-markers`. `class TestPerform<Verb>:` per service method; one test per raised `error_code` (PRD-TDD §11) asserting **`status_code` AND `error_code`, never `message`** (message equality lives only in the error-contract test). Unit mocks at the DB-pool layer (`mock_db_pool` / `mock_db_connection`; `mock_db_action` only when intentionally bypassing DB); never mock your own service layer. Integration = real Postgres via Testcontainers on the architecture-declared image tag + `alembic upgrade head`; Kafka consumer tests (when `HAS_KAFKA`) publish a synthetic event to a Testcontainers broker and assert the Postgres side effect + the mirror `updated_at` idempotency guard. Route tests assert the full envelope + `401` + `404` ownership-miss (never 403) + `403` RBAC map-miss. When `CALENDAR=jalali`: Jalali round-trip on every human-observed date (no Gregorian off-by-one). When the target service owns block-tree content (declared in its PRD-TDD): unknown block type / autosave conflict cases. Parametrized filter / sort / keyset-pagination over the `constants/` allow-lists. Fixtures local per repo — the library ships none. Coverage floor from architecture §3 (`BE_COVERAGE_FLOOR`); data models `min(BE_COVERAGE_FLOOR - 5, 90)`; ratchets up, never down. Env vars set before any `src` import. Reads `testing.md` in full FIRST, then PRD-TDD §3 / §6 / §7 / §8 / §9 / §10 / §11 / §13 / §14, then sliced standards, then `src/` fully, then `conftest.py` at every tier, then existing `tests/` LAST. Refuses if `src/` lacks the canonical shape, PRD-TDD missing, or `pyproject.toml` missing `asyncio_mode = "auto"`.

  - `frontend-bootstrap <repo>` — one-shot skeleton for a frontend repo declared in architecture §1.2. `<repo>` is one of the `FRONTEND_REPOS` discovered from the architecture; framework and build mode (Astro SSG / Vite + React SPA / Next / whatever) come from that row's `stack` cell. Toolchain (pnpm-only per architecture §4.1, ESLint flat config with `eslint-plugin-boundaries` ring rules per `ci-cd.md` §8.1, Prettier + `prettier-plugin-tailwindcss` (+ framework-specific plugins), Husky + lint-staged + commitlint), strict tsconfig + path aliases per `frontend-layout.md` §6, Tailwind bound to every design-system token via `src/styles/tokens.css` with the theme selectors declared in `product/docs/uiux/v<N>/design-system/design-system.md`. Locale shell driven by architecture §4.1 `LOCALE_MODE`: `farsi-only` → native-RTL Farsi-only shell (`<html lang="fa" dir="rtl">`, logical properties, right-edge admin Sidenav, NO i18n runtime, NO locale routing); `bilingual` → path-prefixed `/fa/`, `/en/` with `<html lang="{fa|en}" dir="{rtl|ltr}">` set at build time (never runtime i18n framework); `latin-only` → `<html lang="en" dir="ltr">`. Fonts self-hosted per architecture §4.1: when `LOCALE_MODE=farsi-only OR bilingual`, Vazirmatn (UI) + JetBrains Mono (numerals / code) woff2 fetched from the upstream OFL repos and committed to `public/fonts/`; otherwise whatever the architecture declares — always self-hosted, never a runtime font CDN. When `CALENDAR=jalali` + `DIGIT_RULES=persian-human-ascii-machine`: Jalali + Persian-digit formatters centralized in `@shared/format/` / `@lib/format/` (boundary rule: Jalali / Persian digits on human surfaces, ISO-8601 / ASCII on machine feeds); otherwise the architecture-declared calendar library + `Intl.NumberFormat` per locale. When a `CONTENT_OWNER` service uses block trees (declared in its PRD-TDD): block-renderer / block-editor primitives seeded in the shared ring (dashboard: `@shared/block-editor/` + `serialization.ts` + one file per block + `@shared/block-renderer/`; landing: `@lib/block-renderer/` — parity per `frontend.md` §1.4). Admin frontend auth shell (HTTP-only `Secure SameSite=Lax` cookie + single-flight silent-refresh mutex; JWT never in JS-readable storage; only theme + editor-draft slice persist). Envelope-aware API client (`parseEnvelope<T>`, `X-Request-ID` read from responses — never generated client-side; unhandled errors POST to `AUTH_OWNER`'s `/frontendErrors`). `scripts/codegen.ts` per consumed backend (`/<{{OWNER_TERM}}>/v<N>/openapi.json` — landing consumes the read services listed in the per-repo `stack`; admin adds `AUTH_OWNER`). Vitest + MSW (`onUnhandledRequest: "error"`) + Playwright (locale + timezone from architecture per-repo hints; `chromium` + `visual-desktop` + `visual-mobile`), `.gitlab-ci.yml` per `ci-cd.md` §8 incl. `codegen:drift`, `codegen:drift:scheduled`, and the guarded `visual` job. Landing extras (when the repo is the SSG landing): `src/pages/` route shells per its PRD-TDD, `Base.astro` with SEO emitters + regional trust seal slots, `@lib/seo/{json-ld,open-graph,twitter-card}.ts`. Dashboard extras (when the repo is the SPA admin): React Router 7 data-mode router with guard chain `cookieExists? → silentRefreshOn401Once → me() → permissions()`, registry-driven Sidenav (edge-side driven by `LOCALE_MODE`), theme provider bound to the design-system theme selectors. **No feature pages**; **no Dockerfile in frontend repos** (static output served by `infra-nginx`); the only third-party runtime origins are those declared in the CSP allow-list under architecture §5 / the applicable frontend PRD-TDD's §11. Refuses if `<repo>` is not in `FRONTEND_REPOS`, the PRD-TDD is missing, or `src/features/` already has sub-folders.

  - `frontend-page <repo>::<area>::<page>` — generate one feature folder under `<repo>/src/features/[<sub-bucket>/]<page-slug>/` from the matching UI/UX mockup + design system + feature catalog + consumed backend PRD-TDDs. Only sub-op that writes frontend feature code. `<area>` is any existing folder directly under `product/docs/uiux/v<N>/` (validated dynamically against the filesystem — never a hard-coded allow-list). `<page>` is the HTML mockup file inside that folder (accepted with or without `.html`). `<page-slug>` is `<page>` with `.html` stripped. Target-path mapping: the repo already scopes its own frontend, so a top-level `<area>` matching the repo shape is elided — a landing-area mockup lands in the landing repo's `src/features/<page-slug>/` (not `src/features/landing/<page-slug>/`); an admin-area mockup lands in the admin repo's `src/features/<page-slug>/` (not `src/features/admin/<page-slug>/`); any other `<area>` survives as an inner feature bucket. Mockup lives at `product/docs/uiux/v<N>/<area>/<page>` and carries every theme variant declared in the design system (either co-located in the same file or as paired files — the reader accepts either layout). Writes the entry component (framework-appropriate — component filename convention comes from the frontend repo's PRD-TDD), route append when the framework uses a router table, `queries.ts` / `mutations.ts` (TanStack Query on repos that pin it), `forms.schema.ts` (Zod), `types.ts` (re-exports from generated openapi — never hand-typed), `copy.ts` (locale-appropriate strings — no user-facing strings inline in markup), `errors.ts` (`error_code` → locale-appropriate copy), `__tests__/` scaffolds with `describe` + `it.todo` (real bodies from `frontend-tests`), MSW handlers defaulting to **empty payloads** (never fake fixture rows — empty payloads exercise the four-state UX), and rewritten chrome when the chrome audit classifies the bootstrap shell as stub. Hard rules: visual fidelity is token binding per `frontend-layout.md` §11 (no `bg-[#…]` approximations, no generic palette classes, no inline styles — arbitrary values bind to `tokens.css` custom properties); read the mockup CSS end-to-end BEFORE composing (HTML gives structure, CSS gives grammar); mobile-first responsive contract bound to the mockup's own `@media` queries (landing hamburger drawer with focus trap; dashboard Sidenav edge-side drawer per `LOCALE_MODE`, DataTable cardification via `data-label`, tile-grid 4→2→1, calendar → agenda fallback; beware CSS containing-block traps — render drawers as siblings, not children of `backdrop-filter` / `transform` ancestors); when `LOCALE_MODE=farsi-only OR bilingual`, Persian letter-spacing quarantine on Farsi copy; dates + digits only through the shared formatters declared by architecture §4.1; theme parity across every declared theme (same DOM, tokens differ); envelope-aware (branch on `error_code`, never `message`); auth-aware on the admin frontend (401 → silent refresh once → login with `next=`; 404-not-403); block-renderer parity — a new block type ships editor + both renderers + the `CONTENT_OWNER` schema; never overwrite human-authored files (`Will replace:` + ask; bootstrap-stub chrome is scaffold, not sheltered). Refuses if `<repo>` is not in `FRONTEND_REPOS`, `product/docs/uiux/v<N>/<area>/` does not exist, the resolved mockup file does not exist, `<repo>/src/features/` doesn't exist (bootstrap first), or the feature is not `[x]` in `product/docs/features/v<N>/all-features.md`.

  - `frontend-tests <repo>[::full|gap|feature=<area>[/<page-slug>]|path=<rel-path>]` — generate the **full** Vitest + RTL test suite (or whatever `tech/docs/standards/testing.md` §3 declares for this frontend stack) for every feature folder under `src/features/`. Twin of `backend-tests`; fills the `it.todo` scaffolds left by `frontend-page`. Query priority role → label → text → `data-testid` (with justification comment). `findBy*` async / `getBy*` sync / `queryBy*` absence — never `await waitFor(() => expect(...))`. `userEvent` v14 async only, no `fireEvent`. No CSS-class / inline-style assertions. MSW `onUnhandledRequest: "error"`, never stub `useQuery` / `useMutation`. Fresh `QueryClient` per test. Production locale + direction per architecture `LOCALE_MODE`. When `DIGIT_RULES=persian-human-ascii-machine`: digit and Jalali assertions via the shared formatters' rendered output — never hard-coded glyph literals. Copy asserted through the `copy` object. Every Zod branch tested; every backend `error_code` in `errors.ts` tested. `jest-axe` per rendered page. Four-state coverage on admin surfaces (loading / empty / error with the `X-Request-ID` reference / success). Admin auth flows (silent-refresh success, refresh-fail → login redirect, 404-ownership). When a `CONTENT_OWNER` service ships block-tree fixtures: block-renderer snapshot tests against the canonical fixture library (both repos test the same fixtures for parity per `frontend-layout.md` §8) + lossless editor serialization round-trip on the admin. No real network; co-located `__tests__/` only (E2E + visual baselines are hand-authored). Refuses if `<repo>` not in `FRONTEND_REPOS`, `src/features/` empty, entry component missing, MSW infrastructure missing, or Vitest config lacks `globals: false` + `environment: "jsdom"`.

  - `infra-scaffold <repo>` — generate the v<N> config + Docker Compose + init scripts + operational assets for one of the `INFRA_REPOS` declared in architecture §1.1 / §5. Component chosen by repo name — `infra-postgresql` / `infra-redis` / `infra-minio` / `infra-meilisearch` / `infra-kafka` / `infra-nginx` / `infra-observability` — or the corresponding `devops-*` alias when the project uses that prefix. Per-repo assets: **postgresql** — Dockerfile pinned to the architecture-declared image, `postgresql.conf` (`wal_level = replica`, `archive_mode = on`, `archive_command` → WAL archive when `HAS_MINIO`; timeouts), `pg_hba.conf` with explicit per-{{OWNER_TERM}} `database ↔ user` rules + final `reject` (scram-sha-256 only), `initdb/` per-{{OWNER_TERM}} role + database + `REVOKE CONNECT … FROM PUBLIC` (one file per row in architecture §1.1 that owns a database), `pg_basebackup` + WAL-archive + PITR-restore scripts, **backup runbook**; **redis** — cache-only `redis.conf` (maxmemory + eviction per PRD-TDD) + the per-{{OWNER_TERM}} key-namespace catalog quoted as comments (including the content-owner's redirect / slug-history read cache when architecture §7.1 declares it); **minio** — pinned compose; `scripts/init-buckets.sh` (idempotent `mc mb --ignore-existing` for the bucket catalog quoted from the owning PRD-TDDs), `scripts/{create-service-keys,rotate-keys,lifecycle}.sh` — per-{{OWNER_TERM}} scoped keys, no keys committed; **meilisearch** — pinned config; `scripts/rotate-master-key.sh` + master-key rotation runbook; index-ownership note (indexes created by `SEARCH_OWNER`, never infra); snapshot schedule; **kafka** — single-cluster config + idempotent topic-creation script quoting the canonical catalog (every `<sender>-<receiver(s)>-<event>` + `<topic>-dlq`; mirror topics partitioned by `record_id`) + **DLQ replay runbook**; **nginx** — server blocks for every domain in architecture §1 (public + admin + any additional), `X-Request-ID` **generated at the edge** (`$request_id` — never by frontend or backend), security headers quoted from `security-and-auth.md` §8 (HSTS, nosniff, `SAMEORIGIN`, Referrer-Policy, Permissions-Policy, CSP allow-listing self + `CDN_PROVIDER` origins + declared third-party runtime origins), Let's Encrypt TLS, per-{{OWNER_TERM}} `limit_req_zone`, develop / staging `auth_basic` gate referencing the never-committed `/etc/nginx/.htpasswd` (per architecture §5.7), when `CDN_PROVIDER` is set: origin notes + **purge-adapter reference** (`CdnAdapter` in the assets owner is the sole purge path); **observability** — when `HAS_OBSERVABILITY_STACK`, full-stack compose (per the components table in architecture §5.1); `provisioning/` datasources + starter dashboards (error events grouped by `service` × `service_version` × `error_code`), Loki rules for the project's `error_code` families, Prometheus scrape + alert rules, Alertmanager routes per architecture, Promtail stdout pipeline, OTel Collector as the sole telemetry ingestion point, blackbox probes (`/healthCheck`, TLS expiry), scheduled `/warmup` warmer; no public status page when architecture §9 defers it. Shared across all seven: `docker/docker-compose.yml` on the external `<PROJECT_SLUG>-network`, `.gitlab-ci.yml` (config lint, image build, deploy-on-`PROD_ENV_NAME`, secret scan), `.env.example` (names quoted, values blank), `Makefile`, `docs/v<N>/OPS-RUNBOOK.md` scaffold. Hard rules: contract quoted not restated (anti-hallucination grep against the owning repo); no secrets ever; no application code / module tables in infra repos (Alembic lives in each backend service); envelope pass-through; idempotent bootstrap; the hosting posture from architecture §8 (in-country VM + CDN if declared; no origins outside the project's own servers unless the architecture allow-lists them); silent-skip present config files; never generate TLS material / `.htpasswd` / keys / data volumes. Refuses if `<repo>` is not in `INFRA_REPOS`, the PRD-TDD is missing / placeholder, or the consumed contract for the layer is not addressable (nginx additionally requires every frontend PRD-TDD's routing section).

  Use when the user asks to:
  - "implement `<backend service>`", "scaffold `<service>` from its PRD-TDD", "generate the v<N> code for a backend service", "write the `<entity>` domain — service / DbAction / SQL tree", "wire a consumer / cronjob / worker", "land the migration for `<table>`", "add the cronjob for `<job>`";
  - "implement the shared library", "generate `<SHARED_LIBRARY_NAME>`", "write `jalali_lib` / `persian_normalization` / the `DbAction` base / the SMS client / the JWT verifier / the circuit-breaker agent base";
  - "write tests for `<backend service>`", "generate the test suite", "fill the test scaffolds", "add unit tests for `<Entity>Service`", "integration tests for `<route>` / a Kafka consumer", "migration smoke tests";
  - "bootstrap `<frontend repo>`", "set up the frontend toolchain / Tailwind tokens / RTL shell / auth mutex / block editor primitives", "wire self-hosted fonts", "set up openapi-typescript codegen", "wire MSW + Vitest + Playwright";
  - "generate the `<page>` page", "scaffold the feature folder for `<page>`", "wire the queries / mutations / Zod schema / copy / errors for `<page>`";
  - "write tests for the frontend", "generate the Vitest + RTL suite for `<feature>`", "fill the `it.todo` scaffolds", "add block-renderer snapshot tests";
  - "scaffold `infra-<component>`", "generate the Postgres init scripts / per-{{OWNER_TERM}} DB roles", "provision the MinIO buckets / access keys", "write the Kafka topic catalog script / DLQ replay runbook", "configure nginx for `<domain>` / the CDN origin / the basic-auth gate", "rotate the Meilisearch master key", "set up Grafana / Loki / Prometheus provisioning";
  - Or invokes `/implement`.

  If the first arg is missing or not one of `backend-service | backend-library | backend-tests | frontend-bootstrap | frontend-page | frontend-tests | infra-scaffold`, stop and ask which sub-op — never default. None of the seven sub-ops stages / commits / pushes / opens an MR / runs anything — pair with `/mr open <scope>` afterwards.
---

# implement — routed implementation

```
/implement backend-service     <repo>[::full|gap|section=<n>]
/implement backend-library     [::full|gap|patch=<module>]
/implement backend-tests       <repo>[::full|gap|unit|integration|e2e|entity=<entity>[.<verb>]|path=<rel-path>]
/implement frontend-bootstrap  <repo>
/implement frontend-page       <repo>::<area>::<page>
/implement frontend-tests      <repo>[::full|gap|feature=<area>[/<page-slug>]|path=<rel-path>]
/implement infra-scaffold      <repo>
```

| Sub-cmd | Anchor | One-line summary |
|---|---|---|
| `backend-service` | [`## backend-service`](#backend-service) | Generate the v<N> implementation of one backend {{OWNER_TERM}} (or one module of the monolith). Ops scaffolds + bare test shells. |
| `backend-library` | [`## backend-library`](#backend-library) | Generate the `SHARED_LIBRARY_NAME` package — shared primitives + adapters, distributed by git tag. |
| `backend-tests` | [`## backend-tests`](#backend-tests) | Fill the empty backend test shells with real bodies. |
| `frontend-bootstrap` | [`## frontend-bootstrap`](#frontend-bootstrap) | One-shot skeleton for a frontend repo. No feature pages. |
| `frontend-page` | [`## frontend-page`](#frontend-page) | Generate one feature folder from its UI/UX mockup. |
| `frontend-tests` | [`## frontend-tests`](#frontend-tests) | Fill the `it.todo` scaffolds with real Vitest + RTL bodies. |
| `infra-scaffold` | [`## infra-scaffold`](#infra-scaffold) | Config + Compose + init scripts + operational assets for one infra repo. |

If the first arg is missing or not one of the seven, stop and ask.

## Synopsis

`implement` is the code-writing counterpart to `docs`. Where `docs` writes documentation, `implement` writes source. Every sub-op is **read-heavy, write-once, no side effects**. The full read pass completes before generation; generation produces files; no external command runs.

## Reading the workspace's architecture — Step 1 of every sub-op

Every sub-op begins by reading the workspace's architecture doc — either `tech/docs/project-architecture/v<N>.md` or `tech/docs/v<N>/project-architecture.md` (accept either layout). From it, extract into working memory:

- `ARCH_SHAPE` — one of `microservices` | `monolith` | `hybrid`. Governs which layout standard applies and whether `backend-service` generates a service or a module.
- `OWNER_TERM` — driven by `ARCH_SHAPE` (`service` for microservices / hybrid, `module` for monolith).
- **Backend stack pins from §3:** `PYTHON_VERSION`, `WEB_FRAMEWORK`, `DB_DRIVER`, `MIGRATIONS_TOOL`, `JWT_LIBRARY`, `JWT_ALG`, `CONTAINER_BASE`, `LINTER`, `TYPE_CHECKER`, `TEST_RUNNER`, `BE_COVERAGE_FLOOR`, Postgres image tag, Redis image tag (if `HAS_REDIS`), Kafka image tag (if `HAS_KAFKA`), Meilisearch image tag (if `HAS_MEILISEARCH`).
- **Infrastructure flags:** `HAS_KAFKA`, `HAS_REDIS`, `HAS_MINIO`, `HAS_MEILISEARCH`, `HAS_SHARED_LIBRARY`, `HAS_OBSERVABILITY_STACK`, `HAS_MIRROR_TABLES`, `HAS_CONTENT_BUCKET`, `HAS_WEBSOCKET`, plus per-flow flags (`HAS_SEARCH_INDEXER_FLOW` / `HAS_WEBHOOK_FLOW` / `HAS_AUDIT_FLOW` / `HAS_ASSETS_PURGE_FLOW`).
- **Frontend behavior:** `LOCALE_MODE` (`farsi-only` | `bilingual` | `latin-only`), `CALENDAR` (`jalali` | `gregorian`), `DIGIT_RULES` (`persian-human-ascii-machine` | `ascii-everywhere`), `FE_COVERAGE_FLOOR`.
- **Providers:** `OTP_PROVIDER`, `CDN_PROVIDER`, `CAPTCHA_PROVIDER`, `PSP_PROVIDER`. Empty ⇒ that adapter is not scaffolded. When `PSP_PROVIDER` is empty, migrations that add a currency-shaped column are refused (see the money-column rule under `## backend-service`).
- **Ownership roles:** `AUTH_OWNER`, `CONTENT_OWNER`, `SEARCH_OWNER`, `ASSETS_OWNER`, `AUDIT_OWNER`, `ENGAGEMENT_OWNER`, `ANALYTICS_OWNER`, `NOTIFICATION_OWNER` (any of them may be null if the role has no owner in v<N>).
- **Shared library:** `SHARED_LIBRARY_NAME` (repo name) + `SHARED_LIBRARY_PACKAGE` (import package). Only present when `HAS_SHARED_LIBRARY=true`.
- **Repo lists:** `BACKEND_REPOS`, `FRONTEND_REPOS`, `INFRA_REPOS` — with each row's `name`, `scope`, and PRD-TDD path.
- **Deployment posture:** `PROD_ENV_NAME` (usually `main`, sometimes `production`), `PROJECT_SLUG` (used in the compose network name and every `auth_basic` realm).
- **Branch chain:** `DEFAULT_BRANCH`, `DEV_BRANCH_CHAIN` (from `tech/docs/CLAUDE.md`).

If the architecture doc is missing or unparseable, stop and ask — never guess.

## Reading the applicable layout standard

- `ARCH_SHAPE=microservices` → read `tech/docs/standards/microservice-layout.md`.
- `ARCH_SHAPE=monolith` → read `tech/docs/standards/monolith-layout.md`.
- `ARCH_SHAPE=hybrid` → read both.

Every other standard applies to every shape: `api-and-data-contracts.md`, `errors-and-observability.md`, `security-and-auth.md`, `coding.md`, `frontend.md`, `frontend-layout.md`, `ci-cd.md`, `testing.md`, `documentation.md`, `git.md`, `infrastructure.md`.

## backend-service

Generate the v<N> implementation of one backend {{OWNER_TERM}}. When `ARCH_SHAPE=microservices`, this is a whole service repo; when `ARCH_SHAPE=monolith`, this is one internal module under `src/modules/<module>/` inside the single backend deployable; when `ARCH_SHAPE=hybrid`, either shape based on the target path.

### Argument

`<repo>[::<mode>]` — `<repo>` is one of the discovered `BACKEND_REPOS` (microservices / hybrid) or one of the monolith's declared modules (monolith / hybrid); `<mode>` is `full` (default) | `gap` | `section=<n>` (restrict to one PRD-TDD section — `7` Kafka + mirrors when `HAS_KAFKA`, `8` DB, `9` API, `11` errors).

Refuse if `<repo>` is `SHARED_LIBRARY_NAME` (use `backend-library`) / a frontend / an infra repo, `<repo>` is a reserved-slot owner whose PRD-TDD hasn't materialized, PRD-TDD missing or placeholder, or PRD-TDD has TBD in §6 / §7 / §8 / §9 / §11.

### Hard rules

- Read the PRD-TDD first. Bind §6 → data ownership; §7 → Kafka producers / consumers + mirror tables (only when `HAS_KAFKA`); §8 → migrations + `<{{OWNER_TERM}}>__<entity>` tables; §9 → routes + wire schemas; §10 → `ENVS` + `<{{OWNER_TERM}}>__configurations` seeds; §11 → error catalog; §13 → `check_auth` gating + rate limits.
- **Money-column refusal.** If `PSP_PROVIDER` is empty in architecture, any migration adding a currency-shaped column (`amount_*`, `price_*`, `*_cents`, `*_toman`, `*_rial`, `*_usd`, `*_eur`, and every code-declared currency locale) is refused with a `no PSP provider declared — currency columns require a payment provider in architecture §3` message.
- Layout is fixed by the applicable standard (`microservice-layout.md` / `monolith-layout.md`). Three rings, root `__main__.py` dispatcher, one role per process, versioning only in `src/api/v{N}/` + `*_v<N>.py`.
- Naming discipline code-pinned per `infrastructure.md` §2: `<{{OWNER_TERM}}>__<entity>` tables, `<consumer>__mirror_of_<origin>__<entity>` mirrors when `HAS_MIRROR_TABLES`, `<{{OWNER_TERM}}>:…` Redis keys when `HAS_REDIS`, `<sender>-<receiver(s)>-<event>` Kafka topics when `HAS_KAFKA` (+ `-dlq`), `<{{OWNER_TERM}}>-<purpose>` MinIO buckets when `HAS_MINIO`, `search_<type>` indexes when `HAS_MEILISEARCH` — same `<{{OWNER_TERM}}>` token everywhere.
- ULID `VARCHAR(50)` app-side; no cross-{{OWNER_TERM}} FKs; when a tenant noun is declared in architecture §10, every business table carries the tenant column from day one.
- When `CALENDAR=jalali`: Jalali sidecar columns via `jalali_lib` only (`coding.md §11`); machine feeds ISO-8601 / ASCII. Otherwise Gregorian per architecture §3.
- When the `CONTENT_OWNER` service declares block-tree body in its PRD-TDD: `body JSONB` block tree; schema-as-code sole source of truth (architecture §7.4). Any HTML-column blacklist is the per-project write-edit-guard's job, not this skill's.
- No ORM (per architecture §3 `ORM = None`). Raw `DB_DRIVER` + `$1, $2` via `<Entity>DbAction`. Alembic `op.execute("<raw SQL>")` only; no ORM import; `SET lock_timeout = '5s'`.
- `ProjectBaseException` subclasses only; `error_code` at the raise site.
- `{success, message, data}`, camelCase paths, 404-not-403, 429 with `Retry-After` + `data.retry_after`. `Idempotency-Key` only when `PSP_PROVIDER` is set (money-moving surfaces require it).
- `JWT_ALG` code-pinned (from architecture §3, typically RS256); `AUTH_OWNER` sole private-key holder; single `check_auth` resolver; Anonymous is a first-class role.
- Kafka only broker (when `HAS_KAFKA`); Redis cache only (when `HAS_REDIS`); post-response work per `microservice-layout.md` §4.4 (`Celery-on-Kafka` when `HAS_KAFKA`, else outbox + worker); DLQ per consumer; mirror tables per §4.8 (only when `HAS_MIRROR_TABLES`).
- Attribute prefixes per `coding.md §2.1`; banned vague names.
- When `HAS_SHARED_LIBRARY`: `SHARED_LIBRARY_NAME` pinned to current release; shared wiring through the library, never re-implemented.
- Silent-skip when present: `pyproject.toml`, `.pre-commit-config.yaml`, `Makefile`, `.env.example`, `.gitignore`, `.dockerignore`, `docker/`, `.gitlab-ci.yml`.
- Never generated: `uv.lock`, editor configs.
- No `Co-Authored-By:`; no derived onboarding / readme file references in generated code.

### Inputs

1. **Step 1 — architecture.** `tech/docs/project-architecture/v<N>.md` (extract every knob listed under "Reading the workspace's architecture" above).
2. **The PRD-TDD.** `<repo>/docs/v<N>/PRD-TDD.md` — full, no skimming.
3. Repo onboarding file (when it lands).
4. The applicable layout standard (`microservice-layout.md` when microservices, `monolith-layout.md` when monolith, both when hybrid) + every other `tech/docs/standards/*.md` except `testing.md`.
5. Architecture's cross-cutting decisions section + `architecture-decisions.md` if present.
6. Sibling backend PRD-TDDs touched by §7 Kafka / mirror contracts (only when `HAS_KAFKA`) + the `infra-kafka` topic catalog.
7. **Library — full read of BOTH the PRD-TDD end-to-end AND `src/<SHARED_LIBRARY_PACKAGE>/` end-to-end (when present)**, only when `HAS_SHARED_LIBRARY=true`. PRD-TDD: every section — §1–§3 invariants + locked decisions, §4 personas (this service is one), §5 per-module consumer call-flows, §6 (owns no tables), §7 distribution + pin shape, §8 Public API (binding — every emitted import must match), §9 subclassable class hierarchies, §10 env vars, §11 library exceptions, §12 inherited SLOs, §13 boundaries enforced. `src/`: walk every module — `__init__.py` re-exports + public function signatures + public class signatures + exported constants / `StrEnum`s / Pydantic models → `(module, symbol, signature)` table. **`src/` HEAD wins on conflict with §8** (services import from `src/`, log drift as §17). Import declared by service PRD-TDD but neither library `src/` nor §8 covers → refuse, tell operator to run `/docs prd-tdd-backend <repo> ::merge` (service PRD-TDD stale) or `/docs prd-tdd-library ::merge` + `/implement backend-library ::gap` (library behind). Bootstrap fallback (library `src/` empty) → PRD-TDD §8 sole source + §17 note for re-verify pass after library ships.
8. Current repo state — LAST.

### Generation order

Per entity: `constants` → `data_models` → `database/sql (0N1…0N8)` → `database/action` → `services`. Then transport (`api` → `consumers` when `HAS_KAFKA` → `cronjobs` → `worker`), infra ring (`platform` → `integrations` — only the providers declared in architecture §3), root `__main__.py`, `migrations/`, health probes (`/healthCheck` / `/readiness` / `/warmup`).

### Ops scaffolds (once)

`docker/Dockerfile.<role>` per shipped role on `CONTAINER_BASE` (per the applicable layout standard), `docker/docker-compose.yml` with the architecture-declared Postgres image tag + only the shared infra the service uses per `HAS_*` flags, `.gitlab-ci.yml` (MR gates + shared-logic version-lock when `HAS_SHARED_LIBRARY` + pre-deploy migration gate), `.pre-commit-config.yaml` (pinned per `ci-cd.md §2.3`), `pyproject.toml` skeleton (with the `SHARED_LIBRARY_NAME` git-tag pin when `HAS_SHARED_LIBRARY`), `Makefile`, `.env.example`.

### Test scaffolds

Empty class shells raising `NotImplementedError`, mirrored under `tests/unit/domain/` (or `tests/unit/modules/` for monolith) + `tests/integration/{api,consumers,cronjobs}/` (consumers only when `HAS_KAFKA`) + `tests/e2e/`. Real bodies from [[implement]] (`backend-tests`).

### Library promotion (inline — no separate drift / refactor phase)

Only applies when `HAS_SHARED_LIBRARY=true`. The sole place library grows in response to real service needs. Decision tree (first match wins):

1. **Standard mandates library** (Jalali when `CALENDAR=jalali` · JWT verify · `DbAction` · `ProjectBaseException` + envelope + OTel + `JsonFormatter` when `HAS_OBSERVABILITY_STACK` · MinIO when `HAS_MINIO` · Kafka bases when `HAS_KAFKA` · Redis wrapper when `HAS_REDIS` · agent base + circuit breaker · ULID · Persian normalization when `LOCALE_MODE=farsi-only OR bilingual` · attribute prefixes · SMS client when `OTP_PROVIDER`) → **MUST** come from `SHARED_LIBRARY_PACKAGE`. If library HEAD lacks the symbol, promote: write module into `<SHARED_LIBRARY_NAME>/src/<SHARED_LIBRARY_PACKAGE>/` in the right dep-order slot, splice-merge into library PRD-TDD §8, note in this service's §17 as `promoted → <SHARED_LIBRARY_PACKAGE>:<module>.<symbol>`.
2. **Cross-service utility, worthy** (used by 2+ services per PRD-TDDs seen, foundational, pure/thin, stable interface, no domain knowledge) → promote (same path as rule 1).
3. **Cross-service usage, not worthy** (carries domain knowledge · service-specific config · likely to diverge) → leave local; §17 note `considered for library, rejected: <reason>`.
4. **One-off service-local logic** → local. Never put service-specific code into library.
5. **Rare: symbol only this service needs but plausible library candidate** → local (rule 4); §17 note for future reconsideration.

**Cross-repo write policy.** Rules 1–2 write into BOTH `<repo>/` AND `<SHARED_LIBRARY_NAME>/`. This is the only sub-op crossing the repo boundary in one run. Every promotion reported as `promoted: <library-path> — used by <this-service>`. Human cuts the library tag on `PROD_ENV_NAME` afterwards.

### Report

Print the file tree grouped by repo (service first, then any `promoted:` library files). List every §17 promotion / rejection note added. No shell commands. Ship service with `/mr open <repo>`; if library touched, also `/mr open <SHARED_LIBRARY_NAME>`.

### Related skills

- [[docs]] (`prd-tdd-backend`) — author the PRD-TDD this sub-op consumes.
- [[implement]] (`backend-tests`) — fill the test shells.
- [[mr]] — ship.

## backend-library

Generate the shared backend library declared in architecture §1.1 as `SHARED_LIBRARY_NAME` — the git-tag pinned package every backend service depends on.

### Argument

`[::<mode>]` — no repo positional (target fixed to `SHARED_LIBRARY_NAME`); `<mode>` is `full` (default) | `gap` | `patch=<module>`.

- `full` — the whole package.
- `gap` — only files that don't exist yet (never touch existing). Use for **new modules** added to library PRD-TDD §8.
- `patch=<module>` — regenerate exactly one existing module (dotted path relative to `src/<SHARED_LIBRARY_PACKAGE>/` — the actual module set is discovered from the library's own PRD-TDD §8, not hard-coded here); every other module and the packaging layer untouched.

Refuse if `HAS_SHARED_LIBRARY=false` in architecture, an explicit repo arg names anything other than `SHARED_LIBRARY_NAME`, `<SHARED_LIBRARY_NAME>/docs/v<N>/PRD-TDD.md` is missing / placeholder / has TBD in its module-catalog or public-API sections, or `patch=<module>` names an undeclared module.

### Hard rules

- Library, not a service: no app, no routes, no `__main__.py`, no per-role Dockerfiles, no DB, no `migrations/`. Import surface `<SHARED_LIBRARY_PACKAGE>.*`; distribution by git tag, **release tags cut on `PROD_ENV_NAME`**; version-lock gate in every consumer (`ci-cd.md §3.2`).
- When `CALENDAR=jalali`: `jalali_lib` is the single implementation site of the Jalali locked decision — `to_jalali` / `to_utc` / `persian_slugify` + the boundary rule; never a Gregorian round-trip.
- When `LOCALE_MODE=farsi-only OR bilingual`: `persian_normalization` — ZWNJ, ی/ي, ک/ك, diacritic fold, digit fold.
- `DbAction` per `infrastructure.md §3.6` — full method table + filter engine + keyset pagination.
- `exception` + `fastapi_exception_handler` — `ProjectBaseException` (`status_code` / `message` / `error_code` required; `extra` log-only) + envelope rendering.
- `security` — `JWT_ALG` **verify-only** (signing lives solely in `AUTH_OWNER`), `check_auth` primitives, `CurrentUser`.
- Adapters conditional on architecture flags: MinIO when `HAS_MINIO` (sole object-storage path), Kafka bases when `HAS_KAFKA`, Redis wrapper when `HAS_REDIS` (cache-only), agent base with circuit breaker + retry (third-party calls only).
- When `OTP_PROVIDER` is set: SMS client for that provider — v<N> home; migrates to `NOTIFICATION_OWNER` when that owner materializes without changing auth's public interface.
- When `HAS_OBSERVABILITY_STACK`: OTel bootstrap + `JsonFormatter` (`x_request_id` / `trace_id` / `service_version`, PII scrubbing); shared validators + ULID helpers + Celery template.
- Ships no pytest fixtures for consumers; semver discipline; the release job opens pin-bump MRs into every consumer.
- Silent-skip when present: `pyproject.toml`, `.pre-commit-config.yaml`, `Makefile`, `.env.example`, `.gitignore`, `.gitlab-ci.yml`. Never generated: `uv.lock`, editor configs.

### Inputs

1. **Step 1 — architecture.** Confirm `HAS_SHARED_LIBRARY=true`; extract `SHARED_LIBRARY_NAME` + `SHARED_LIBRARY_PACKAGE` + every stack pin.
2. `<SHARED_LIBRARY_NAME>/docs/v<N>/PRD-TDD.md` (full).
3. Every standard except `testing.md` — the library implements the contracts they reference.
4. Architecture §7.2 (Shared-logic version lock) + `architecture-decisions.md` if present.
5. Consumer-facing call sites named in sibling backend PRD-TDDs (§7 modules imported, §10 env keys). Never reads sibling `src/`.
6. Current repo state — LAST.

### Writes

- `full` — `src/<SHARED_LIBRARY_PACKAGE>/` in dependency order: `exception` → `logging` / `observability` when `HAS_OBSERVABILITY_STACK` → `jalali_lib` when `CALENDAR=jalali` → `persian_normalization` when `LOCALE_MODE=farsi-only OR bilingual` → validators / ULID → `DbAction` → `security` → adapters (`minio_adapter` if `HAS_MINIO`, `kafka` if `HAS_KAFKA`, `redis` if `HAS_REDIS`) → agent base → `<OTP_PROVIDER>` client if `OTP_PROVIDER` → Celery template if `HAS_KAFKA` → `fastapi_exception_handler`. Then packaging (`pyproject.toml`, `.gitlab-ci.yml` with the release-tag + bump-MR job, `.pre-commit-config.yaml`, `Makefile`), then bare test scaffolds under `tests/unit/<module>/`.
- `gap` — same dependency walk, skip modules already present; packaging silent-skip; test scaffolds added only for newly written modules.
- `patch=<module>` — regenerate exactly `src/<SHARED_LIBRARY_PACKAGE>/<module>/` (or `<module>.py`) against PRD-TDD §8; every other module untouched; packaging untouched; test scaffold updated only for new symbols; version bump on `pyproject.toml` is a human act before the release tag.

### Report

Print the file tree. No shell commands. Ship with `/mr open <SHARED_LIBRARY_NAME>`; the release tag is a human act on `PROD_ENV_NAME`.

### Related skills

- [[docs]] (`prd-tdd-library`) — author the PRD-TDD this sub-op consumes.
- [[implement]] (`backend-tests`) — fill the library's test shells.
- [[mr]] — ship.

## backend-tests

Generate the full test suite for one backend repo.

### Argument

`<repo>[::<mode>]` — `<repo>` is one of the discovered backend repos or `SHARED_LIBRARY_NAME`; `<mode>` is `full` | `gap` | `unit` | `integration` | `e2e` | `entity=<entity>[.<verb>]` | `path=<rel-path>` (write set narrowed, read set unchanged).

Refuse if `<repo>` not in the backend allow-list (BACKEND_REPOS + `SHARED_LIBRARY_NAME` when `HAS_SHARED_LIBRARY`), `src/` missing the canonical shape, PRD-TDD missing, or `pyproject.toml` missing `asyncio_mode = "auto"`.

### Hard rules

- **Anti-hallucination** — list real symbols first; a test referencing a name `grep` cannot find in `src/` is hallucinated.
- `asyncio_mode = "auto"` — no `@pytest.mark.asyncio`.
- `@pytest.mark.unit` / `.integration` / `.e2e` under `--strict-markers`.
- `class TestPerform<Verb>:` per method; one test per raised `error_code`; descriptive names.
- **Assert `status_code` AND `error_code`, never `message`** (error-contract test excepted).
- Assert side effects did NOT happen on failure.
- Unit mocks at the DB-pool layer; never mock your own service layer; integrations mocked at the agent boundary.
- Integration = real Postgres via Testcontainers on the architecture-declared image tag + `alembic upgrade head`; Kafka consumers (when `HAS_KAFKA`) via Testcontainers broker with mirror-idempotency proof (when `HAS_MIRROR_TABLES`).
- Reject any migration test importing SQLAlchemy or using `op.create_table()`.
- Route tests: full envelope + `401` + `404` ownership-miss (never 403) + `403` RBAC map-miss.
- When `CALENDAR=jalali`: Jalali round-trip on human-observed dates. When the service under test owns block-tree content: unknown-type / autosave-concurrency cases.
- Parametrized filter / sort / keyset tests over `constants/` allow-lists.
- Env vars before any `src` import; fixtures local per repo (the library ships none).
- Coverage: `≥ BE_COVERAGE_FLOOR` overall (from architecture §3), data models `≥ min(BE_COVERAGE_FLOOR - 5, 90)`, ratcheting up.
- Banned: opaque-blob snapshots, log-string primary outcomes, `test_everything`, `time.sleep`, conditional logic in tests, vague names.

### Inputs

1. **Step 1 — architecture.** Extract `TEST_RUNNER`, `BE_COVERAGE_FLOOR`, Postgres image tag, `HAS_KAFKA`, `HAS_MIRROR_TABLES`, `CALENDAR`.
2. `testing.md` FIRST, in full.
3. PRD-TDD (§3 / §6 / §7 / §8 / §9 / §10 / §11 / §13 / §14 — each acceptance bullet maps to a happy-path test).
4. Repo onboarding file (when it lands).
5. Sliced standards (`coding.md`, applicable layout standard, `api-and-data-contracts.md`, `errors-and-observability.md`, `security-and-auth.md`, `infrastructure.md` §3.6.1).
6. Full `<repo>/src/` — anti-hallucination.
7. `<repo>/tests/conftest.py` at every tier.
8. Existing `<repo>/tests/` LAST.

### Required cases per `perform_<verb>`

Happy path, Not found (404), Invalid input (400 / 422), Conflict (409 — slug / workflow / autosave), Ownership miss (404), Dependency error (502 / 504), PATCH semantics (`exclude_unset`).

### Report

Print the file list. No shell commands. Ship with `/mr open <repo>`.

### Related skills

- [[docs]] (`prd-tdd-backend`, `prd-tdd-library`).
- [[implement]] (`backend-service`, `backend-library`).
- [[mr]] — ship.

## frontend-bootstrap

One-shot skeleton for a frontend repo — toolchain, build config, Tailwind bound to the design-system tokens, locale-appropriate shell, self-hosted fonts, formatters, block-renderer / block-editor primitives (when the project ships block content), admin auth shell, envelope-aware API client, openapi-typescript pipeline, Vitest + MSW + Playwright.

**No feature pages.**

### Argument

`<repo>` — one of the `FRONTEND_REPOS` discovered in architecture §1.2. No mode flag.

Refuse if `<repo>` not in `FRONTEND_REPOS`, PRD-TDD missing / empty (it pins framework-specific decisions like TipTap-vs-Lexical when a block editor is used), or `src/features/` already has sub-folders.

### Hard rules

- Static output only per architecture §4. No SSR unless the repo's `stack` cell in §1.2 explicitly names it; no Node at the edge; landing content GETs are build-time only (rebuild-on-publish) when the framework is SSG.
- Fonts self-hosted per architecture §4.1. When `LOCALE_MODE=farsi-only OR bilingual`, fetch Vazirmatn + JetBrains Mono woff2 from the upstream OFL repos and commit them; otherwise whatever the architecture declares. Never a runtime font CDN.
- Locale shell per `LOCALE_MODE`. `farsi-only`: `<html lang="fa" dir="rtl">`, logical properties only, no i18n runtime, no locale routing, no locale toggle. `bilingual`: `/fa/` + `/en/` path-prefixed at build time, `<html lang dir>` set per prefix. `latin-only`: `<html lang="en" dir="ltr">`.
- Digits + calendar per `DIGIT_RULES` + `CALENDAR`. When `DIGIT_RULES=persian-human-ascii-machine`: `Intl.NumberFormat('fa-IR')` on human surfaces, ASCII on machine feeds — never auto-convert. When `CALENDAR=jalali`: `date-fns-jalali` for human surfaces, `Intl.DateTimeFormat` for machine feeds only. Centralized in `@shared/format/` / `@lib/format/` — never inline in features.
- Third-party runtime origins only when the architecture / frontend PRD-TDD §11 CSP allow-list names them. Icons bundled.
- Server is truth; admin permissions re-fetched per section via `/<{{OWNER_TERM}}>/me/permissions`.
- Admin auth via HTTP-only `Secure SameSite=Lax` cookie + single-flight silent-refresh mutex; JWT never in JS-readable storage. Only theme choice + editor draft slice persist.
- Block subsystem parity only when a `CONTENT_OWNER` service ships block trees (declared in its PRD-TDD) — bootstrap seeds editor + renderer sides with the declared v<N> block set (`frontend.md §1.4`).
- **No `Dockerfile` / `.dockerignore` / `docker/` in frontend repos** — static bundles served by `infra-nginx`.
- Silent-skip when present: `package.json`, `tsconfig.json`, `pnpm-lock.yaml`, `.gitignore`, `.gitlab-ci.yml`, `.env.example`, `eslint.config.js`, `.prettierrc.json`, `.editorconfig`, `.husky/`.
- Never generated: `pnpm-lock.yaml`, editor configs.

### Inputs

1. **Step 1 — architecture.** Extract `LOCALE_MODE`, `CALENDAR`, `DIGIT_RULES`, `FE_COVERAGE_FLOOR`, `CONTENT_OWNER` (drives block-tree seeding), `FRONTEND_REPOS` (this row's `stack` cell drives framework choice).
2. PRD-TDD — full end-to-end, every section.
3. Repo onboarding file (when it lands).
4. Frontend-relevant standards (`frontend-layout.md` authoritative; skip `microservice-layout.md`, `monolith-layout.md`, `infrastructure.md`, `testing.md`).
5. Architecture §1.2 / §4 / §6.
6. Design system — `product/docs/uiux/v<N>/design-system/design-system.md` FULL end-to-end (every theme selector + tokens + colour + typography + spacing + motion + elevation + breakpoints + components + locale/RTL sections — no section skipping).
7. Brand — `business/docs/brand/` when present.
8. Sibling frontend PRD-TDD — surgical read of shared-contract sections (envelope, theme key, CSP baseline, block-tree fixture, shared components). Never read sibling mockups.
9. Feature catalog — full end-to-end `product/docs/features/v<N>/all-features.md`; tag owned / consumed-from-sibling / out-of-scope; `[ ]` → deferred.
10. Consumed backend PRD-TDDs §9 — codegen scope (per this repo's PRD-TDD).
11. Current repo state LAST.

### Writes

- **Shared:** `package.json`, `tsconfig.json`, `eslint.config.js` (boundaries rules per `ci-cd.md §8.1`), `.prettierrc.json`, `.editorconfig`, `.husky/`, `commitlint.config.mjs`, `postcss.config.js`, `tailwind.config.ts` (every design-system token exposed), `src/styles/{tokens,global,fonts}.css` (per-theme blocks from the design system), `public/fonts/*.woff2` (fetched from upstream repos and committed), logo + favicon from `business/docs/brand/`, `.gitignore`, `.gitlab-ci.yml` (per `ci-cd.md §8` incl. `codegen:drift`, `codegen:drift:scheduled`, guarded `visual`), `.env.example` (`PUBLIC_*` / `VITE_*` base URLs only), Vitest config + setup (MSW `onUnhandledRequest: "error"`), `playwright.config.ts` (locale + timezone per architecture; `chromium` + `visual-desktop` + `visual-mobile`), `tests/e2e/.gitkeep`, MSW under `src/mocks/`, `scripts/codegen.ts`.
- **Landing-side (when the repo is the SSG landing):** framework-appropriate config (e.g. `astro.config.mjs` with `output: 'static'`), route shells per the repo's PRD-TDD, base layout with SEO emitters + regional trust seal slots, theme bootstrap, `src/lib/api/*`, `src/lib/errors/catalog.ts`, formatter module (`jalali` + `persian-digits` + `iso-8601` when `CALENDAR=jalali` + `DIGIT_RULES=persian-human-ascii-machine`; otherwise the equivalent per architecture), block-renderer (only when `CONTENT_OWNER` ships block trees), SEO module, `src/lib/theme/tokens.ts`, `src/copy/index.ts`, `src/features/.gitkeep`.
- **Dashboard-side (when the repo is the SPA admin):** `vite.config.ts` (aliases `@` / `@shared` / `@features`), `index.html` with the default theme selector, `src/main.tsx`, `src/App.tsx`, `src/router/{index,guards,PendingRoute,RootErrorFallback}.tsx` (guard chain `cookieExists? → silentRefreshOn401Once → me() → permissions()`), `src/shared/api/{client,envelope,generated/}`, `src/shared/app-shell/*` (registry-driven Sidenav on the edge dictated by `LOCALE_MODE`), `src/shared/auth/*` (cookie + mutex), `src/shared/block-editor/*` + `src/shared/block-renderer/*` (only when `CONTENT_OWNER` ships block trees — TipTap-or-Lexical wrapper per PRD-TDD pin + `serialization.ts` + blocks + slash menu), `src/shared/copy/index.ts`, `src/shared/errors/catalog.ts`, formatter module (per architecture flags), `src/shared/theme/*` (per-theme provider), `src/features/.gitkeep`.

### Report

Print the file tree. No shell commands. Ship with `/mr open <repo>`.

### Related skills

- [[docs]] (`prd-tdd-frontend`) — author the PRD-TDD this sub-op consumes.
- [[implement]] (`frontend-page`) — write the feature folders.
- [[implement]] (`frontend-tests`) — fill the tests.
- [[mr]] — ship.

## frontend-page

Generate one feature folder under `<repo>/src/features/[<sub-bucket>/]<page-slug>/`. `<area>` picks the mockup source; the target path drops the top-level `<area>` when it matches the repo's own frontend shape.

### Argument

`<repo>::<area>::<page>` — all three required.

- `<repo>` — one of the discovered `FRONTEND_REPOS`.
- `<area>` — **dynamically resolved** against `product/docs/uiux/v<N>/`: any existing folder name directly under that path. No hard-coded allow-list; whatever `uiux scaffold` has produced is a valid `<area>`. Kebab-case (mirrors folder name on disk).
- `<page>` — the HTML mockup file inside `product/docs/uiux/v<N>/<area>/`. Accepted with or without the `.html` extension — `index` and `index.html` both resolve to `product/docs/uiux/v<N>/<area>/index.html`.
- `<page-slug>` — derived, not passed: `<page>` with any trailing `.html` stripped.

Target-path mapping — the repo already scopes its own frontend, so a top-level `<area>` matching the repo shape is **elided**; inner mockup sub-folders survive as feature buckets. `<page-slug>` is always the mockup filename minus `.html`.

| Mockup source | Target feature folder |
|---|---|
| `product/docs/uiux/v<N>/<repo-shape>/<page>.html` (e.g. `admin/`, `landing/` — matches the repo's own shape) | `<repo>/src/features/<page-slug>/` |
| `product/docs/uiux/v<N>/<repo-shape>/<sub>/<page>.html` | `<repo>/src/features/<sub>/<page-slug>/` |
| `product/docs/uiux/v<N>/<other-area>/<page>.html` (any repo) | `<repo>/src/features/<other-area>/<page-slug>/` |

Refuse if:

- `<repo>` is not in `FRONTEND_REPOS`.
- `product/docs/uiux/v<N>/<area>/` does not exist as a directory (author the mockup area first with `/uiux scaffold <area>`).
- The resolved mockup file does not exist as a file.
- `<repo>/src/features/` does not exist (run `/implement frontend-bootstrap <repo>` first).
- The target feature is not `[x]` in `product/docs/features/v<N>/all-features.md`.

### Hard rules

- **Visual fidelity — token binding, not approximation** per `frontend-layout.md §11`. No generic palette classes, no inline styles, no hand-rolled colors; arbitrary-value Tailwind binds to `tokens.css` custom properties.
- **Design from mockup, logic from you — explicit split.** Everything visible on screen AND every enumerated data structure the mockup exposes is CONTRACT sourced verbatim from the mockup: nav groups + entry order + labels + icons + count badges + status pill states + block-type slash menu + error-catalog copy + role-visibility rules. **Do NOT invent groupings, drop entries, rename labels, re-order entries, or substitute icons "because they fit better".** Application LOGIC — state store shape, query keys, mutation invalidation, effect dependency arrays, focus trap, silent-refresh mutex, event handlers, memoisation, custom hooks — is YOURS to author from PRD-TDD + standards; the mockup is static HTML and cannot express it. **Contract ≠ demo data** — badge counts / activity-feed titles / thumbnails / sample audit rows in the mockup are demo copy, NOT contract. Never hard-code them. Import the STRUCTURE, not the CONTENT.
- **Mockup CSS is the visual grammar — read it end-to-end BEFORE composing any component.** HTML gives structure; the CSS gives every actual value (padding, `font-size`, `letter-spacing`, hover / state colors). Bind against the mockup's own `@media` queries and every declared theme variant.
- **Design system trumps mockup on visual-quality slips — narrow exception.** STRUCTURAL contract (groupings, labels, icons, order, `data-*`, block-type registry, responsive breakpoints) still binds unconditionally — never drop, rename, substitute, or reorder. When the mockup carries a **provable design-system violation** — an off-token button height, a sub-threshold contrast pairing, an ungoverned hex outside the design-system palette, an off-baseline spacing, a mis-scaled elevation, an inline `oklch()` outside `tokens.css` — bind to the design-system-correct value even at the cost of pixel-match at that spot. Stylistic taste is NOT a trigger. Every deviation is announced in the report's `UI/UX deviations` line — silent deviation is a merge-block.
- **Mockup `data-*` attributes are contract, not decoration.** Enumerate every `data-*` before generation — each maps to a prop / handler in the composed code, or is called out as intentionally dropped.
- **Chrome audit BEFORE feature work (dashboard-side).** Read `src/shared/app-shell/*` + `src/shared/theme/*` + every shell-ring data registry (`nav.ts`, `errors/catalog.ts`, block-editor blocks, MSW handlers) in full. Classify EACH file — code AND data — as `stub` or `designed`. Bootstrap-stub chrome plus a designed-shell mockup ⇒ REWRITE the chrome in the same MR with the same token binding; announce the classification. Stub files are scaffold — not sheltered by "never overwrite human-authored files".
- **MSW handlers default to empty payloads** — zeros / empty arrays / `null` optionals, never fake fixture rows; empty payloads exercise the four-state UX. Demo seeds only on explicit request, in a follow-up MR.
- When `LOCALE_MODE=farsi-only OR bilingual`: **Persian letter-spacing quarantine** — Latin micro-label tracking ≥ 0.1em MUST be overridden to `normal` (or ≤ 0.05em) on Farsi copy.
- **Mobile-first + responsive — non-negotiable.** Explicit breakpoint variants on every composite, thresholds mirrored from the mockup's `@media` queries. Landing header → real hamburger drawer (overlay + backdrop + `Esc` / click-outside / link-click close + focus trap). Dashboard: Sidenav → edge-side drawer per `LOCALE_MODE` over a scrim; data tables cardify into `label:value` stacks via inline `data-label` on every `<td>` (never omit); tile grids 4 → 2 → 1; page-head stacks; editorial calendar → agenda fallback. "One layout only" is a merge-block. **Containing-block trap:** `backdrop-filter` / `filter` / `transform` / `will-change` / `perspective` on an ancestor re-scopes `position: fixed` — render drawers as siblings of the chrome, never children.
- **Locale-appropriate copy through `copy.ts`** — no user-facing strings inline in JSX / `.astro`. When `DIGIT_RULES=persian-human-ascii-machine`: Persian digits via the shared formatter on human surfaces, ASCII on machine feeds; never auto-convert.
- **Dates through the shared formatter** — no inline `Intl.DateTimeFormat` in features; `<time datetime>` always ISO-8601.
- Server is truth. Envelope-aware — branch on `error_code`, never `message`.
- Auth-aware (dashboard-side): 401 → silent-refresh once → retry; second 401 → login with `next=`; 404-not-403.
- Theme parity — same DOM, only theme variables differ; every declared theme variant is the target.
- **Block-renderer parity** — a new block type ships the dashboard editor block + both renderers + the `CONTENT_OWNER` schema change; a missing side breaks the contract-drift check.
- Types from generated openapi only.
- Never overwrite human-authored files (`Will replace:` + ask).

### Inputs

1. **Step 1 — architecture.** Extract `LOCALE_MODE`, `CALENDAR`, `DIGIT_RULES`, `CONTENT_OWNER`, `FRONTEND_REPOS`, `AUTH_OWNER`.
2. PRD-TDD — full end-to-end, every section (no section-picking; feature contracts cross-reference across many sections).
3. `frontend-layout.md` §5 + §6 + §11 + §12.
4. `frontend.md`, `coding.md` §F0–§F9, `api-and-data-contracts.md`, `security-and-auth.md`, `errors-and-observability.md`.
5. **Design system — full end-to-end** — `product/docs/uiux/v<N>/design-system/design-system.md` every section.
6. **Mockup HTML + CSS end-to-end** — `product/docs/uiux/v<N>/<area>/<page>` (and any co-located CSS / JS the file references), every theme variant, every `@media` query. Mockups drawn at desktop width — visual target, not the responsive contract. Enumerate every `data-*` attribute.
7. **Companion area spec** — `product/docs/uiux/v<N>/<area>/<PROJECT_SLUG>-<area>.md` when the file exists. §1 sitemap enumerates every route; §4.N sub-section rules define block-level intent; §5 deferred-scope ledger names what MUST NOT be reached for; §6 changelog explains divergence from earlier iterations. Not optional when the file exists.
8. Existing chrome (dashboard-side) — classify `stub` vs `designed`.
9. Feature catalog — full end-to-end read; verify feature is `[x]` (refuse on `[ ]`); adjacent rows constrain the same UI shell; `[ ]` rows define what the current feature MUST NOT reach for.
10. Consumed backend PRD-TDDs §9 + §11 for every endpoint this feature calls.
11. Current state LAST.

### Writes

Under the target feature folder (per the mapping table above): entry component (framework-appropriate — `.tsx` for React SPAs, `.astro` + islands `.tsx` for Astro islands, whatever the repo's `stack` cell declares), `<page-slug>.route.tsx` appended to the router table when the framework uses one, `queries.ts` / `mutations.ts` (TanStack Query on repos that pin it), `forms.schema.ts` (Zod, only when the surface has a form), `types.ts` (re-exports from generated openapi), `copy.ts` (locale strings), `errors.ts` (feature-local `error_code` → locale copy), `__tests__/` (`it.todo` scaffolds). Plus a `src/pages/<...>.astro` composition when a landing feature backs a route, MSW handler additions (empty payloads) wired into the handler index, and rewritten chrome under `src/shared/app-shell/*` when the audit classifies it stub.

### Report

Print, in order:

1. **File list** — every file written or rewritten.
2. **Hook-in touchpoints** — one line per (router append, MSW handler append).
3. **Chrome audit classification** (dashboard-side) — one line, code files first then registries: `Chrome audit: AppShell=<stub|designed> · Topbar=<…> · Sidenav=<…> · ThemeProvider=<…> · nav.ts=<…> · errors/catalog.ts=<…> · mocks/handlers/*=<…>`, with `→ rewritten` appended to every file rewritten in this run.
4. **`data-*` contract map** — one line per mockup `data-*` attribute enumerated in Inputs #6, either mapped to a code touchpoint or explicitly deferred with a reason.
5. **Responsive-contract statement** — one line per breakpoint listing the composites that reflow, thresholds mirroring the mockup's `@media` queries.
6. **UI/UX deviations** — one line per design-system-driven deviation from the mockup: `<component> · mockup: <offending value> · design-system rule: <cited token / §> · bound: <corrected value>`. If none, print `UI/UX deviations: none`. STRUCTURAL divergences are forbidden — not deviations, not reported here.

No shell commands.

### Related skills

- [[implement]] (`frontend-tests`) — fill the tests.
- [[mr]] — ship.

## frontend-tests

Generate the full Vitest + RTL suite for every feature folder under `<repo>/src/features/`. Fills the `it.todo` scaffolds from `frontend-page`.

### Argument

`<repo>[::<mode>]` — `<repo>` is one of the discovered `FRONTEND_REPOS`; `<mode>` is `full` | `gap` | `feature=<area>[/<page-slug>]` | `path=<rel-path>`.

Refuse if `<repo>` not in `FRONTEND_REPOS`, `src/features/` empty, feature entry component missing, MSW infrastructure missing, or Vitest config missing `globals: false` + `environment: "jsdom"`.

### Hard rules

- Query priority role → label → text. `data-testid` last resort with justification.
- `findBy*` async / `getBy*` sync / `queryBy*` absence. Never `await waitFor(...)`.
- `userEvent` v14 async only, no `fireEvent`.
- No class-assertion, no inline-style assertion.
- MSW `onUnhandledRequest: "error"`. Never stub `useQuery` / `useMutation`.
- Fresh `QueryClient` per test.
- Production locale + direction per architecture `LOCALE_MODE` (`dir="rtl"` + Farsi copy when `farsi-only`; per-locale when `bilingual`; `dir="ltr"` + English when `latin-only`).
- When `DIGIT_RULES=persian-human-ascii-machine`: digit + Jalali assertions via the shared formatters' rendered output — never hard-coded glyph literals.
- Locale copy asserted through the `copy` object.
- Every Zod branch tested. Every backend `error_code` in `errors.ts` tested.
- `jest-axe` `axe(container)` per rendered page.
- Four-state coverage on admin surfaces (loading / empty / error with `X-Request-ID` reference / success).
- Admin auth flows (silent-refresh success / refresh-fail → login redirect / 404-ownership).
- **Block-renderer snapshot tests** against the canonical fixture library from `CONTENT_OWNER` (when the project uses block trees) — both repos test the same set; dashboard-side adds the lossless editor serialization round-trip.
- No real network. Co-located `__tests__/` only (E2E + visual baselines are hand-authored).

### Inputs

1. **Step 1 — architecture.** Extract `LOCALE_MODE`, `DIGIT_RULES`, `CALENDAR`, `CONTENT_OWNER`, `FE_COVERAGE_FLOOR`.
2. `testing.md §3` FIRST.
3. `frontend-layout.md` §5 + §6 + §8.
4. `frontend.md` §2.
5. `coding.md` §F0–§F9 (banned names in tests too).
6. PRD-TDD (features + auth + error mapping + route map).
7. Feature catalog + UI/UX mockup — labels drive `getByRole({name})`.
8. Actual feature folder — anti-hallucination.
9. Existing `__tests__/` LAST.

### Writes

- MSW handler additions in `src/mocks/handlers/<{{OWNER_TERM}}>.ts`.
- Vitest + RTL bodies in `__tests__/<Component>.test.tsx`.
- Block-renderer snapshot tests against the canonical fixtures (when applicable).

### Report

Print the file list. No shell commands.

### Related skills

- [[docs]] (`prd-tdd-frontend`).
- [[implement]] (`frontend-page`).
- [[mr]] — ship.

## infra-scaffold

Generate the v<N> config + Docker Compose + init scripts + operational assets for one of the discovered `INFRA_REPOS` from its PRD-TDD + `infrastructure.md` + the consuming services' contracts.

### Argument

`<repo>` — one of the discovered `INFRA_REPOS` (component chosen by repo name: `infra-postgresql` / `infra-redis` / `infra-minio` / `infra-meilisearch` / `infra-kafka` / `infra-nginx` / `infra-observability`, or the corresponding `devops-*` alias when the project uses that prefix). No mode flag.

Refuse if:

- `<repo>` not in `INFRA_REPOS`,
- `<repo>` is a backend or frontend repo (use the appropriate sub-op),
- target PRD-TDD missing / placeholder (author via `/docs prd-tdd-infra <repo>::overwrite`) or carrying unresolved TBD in its role / topology / access-control / bootstrap / ops sections,
- the consumed contract for the layer is not addressable (postgres → per-{{OWNER_TERM}} DB + role list; kafka → topic catalog; minio → bucket catalog; meilisearch → `SEARCH_OWNER` PRD-TDD; nginx → backend §9 prefixes AND every frontend PRD-TDD's routing sections; observability → the probe contract in `errors-and-observability.md` §13).

### Hard rules

- Read the PRD-TDD + consuming contracts first. Bind: role → invariants in config comments; topology → resource limits; access control → roles / keys / policies / rate limits; bootstrap → init scripts; ops → backup / rotation / replay runbooks.
- `infrastructure.md` authoritative: §2 naming, §3.2 per-{{OWNER_TERM}} DB-role isolation, §4 Redis cache-only (when `HAS_REDIS`), §5 one-sender-enumerated-receivers topics + DLQ per source (when `HAS_KAFKA`), §6 per-{{OWNER_TERM}} MinIO keys (when `HAS_MINIO`), §7 Meilisearch owned by `SEARCH_OWNER` (when `HAS_MEILISEARCH`).
- Cross-repo contract is **quoted, not restated** — database / topic / bucket / index / path / env-var names grep-verified against the owning repo; zero hits ⇒ hallucinated ⇒ rewrite.
- **No secrets, ever.** No passwords, TLS material, master keys, access keys, `GITLAB_PAT`, credentialed DSNs, or `.htpasswd` content; `.env.example` carries names only. develop / staging basic-auth credentials live out-of-band on the host.
- **No application code in infra repos.** `initdb/` holds bootstrap `CREATE ROLE` / `CREATE DATABASE` / `REVOKE` / `GRANT` only — never module tables; Alembic lives in each backend service.
- **`X-Request-ID` is generated at the nginx edge** (`$request_id`), forwarded upstream, echoed on responses, logged — never generated by frontend or backend.
- Envelope pass-through — nginx never rewrites `{success, message, data}`; static fallback only for `502` / `504`.
- Hosting posture per architecture §8 (in-country VM when the architecture declares it; `CDN_PROVIDER` in front of nginx when set — restore real client IP; Let's Encrypt at nginx). No origins outside the project's own servers unless the architecture allow-lists them.
- develop / staging gated by nginx HTTP Basic (`auth_basic "<PROJECT_SLUG>-<env>"` on every server block per architecture §5.7); `PROD_ENV_NAME` carries none.
- Idempotent bootstrap: `mc mb --ignore-existing`; topic creation skips existing; `initdb/*.sql` runs on empty volumes only.
- Silent-skip when present: `docker/docker-compose.yml`, `docker/Dockerfile`, `.gitlab-ci.yml`, `Makefile`, `.env.example`, `.gitignore`, `.dockerignore`, `nginx.conf`, `postgresql.conf`, `pg_hba.conf`, `redis.conf`, `meilisearch.yaml`, `kafka.properties`, anything under `docker/conf.d/`, `docker/initdb/`, `docker/policies/`, `provisioning/`, `scripts/`.
- Never generated: TLS certs / keys, `letsencrypt/live/`, `.htpasswd`, data volumes, master / access keys, editor configs, GitLab CI/CD variable definitions.
- No `Co-Authored-By:`; no derived onboarding / readme file references in generated config or scripts.

### Inputs

1. **Step 1 — architecture.** Extract `INFRA_REPOS`, `PROJECT_SLUG`, `PROD_ENV_NAME`, `CDN_PROVIDER`, every `HAS_*` flag, image tags from §3 / §5.
2. Target `<repo>/docs/v<N>/PRD-TDD.md` (full).
3. Sibling infra PRD-TDDs the contract touches (Postgres ↔ MinIO WAL / backups; nginx ↔ everything; observability ↔ every layer; Kafka DLQs ↔ the content admin surface when `CONTENT_OWNER` declares one).
4. Consuming backend PRD-TDDs (§6 / §8 for postgres; §7 for kafka; bucket catalogs for minio; §9 for nginx; Redis key families; `SEARCH_OWNER` for meilisearch).
5. Every frontend PRD-TDD's routing sections (nginx only — refuse if missing).
6. Standards — primary `infrastructure.md`, `security-and-auth.md` §8, `errors-and-observability.md` §11–§13, `ci-cd.md`; secondary applicable layout standard, `git.md`, `documentation.md`; skip the rest.
7. Architecture §5 + §8 (single-VM Compose topology, backup path, hosting posture).
8. Feature catalog — full end-to-end `product/docs/features/v<N>/all-features.md`; tag both `[x]` (scope) and `[ ]` (surfaces scaffold as commented blocks with `# gated on feature <slug>`, never omitted).
9. Current repo state LAST.

### Writes — shared

`docker/docker-compose.yml` (external `<PROJECT_SLUG>-network`, cross-layer `depends_on`), `.gitlab-ci.yml` (config lint, image build, deploy-on-`PROD_ENV_NAME`, secret scan), `.env.example` (names quoted from the consuming contracts), `Makefile` (`up` / `down` / `logs` / `lint` / `check` + the layer verb), `.gitignore`, `.dockerignore` (if an image is built), `docs/v<N>/OPS-RUNBOOK.md` scaffold.

### Writes — per repo

- **`infra-postgresql`** — `docker/Dockerfile` (architecture-declared Postgres tag); `postgresql.conf` (`wal_level = replica`, `archive_mode = on`, `archive_command` when `HAS_MINIO`, timeouts); `pg_hba.conf` (explicit per-{{OWNER_TERM}} `database ↔ user` rules + final `reject`; `scram-sha-256` only); `initdb/` per-{{OWNER_TERM}} role + database + `REVOKE CONNECT … FROM PUBLIC` (one file per row in architecture §1.1 that owns a database, plus commented rows for reserved-slot owners); `scripts/{backup,wal-archive,restore}.sh` (`pg_basebackup` + WAL → MinIO when `HAS_MINIO`; nightly cold-VM rsync; PITR); backup runbook.
- **`infra-redis`** — cache-only `redis.conf` (maxmemory + eviction per PRD-TDD); per-{{OWNER_TERM}} key-namespace catalog quoted as comments (incl. `CONTENT_OWNER`'s redirect / slug-history read cache when architecture §7.1 declares it); smoke-check script.
- **`infra-minio`** — pinned compose; `scripts/init-buckets.sh` (idempotent `mc mb` for the bucket catalog quoted from the owning PRD-TDDs); `scripts/{create-service-keys,rotate-keys,lifecycle}.sh` — per-{{OWNER_TERM}} scoped keys, no keys committed.
- **`infra-meilisearch`** — pinned config; `scripts/rotate-master-key.sh` + rotation runbook; index-ownership note (`search_*` indexes created by `SEARCH_OWNER`, never infra); snapshot schedule.
- **`infra-kafka`** — single-cluster `kafka.properties` + compose; `scripts/create-topics.sh` quoting the canonical catalog (every topic + `-dlq`; mirror topics partitioned by `record_id` when `HAS_MIRROR_TABLES`); retention per topic family; DLQ replay runbook.
- **`infra-nginx`** — `nginx.conf` (`client_max_body_size` matching the assets-owner upload limit when `HAS_MINIO`); `conf.d/upstreams.conf`; `conf.d/<PROJECT_SLUG>.conf` (server blocks for every domain declared in architecture §1); `conf.d/rate-limits.conf`; `conf.d/security-headers.conf` (quoted from `security-and-auth.md §8`, CSP allow-listing self + `CDN_PROVIDER` edges + every runtime origin the frontend PRD-TDD §11 declares); `conf.d/tls.conf` (Let's Encrypt, TLSv1.2 / 1.3); `conf.d/basic-auth.conf` (develop / staging snippet, file never committed); `X-Request-ID` generation + forwarding + echo; when `CDN_PROVIDER` set: origin notes + purge-adapter reference (`CdnAdapter` in `ASSETS_OWNER` is the sole purge path); `scripts/{reload,renew-certs}.sh`.
- **`infra-observability`** — when `HAS_OBSERVABILITY_STACK`: full-stack compose per architecture §5.1 components table; `provisioning/` datasources + starter dashboards (errors by `service` × `service_version` × `error_code`), Loki rules for the project's `error_code` families, Prometheus scrape + alert rules, Alertmanager routes per architecture, Promtail stdout pipeline, OTel Collector as the sole telemetry ingestion point, blackbox probes (`/healthCheck`, TLS expiry), scheduled `/warmup` warmer. No public status page in v<N> unless architecture §9 doesn't defer it.

### Report

Print the file tree. No shell commands. Ship with `/mr open <repo>`.

### Related skills

- [[docs]] (`prd-tdd-infra`) — author the PRD-TDD this sub-op consumes.
- [[implement]] (`backend-service`) — the consumers whose contracts drive the infra shapes.
- [[mr]] — ship.

## What this skill will NOT do (any sub-op)

- Stage, commit, push, open an MR — that's [[mr]] (`open` / `ship`).
- Run migrations (`alembic upgrade head`), run tests (`pytest`, `vitest`, `playwright`), install dependencies (`uv sync`, `pnpm install`), cut release tags, create topics / buckets / indexes, apply Compose, issue TLS certs, rotate keys, or make network calls (single exception: `frontend-bootstrap` fetching the font binaries it commits).
- Overwrite the silent-skip file list per sub-op.
- Overwrite human-authored files. Scaffold files (`NotImplementedError`, `it.todo`, bootstrap-stub chrome) are considered scaffold, not authored — filling or rewriting them is allowed.
- Reference derived onboarding / readme markdown files from generated code (the per-project `write-edit-guard.sh` hook would block it).
- Add a currency-shaped column (per the money-column rule) when `PSP_PROVIDER` is empty in architecture. Any additional per-project blocklist (e.g. HTML body columns, machine-feed digit rules) is enforced by the per-project write-edit-guard hooks, not by this skill.
- Bootstrap a `Dockerfile` in frontend repos (static bundles served by `infra-nginx`).
- Commit any secret material (TLS keys, passwords, tokens, master keys, access keys, `.htpasswd`) into any repo.

## Related skills

- [[docs]] (`prd-tdd-backend`, `prd-tdd-library`, `prd-tdd-infra`, `prd-tdd-frontend`) — author the PRD-TDDs this skill consumes.
- [[mr]] — ship every diff.
- [[workspace]] — sync / clean before + after.
