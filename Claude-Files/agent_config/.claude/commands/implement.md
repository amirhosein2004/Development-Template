---
description: implement — backend-service|backend-library|backend-tests|frontend-bootstrap|frontend-page|frontend-tests|infra-scaffold. Routed implementation skill for the backend, library, frontend, and infra repos. Reads stack, locale, calendar, and providers from tech/docs/project-architecture/v<N>.md; nothing about the target stack lives in the skill body. Writes files only — no stage/commit/push/MR/migration/tests-run/install.
argument-hint: <backend-service|backend-library|backend-tests|frontend-bootstrap|frontend-page|frontend-tests|infra-scaffold> [<repo>][::<mode-or-area-or-page|patch=<module>>]
---

# implement — routed implementation

Routed command covering implementation across every engineering repo declared in the workspace's `tech/docs/project-architecture/v<N>.md`. The full body — inputs, generation order, ops scaffolds, test scaffolds, per-repo writes, library-promotion decision tree, hard rules — lives in the skill twin at `skills/implement/SKILL.md`. This file names the sub-ops, their argument shapes, and their refusal conditions; the skill executes them.

**Reads stack from architecture — no target stack lives here.** Every sub-op begins by reading the workspace's architecture doc (`tech/docs/project-architecture/v<N>.md` or `tech/docs/v<N>/project-architecture.md`) and extracting into working memory every stack pin the skill needs at generation time: `ARCH_SHAPE` and `OWNER_TERM`; the §3 backend pins (`PYTHON_VERSION`, `WEB_FRAMEWORK`, `DB_DRIVER`, `MIGRATIONS_TOOL`, `JWT_LIBRARY`, `JWT_ALG`, `CONTAINER_BASE`, `LINTER`, `TYPE_CHECKER`, `TEST_RUNNER`, `BE_COVERAGE_FLOOR`, per-component image tags); the infrastructure flags (`HAS_KAFKA` / `HAS_REDIS` / `HAS_MINIO` / `HAS_MEILISEARCH` / `HAS_SHARED_LIBRARY` / `HAS_OBSERVABILITY_STACK` / `HAS_MIRROR_TABLES` / `HAS_CONTENT_BUCKET` / `HAS_WEBSOCKET` / per-flow flags); frontend behavior (`LOCALE_MODE`, `CALENDAR`, `DIGIT_RULES`, `FE_COVERAGE_FLOOR`); providers (`OTP_PROVIDER`, `CDN_PROVIDER`, `CAPTCHA_PROVIDER`, `PSP_PROVIDER` — empty ⇒ adapter not scaffolded); ownership roles (`AUTH_OWNER`, `CONTENT_OWNER`, `SEARCH_OWNER`, `ASSETS_OWNER`, `AUDIT_OWNER`, `ENGAGEMENT_OWNER`, `ANALYTICS_OWNER`, `NOTIFICATION_OWNER`); the shared library pins (`SHARED_LIBRARY_NAME` + `SHARED_LIBRARY_PACKAGE` when `HAS_SHARED_LIBRARY`); the repo lists (`BACKEND_REPOS`, `FRONTEND_REPOS`, `INFRA_REPOS`); deployment posture (`PROD_ENV_NAME`, `PROJECT_SLUG`, `DEFAULT_BRANCH`, `DEV_BRANCH_CHAIN`). If the architecture doc is missing or unparseable, stop and ask — never guess. The applicable layout standard is then read per `ARCH_SHAPE` (`microservice-layout.md` for microservices, `monolith-layout.md` for monolith, both for hybrid); every other standard applies to every shape.

## Synopsis

```
/implement backend-service     <repo>[::full|gap|section=<n>]
/implement backend-library     [::full|gap|patch=<module>]
/implement backend-tests       <repo>[::full|gap|unit|integration|e2e|entity=<entity>[.<verb>]|path=<rel-path>]
/implement frontend-bootstrap  <repo>
/implement frontend-page       <repo>::<area>::<page>
/implement frontend-tests      <repo>[::full|gap|feature=<area>[/<page-slug>]|path=<rel-path>]
/implement infra-scaffold      <repo>
```

