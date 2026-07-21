---
name: docs
description: |
  Author PRD-TDD documentation across the engineering repos discovered under `tech/` (backend microservices or a monolith module tree, an optional shared library, infra / devops repos, and frontends). First positional argument is `<prd-tdd-backend|prd-tdd-library|prd-tdd-infra|prd-tdd-frontend>`; subsequent args are sub-op specific. Every target set is discovered from disk plus the workspace's platform architecture doc — nothing is hard-coded to a specific project's repo list.

  - `prd-tdd-backend <repo>::<mode>` — author the full v`<N>` PRD & TDD for a single backend microservice — TL;DR through Changelog — by deeply reading every engineering standard (with primary focus on the architecture-layout file — `microservice-layout.md` when architecture's `ARCH_SHAPE = microservices`, `monolith-layout.md` when `monolith` — plus `infrastructure.md`, `api-and-data-contracts.md`, `errors-and-observability.md`, `security-and-auth.md`, `coding.md` including calendar boundary when `CALENDAR = jalali` and block-tree section when `BLOCK_EDITOR = true`), the platform architecture at `tech/docs/project-architecture/v<N>.md` or `tech/docs/v<N>/project-architecture.md` (incl. the §2 feature → service map), any `architecture-decisions.md` locked-decision file, the full product feature catalog at `product/docs/features/v<N>/all-features.md`, the UI/UX pack, and — when `HAS_KAFKA` — the Kafka topic catalog from the discovered kafka infra repo, then composing the document section-by-section against the canonical `TEMPLATE-backend.md` in this skill. `<repo>` is one of the on-disk `tech/backend-*` microservices (excluding the shared library, whose name comes from architecture's `SHARED_LIBRARY_NAME`); not the shared library (use `prd-tdd-library`), not infra/devops (use `prd-tdd-infra`), not frontend (use `prd-tdd-frontend`). `<mode>` is `merge` (preserve §8 Database schema verbatim) | `overwrite` (replace the file). **§7 is Kafka + mirror contracts when `HAS_KAFKA`**, else a synchronous cross-service-REST contract section; topic names (`<sender>-<receiver(s)>-<event>`, DLQ `<topic>-dlq`) are quoted from the kafka topic catalog, never invented and never cross-read from sibling backend PRD-TDDs. **§6.4 (Money columns) is omitted when `PSP_PROVIDER` is unset** — no money-moving operations in that workspace. Writes only `<repo>/docs/v<N>/PRD-TDD.md`; does NOT stage / commit / push / open MR. Refuses if `<repo>` is not a discovered backend microservice, if `<mode>` missing (stop and ask `merge` | `overwrite`), or if `<mode>` is not one of those two.
  - `prd-tdd-library ::<mode>` — author the full v`<N>` PRD & TDD for the shared library repo whose name comes from architecture's `SHARED_LIBRARY_NAME` — the calendar library (when `CALENDAR = jalali`) + shared adapters (`DbAction`, JWT verifier, MinIO adapter when `HAS_MINIO`, OTel bootstrap, SMS client when `OTP_PROVIDER` and the library owns it in v`<N>`) — against the same `TEMPLATE-backend.md` with a **documented library delta**: no transport surface, no routes, no entrypoint dispatcher; the repo distributes as a git-tag pinned package with the version-lock CI gate from architecture §7.2. §4 personas are the discovered consuming backends; §5 journeys are per-module consumer call-flows; §6 owns no tables / buckets / topics; §7 becomes the **distribution contract** (git-tag pinned package, release tags cut on `main`, version-lock CI gate, automated bump-MR fan-out); §8 becomes the **Public API surface** (module-by-module exported symbols — preserved verbatim on `merge`, exactly as §8 schema is for a service); §9 lists public functions instead of routes; §12 carries per-call budgets (when `CALENDAR = jalali` the calendar conversion is a hot path — the reason the HTTP-service alternative was rejected). Target is fixed to the discovered `SHARED_LIBRARY_NAME` — no `<repo>` positional. Refuses when `HAS_SHARED_LIBRARY = false`, if `<mode>` missing or invalid, or if the operator supplies any repo other than the discovered `SHARED_LIBRARY_NAME`.
  - `prd-tdd-infra <repo>::<mode>` — author a **lean** v`<N>` service-design doc for one discovered `tech/infra-*` OR `tech/devops-*` repo — 9 sections, ≤ ~250 lines target — following the canonical `TEMPLATE-infra.md` in this skill. The workspace's infra repos may live under either prefix; the skill discovers whichever exists. Component role is inferred from the repo suffix (e.g. `-postgresql`, `-redis`, `-minio`, `-meilisearch`, `-kafka`, `-nginx`, `-observability`). Reads the workspace-root onboarding, the repo's **config tree if present** (`docker-compose*.yml`, `config/`, `*.conf`, migrations for postgresql, bucket policy for minio, `topics.yaml` for kafka, nginx confs, `meilisearch.yaml`, observability YAML — every one conditional; bootstrap-state repos ship only a stub `README.md` so this step silently skips), every infra-relevant engineering standard (`infrastructure.md` primary, `security-and-auth.md`, `errors-and-observability.md`, `ci-cd.md`, `documentation.md`, plus `api-and-data-contracts.md` for the nginx repo only), the platform architecture (§5 infrastructure + §5.6 environments + §5.7 non-production HTTP Basic-auth gate when declared + §8 deployment topology), the existing PRD-TDD, the **product feature catalog** tagging only `[x]` items whose delivery physically crosses this layer (postgresql: any item hitting `<service>__*` tables; redis (when `HAS_REDIS`): counters + caches; minio (when `HAS_MINIO`): media surfaces + backup targets; meilisearch (when `HAS_MEILISEARCH`): search + normalization; kafka (when `HAS_KAFKA`): day-one consumer flows from architecture §5.3; nginx: every user-facing route + TLS / security headers + CDN origin when `CDN_PROVIDER`; observability: SLO surfaces) — `[ ]` items feed §2.4 Out-of-scope with a re-open trigger, the **UI/UX pack** limited to routing signal (the design-system's font-hosting posture is load-bearing for the nginx repo), and — most importantly — the **consumer-side slices** of the discovered backend PRD-TDDs (§8 schema for postgresql, Redis-key sections for redis, §6.2 buckets for minio, `SEARCH_OWNER` only for meilisearch, §7 Kafka sections for kafka — whose own PRD-TDD is the binding topic registry, §9 + §12 for nginx plus the discovered frontend PRD-TDDs' upstream + CSP sections, SLO / logging sections for observability). **References consumer-side artifacts by namespace / prefix only** — never enumerates the Postgres tables, Kafka topics, MinIO buckets, Redis keys, or nginx endpoints of consuming services. **Extracts routing signal from the UI/UX read, never re-implements the UI.** Deliberately omits a Configuration key list (→ `<repo>/config/`), Threat model (→ security team), Decision log (→ `<repo>/docs/v<N>/adr/`), and Changelog (→ `git log`). `<mode>` is `merge` (preserve §9 Alternatives & open questions verbatim — institutional memory) | `overwrite` (regenerate every section including §9). **Terminology note:** this sub-op is named `prd-tdd-infra` regardless of whether the workspace uses `tech/infra-*` or `tech/devops-*` — discovery covers both. Refuses if `<repo>` is not one of the discovered infra/devops repos, if `<mode>` missing (stop and ask), or if `<mode>` is not `merge` | `overwrite`.
  - `prd-tdd-frontend <repo>::<mode>` — author the full v`<N>` PRD & TDD for one discovered `tech/frontend-*` repo — 26 sections — following the canonical `TEMPLATE-frontend.md` in this skill. Two canonical shapes: `landing` (SSG at `PUBLIC_DOMAIN` — the public reader surface, islands, rebuild-on-publish, SEO-critical) and `dashboard` (SPA at `APP_DOMAIN` — the admin/dashboard repo, hosting every editorial + admin surface). Shape is decided by repo-name pattern (`frontend-landing` → landing; `frontend-admin` / `frontend-dashboard` / `frontend-platform-admin` → dashboard) and confirmed against architecture §1.2 + §4. Detects the repo shape, then reads the feature catalog `product/docs/features/v<N>/all-features.md` (landing binds the reader-facing `[x]` rows, dashboard binds the editorial / admin rows; the architecture §2 map resolves shared rows), the UI/UX pack (`design-system/design-system.md` — the canonical spec — + its HTML twin + brand assets under `business/docs/brand/`; per-page mockups conditional), every frontend-relevant standard (`frontend.md` + `frontend-layout.md` primary, plus `api-and-data-contracts.md`, `security-and-auth.md`, `errors-and-observability.md`, `coding.md` — including calendar-boundary + block-tree sections when applicable, `ci-cd.md`, `testing.md`), the platform architecture (§1.2, §4, §6), the existing PRD-TDD, the sibling frontend PRD-TDD (theme key + envelope helper + block-tree fixture-mirror cross-consistency when `BLOCK_EDITOR = true`; `frontend.md` wins on contradiction), and the **§9 API endpoint families** of every consumed backend (landing consumes reader-serving backends per architecture §2; dashboard consumes every admin-surface backend). Locale posture is load-bearing per `LOCALE_MODE`; block tree is the only authoring model when `BLOCK_EDITOR = true`; captcha per `CAPTCHA_PROVIDER`; sanctions-safe by construction when architecture declares an Iran-market posture (self-hosted fonts, no Google origin ever). §11 Auth: landing none; dashboard cookie + silent refresh + admin-sidebar registry (JSONB UI hint synced via `<service>-<AUTH_OWNER>-admin-role-sync` Kafka events when `HAS_KAFKA`; JWT carries no role claims; owning service re-checks per call). §16 SEO: landing-deep (JSON-LD, OG, canonical, per-market embed hints); dashboard one-paragraph `noindex`. `<mode>` is `merge` (preserve §22 Decision log verbatim) | `overwrite`. Refuses if `<repo>` is not among the discovered `tech/frontend-*` repos, if `<mode>` missing (stop and ask), or if `<mode>` is not `merge` | `overwrite`.

  Use when the user asks to:
  - "write the PRD-TDD for `<backend-repo>`", "author the v`<N>` PRD/TDD for `<service>`", "fill in the PRD-TDD of `<backend>` from the product + standards", "regenerate the PRD-TDD for `<backend>`", "merge new sections into `<backend>`'s PRD-TDD without touching the schema";
  - "write the PRD-TDD for the shared library", "author the v`<N>` PRD/TDD for the shared library", "document the shared adapters", "regenerate the library PRD-TDD without losing the public API surface";
  - "write the PRD-TDD for `<infra-or-devops-repo>`", "author the v`<N>` PRD/TDD for `tech/infra-<x>` / `tech/devops-<x>`", "draft the infrastructure PRD-TDD for `<postgres|redis|minio|meilisearch|kafka|nginx|observability>`", "create the PRD-TDD for our nginx / kafka / postgres";
  - "write the PRD-TDD for `<frontend-repo>`", "author the v`<N>` PRD/TDD for `tech/frontend-<x>`", "draft the frontend PRD-TDD for `<frontend-landing|frontend-admin|frontend-dashboard>`", "create the PRD-TDD for our landing / dashboard frontend", "regenerate the frontend PRD-TDD without losing the decision log";
  - Or invokes `/docs`.

  If the first arg is missing or not one of `prd-tdd-backend|prd-tdd-library|prd-tdd-infra|prd-tdd-frontend`, stop and ask which sub-op — never default. None of the four sub-ops stages / commits / opens an MR — pair with `/mr open <scope>` afterwards.
