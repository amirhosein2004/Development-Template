# {{PROJECT_NAME}} v{{N}} — Architecture

Authoritative high-level architecture for v{{N}}: {{OWNER_TERM}}s, features each {{OWNER_TERM}} owns, and the fixed stack (backend, frontend, infrastructure).

Version-agnostic standards live in [`../standards/`](../standards/). Per-{{OWNER_TERM}} implementation details live in each {{OWNER_TERM}}'s own `docs/v{{N}}/PRD-TDD.md`.

The planning artifact that seeds this document is [`../../../product/docs/tech-plan/v{{N}}-architecture.md`](../../../product/docs/tech-plan/v{{N}}-architecture.md); product identity lives in [`../../../product/docs/product.md`](../../../product/docs/product.md). Every framework, library, infrastructure component, and naming convention named here is **fixed for v{{N}}**. Disagreements are resolved by editing this document — not by drift in the code.

{{POSITIONING}}

---

## 1. {{#IF ARCH_SHAPE=microservices}}Service{{/IF}}{{#IF ARCH_SHAPE=monolith}}Repository{{/IF}}{{#IF ARCH_SHAPE=hybrid}}Service{{/IF}} map

{{#IF ARCH_SHAPE=microservices}}
{{BACKEND_REPO_COUNT}} backend {{OWNER_TERM}}s + {{FRONTEND_REPO_COUNT}} frontends + {{INFRA_REPO_COUNT}} infra {{OWNER_TERM}}s behind a single nginx edge. Both frontends and every backend {{OWNER_TERM}} sit behind the single nginx edge — no other ingress.

```
            ┌──────────────────────────────────────────┐
            │                  nginx                   │
            │  (single edge — fronts EVERYTHING:       │
            │   {{PUBLIC_DOMAIN}}, {{APP_DOMAIN}},     │
            │   internal REST{{#IF HAS_WEBSOCKET}}, WebSocket/SSE{{/IF}}{{#IF CDN_PROVIDER}}, behind {{CDN_PROVIDER}} CDN{{/IF}})  │
            └─────┬───────────────────────────────┬────┘
                  │ static / SSG upstream         │ internal HTTP
                  ▼                               ▼
        ┌─────────────────┐         ┌──────────────────────────────────┐
        │ frontend-       │         │ Backend microservices             │
        │  landing,       │         │ {{BACKEND_REPO_ONE_LINER}}        │
        │ frontend-       │         │                                   │
        │  {{ADMIN_SLUG}} │         │                                   │
        └─────────────────┘         └────────┬─────────────────────────┘
                                             │
                       ┌─────────────────────┼─────────────────────┐
                       ▼                     ▼                     ▼
                  PostgreSQL           {{#IF HAS_KAFKA}}Kafka{{#ELSE}}     (no broker){{/IF}}         {{#IF HAS_MINIO}}MinIO{{#ELSE}}     (no object store){{/IF}}
                 (per-{{OWNER_TERM}} DB)      {{#IF HAS_KAFKA}}(single broker){{/IF}}        {{#IF HAS_MINIO}}(per-{{OWNER_TERM}} buckets){{/IF}}
                       │                     │
                       ▼                     ▼
                  {{#IF HAS_REDIS}}Redis{{#ELSE}}(no cache){{/IF}}              {{#IF HAS_MEILISEARCH}}Meilisearch{{#ELSE}}     (no search engine){{/IF}}
              {{#IF HAS_REDIS}}(per-{{OWNER_TERM}} namespace){{/IF}}   {{#IF HAS_MEILISEARCH}}({{OWNER_TERM}}-search-owned){{/IF}}
```
{{/IF}}
{{#IF ARCH_SHAPE=monolith}}
{{BACKEND_REPO_COUNT}} backend deployable (one FastAPI monolith with {{MODULE_COUNT}} internal modules) + {{FRONTEND_REPO_COUNT}} frontends + {{INFRA_REPO_COUNT}} infra repos behind a single nginx edge. Modularity lives inside `src/modules/`, not at the process boundary. This is a deliberate v{{N}} choice.

```
                     ┌──────────────────────────────────────────┐
                     │                  nginx                   │
                     │  (single edge — fronts EVERYTHING:       │
                     │   {{PUBLIC_DOMAIN}}, /api/v{{N}}/*,       │
                     │   admin sub-path{{#IF CDN_PROVIDER}}, behind {{CDN_PROVIDER}} CDN{{/IF}}) │
                     └─────┬────────────────┬────────────────┬───┘
                           │ static         │ static         │ /api/v{{N}}/*
                           ▼                ▼                ▼
                  ┌────────────────┐ ┌──────────────┐ ┌──────────────────┐
                  │ frontend-      │ │ frontend-    │ │ backend-monolithic│
                  │  landing       │ │  {{ADMIN_SLUG}} │ │ (FastAPI)         │
                  │ (Astro SSG)    │ │ (React SPA)  │ │  {{MODULE_COUNT}} modules:       │
                  │                │ │              │ │  {{MODULE_ONE_LINER}}    │
                  └────────────────┘ └──────────────┘ └────────┬─────────┘
                                                               │
                                                ┌──────────────┴──────────────┐
                                                ▼                              ▼
                                           PostgreSQL                       {{#IF HAS_MINIO}}MinIO{{#ELSE}}(no object store){{/IF}}
                                        (one database,                {{#IF HAS_MINIO}}(one bucket per{{/IF}}
                                        module tables                 {{#IF HAS_MINIO}} media purpose){{/IF}}
                                        `<module>__<table>`)
```
{{/IF}}
{{#IF ARCH_SHAPE=hybrid}}
{{BACKEND_REPO_COUNT}} backend {{OWNER_TERM}}s — a monolithic core plus split-out {{OWNER_TERM}}s for the workloads whose scale or ownership demanded separation — + {{FRONTEND_REPO_COUNT}} frontends + {{INFRA_REPO_COUNT}} infra repos behind a single nginx edge. Both frontends and every backend {{OWNER_TERM}} sit behind the single nginx edge — no other ingress.

```
            ┌──────────────────────────────────────────┐
            │                  nginx                   │
            │  (single edge — fronts EVERYTHING:       │
            │   {{PUBLIC_DOMAIN}}, {{APP_DOMAIN}},     │
            │   internal REST{{#IF CDN_PROVIDER}}, behind {{CDN_PROVIDER}} CDN{{/IF}})  │
            └─────┬───────────────────────────────┬────┘
                  │ static / SSG upstream         │ internal HTTP
                  ▼                               ▼
        ┌─────────────────┐         ┌──────────────────────────────────┐
        │ frontend-       │         │ Backend                           │
        │  landing,       │         │  • backend-monolithic (core)      │
        │ frontend-       │         │  • split-out services:            │
        │  {{ADMIN_SLUG}} │         │    {{SPLIT_SERVICES_ONE_LINER}}   │
        └─────────────────┘         └────────┬─────────────────────────┘
                                             │
                       ┌─────────────────────┼─────────────────────┐
                       ▼                     ▼                     ▼
                  PostgreSQL           {{#IF HAS_KAFKA}}Kafka{{#ELSE}}     (no broker){{/IF}}         {{#IF HAS_MINIO}}MinIO{{#ELSE}}     (no object store){{/IF}}
                 (shared for core;      {{#IF HAS_KAFKA}}(single broker){{/IF}}        {{#IF HAS_MINIO}}(per-owner buckets){{/IF}}
                  per-{{OWNER_TERM}} DB otherwise)
                       │                     │
                       ▼                     ▼
                  {{#IF HAS_REDIS}}Redis{{#ELSE}}(no cache){{/IF}}              {{#IF HAS_MEILISEARCH}}Meilisearch{{#ELSE}}     (no search engine){{/IF}}
              {{#IF HAS_REDIS}}(per-{{OWNER_TERM}} namespace){{/IF}}   {{#IF HAS_MEILISEARCH}}({{OWNER_TERM}}-search-owned){{/IF}}
```
{{/IF}}

{{#IF CDN_PROVIDER}}{{CDN_PROVIDER}} sits in front of nginx at the DNS layer for the public read path.{{/IF}}

### 1.1 Backend {{OWNER_TERM}}s

| {{#IF ARCH_SHAPE=monolith}}Module{{#ELSE}}{{OWNER_TERM}}{{/IF}} | Scope | Details |
|---|---|---|
{{#EACH BACKEND_REPOS}}
| **{{this.name}}** | {{this.role}}{{#IF this.owns}} — owns {{this.owns}}{{/IF}} | [`{{this.name}}/docs/v{{N}}/PRD-TDD.md`](../../../{{this.name}}/docs/v{{N}}/PRD-TDD.md) |
{{/EACH}}

{{#IF HAS_SHARED_LIBRARY}}
`{{SHARED_LIBRARY_NAME}}` is a **library, not a {{OWNER_TERM}}** — distributed as a pinned git-tag package (see §7.2 "Shared-logic version lock"). It carries the cross-cutting primitives every backend imports: {{#IF CALENDAR=jalali}}Jalali calendar (storage primitive + boundary rule "human layer Jalali / Persian digits, machine layer ISO-8601 / ASCII"), {{/IF}}{{#IF LOCALE_MODE=farsi-only OR LOCALE_MODE=bilingual}}ZWNJ / normalization utilities, {{/IF}}`DbAction` raw-asyncpg base, JWT verifier (RS256 public key only){{#IF HAS_MINIO}}, MinIO adapter{{/IF}}{{#IF HAS_KAFKA}}, Kafka producer / consumer bases{{/IF}}{{#IF HAS_REDIS}}, Redis wrapper{{/IF}}, OTel bootstrap, structured logger{{#IF OTP_PROVIDER}}, {{OTP_PROVIDER}} SMS client{{/IF}}.
{{/IF}}

### 1.2 Frontends

| Repo | Domain | Stack | Details |
|---|---|---|---|
{{#EACH FRONTEND_REPOS}}
| `{{this.name}}` | `{{this.domain}}` | {{this.stack}} | [`{{this.name}}/docs/v{{N}}/PRD-TDD.md`](../../../{{this.name}}/docs/v{{N}}/PRD-TDD.md) |
{{/EACH}}

All frontends produce static output served by the platform nginx. No Node at the edge, no server logic in any of these repos.

### 1.3 Per-{{OWNER_TERM}} ownership rules

{{#IF ARCH_SHAPE=microservices}}
- Each {{OWNER_TERM}} owns its database (one DB per {{OWNER_TERM}}, one logical PostgreSQL cluster in v{{N}}). **No cross-{{OWNER_TERM}} SQL, no cross-{{OWNER_TERM}} foreign keys.** Tables `<{{OWNER_TERM}}>__<table>` (double underscore).
{{/IF}}
{{#IF ARCH_SHAPE=monolith}}
- Each module owns its Postgres tables inside the shared database using the `<module>__<table>` naming discipline (double underscore). No cross-module foreign keys; integrity across modules is enforced at the service layer. Modules never call each other's `DbAction` directly — cross-module work goes through the target module's service class.
{{/IF}}
{{#IF ARCH_SHAPE=hybrid}}
- The monolithic core owns tables `core__<table>`. Each split-out {{OWNER_TERM}} owns its own database with tables `<{{OWNER_TERM}}>__<table>` (double underscore). No cross-{{OWNER_TERM}} SQL, no cross-{{OWNER_TERM}} FKs; integrity across the boundary is enforced at the service layer or via {{#IF HAS_KAFKA}}Kafka mirror-table sync{{#ELSE}}synchronous REST{{/IF}}.
{{/IF}}
{{#IF HAS_REDIS}}
- Each {{OWNER_TERM}} owns its Redis namespace — keys are prefixed `<{{OWNER_TERM}}>:…`; two {{OWNER_TERM}}s never share keys. Redis is **caching and short-lived counters only** — never a broker, never a queue{{#IF HAS_KAFKA}} (Kafka owns async){{/IF}}. Anything in Redis must be reconstructible from Postgres{{#IF HAS_KAFKA}} + Kafka{{/IF}}.
{{/IF}}
{{#IF HAS_MINIO}}
- Each {{OWNER_TERM}} owns its MinIO bucket(s) — bucket names start with `<{{OWNER_TERM}}>-` (S3-compatible: lowercase, digits, dashes; **no underscores**). All bucket access goes through the shared MinIO adapter{{#IF HAS_SHARED_LIBRARY}} in `{{SHARED_LIBRARY_NAME}}`{{/IF}}, under a per-{{OWNER_TERM}} access key scoped to that {{OWNER_TERM}}'s bucket family.
{{/IF}}
- Each {{OWNER_TERM}} owns its RBAC tables: `<{{OWNER_TERM}}>__roles` (role definitions — read-only at runtime, seeded from code, PK is `name`) and `<{{OWNER_TERM}}>__user_roles` (sparse assignments — users on the default role have no row). One role per user per {{OWNER_TERM}}.
- Each {{OWNER_TERM}} owns its configuration table (`<{{OWNER_TERM}}>__configurations`, PK is `key`) — the canonical store for that {{OWNER_TERM}}'s runtime, admin-tunable settings. Rows are seeded from code; admin can read and update `value` and `description`, but cannot change `key` and cannot create or delete rows. Runtime DB grant is exactly `SELECT, UPDATE (value, description)`.

---

## 2. Feature → {{OWNER_TERM}} map

Every `[x]` feature in [`../../../product/docs/features/v{{N}}/all-features.md`](../../../product/docs/features/v{{N}}/all-features.md) belongs to exactly one {{OWNER_TERM}} (or to a frontend). Items marked `[ ]` are out of scope and not assigned.

{{#EACH FEATURE_DIMENSIONS}}
### 2.{{this.index}} {{this.title}}

| Feature | {{OWNER_TERM}} |
|---|---|
{{#EACH this.rows}}
| {{this.feature}} | {{this.owner}} |
{{/EACH}}

{{/EACH}}

---

## 3. Backend stack — fixed for v{{N}}

| Concern | Pinned choice |
|---|---|
| Language | Python 3.13 |
| Web framework | FastAPI |
| ASGI server | Uvicorn + uvloop + httptools |
| Package manager | uv (`pyproject.toml` + `uv.lock`) |
| Validation | Pydantic v2 + pydantic-settings |
| JSON serialiser | orjson |
| Database | PostgreSQL 17 (Docker: `postgres:17.10-bookworm`) |
| DB driver | asyncpg (async) |
| ORM | None — raw parameterised SQL via `DbAction`{{#IF HAS_SHARED_LIBRARY}} in `{{SHARED_LIBRARY_NAME}}`{{/IF}} |
| Migrations | Alembic with raw SQL only (no model autogeneration) |
{{#IF HAS_REDIS}}
| Cache | Redis (per-{{OWNER_TERM}} namespace; see §5.2) — Docker: `redis:7.4-bookworm`, `maxmemory 256mb`, `maxmemory-policy noeviction` |
{{/IF}}
{{#IF HAS_KAFKA}}
| Message broker | Apache Kafka (single cluster; see §5.3) — KRaft mode (no ZooKeeper), image pinned `apache/kafka:4.0.0` |
{{#ELSE}}
| Message broker | **None in v{{N}}.** Cross-{{OWNER_TERM}} coordination is synchronous; post-response side effects run as `starlette.BackgroundTasks` for lightweight work or a persistent `outbox` table drained by a single in-process worker for durable work. |
{{/IF}}
{{#IF HAS_MINIO}}
| Object storage | MinIO (S3-compatible) via the shared adapter — see §5.4 |
{{/IF}}
{{#IF HAS_MEILISEARCH}}
| Search engine | Meilisearch{{#IF SEARCH_OWNER}} (owned by `{{SEARCH_OWNER}}`){{/IF}} — image pinned `getmeili/meilisearch:v1.15`; see §5.5 |
{{/IF}}
| JWT library | PyJWT |
| JWT algorithm | **RS256** (asymmetric: `{{AUTH_OWNER}}` holds the private key, every other {{OWNER_TERM}} holds the public key) |
| Password / OTP hashing | bcrypt via passlib |
| HTTP client (async) | httpx |
| ID generation | ULID via python-ulid (stored as `VARCHAR(50)`) |
| Container base | `python:3.13-slim-bookworm` |
{{#IF HAS_SHARED_LIBRARY}}
| Shared internal library | `{{SHARED_LIBRARY_NAME}}` (private GitLab repo, pinned by tag — version-lock CI gate in §7.2) |
{{/IF}}
| Linter / formatter | Ruff |
| Type checker | mypy |
| Test runner | pytest + pytest-asyncio + pytest-cov (coverage floor: **≥ {{BE_COVERAGE_FLOOR}}%**, ratchets up, never down) |
| Pre-commit | pre-commit |
| OpenTelemetry SDK | opentelemetry-distro + opentelemetry-exporter-otlp |
| Logger | python-json-logger (structured JSON to stdout) |
{{#IF CALENDAR=jalali}}
| Jalali library | Custom module{{#IF HAS_SHARED_LIBRARY}} in `{{SHARED_LIBRARY_NAME}}`{{/IF}} (see §7.4 "Locked decision — Jalali as storage primitive") |
{{#ELSE}}
| Calendar | Gregorian (`Intl.DateTimeFormat` for machine surfaces; date-fns for human surfaces) |
{{/IF}}
{{#IF OTP_PROVIDER}}
| SMS provider | {{OTP_PROVIDER}}{{#IF HAS_SHARED_LIBRARY}} (v{{N}} client lives in `{{SHARED_LIBRARY_NAME}}`; migrates to `backend-notification` when that {{OWNER_TERM}} materializes){{/IF}} |
{{/IF}}
{{#IF CAPTCHA_PROVIDER}}
| Captcha | {{CAPTCHA_PROVIDER}} (server-side verify) |
{{/IF}}
{{#IF CDN_PROVIDER}}
| CDN | {{CDN_PROVIDER}} — pluggable behind a single `CdnAdapter` interface (see §7.3) |
{{/IF}}
{{#IF PSP_PROVIDER}}
| Payment provider | {{PSP_PROVIDER}} — pluggable behind a per-provider PSP adapter inside `backend-finance` |
{{/IF}}

---

## 4. Frontend stack — fixed for v{{N}}

Cross-cutting choices shared by every frontend. Each repo's framework / build mode and per-library detail live in its own `docs/v{{N}}/PRD-TDD.md`.

### 4.1 Shared across every frontend

| Concern | Pinned choice |
|---|---|
| Language | TypeScript, strict |
| Typed API client | openapi-typescript (generated per {{OWNER_TERM}} from OpenAPI) |
{{#IF LOCALE_MODE=farsi-only}}
| Copy / language | Farsi-only, no i18n runtime. `<html lang="fa" dir="rtl">`. User-facing strings in `src/copy/`. |
{{/IF}}
{{#IF LOCALE_MODE=bilingual}}
| Copy / language | Bilingual by parity — Persian (fa, RTL) + English (en, LTR) as peers. Path-prefixed URLs (`/fa/...`, `/en/...`), `<html lang="{fa|en}" dir="{rtl|ltr}">` set at build time. Never translate — every page is authored per locale. |
{{/IF}}
{{#IF LOCALE_MODE=latin-only}}
| Copy / language | English-only, no i18n runtime. `<html lang="en" dir="ltr">`. User-facing strings in `src/copy/`. |
{{/IF}}
{{#IF LOCALE_MODE=farsi-only OR LOCALE_MODE=bilingual}}
| Fonts | Self-hosted Vazirmatn (UI) + JetBrains Mono (numerals / code) — woff2 in-repo, loaded via local `@font-face`. **No third-party CDNs** (Google Fonts blocked / unreliable inside Iran; any dependency that would cause the frontend to fetch from origins outside the project's own servers must be flagged). |
{{#ELSE}}
| Fonts | Self-hosted woff2 in `public/fonts/`, loaded via local `@font-face`. No third-party font CDNs. |
{{/IF}}
{{#IF CALENDAR=jalali}}
| Calendar | date-fns-jalali (human surfaces); native `Intl.DateTimeFormat` for machine feeds only when necessary. |
{{#ELSE}}
| Calendar | date-fns; native `Intl.DateTimeFormat` for machine feeds. |
{{/IF}}
{{#IF DIGIT_RULES=persian-human-ascii-machine}}
| Number formatting | `Intl.NumberFormat('fa-IR')` on human surfaces (Persian digits); ASCII digits in machine feeds (JSON-LD, sitemap, RSS `pubDate`, API payloads, HTTP headers, `datetime` attribute of `<time>` tags). Never auto-convert. |
{{/IF}}
{{#IF DIGIT_RULES=ascii-everywhere}}
| Number formatting | `Intl.NumberFormat` per locale; ASCII digits throughout. |
{{/IF}}
| Testing — unit | Vitest + React Testing Library (coverage floor: **≥ {{FE_COVERAGE_FLOOR}}%**) |
| Testing — E2E | Playwright |
| Package manager | pnpm |
| Linter / formatter | ESLint + Prettier |

---

## 5. Infrastructure — fixed for v{{N}}

Each infra component's run-time configuration, naming-convention catalog, and topic / bucket / key listings live in its infra repo's `docs/v{{N}}/PRD-TDD.md`. The cross-cutting contract each {{OWNER_TERM}} must follow is stated here. Components without an image pin in §3 require an exact-tag image pin recorded in their repo's compose file at scaffold time; **never `latest`**.

| Concern | Pinned choice | Details |
|---|---|---|
{{#EACH INFRA_REPOS}}
| {{this.role}} | {{this.stack}} | [`{{this.name}}/docs/v{{N}}/PRD-TDD.md`](../../../{{this.name}}/docs/v{{N}}/PRD-TDD.md) |
{{/EACH}}

{{#IF HAS_OBSERVABILITY_STACK}}
### 5.1 Observability — fixed stack

Single infra repo (`infra-observability`) for the whole stack. Per-component runtime config lives in that repo's PRD-TDD.

| Component | Role |
|---|---|
| Grafana | Single UI for logs, metrics, traces, alerts |
| Loki | Log store (label-indexed) |
| Promtail | Reads container stdout and ships to Loki |
| Prometheus | Metrics scraping + alert-rule evaluation |
| Tempo | Traces store |
| Alertmanager | Routes alerts to Telegram / Slack |
| OTel Collector | Single ingestion point for metrics + traces |
| Prometheus blackbox exporter | Uptime probes (health endpoints, TCP checks, TLS expiry) |

Public status page is out of scope in v{{N}}. Uptime is monitored internally only. **No alert is fired from app code** — every rule is a Loki ruler / Prometheus rule evaluated inside this layer.
{{/IF}}

{{#IF HAS_REDIS}}
### 5.2 Redis — read caches and short-lived counters

Caching only. Never a broker, never a queue{{#IF HAS_KAFKA}} (Kafka owns that per §5.3){{/IF}}. v{{N}} uses:

- Rate-limit counters ({{AUTH_OWNER}}{{#IF ENGAGEMENT_OWNER}}, {{ENGAGEMENT_OWNER}}{{/IF}}).
{{#IF OTP_PROVIDER}}
- OTP TTL + resend throttle ({{AUTH_OWNER}}).
{{/IF}}
- Render cache for computed derivations{{#IF CONTENT_OWNER}} ({{CONTENT_OWNER}}){{/IF}}.
{{#IF HAS_CONTENT_BUCKET}}
- **Redirect + slug-history read cache** (see §7.1).
{{/IF}}

Everything in Redis must be reconstructible from Postgres{{#IF HAS_KAFKA}} + Kafka{{/IF}}; **RPO = 0 by construction**.
{{/IF}}

{{#IF HAS_KAFKA}}
### 5.3 Kafka — day-one flows

Topic naming: `<sender_{{OWNER_TERM}}>-<receiver_{{OWNER_TERM}}(s)>-<event>` — exactly one sender, one or more receivers; multi-receiver lists sorted alphabetically and joined by `_`. DLQ per source: `<source-topic>-dlq`. Priority by topic, not by message field.

Real day-one consumer flows in v{{N}}:

{{#IF HAS_SEARCH_INDEXER_FLOW}}
1. **search-indexer** — {{CONTENT_OWNER}} publishes publish/update/delete events; `{{SEARCH_OWNER}}` consumes and re-indexes. Replaces "call search on every save."
{{/IF}}
{{#IF HAS_WEBHOOK_FLOW}}
2. **webhook dispatcher** — {{CONTENT_OWNER}} publishes `webhook-triggered` events; a webhook-dispatch consumer delivers HMAC-signed payloads to consumer-configured URLs with retry / DLQ.
{{/IF}}
{{#IF HAS_AUDIT_FLOW}}
3. **audit-recorded sink** — every {{OWNER_TERM}} that owns admin-visible mutations publishes `<{{OWNER_TERM}}>-*-audit-recorded` events; the audit sink lives inside {{AUDIT_OWNER}} in its own audit table, keeping the cross-{{OWNER_TERM}} audit trail in one queryable place.
{{/IF}}
{{#IF HAS_ASSETS_PURGE_FLOW}}
4. **assets CDN purge** — the assets replace-in-place flow (§7.3) rides on Kafka so the editor's write path is not coupled to CDN uptime.
{{/IF}}

Plus the cross-{{OWNER_TERM}} admin-role registry stream (`<{{OWNER_TERM}}>-{{AUTH_OWNER}}-admin-role-sync`, see §6).
{{/IF}}

{{#IF HAS_MINIO}}{{#IF CDN_PROVIDER}}
### 5.4 Assets — CDN + storage

- **CDN:** {{CDN_PROVIDER}} in v{{N}}. Other providers are pluggable through a single `CdnAdapter` interface owned by the assets {{OWNER_TERM}}; each provider implements the same `purge(urls: list[str]) -> None` contract.
- **Storage backends:** MinIO in v{{N}} (via the shared adapter). Other providers pluggable through the same storage-adapter interface. See §7.3 for the replace-in-place contract.
{{/IF}}{{/IF}}

{{#IF HAS_MEILISEARCH}}
### 5.5 Search — Meilisearch

- Meilisearch runs as its own deployment (`infra-meilisearch`).
- `{{SEARCH_OWNER}}` is the only {{OWNER_TERM}} that talks to it; every other {{OWNER_TERM}} that needs search calls `{{SEARCH_OWNER}}`'s REST API.
{{#IF LOCALE_MODE=farsi-only OR LOCALE_MODE=bilingual}}
- **Persian normalization** (ZWNJ, ی/ي, ک/ك, diacritic fold, Persian → ASCII digit fold) runs in `{{SEARCH_OWNER}}` before indexing so the index carries normalized keys and the query wrapper does not have to re-normalize per request. Applied identically at index and query time.
{{/IF}}
- Elasticsearch is deliberately not in v{{N}}; escape hatch reserved for later if traffic profile forces it.
{{/IF}}

### 5.6 Configuration

- The platform has **four running environments**: `local` (developer laptops), `develop`, `staging`, `{{PROD_ENV_NAME}}`. `ENVS.ENVIRONMENT` carries one of those four values. Branches don't align one-to-one with environment names: `local` runs from any feature branch, the protected branch trio is `develop → staging → main`, and the `main` branch is what serves the `{{PROD_ENV_NAME}}` environment in production.
- `.env.example` is committed in every branch with placeholder values. On `develop` it doubles as the actual config used for develop-server deployment (placeholder values are the develop-server values).
- `staging` and `main` branches each have their own `.env` — never committed; injected from GitLab CI/CD variables at deploy time. The committed `.env.example` on those branches stays placeholders-only.
- No managed-cloud secret manager in v{{N}}.

### 5.7 Non-production access control

- `develop` and `staging` deployments are gated behind HTTP Basic auth at the nginx edge.
- Credentials live in `/etc/nginx/.htpasswd` on the host — out-of-band, never committed, injected via GitLab CI/CD variables at deploy time alongside `.env`. The same file gates every server block on those environments (every frontend + backend REST).
- Nginx snippet applied to every server block on `develop` / `staging`:

  ```nginx
  auth_basic "{{PROJECT_SLUG}}-develop";   # "{{PROJECT_SLUG}}-staging" on staging
  auth_basic_user_file /etc/nginx/.htpasswd;
  ```

- The `main` branch (which serves the `{{PROD_ENV_NAME}}` environment) carries no nginx-edge basic auth. Production-side crawler control lives {{#IF HAS_CONTENT_BUCKET}}inside `{{CONTENT_OWNER}}` (per-page `robots` meta emitted by `frontend-landing`, plus the site-settings-controlled `robots.txt`){{#ELSE}}in per-page `robots` meta plus `robots.txt`{{/IF}}. No `X-Robots-Tag` overrides needed on `{{PROD_ENV_NAME}}` beyond the per-page meta.

---

## 6. Authentication & authorization

Architectural summary; request-level rules live in [`../standards/security-and-auth.md`](../standards/security-and-auth.md).

- End users authenticate with JWT (**RS256**, algorithm code-pinned). `{{AUTH_OWNER}}` is the only {{OWNER_TERM}} holding the private key; every other {{OWNER_TERM}} holds the public key and verifies locally.
- Service-to-service authenticates with manually-rotated long-lived API keys (`Authorization: API_KEY <key>`).
- Roles are per-{{OWNER_TERM}}. Each {{OWNER_TERM}} owns its own role-definition table (`<{{OWNER_TERM}}>__roles`, read-only and seeded from code) and assignment table (`<{{OWNER_TERM}}>__user_roles`, sparse — default-role users have no row). One role per user per {{OWNER_TERM}}.
- **v{{N}} role registry — {{ROLE_COUNT}} roles.** {{ROLE_LIST}}
{{#IF ARCH_SHAPE=microservices OR ARCH_SHAPE=hybrid}}
- **Cross-{{OWNER_TERM}} admin-role registry.** `{{AUTH_OWNER}}` keeps a dictionary `{{OWNER_TERM}}: role_name` per user as a JSONB column on `{{AUTH_OWNER}}__users` (no separate table), populated via {{#IF HAS_KAFKA}}Kafka events (`<{{OWNER_TERM}}>-{{AUTH_OWNER}}-admin-role-sync`){{#ELSE}}synchronous REST calls{{/IF}} published by the owning {{OWNER_TERM}} whenever it grants or revokes an admin role. A `null` role means "demoted to default" and removes that {{OWNER_TERM}}'s key from the dictionary. Sync is eventually consistent. The registry is a **UI hint only** for the dashboard's admin sidebar; the receiving {{OWNER_TERM}} still re-checks against its own `<{{OWNER_TERM}}>__user_roles` on every gated call.
{{/IF}}
{{#IF ARCH_SHAPE=monolith}}
- **RBAC is single-service** (there is only one process). Every admin endpoint gates on the required permission set matched against `{{AUTH_OWNER}}__roles.permissions`.
- **Service-to-service authentication is not needed** — there is only one process. The dispatcher may separate the API process from a background worker, but both share the database directly.
{{/IF}}
- The JWT does not carry role / permission claims; role information is delivered alongside the user profile on the login response. Sidebar has one section per {{OWNER_TERM}} the user has any role in; tabs within a section are lazy-fetched from the owning {{OWNER_TERM}} via `GET /<{{OWNER_TERM}}>/me/permissions` on section click.

---

## 7. Cross-cutting decisions (load-bearing, versioned)

The load-bearing architectural decisions the architecture must honor. Repeated here so the document is self-contained.

{{#IF HAS_CONTENT_BUCKET}}{{#IF HAS_REDIS}}
### 7.1 Redirect + slug-history read path

Slug-history and the manual 301 / 302 redirect table both feed a lookup that runs on **every 404-shaped request** — a hot path. Hitting PostgreSQL for each miss is unacceptable at portal-scale traffic.

- `{{CONTENT_OWNER}}` owns the canonical tables (`{{CONTENT_OWNER}}__redirect_rules`, `{{CONTENT_OWNER}}__slug_history`) in PostgreSQL as source of truth.
- Redis holds the read cache: key = old path, value = `{new_path, status_code}`.
- Read flow on any inbound path that does not match a live entry:
  1. Look up Redis first. Hit → serve 301 / 302 immediately.
  2. Miss → PostgreSQL query, populate Redis with TTL (24h default), serve.
  3. No match → real 404.
- Write flow (any place that changes a slug or adds a redirect rule): PostgreSQL insert / update **and** Redis `SET` inside the same request, so the cache is always consistent going forward.

Nginx map-file was considered and rejected — it forces every redirect edit through a deploy or a file-push pipeline, which is heavier than the read-path win at v{{N}} scale.
{{/IF}}{{/IF}}

{{#IF ARCH_SHAPE=microservices}}{{#IF HAS_SHARED_LIBRARY}}
### 7.2 Shared-logic version lock

`{{SHARED_LIBRARY_NAME}}` distributes as a versioned library. Each downstream {{OWNER_TERM}} pins a version in its dependency manifest. Without a guard, {{OWNER_TERM}}s drift onto different versions of the same {{#IF CALENDAR=jalali}}Jalali / {{/IF}}JWT / SMS / OTel code and produce divergent behavior for the same input.

- Every backend {{OWNER_TERM}} repo runs a CI check on every MR: read the pinned `{{SHARED_LIBRARY_NAME}}` version from the manifest, compare against the latest tagged release, **fail the pipeline if the pin is not the current release** (policy in `ci-cd.md`).
- The release process for `{{SHARED_LIBRARY_NAME}}` opens an automated MR into each consumer repo bumping the pin, so the human step is "review + merge" per {{OWNER_TERM}}, not "remember to bump."
- Deploy order for a shared-logic change: cut the library release → merge the bump MR in every consumer → deploy consumers in any order.
- On-call playbook: if two {{OWNER_TERM}}s report the same shared-logic-owned behavior differently, first check pinned versions before opening a code investigation.

Turning `{{SHARED_LIBRARY_NAME}}` into an HTTP {{OWNER_TERM}} was rejected — {{#IF CALENDAR=jalali}}Jalali is a hot-path call (every render, every audit line){{#ELSE}}the shared primitives are hot-path calls{{/IF}}, and paying network latency for it is worse than the version-drift risk.
{{/IF}}{{/IF}}

{{#IF CDN_PROVIDER}}{{#IF HAS_KAFKA}}
### 7.3 CDN purge on replace-in-place

The **Replace-in-place** asset feature swaps the file behind a stable URL. Everything that referenced the old file — pages, RSS enclosures, JSON-LD `image` blocks — automatically points at the new content. But every CDN edge still serves the pre-swap bytes from cache until TTL expires. Without an active purge, editors see "the new image is up" while readers see the old one for hours.

- The assets {{OWNER_TERM}} defines a `CdnAdapter` interface with a single method: `purge(urls: list[str]) -> None`.
- {{CDN_PROVIDER}} is the v{{N}} implementation. Other providers implement the same interface when they are configured.
- The replace-in-place handler executes in this order inside a single transaction:
  1. Write the new bytes to object storage.
  2. Update the `asset` row (checksum, size, `updated_at`) in PostgreSQL.
  3. Emit an `asset.replaced` Kafka event with the affected URLs (canonical + all `srcset` / transform variants derived from that asset).
  4. A CDN-purge consumer reads the event, calls `CdnAdapter.purge(...)` with retries + DLQ on the source topic.
- Purge is **async** (via Kafka) rather than inline so a slow or flaky CDN API never blocks the editor's "save."
- The variant list is derived, not stored per-render: URL patterns (`?w=`, `?fmt=`, focal-point crops) are re-computed from the asset's public URL, so the purge covers every representation.
{{/IF}}{{/IF}}

### 7.4 Locked decisions the architecture must honor

{{#IF CALENDAR=jalali}}
1. **Jalali as storage primitive** — every {{OWNER_TERM}} that stores a date column stores the Jalali components (year / month / day) as the primary representation; Gregorian conversion happens only at the boundary of machine feeds (JSON-LD, sitemap, RSS, API payload). The rule is centralized{{#IF HAS_SHARED_LIBRARY}} in `{{SHARED_LIBRARY_NAME}}`'s `jalali_lib`{{/IF}} — else every {{OWNER_TERM}} will get it wrong differently.
{{/IF}}
{{#IF BLOCK_EDITOR}}
2. **Content body = JSON block tree** — the authoring model is typed blocks with typed inline marks, persisted as structured JSON. HTML and Markdown are **render output only**, generated at export time; they are never authoring input and never round-trip back into content. This is the contract between the content {{OWNER_TERM}}, `frontend-landing` (renderer), and every SDK.
{{/IF}}
{{#IF HAS_CONTENT_BUCKET}}
3. **schema-as-code is the sole source of truth** — content types (fields, validation, relations) are defined in Python code inside the content {{OWNER_TERM}}, typegen produces the frontend SDK; **no schema editing from the dashboard**. Admin users — including the Administrator role — cannot add / remove / rename fields via the UI. Schema changes ship via code review + migration, not runtime clicks.
{{/IF}}
{{#UNLESS PSP_PROVIDER}}
- **No monetization in v{{N}}.** No money columns, no PSP wiring, no wallet, no currency. Any migration that adds a money column is blocked at CI.
{{/UNLESS}}
- **No cross-{{OWNER_TERM}} FKs, no cross-{{OWNER_TERM}} SQL.** Reach another {{OWNER_TERM}} via REST{{#IF HAS_KAFKA}}, Kafka, or a mirror table{{/IF}}.
- **All timestamps are `TIMESTAMPTZ NOT NULL DEFAULT NOW()` in UTC.** Human display converts at the boundary.
- **ULID everywhere.** Stored as `VARCHAR(50)`, generated via python-ulid.
- **Envelope shape.** Every REST response is `{success, message, data}` per `api-and-data-contracts.md`.

---

## 8. Deployment topology

- One repo per {{OWNER_TERM}}. Container per {{OWNER_TERM}}. Local dev + production both run on Docker Compose. **No Kubernetes in v{{N}}.**
{{#IF ARCH_SHAPE=monolith}}
- **One VM in v{{N}}.** All processes co-locate: nginx + backend API + backend worker (same image, different `CMD`) + Postgres{{#IF HAS_MINIO}} + MinIO{{/IF}}{{#IF HAS_REDIS}} + Redis{{/IF}}{{#IF HAS_OBSERVABILITY_STACK}} + observability sidecars{{/IF}}. Only nginx has a public IP.
{{#ELSE}}
- **VM layout.** v{{N}} uses {{VM_LAYOUT_DESCRIPTION}}. A second (or third) VM is added only when a specific workload demonstrably needs it. Private network between VMs; nginx is the only one with a public IP.
{{/IF}}
- **Hosting.** {{MARKET_GEOGRAPHY}}.
- **Postgres HA.** Single primary + WAL archive to {{#IF HAS_MINIO}}MinIO{{#ELSE}}a cold VM{{/IF}} in v{{N}}; `pg_auto_failover` reserved for later.
- **Backups.** `pg_basebackup` + WAL archive{{#IF HAS_MINIO}} to MinIO{{/IF}} + nightly `pg_dumpall` snapshot rsynced to a cold VM at a different provider.
- **CI/CD.** GitLab CI/CD (the only sanctioned path to production).

---

## 9. Out of v{{N}}

Not in v{{N}}; the architecture leaves room. Reserved slots come from buckets with 0 `[x]` features in the current feature catalog.

{{#EACH DEFERRED_BUCKETS}}
- **{{this.name}}** — {{this.rationale}}{{#IF this.reserved_slot}} Reserved slot: {{this.reserved_slot}}.{{/IF}}
{{/EACH}}
{{#UNLESS DEFERRED_BUCKETS}}
- No dimension is fully deferred in v{{N}} — every product-catalog bucket has at least one `[x]` feature.
{{/UNLESS}}

Structural deferrals independent of feature scope:

- **Kubernetes.**
- **Public status page.**
- **Managed-cloud secret manager.**
{{#UNLESS HAS_KAFKA}}
- **Kafka.** Introduce when the first flow needs at-least-once, ordered, replayable delivery.
{{/UNLESS}}
{{#UNLESS HAS_REDIS}}
- **Redis.** Reintroduce if latency profiling justifies it; until then, rate-limit counters live at the edge (`limit_req_zone`) and per-worker TTL'd in-memory caches suffice.
{{/UNLESS}}

---

## 10. Glossary

Terms used here map 1:1 to the product feature catalog:

- **{{OWNER_TERM}}** — one of the units in §1.1{{#IF ARCH_SHAPE=microservices}} — an independently-deployed backend process{{/IF}}{{#IF ARCH_SHAPE=monolith}} — an internal folder under `src/modules/` inside the single backend deployable{{/IF}}{{#IF ARCH_SHAPE=hybrid}} — either an internal module inside `backend-monolithic` or a split-out {{OWNER_TERM}} with its own deployment{{/IF}}.
{{#IF TENANT_NOUN}}
- **{{TENANT_NOUN}}** — the containing tenant. v{{N}} is single-{{TENANT_NOUN}}; every table carries `{{TENANT_NOUN_SNAKE}}_id` for multi-tenancy insurance.
{{/IF}}
- **Login session** — the authenticated browser session attached to a JWT; owned by `{{AUTH_OWNER}}` in `{{AUTH_OWNER}}__login_sessions`.
- **Environment** — one of `local` / `develop` / `staging` / `{{PROD_ENV_NAME}}`, per §5.6.
{{#EACH BUCKET_GLOSSARY_ROWS}}
- **{{this.term}}** — {{this.definition}}
{{/EACH}}