| Sub-op | Anchor | One-liner |
|---|---|---|
| `backend-service` | [`## backend-service`](#backend-service) | Generate the v<N> implementation of one backend {{OWNER_TERM}} (or one monolith module) from its PRD-TDD + the applicable layout standard + every other standard. Ops scaffolds + bare test shells. |
| `backend-library` | [`## backend-library`](#backend-library) | Generate the shared library named `SHARED_LIBRARY_NAME` — the calendar / normalization / adapter / JWT / SMS primitives. Refuses when `HAS_SHARED_LIBRARY=false`. |
| `backend-tests` | [`## backend-tests`](#backend-tests) | Generate the full test suite for one backend repo — real assertions, fixtures, mocks — unit + integration + e2e. Fills the shells left by `backend-service` / `backend-library`. |
| `frontend-bootstrap` | [`## frontend-bootstrap`](#frontend-bootstrap) | One-shot skeleton for a frontend repo — toolchain, build, Tailwind-to-tokens, locale shell, self-hosted fonts, block subsystem (when the project uses block trees), admin auth shell. **No feature pages.** |
| `frontend-page` | [`## frontend-page`](#frontend-page) | Generate one feature folder under `<repo>/src/features/[<sub-bucket>/]<page-slug>/` from the matching UI/UX mockup. Only sub-op that writes frontend feature code. |
| `frontend-tests` | [`## frontend-tests`](#frontend-tests) | Generate the full Vitest + RTL suite for every feature folder. Fills the `it.todo` scaffolds left by `frontend-page`. |
| `infra-scaffold` | [`## infra-scaffold`](#infra-scaffold) | v<N> config + Docker Compose + init scripts + operational assets for one of the discovered `INFRA_REPOS` from its PRD-TDD + `infrastructure.md` + the consuming services' contracts. |

If the first arg is missing or not one of the seven, stop and ask — never default.

## Hard rules — apply to every sub-op

- **Writes files only.** No `git add`, no `git commit`, no `git push`, no MR open.
- **No migrations run.** No `alembic upgrade`, no `pytest`, no dependency install.
- **No shell commands announced as "next steps."** Ship afterwards with [[mr]] `open current` (or `open <repo>` from outside the worktree).
- **No `Co-Authored-By:`.** No references to derived onboarding / readme markdown files inside generated code.
- **Never overwrite human-authored files.** Print `Will replace: <path>` and ask. Scaffold-only shells (`NotImplementedError`, `it.todo`, bootstrap-stub chrome) are scaffold, not authored — filling or rewriting them is allowed.
- **No committed secrets** anywhere: TLS keys, passwords, tokens, master keys, access keys, `.htpasswd`.

---

## backend-service

Generate the v<N> implementation of one backend {{OWNER_TERM}}. When `ARCH_SHAPE=microservices`, `<repo>` is a whole service repo. When `ARCH_SHAPE=monolith`, `<repo>` names one internal module under `src/modules/<module>/` in the single backend deployable. When `ARCH_SHAPE=hybrid`, either shape based on the target path.

### Argument

`<repo>[::<mode>]`

| Slot | Required | Values |
|---|---|---|
| `<repo>` | yes | One of `BACKEND_REPOS` (microservices / hybrid) or a declared monolith module (monolith / hybrid). |
| `<mode>` | no | `full` (default) \| `gap` \| `section=<n>` (restrict to PRD-TDD §`<n>` — `7` Kafka + mirrors when `HAS_KAFKA`, `8` DB schema, `9` API endpoints, `11` errors). |

**Full procedure:** `skills/implement/SKILL.md#backend-service` — PRD-TDD section map, hard rules (money-column refusal, layout, naming, ULID, tenant column, calendar, block-tree body, no-ORM, error envelope, `JWT_ALG`, broker rule, mirror tables, attribute prefixes, shared-library pin, silent-skip list, never-generated list), inputs order (architecture → PRD-TDD → onboarding → layout standard + every other standard except `testing.md` → architecture decisions → sibling PRD-TDDs touched by §7 → library PRD-TDD + `src/` end-to-end when `HAS_SHARED_LIBRARY` → current repo state LAST), generation order (`constants → data_models → database/sql → database/action → services` per entity; then transport ring; then infra ring; then `__main__.py`; then `migrations/`; then probes), ops scaffolds, test-shell layout, library-promotion decision tree (5 rules), cross-repo write policy, report shape.

### Refusal conditions

Refuse and stop if:

- `<repo>` is `SHARED_LIBRARY_NAME` (library, not a service — use `backend-library`),
- `<repo>` is a frontend or infra repo (use the appropriate sub-op),
- `<repo>` is a reserved-slot owner whose PRD-TDD has not materialized in this v<N>,
- `<repo>/docs/v<N>/PRD-TDD.md` is missing or empty (author it first via `/docs prd-tdd-backend <repo>::overwrite`),
- the PRD-TDD contains unresolved `<TBD>` / `<TODO>` / `<placeholder>` markers in §6 (Scope), §7 (Kafka — only if `HAS_KAFKA`), §8 (Database schema), §9 (API), or §11 (Errors).

---

## backend-library

Generate the v<N> implementation of the shared library named `SHARED_LIBRARY_NAME` in architecture §1.1 — the Python package every backend service pins by git tag. Single implementation site for every locked-decision primitive.

### Argument

`[::<mode>]` — no repo positional; target fixed to `SHARED_LIBRARY_NAME`.

| Slot | Required | Values |
|---|---|---|
| `<mode>` | no | `full` (default) \| `gap` (only new modules per library PRD-TDD §8) \| `patch=<module>` (regenerate exactly one existing module, dotted path relative to `src/<SHARED_LIBRARY_PACKAGE>/`; the module set is declared in the library's own PRD-TDD §8 — not hard-coded here). |

**Full procedure:** `skills/implement/SKILL.md#backend-library` — hard rules (library-not-service posture, `jalali_lib` as sole implementation site when `CALENDAR=jalali`, `persian_normalization` when `LOCALE_MODE=farsi-only OR bilingual`, `DbAction` per `infrastructure.md §3.6`, `exception` + `fastapi_exception_handler`, `security` verify-only, conditional adapters, SMS client when `OTP_PROVIDER`, observability when `HAS_OBSERVABILITY_STACK`, no consumer fixtures, semver discipline, silent-skip list), inputs order, dependency-order writes for `full` / `gap` / `patch=<module>`, packaging layer, release-tag policy on `PROD_ENV_NAME`.

### Refusal conditions

Refuse and stop if:

- `HAS_SHARED_LIBRARY=false` in architecture (no shared library in this project — refuse with `no shared library in this project's architecture`),
- an explicit repo arg names anything other than `SHARED_LIBRARY_NAME`,
- `<SHARED_LIBRARY_NAME>/docs/v<N>/PRD-TDD.md` is missing or empty (author it first via `/docs prd-tdd-library ::overwrite`),
- the PRD-TDD has unresolved `<TBD>` / `<TODO>` markers in its module catalog or public-API sections,
- `<mode>` is `patch=<module>` and `<module>` is missing / not one of the declared modules / not present in the current `src/<SHARED_LIBRARY_PACKAGE>/` tree,
- `<mode>` is `patch=<module>` and `src/<SHARED_LIBRARY_PACKAGE>/` is empty (nothing to patch — run `full` or `gap` first).

---

## backend-tests

Generate the full test suite for one backend repo — real assertions, fixtures, mocks — unit + integration + e2e. Fills the shells left by `backend-service` / `backend-library`. Twin of `frontend-tests`.

### Argument

`<repo>[::<mode>]`

| Slot | Required | Values |
|---|---|---|
| `<repo>` | yes | One of the discovered backend repos or `SHARED_LIBRARY_NAME` (library's suite has no transport tier; integration tier reduces to real-Postgres `DbAction` + adapter tests). |
| `<mode>` | no | `full` (default) \| `gap` \| `unit` \| `integration` \| `e2e` (`e2e` only if `tests/e2e/` already exists — never create the tier from scratch) \| `entity=<entity>[.<verb>]` (restrict to one entity or one `perform_<verb>`) \| `path=<rel-path>` (restrict to tests targeting a source path under `src/` or a test location under `tests/` — read set unchanged, write set narrowed; refuse if the path doesn't exist or sits outside `src/` / `tests/`). |

**Full procedure:** `skills/implement/SKILL.md#backend-tests` — hard rules (anti-hallucination, `asyncio_mode = "auto"`, markers under `--strict-markers`, `class TestPerform<Verb>:`, one test per `error_code` asserting `status_code` AND `error_code` — never `message`, side-effects-did-not-happen on failure, DB-pool mocking layer, Testcontainers integration + real Postgres + Kafka broker when `HAS_KAFKA` + mirror idempotency when `HAS_MIRROR_TABLES`, no SQLAlchemy in migration tests, route envelope + `401` + `404`-ownership-miss + `403` RBAC-map-miss, Jalali round-trip when `CALENDAR=jalali`, block-tree cases when the service owns block-tree content, parametrized filter/sort/keyset, env vars before `src` imports, local fixtures, coverage floors ratcheting up, banned patterns), inputs order (architecture → `testing.md` FIRST → PRD-TDD (§3/§6/§7/§8/§9/§10/§11/§13/§14) → onboarding → sliced standards → full `src/` → `conftest.py` tiers → existing `tests/` LAST), required cases per `perform_<verb>`.

### Refusal conditions

Refuse and stop if:

- `<repo>` not in the backend allow-list (`BACKEND_REPOS` + `SHARED_LIBRARY_NAME` when `HAS_SHARED_LIBRARY`),
- `<repo>/src/` is empty or missing the canonical shape (nothing to test — run `/implement backend-service` or `backend-library` first),
- `<repo>/docs/v<N>/PRD-TDD.md` missing (need §11 error catalog + §14 acceptance criteria to bind test cases),
- `<repo>/pyproject.toml` does not declare `asyncio_mode = "auto"` under `[tool.pytest.ini_options]`.

---

## frontend-bootstrap

One-shot skeleton for a frontend repo — toolchain, build config, Tailwind bound to the design-system tokens, locale-appropriate shell per architecture §4.1, self-hosted fonts, formatters, block-renderer / block-editor primitives in the shared ring (when a `CONTENT_OWNER` uses block trees), admin auth shell (cookie + silent-refresh), envelope-aware API client, openapi-typescript pipeline, Vitest + MSW + Playwright test infrastructure. **No feature pages.**

### Argument

`<repo>` — one of the discovered `FRONTEND_REPOS` in architecture §1.2. Framework and build mode (Astro SSG / Vite + React SPA / Next / whatever) come from that row's `stack` cell. No mode flag — one-shot.

**Full procedure:** `skills/implement/SKILL.md#frontend-bootstrap` — hard rules (static output only, self-hosted fonts per `LOCALE_MODE` with upstream OFL fetch, locale shell per `LOCALE_MODE`, user-facing strings in `copy/`, dates + digits per `CALENDAR` + `DIGIT_RULES` centralized in `@shared/format/` / `@lib/format/`, no third-party runtime origins outside the CSP allow-list, server-is-truth, admin cookie + mutex, block subsystem parity when the project ships block trees, no `Dockerfile` in frontend repos, silent-skip list, never-generated list), inputs order (architecture → PRD-TDD full → onboarding → frontend-relevant standards → architecture §1.2 / §4 / §6 → design system full → brand → sibling frontend PRD-TDD surgical read → feature catalog full → consumed backend PRD-TDDs §9 → current state LAST), shared writes, landing-side writes, dashboard-side writes.

### Refusal conditions

Refuse and stop if:

- `<repo>` not in `FRONTEND_REPOS`,
- `<repo>/docs/v<N>/PRD-TDD.md` missing or empty (author it first via `/docs prd-tdd-frontend <repo>::overwrite` — it pins framework-specific decisions like TipTap-vs-Lexical when a block editor is used),
- `<repo>/src/features/` already contains sub-folders (bootstrap has already run — either delete the feature folders or run `frontend-page` instead),
- PRD-TDD has unresolved TBD in its stack or auth sections.

---

## frontend-page

Generate one feature folder under `<repo>/src/features/[<sub-bucket>/]<page-slug>/` from the matching UI/UX HTML mockup + design system + feature catalog + consumed backend PRD-TDDs. `<area>` picks the mockup source; the target path drops the top-level `<area>` when it matches the repo's own frontend shape.

### Argument

`<repo>::<area>::<page>` — all three required.

| Slot | Required | Values |
|---|---|---|
| `<repo>` | yes | One of the discovered `FRONTEND_REPOS`. |
| `<area>` | yes | **Dynamically resolved** against `product/docs/uiux/v<N>/`: any directory that exists directly under that path. No hard-coded allow-list — whatever `uiux scaffold` has produced is a valid `<area>`. |
| `<page>` | yes | HTML mockup file inside `product/docs/uiux/v<N>/<area>/`. Accepted with or without `.html` (`index` and `index.html` both resolve). Every theme variant declared in the design system must be present. |
| `<page-slug>` | derived | `<page>` with any trailing `.html` stripped. |

**Full procedure:** `skills/implement/SKILL.md#frontend-page` — hard rules (visual fidelity via token binding per `frontend-layout.md §11`, design-from-mockup / logic-from-you split — structural contract binds, demo data does NOT, mockup CSS end-to-end BEFORE composition, design-system trumps mockup on provable violation with report line, `data-*` attributes are contract, chrome audit BEFORE feature work with stub/designed classification, MSW empty payloads never fake fixtures, Persian letter-spacing quarantine when `LOCALE_MODE=farsi-only OR bilingual`, logical CSS only, mobile-first responsive with hamburger drawer + Sidenav drawer + DataTable cardify + tile-grid reflow + containing-block traps, copy through `copy.ts`, dates through shared formatter, server-is-truth, envelope-aware, auth-aware, theme parity, block-renderer parity, types from generated openapi, never overwrite human files), inputs order, target-path mapping table (repo-shape elision), files written into the feature folder.

### Refusal conditions

Refuse and stop if:

- `<repo>` is not in `FRONTEND_REPOS`,
- `product/docs/uiux/v<N>/<area>/` does not exist as a directory (author the mockup area first with `/uiux scaffold <area>`),
- the resolved mockup file does not exist as a file,
- `<repo>/src/features/` doesn't exist (run `frontend-bootstrap` first),
- the target feature is not `[x]` in `product/docs/features/v<N>/all-features.md`.

---

## frontend-tests

Generate the full Vitest + RTL test suite for every feature folder under `<repo>/src/features/`. Fills the `it.todo` scaffolds left by `frontend-page`. Twin of `backend-tests`.

### Argument

`<repo>[::<mode>]`

| Slot | Required | Values |
|---|---|---|
| `<repo>` | yes | One of the discovered `FRONTEND_REPOS`. |
| `<mode>` | no | `full` (default) \| `gap` \| `feature=<area>[/<page-slug>]` (restrict to one feature) \| `path=<rel-path>` (restrict to tests co-located with that source path). |

**Full procedure:** `skills/implement/SKILL.md#frontend-tests` — hard rules (query priority role → label → text → `data-testid` last with `// justification:` comment, `findBy*` async / `getBy*` sync / `queryBy*` absence — never `await waitFor(() => expect(...))`, `userEvent` v14 async only, no class / inline-style assertions, MSW `onUnhandledRequest: "error"` never stub `useQuery` / `useMutation`, fresh `QueryClient` per test, production locale + direction, Persian-digit assertions via rendered output when `DIGIT_RULES=persian-human-ascii-machine`, dates via shared formatter, copy via `copy` object, every Zod branch + every `error_code` in `errors.ts` tested, `jest-axe` per rendered page, four-state coverage on admin surfaces, admin auth flows, block-renderer parity via canonical fixture library when the project ships block trees, no real network, co-located `__tests__/` only), inputs order, writes.

### Refusal conditions

Refuse and stop if:

- `<repo>` not in `FRONTEND_REPOS`,
- `<repo>/src/features/` empty,
- target feature's entry component missing,
- MSW infrastructure missing (`src/mocks/server.ts` + ≥ 1 handler + setup calls `server.listen({onUnhandledRequest: "error"})`),
- Vitest config missing `globals: false` + `environment: "jsdom"`.

---

## infra-scaffold

Generate the v<N> config + Docker Compose + init scripts + operational assets for one of the discovered `INFRA_REPOS` from its PRD-TDD + [`infrastructure.md`](../../tech/docs/standards/infrastructure.md) + the consuming services' contracts.

### Argument

`<repo>` — one of the discovered `INFRA_REPOS`. Component chosen by repo name: `infra-postgresql` \| `infra-redis` \| `infra-minio` \| `infra-meilisearch` \| `infra-kafka` \| `infra-nginx` \| `infra-observability`, or the corresponding `devops-*` alias when the project uses that prefix. No mode flag.

**Full procedure:** `skills/implement/SKILL.md#infra-scaffold` — hard rules (read PRD-TDDs + consuming contracts first, `infrastructure.md` authoritative — §2 naming / §3.2 per-{{OWNER_TERM}} DB isolation / §4 Redis cache-only / §5 topic contract when `HAS_KAFKA` / §6 per-{{OWNER_TERM}} MinIO keys when `HAS_MINIO` / §7 Meilisearch ownership by `SEARCH_OWNER` when `HAS_MEILISEARCH`, cross-repo contract quoted-not-restated with anti-hallucination grep, no secrets ever, no application code in infra repos, `X-Request-ID` generated at nginx edge, envelope pass-through, hosting posture per architecture §8, develop/staging HTTP Basic gating at nginx edge, idempotent bootstrap, silent-skip list, never-generated list including TLS material / `.htpasswd` / keys / data volumes), inputs order, writes-shared-across-all-seven, per-repo writes (`infra-postgresql` / `infra-redis` only when `HAS_REDIS` / `infra-minio` only when `HAS_MINIO` / `infra-meilisearch` only when `HAS_MEILISEARCH` / `infra-kafka` only when `HAS_KAFKA` / `infra-nginx` / `infra-observability` only when `HAS_OBSERVABILITY_STACK`).

### Refusal conditions

Refuse and stop if:

- `<repo>` is not in `INFRA_REPOS`,
- `<repo>` is a backend or frontend repo (use the appropriate sub-op),
- `<repo>/docs/v<N>/PRD-TDD.md` is missing or a placeholder (author it first via `/docs prd-tdd-infra <repo>::overwrite`),
- the PRD-TDD contains unresolved `<TBD>` / `<TODO>` / `<placeholder>` markers in its role / topology / access-control / bootstrap / ops sections,
- the consumed contract for the layer is not addressable: for `infra-postgresql`, the per-{{OWNER_TERM}} database + role list; for `infra-kafka` (when `HAS_KAFKA`), the canonical topic catalog; for `infra-minio` (when `HAS_MINIO`), the bucket catalog; for `infra-meilisearch` (when `HAS_MEILISEARCH`), `SEARCH_OWNER`'s PRD-TDD; for `infra-nginx`, the backend §9 endpoint prefixes AND every frontend PRD-TDD's routing sections; for `infra-observability` (when `HAS_OBSERVABILITY_STACK`), the probe surface (`/healthCheck` / `/readiness` / `/warmup`) contract in `errors-and-observability.md` §13.

---

Writes files only. Ship afterwards with [[mr]] `open <repo>` (or `open current` from inside the worktree).