---

# docs — author PRD-TDDs

```
/docs prd-tdd-backend   <repo>::<mode>
/docs prd-tdd-library   ::<mode>                      # target is always the discovered SHARED_LIBRARY_NAME
/docs prd-tdd-infra     <repo>::<mode>
/docs prd-tdd-frontend  <repo>::<mode>
```

| Sub-cmd | Anchor | One-line summary |
|---|---|---|
| `prd-tdd-backend` | [`## prd-tdd-backend`](#prd-tdd-backend) | Author the v`<N>` PRD & TDD for one discovered `tech/backend-*` microservice against [`TEMPLATE-backend.md`](TEMPLATE-backend.md). |
| `prd-tdd-library` | [`## prd-tdd-library`](#prd-tdd-library) | Author the v`<N>` PRD & TDD for the shared library (name from architecture's `SHARED_LIBRARY_NAME`) against [`TEMPLATE-backend.md`](TEMPLATE-backend.md) + the library delta. |
| `prd-tdd-infra` | [`## prd-tdd-infra`](#prd-tdd-infra) | Author the v`<N>` PRD & TDD for one discovered `tech/infra-*` or `tech/devops-*` repo against [`TEMPLATE-infra.md`](TEMPLATE-infra.md). |
| `prd-tdd-frontend` | [`## prd-tdd-frontend`](#prd-tdd-frontend) | Author the v`<N>` PRD & TDD for one discovered `tech/frontend-*` repo against [`TEMPLATE-frontend.md`](TEMPLATE-frontend.md). |

If the first arg is missing or not one of the four, stop and ask.

---

## Workspace discovery (applies to every sub-op)

Before any sub-op runs its Step 1, the skill walks disk to build the target set from what actually exists — nothing is hard-coded to a specific project's repo list.

1. **Workspace root.** The directory containing `business/`, `product/`, `tech/`, and at least one docs container (a child that holds `.claude/` — commonly `docs/` or `agent_config/`).
2. **Version `<N>`.** The highest integer for which `tech/docs/project-architecture/v<N>.md` **or** `tech/docs/v<N>/project-architecture.md` exists. If both spellings exist, prefer `tech/docs/project-architecture/v<N>.md`. Product feature catalog is expected at `product/docs/features/v<N>/all-features.md`.
3. **Backend repos.** Every directory matching `tech/backend-*` **minus** the shared-library repo.
4. **Frontend repos.** Every directory matching `tech/frontend-*`. Landing vs admin/dashboard shape is decided by repo-name suffix (`landing` vs `admin` / `dashboard`) and confirmed against architecture §4 + §1.2.
5. **Shared library.** Only present when architecture declares `HAS_SHARED_LIBRARY = true`; the repo path is architecture's `SHARED_LIBRARY_NAME` (e.g. `tech/backend-shared-logic`, `tech/lib-shared`). Never assume a fixed name.
6. **Infra / devops repos.** Every directory matching `tech/infra-*` **or** `tech/devops-*` (the workspace uses one naming convention — if both prefixes exist the operator picks per call).
7. **Architecture flags.** Read the architecture doc once and pick up: `PROJECT_NAME`, `PROJECT_SLUG`, `ARCH_SHAPE`, `HAS_KAFKA`, `HAS_REDIS`, `HAS_MINIO`, `HAS_MEILISEARCH`, `HAS_SHARED_LIBRARY`, `SHARED_LIBRARY_NAME`, `LOCALE_MODE`, `CALENDAR`, `DIGIT_RULES`, `OTP_PROVIDER`, `CDN_PROVIDER`, `CAPTCHA_PROVIDER`, `PSP_PROVIDER`, `AUTH_OWNER`, `CONTENT_OWNER`, `SEARCH_OWNER`, `ASSETS_OWNER`, `AUDIT_OWNER`, `ENGAGEMENT_OWNER`, `PUBLIC_DOMAIN`, `APP_DOMAIN`, `PROD_ENV_NAME`, `DEFAULT_BRANCH`, `BLOCK_EDITOR`, `BE_COVERAGE_FLOOR`, `FE_COVERAGE_FLOOR`, day-one Kafka flow flags (`HAS_SEARCH_INDEXER_FLOW`, `HAS_WEBHOOK_FLOW`, `HAS_AUDIT_FLOW`, `HAS_ASSETS_PURGE_FLOW`).
8. **Standards.** Read every file under `tech/docs/standards/`. The architecture-layout file is `microservice-layout.md` when `ARCH_SHAPE = microservices`, `monolith-layout.md` when `monolith`, or both when `hybrid` (prefer whichever the target repo's role implies).

Any of the above missing → surface the gap, add it as an §17 (Open question) in the output, and proceed on whatever remains. Never fabricate a discovered value.

---

## prd-tdd-backend

Compose a full, binding `docs/v<N>/PRD-TDD.md` for one backend microservice — TL;DR through Changelog — following the canonical template shipped at [`TEMPLATE-backend.md`](TEMPLATE-backend.md) next to this file.

The skill is **read-heavy, write-once**. Its whole value is the depth of the read pass. No section is composed until every binding input is read in full; cross-service contracts are resolved from the kafka topic catalog (when `HAS_KAFKA`) or from a synchronous-REST contract section (when `HAS_KAFKA = false`), never invented.

Workspace root is the directory containing `business/`, `product/`, `tech/`, and the docs container.

### Argument

`<repo>::<mode>` where:

- `<repo>` — one of the discovered `tech/backend-*` repos (see workspace discovery §3). The set is not hard-coded — the skill lists actual on-disk backends and refuses anything outside that set.
- `<mode>` — required, `merge` | `overwrite`.

Refuse and stop if:

- argument missing or `<repo>` not in the discovered backend list,
- `<repo>` matches the discovered `SHARED_LIBRARY_NAME` (use `prd-tdd-library`) or any `tech/infra-*` / `tech/devops-*` / `tech/frontend-*`,
- `<mode>` missing — stop and ask,
- `<mode>` given but not `merge` | `overwrite`.

### Hard rules (do not violate)

- **Read first, write last.**
- **Only `[x]` features are in scope** for §3 Goals, §4 Personas, §5 Journeys, §6.1 Features owned, and §9 API.
- **Standards are linked, not duplicated.**
- **`merge` preserves §8 Database schema verbatim.**
- **Cross-service contracts come from the Kafka topic catalog only** (when `HAS_KAFKA`) — the discovered kafka infra repo's `docs/v<N>/PRD-TDD.md` is the single source. Sibling backend PRD-TDDs are NEVER read (cross-reading creates a coupling loop). The only outside PRD-TDD read is the shared-library PRD-TDD (when `HAS_SHARED_LIBRARY`). Topic missing from catalog → §17 Open question, never fabricated. When `HAS_KAFKA = false`, §7 becomes a synchronous cross-service-REST contract section.
- **§7 is Kafka + mirror contracts** when `HAS_KAFKA`. Day-one consumer families come from architecture §5.3 (`HAS_SEARCH_INDEXER_FLOW`, `HAS_WEBHOOK_FLOW`, `HAS_AUDIT_FLOW`, `HAS_ASSETS_PURGE_FLOW`).
- **§6.4 (Money columns) is omitted** when `PSP_PROVIDER` is unset (no money-moving in v`<N>`; the guard hook blocks money columns). When a PSP is declared, §6.4 documents per-currency columns per the finance-owner service.
- **The locked decisions bind every section** — read them from architecture §7 verbatim: Jalali-as-storage-primitive (when `CALENDAR = jalali`), content body = JSON block tree (when `BLOCK_EDITOR = true`), schema-as-code sole source of truth, ULID everywhere, envelope `{success, message, data}`, no cross-service FKs.
- **camelCase paths, ULID identifiers, `{success, message, data}` envelope, 404-not-403 on ownership** per `tech/docs/standards/api-and-data-contracts.md`.
- **Workspace hard rules apply to the output document itself:** no `Co-Authored-By:`, no reference to derived-artifact onboarding files. Locale posture for in-product copy follows `LOCALE_MODE`; the document itself is English (engineering doc convention).

### Style rules (every section)

- No `Story N` wrapping.
- NFRs in tables (§12), STRIDE-lite in §13.
- DDL only in §8. Other sections name columns (e.g. `content__articles.slug`).
- Calendar / digit boundary explicit wherever a date or number crosses the wire, per `CALENDAR` + `DIGIT_RULES`.
- Tables beat prose for matrix-shaped content.

### Step 1 — read every binding input

1. Template: [`TEMPLATE-backend.md`](TEMPLATE-backend.md).
2. Repo onboarding if present. Bootstrap-state repos ship only a stub `README.md` — skip silently, fall back to architecture §1–§2.
3. Existing PRD-TDD: `<repo>/docs/v<N>/PRD-TDD.md` (bootstrap state: may not exist).
4. Architecture: `tech/docs/project-architecture/v<N>.md` OR `tech/docs/v<N>/project-architecture.md` — service map, §2 feature → service map, JWT posture, Kafka day-one consumers (when `HAS_KAFKA`), deployment topology, locked decisions.
5. Locked decisions: any `architecture-decisions.md` — locked + cross-cutting decisions + live open questions.
6. Every engineering standard under `tech/docs/standards/` — primary: the architecture-layout file (`microservice-layout.md` OR `monolith-layout.md` per `ARCH_SHAPE`), `infrastructure.md`, `api-and-data-contracts.md`, `errors-and-observability.md`, `security-and-auth.md`, `coding.md` (calendar section when `CALENDAR = jalali` + block-tree section when `BLOCK_EDITOR = true`).
7. Feature catalog: `product/docs/features/v<N>/all-features.md` — every section + v`<N>` Selection Summary; tag each `[x]` with the owning service.
8. UI/UX pack — narrow to this service's surface only. Always `design-system/design-system.md`. Then only the areas whose surface this backend serves: `landing/` if the service serves the public reader (`CONTENT_OWNER` public reads, `SEARCH_OWNER` type-ahead, `ENGAGEMENT_OWNER` public comment POST, the analytics owner's pageview ingest) — otherwise skip. `system/` (dashboard mockups) if the service has any editor / admin surface — typically every backend except reserved-slot repos. Never read a UI/UX area outside this service's surface. Absent area whose surface this service serves → §17 gap.
9. Workspace-root onboarding.
10. Kafka topic catalog (when `HAS_KAFKA`): the discovered kafka infra repo's `docs/v<N>/PRD-TDD.md` — **the sole binding source** for cross-service topic names, partition keys, payload contracts, DLQ pairs. Sibling backend PRD-TDDs are NEVER read (cross-reading creates coupling loop). Topic missing from catalog → §17. Skip entirely when `HAS_KAFKA = false`.
11. **Library PRD-TDD** (`<SHARED_LIBRARY_NAME>/docs/v<N>/PRD-TDD.md`) when `HAS_SHARED_LIBRARY` — §8 Public API + §9 Public functions/classes + §10 env vars. Only outside-`<repo>` PRD-TDD read. Feeds §6 imports, §7 Kafka base + retry (when `HAS_KAFKA`), §9 JWT verify + auth-check gating, §10 env vars, §11 library exceptions, §12 budgets. Skip when `HAS_SHARED_LIBRARY = false`.
12. Umbrella git baseline: any `docs/standards/git.md` — decision-log / changelog conventions.

Print one compact summary line per source read (path + 5–10 word takeaway) before moving to Step 2.

### Step 2 — derive the service profile

State back once before writing:

- `service_slug` — `<repo>` minus `backend-`.
- `default_branch` = `DEFAULT_BRANCH` (typically `develop`).
- `owned_tables` — `<slug>__*` (always incl. `<slug>__roles`, `<slug>__user_roles`, `<slug>__configurations`; every business table carries the multi-tenancy column per architecture §1.3 — typically `publication_id` or `tenant_id`).
- `owned_redis_namespace` — `<slug>:*` when `HAS_REDIS`, else "none".
- `owned_buckets` — `<slug>-<purpose>` list when `HAS_MINIO`, else "none".
- `produced_topics` / `consumed_topics` — verbatim topic lists when `HAS_KAFKA`, else "none — cross-service is synchronous REST".
- `mirror_origin_entities` / `mirror_consumer_tables` — or "none".
- `feature_catalog_sections_owned` — `(§n, title)` triples.
- `personas_served` — subset of the workspace's role registry (per architecture §6 `ROLE_LIST`).

Anything genuinely undetermined → §17. Do not block.

### Step 3 — compose

Walk [`TEMPLATE-backend.md`](TEMPLATE-backend.md) top-to-bottom. The template carries its own section map + section headers + per-section binding rules as `{{VARIABLE}}` / `{{#IF}}` / `{{#EACH}}` placeholders — the composition job is to resolve those placeholders from Step 1 reads + the Step 2 profile. Highlights:

- **§1 TL;DR** — ≤ 6 lines; the one invariant only this service holds + biggest risk.
- **§5 Journeys** — Mermaid `sequenceDiagram` per top flow + failure branches (400/401/404/409/422/429/502/504).
- **§7** — producer table, consumer table, mirror blocks (when `HAS_KAFKA`); name which day-one consumers this service participates in. When `HAS_KAFKA = false`, sync-REST contract section.
- **§8** — `merge`: verbatim copy. `overwrite`: band-map + entity-map + per-entity DDL + column guide; multi-tenancy column on every business table; calendar sidecar columns on human-observed dates when `CALENDAR = jalali`; Alembic raw SQL only.
- **§11** — `<SERVICE>_<CODE>` namespace; no raw 500; 502/504/429-not-500; load-bearing codes per feature catalog (e.g. content unknown block type when `BLOCK_EDITOR = true`, slug conflict, captcha verify codes when `CAPTCHA_PROVIDER`).
- **§15** — at least three real alternatives (e.g. Redis read cache vs nginx map-file when `HAS_REDIS`; shared-logic library vs HTTP service when `HAS_SHARED_LIBRARY`; Meilisearch vs Elasticsearch when `HAS_MEILISEARCH`; plus service-local ones).

### Step 4 — write

Output: `<repo>/docs/v<N>/PRD-TDD.md`. On `merge`: `[§1–§7 fresh] ∪ [§8 verbatim] ∪ [§9–§20 fresh]`. On `overwrite`: full replacement. Create `<repo>/docs/v<N>/` if absent. Single Write call — compose in memory first.

### Step 5 — report

1. `mode` used.
2. List of reads from Step 1 with one-line takeaways.
3. Derived service profile from Step 2.
4. Output path + line count.
5. Next-steps block ending with `/mr open <repo>`.

Stop. Do not stage, commit, push, or merge.

### Related skills

- [[mr]] — ship the PRD-TDD.
- [[audit]] — cross-corpus audit after merge.
- [[implement]] — land the implementation the PRD-TDD declares.

---

## prd-tdd-library

Compose a full, binding `docs/v<N>/PRD-TDD.md` for the shared library repo (whose name comes from architecture's `SHARED_LIBRARY_NAME` — never hard-coded) — the calendar library (when `CALENDAR = jalali`) + shared adapters — following [`TEMPLATE-backend.md`](TEMPLATE-backend.md) **with the library delta applied**. Read-heavy, write-once, same as `prd-tdd-backend`; the target is a library, not a service.

Refuses when `HAS_SHARED_LIBRARY = false`.

### Argument

`::<mode>` — no `<repo>` positional (target is fixed to the discovered `SHARED_LIBRARY_NAME`); `<mode>` required, `merge` | `overwrite`.

Refuse and stop if:

- `HAS_SHARED_LIBRARY = false` in architecture,
- `<mode>` missing — stop and ask,
- `<mode>` given but not `merge` | `overwrite`,
- the operator supplies a repo other than the discovered `SHARED_LIBRARY_NAME`.

### The library delta (versus `TEMPLATE-backend.md`)

Spelled out in full in the command file [`/docs prd-tdd-library`](../../commands/docs.md) — apply it verbatim. In brief:

- **No transport surface, no routes, no entrypoint dispatcher** — the repo distributes as a git-tag pinned package.
- §4 Personas → the discovered consuming services (`personas_served = { SERVICE }`).
- §5 Journeys → per-module consumer call-flows (calendar round-trip when `CALENDAR = jalali`, `DbAction` query, JWT verify, MinIO upload when `HAS_MINIO`, OTel bootstrap, SMS OTP send from `AUTH_OWNER` when `OTP_PROVIDER` and library owns the client).
- §6 → owns **no tables / buckets / Redis namespace / topics**; owns the module contracts instead (calendar boundary rule, normalization canon per `LOCALE_MODE`, digit formatters per `DIGIT_RULES`).
- §7 → **distribution contract**: release tags cut on `main`; consumer pins by git tag; version-lock CI gate (stale pin fails the pipeline); automated bump-MR fan-out; deploy order.
- §8 → **Public API surface** — module-by-module exported symbols (calendar · normalization utils · `DbAction` · JWT verifier · MinIO adapter when `HAS_MINIO` · OTel bootstrap · SMS client when `OTP_PROVIDER`). **Preserved verbatim on `merge`.**
- §9 → public functions / classes, not routes. §10 → consumer-side env keys, no `__configurations` table. §12 → per-call budgets (when `CALENDAR = jalali`, conversion is a hot path — the reason the HTTP-service alternative was rejected).
- **§6.4 Money columns omitted** when `PSP_PROVIDER` is unset — workspace-wide rule.

### Steps

Step 1 reads: template → existing PRD-TDD (preserve §8 on `merge`) → architecture §1.1 + §7.2 + §7.4 → any `architecture-decisions.md` (version lock + locked decisions) → library-relevant standards (`coding.md` calendar + block-tree sections when applicable, `infrastructure.md`, `security-and-auth.md`, `errors-and-observability.md`, `testing.md` property-based scope, `ci-cd.md` version-lock gate, `documentation.md`) → **feature catalog end-to-end** (all sections + v`<N>` Selection Summary; library substrate for every service so scope is not confined to one section; tag every `[x]` against three lenses — owned end-to-end, substrate for another service (→ §5 journeys, §8 API, §12 SLOs, never §6 ownership), out-of-scope; `[ ]` rows all §18) → **every existing sibling backend PRD-TDD in full** — all discovered `tech/backend-*/docs/v<N>/PRD-TDD.md`, read end-to-end (conditional on existence, no cherry-picking sections — every section is potentially load-bearing since the library is the substrate they all import); any absent sibling → §17 gap → any `docs/standards/git.md`.

Step 2 profile: `service_slug = SHARED_LIBRARY_NAME` minus `backend-` / `lib-` prefix · `default_branch = DEFAULT_BRANCH` (release tags on `main`) · `modules` (per architecture-declared list) · `consumers` (discovered backends + pins) · `owned_tables / buckets / topics = none` · `personas_served = { SERVICE }`.

Steps 3–5: same shape as `prd-tdd-backend`; `merge` splice `[§1–§7 fresh] ∪ [§8 verbatim] ∪ [§9–§20 fresh]`; report ends with `/mr open <SHARED_LIBRARY_NAME>`.

### Related skills

- [[mr]] — ship it.
- [[implement]] — generate the library this PRD-TDD declares.
- [[audit]] — cross-corpus audit after authoring.

---

## prd-tdd-infra

Compose a full, binding `docs/v<N>/PRD-TDD.md` for one discovered `tech/infra-*` OR `tech/devops-*` repo — nine sections, ≤ ~250 lines target — following [`TEMPLATE-infra.md`](TEMPLATE-infra.md). Same read-heavy / write-once shape as `prd-tdd-backend`, but with an infra-specific input set: standards + architecture + the **consumer-side slices** of the discovered backend PRD-TDDs (plus discovered frontends for the nginx repo).

### Argument

`<repo>::<mode>` where:

- `<repo>` — one of the discovered infra/devops repos (see workspace discovery §6). Role inferred from the suffix (`-postgresql`, `-redis`, `-minio`, `-meilisearch`, `-kafka`, `-nginx`, `-observability`).
- `<mode>` — `merge` (preserve §9 verbatim) | `overwrite`.

Refuse and stop if:

- argument missing or `<repo>` not in the discovered list,
- `<repo>` is a `tech/backend-*` (use `prd-tdd-backend` / `prd-tdd-library`) or `tech/frontend-*` (use `prd-tdd-frontend`),
- `<mode>` missing or not `merge` | `overwrite`.

**Terminology note.** `prd-tdd-infra` matches whichever prefix the workspace uses — `tech/infra-*` or `tech/devops-*`. Standards files (`infrastructure.md`, `ci-cd.md`) may use either term.

### Hard rules

- Read first, write last. Standards linked, not duplicated.
- **Cross-service contracts are quoted from the consumer PRD-TDDs, never invented.** Postgres prefixes, Redis namespaces (when `HAS_REDIS`), MinIO bucket names (when `HAS_MINIO`), Kafka topic names (when `HAS_KAFKA`), nginx upstream pools → verbatim from the discovered backend PRD-TDDs or from `tech/docs/standards/infrastructure.md`.
- **`merge` preserves §9.**
- No `Co-Authored-By:`; no derived-artifact refs.

### What NOT to read

- ❌ `business/docs/` beyond the workspace-root onboarding.
- ❌ Sibling infra/devops repos other than the target.
- ❌ The shared-library repo (exception: minio target notes the shared adapter as the single access path, when `HAS_SHARED_LIBRARY` + `HAS_MINIO`).
- ❌ `testing.md` / `coding.md` unless the target ships application code.
- ❌ `tmp/` and `docs/.claude/`.

> The product feature catalog and UI/UX pack **are** read (Step 1 §7 + §8) — but only the slices this infra layer physically serves. `[x]`-only rule still applies.

### Step 1 — read every binding input

1. Template: [`TEMPLATE-infra.md`](TEMPLATE-infra.md).
2. **Repo config tree — if present.** `docker-compose*.yml`, `config/`, `*.conf`, `migrations/` (postgresql), bucket policy (minio), `topics.yaml` (kafka), `nginx.conf` (nginx), `meilisearch.yaml`, observability YAML. Every one conditional — skip silently if missing.
3. Existing PRD-TDD: `<repo>/docs/v<N>/PRD-TDD.md`.
4. Workspace-root onboarding.
5. Architecture: `tech/docs/project-architecture/v<N>.md` §5 + §5.6 + §5.7 (when declared) + §8.
6. Infra-relevant standards: `infrastructure.md` (primary), `security-and-auth.md`, `errors-and-observability.md`, `ci-cd.md`, `documentation.md`, plus `api-and-data-contracts.md` for the nginx target.
7. **Product feature catalog — full end-to-end read** (all sections + v`<N>` Selection Summary); tag both `[x]` and `[ ]`. `[x]` items whose delivery crosses this layer feed the scope table below; `[ ]` items feed §2.4 out-of-scope with a re-open trigger. Per-role selection derived from repo suffix:
   - **postgresql** — items hitting `<service>__*` tables. Signal: growth + retention per prefix.
   - **redis** (when `HAS_REDIS`) — counters + caches. Signal: namespace + TTL class.
   - **minio** (when `HAS_MINIO`) — media + backup targets. Signal: per-bucket growth + variant count.
   - **meilisearch** (when `HAS_MEILISEARCH`) — search + normalization (when `LOCALE_MODE = farsi-only OR bilingual`). Signal: index size + reindex rate.
   - **kafka** (when `HAS_KAFKA`) — day-one consumer flows from architecture §5.3. Signal: topic count + throughput + DLQ pairs.
   - **nginx** — every user-facing route + TLS / headers + CDN origin (when `CDN_PROVIDER`). Signal: per-host / per-path RPS + rate tier.
   - **observability** — operations items + every service's SLO surface. Signal: scrape targets + log volume.

   `[ ]` items go into §2.4 (Out of scope — v`<N>`) with a re-open trigger.
8. **UI/UX pack — routing signal only.** `product/docs/uiux/v<N>/design-system/design-system.md` once (font-hosting posture load-bearing for the nginx repo), then any existing `<page>/` mockups this layer serves (conditional). Extract hostname / path / cache class / rate class / origin binding only — never colours, components, or copy.
9. Consumer-side reads per target: schema slices for postgresql, key sections for redis, bucket owners for minio, `SEARCH_OWNER` only for meilisearch, §7 sections for kafka (this repo's own PRD-TDD is the binding topic registry), §9 + §12 + discovered frontends' upstream/CSP sections for nginx, SLO/logging sections for observability.

   **Extract aggregate signal, never enumerate** — count, growth rate, retention class, naming-shape compliance, criticality. More than ~3 examples of any consumer-side artifact means you copied too much.

### Step 2 — derive the infrastructure profile

- `service_slug` — `<repo>` minus `infra-` / `devops-` prefix.
- `default_branch = DEFAULT_BRANCH`.
- `role` — one line derived from suffix + architecture §5.
- `single_owner_invariants` — quote verbatim from architecture.
- `consumers` — pair list (every backend for postgresql / redis / kafka / observability; `SEARCH_OWNER` only for meilisearch; frontends only for nginx).
- `naming_contract` — the binding shape this infra owns.
- `capacity_assumptions` — declared numbers (per architecture §8 `VM_LAYOUT_DESCRIPTION`).
- `existing_alternatives_open_questions` — preserved on `merge`.

### Step 3 — compose

Walk [`TEMPLATE-infra.md`](TEMPLATE-infra.md) — nine sections; per-section rules per the template's own concision mandate. Deliberately omitted: Configuration key list (→ `<repo>/config/`), Threat model (→ security team), Decision log (→ `<repo>/docs/v<N>/adr/`), Changelog (→ `git log`).

### Step 4 — write

Output: `<repo>/docs/v<N>/PRD-TDD.md`. `merge` = `[§1–§8 fresh] ∪ [§9 verbatim]`. `overwrite` = full replacement.

### Step 5 — report

Same shape as `prd-tdd-backend`. End with `/mr open <repo>`.

### Related skills

- [[mr]] — ship it.
- [[audit]] — cross-corpus audit after authoring.
- [[implement]] — generate the config + Docker Compose + init scripts + operational assets for the target infra repo from this PRD-TDD.

---

## prd-tdd-frontend

Compose a full, binding `docs/v<N>/PRD-TDD.md` for one discovered `tech/frontend-*` repo — 26 sections — following [`TEMPLATE-frontend.md`](TEMPLATE-frontend.md). Two canonical shapes: `landing` (SSG at `PUBLIC_DOMAIN`) and `dashboard` (SPA at `APP_DOMAIN`, hosting every editorial + admin surface). Shape decided by repo-name suffix and confirmed against architecture §4 + §1.2. Reserved-slot frontends (e.g. `frontend-platform-admin`) are handled the same way.

### Argument

`<repo>::<mode>` where:

- `<repo>` — one of the discovered `tech/frontend-*` repos.
- `<mode>` — `merge` (preserve §22 Decision log verbatim) | `overwrite`.

Refuse and stop if:

- argument missing or `<repo>` not in the discovered frontend list,
- `<repo>` is a `tech/backend-*` (use `prd-tdd-backend` / `prd-tdd-library`) or `tech/infra-*` / `tech/devops-*` (use `prd-tdd-infra`),
- `<mode>` missing or not `merge` | `overwrite`.

### Hard rules

- Read first, write last. Standards linked, not duplicated — `tech/docs/standards/frontend.md` + `tech/docs/standards/frontend-layout.md` are primary.
- **Only `[x]` features** — landing binds the reader-facing rows, dashboard the editorial / admin rows; the architecture §2 map resolves shared rows; deferred sections (entirely `[ ]` in this workspace) feed §24 only.
- **Consumed API contracts come from the backend PRD-TDDs**, never invented.
- **Locale posture is load-bearing** per `LOCALE_MODE`. When `farsi-only`: `<html lang="fa" dir="rtl">`, no i18n runtime, strings in `src/copy/`. Persian numerals + Jalali dates on human surfaces (when `CALENDAR = jalali` and `DIGIT_RULES = persian-human-ascii-machine`); ASCII digits + ISO-8601 Gregorian on machine feeds. **Never auto-convert.**
- **Block tree is the only authoring model** when `BLOCK_EDITOR = true` — dashboard editor pinned in the doc; the landing renderer consumes the same tree; HTML / Markdown are render output only.
- **Font / captcha posture from architecture.** Self-hosted fonts per `LOCALE_MODE` + `MARKET_GEOGRAPHY`. Captcha per `CAPTCHA_PROVIDER`; first-party analytics via the analytics-owner service. No Google origin when architecture declares an Iran-market posture.
- **`merge` preserves §22.**
- No `Co-Authored-By:`; no derived-artifact refs; no money mentions when `PSP_PROVIDER` is unset.

### What NOT to read

- ❌ Backend PRD-TDDs §7 Kafka, §8 Database schema, §10 Configuration — only §9 API endpoints + §11 error-code rows matter for the frontend.
- ❌ Infra/devops PRD-TDDs beyond what's needed to know the routing shape.
- ❌ Deferred catalog sections beyond scoping §24.
- ❌ `tmp/` and `docs/.claude/`.

### Step 1 — read every binding input

1. Template: [`TEMPLATE-frontend.md`](TEMPLATE-frontend.md).
2. Repo onboarding if present (bootstrap-state repos ship only a stub `README.md`).
3. Existing PRD-TDD: `<repo>/docs/v<N>/PRD-TDD.md`.
4. `<repo>/src/`, `<repo>/package.json`, `<repo>/tsconfig.json` if present.
5. Workspace-root onboarding.
6. Architecture: `tech/docs/project-architecture/v<N>.md` §1.2 + §4 + §6.
7. Frontend-relevant standards (read in full): `frontend.md`, `frontend-layout.md`, `api-and-data-contracts.md`, `security-and-auth.md`, `errors-and-observability.md`, `coding.md` (frontend section + calendar section when `CALENDAR = jalali` + block-tree section when `BLOCK_EDITOR = true`), `ci-cd.md` (frontend CI + contract-drift job), `testing.md`.
8. Feature catalog — full end-to-end: `product/docs/features/v<N>/all-features.md` — every section + v`<N>` Selection Summary. Tag three lenses — owned end-to-end by this repo · consumed from sibling · out-of-scope; `[ ]` → §24.
9. UI/UX pack — narrow to this repo's surface ONLY:
   - Always: `product/docs/uiux/v<N>/design-system/design-system.md` + its HTML twin (if present) + brand assets under `business/docs/brand/`.
   - Per-shape mockup — exactly one, never both: landing → `product/docs/uiux/v<N>/landing/` (only); dashboard → `product/docs/uiux/v<N>/system/` (only). Cross-shape reads forbidden. Absent target → §17 gap.
10. Sibling frontend PRD-TDD — surgical read of shared-contract sections only (§9, §10, §11, §17, §18). Never read sibling's mockups or feature scope. If contradicts `frontend.md`, `frontend.md` wins.
11. Consumed backend PRD-TDDs — §1, §2, §9, §11, §12, §13 of each. Landing: reader-serving backends per architecture §2 map. Dashboard: every backend the dashboard exposes a surface for.

### Step 2 — derive the frontend profile

- `service_slug` — `<repo>` minus `frontend-`.
- `default_branch = DEFAULT_BRANCH`.
- `shape` — `landing` | `dashboard`.
- `hostname` — `PUBLIC_DOMAIN` (landing) | `APP_DOMAIN` (dashboard).
- `build_mode` — per architecture §4.
- `personas_served` — `{ PUBLIC }` (landing) or the authenticated subset of `ROLE_LIST` (dashboard).
- `owned_feature_catalog_sections` — `(§n, title)` triples.
- `consumed_backends` — `<service>` with `(base_url_env_var, endpoint_families_used_summary)`.
- `env_var_prefix` — `PUBLIC_` (landing SSG) | `VITE_` (dashboard SPA) per build-mode.
- `csp_connect_src` — backend hosts + captcha endpoint (when `CAPTCHA_PROVIDER`).
- `existing_decision_log` — preserved on `merge`.

### Step 3 — compose

Walk [`TEMPLATE-frontend.md`](TEMPLATE-frontend.md). Section-by-section rules are codified in the command file [`/docs prd-tdd-frontend`](../../commands/docs.md) §Step 3.

Shape-specific composition notes:

- **§11 (Auth)** — landing: none (any draft-preview route is token-gated, not session-gated). Dashboard: HTTP-only cookie + silent refresh; sidebar driven by the cross-service admin-role registry (JSONB on `<AUTH_OWNER>__users`, **UI hint only**, synced via `<service>-<AUTH_OWNER>-admin-role-sync` events when `HAS_KAFKA`); tabs lazy-fetch `GET /<service>/me/permissions`; JWT carries no role claims; the owning service re-checks per gated call.
- **§13 (i18n & RTL)** — per `LOCALE_MODE`. When `farsi-only`: no i18n runtime; logical CSS; `Intl.NumberFormat('fa-IR')` + date-fns-jalali on human surfaces (when `CALENDAR = jalali`); ASCII + ISO-8601 on machine feeds; `Asia/Tehran` time zone. When `bilingual`: peer parity, path-prefixed URLs. When `latin-only`: `<html lang="en" dir="ltr">`.
- **§10.3** — one `openapi-typescript` client per consumed service (`src/lib/api/generated/` landing / `src/shared/api/generated/` dashboard).
- **§16 (SEO)** — landing-deep (JSON-LD, OG + Twitter Card, canonical, per-market embed hints; sitemap / RSS served by `CONTENT_OWNER`, linked not re-emitted). Dashboard: one paragraph — `noindex, nofollow` everywhere.
- **§18 (CSP)** — captcha (when `CAPTCHA_PROVIDER`) is typically the only non-`self` script origin. No third-party analytics origin ever.

### Step 4 — write

Output: `<repo>/docs/v<N>/PRD-TDD.md`. `merge` splice: `[§1–§21 fresh] ∪ [§22 verbatim] ∪ [§23–§26 fresh; §26 prepends today's row]`.

### Step 5 — report

End with `/mr open <repo>`.

### Related skills

- [[mr]] — ship it.
- [[audit]] — cross-corpus audit after authoring.
- [[implement]] — implement the routes / composites / tests this PRD-TDD declares.
