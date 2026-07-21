# {{#IF ARCH_SHAPE=monolith}}module{{#ELSE}}backend{{/IF}}-{{SERVICE_SLUG}} — PRD & TDD (v{{N}})

> Per-{{OWNER_TERM}} product requirements and technical design for the **{{SERVICE_SLUG}}** {{OWNER_TERM}}.
> Platform architecture: [`tech/docs/project-architecture/v{{N}}.md`](../../../docs/project-architecture/v{{N}}.md).
> Cross-cutting standards: [`tech/docs/standards/`](../../../docs/standards/). Do not duplicate them here — link or note deviations only.
> {{OWNER_TERM_PROPER}} layout: [`tech/docs/standards/{{#IF ARCH_SHAPE=microservices}}microservice-layout.md{{/IF}}{{#IF ARCH_SHAPE=monolith}}monolith-layout.md{{/IF}}{{#IF ARCH_SHAPE=hybrid}}microservice-layout.md{{/IF}}`](../../../docs/standards/{{#IF ARCH_SHAPE=microservices}}microservice-layout.md{{/IF}}{{#IF ARCH_SHAPE=monolith}}monolith-layout.md{{/IF}}{{#IF ARCH_SHAPE=hybrid}}microservice-layout.md{{/IF}}) is authoritative for the ring structure, the root dispatcher, and the per-role container shape.

---

## 1. TL;DR

<One paragraph (≤ 6 lines). Anyone — PM, engineer, on-call — should know after reading this paragraph: what this {{OWNER_TERM}} is (one of the {{BACKEND_COUNT}} {{PROJECT_NAME}} backend {{OWNER_TERM}}s — {{BACKEND_LIST_ONE_LINER}}), who it serves, the one or two invariants it enforces that no other {{OWNER_TERM}} does, and the single biggest risk it carries.>

---

## 2. Context & Problem

- **Where this fits.** <How this {{OWNER_TERM}} sits in the platform — one sentence + a link to architecture §1.1.>
- **Problem it solves.** <The publisher / editorial / platform pain that justifies this {{OWNER_TERM}} existing as its own deployable.>
- **Why a separate {{OWNER_TERM}}.** <Why this is not part of `<adjacent-{{OWNER_TERM}}>` — invariant, blast-radius, ownership, lifecycle, scaling profile.>

---

## 3. Goals & Non-Goals

### 3.1 Goals (measurable)

| # | Goal | How we measure | Target (v{{N}}) |
|---|------|----------------|-------------|
| G1 | <goal> | <metric / KPI> | <number> |
| G2 | … | … | … |

### 3.2 Non-Goals (explicit, binding)

| # | Out of scope | Why excluded | Where it lives instead |
|---|--------------|--------------|------------------------|
| N1 | <thing this {{OWNER_TERM}} will not do> | <reason> | <other {{OWNER_TERM}} / future version / never> |
| N2 | … | … | … |

> **Rule.** Anything not in §3.1 and not in §3.2 is **undefined**. A request to add it is a scope change, not a clarification.

---

## 4. Personas & JTBD (Jobs To Be Done)

| Persona | Job (when…, I want to…, so I can…) | Frequency | Success looks like |
|---------|-------------------------------------|-----------|--------------------|
{{#EACH PERSONAS_SERVED}}
| **{{this.name}}**{{#IF this.scope}} ({{this.scope}}){{/IF}} | When …, I want to …, so I can …. | <hourly/daily/monthly> | <observable outcome> |
{{/EACH}}

> Only list personas this {{OWNER_TERM}} **directly** serves — the workspace's {{ROLE_COUNT}}-role registry is the full set ([`security-and-auth.md`](../../../docs/standards/security-and-auth.md)); most {{OWNER_TERM}}s serve a subset. Personas served by other {{OWNER_TERM}}s even if they ultimately consume this data should not appear here.

---

## 5. User Journeys (sequence)

For each top-1–5 flow, a sequence diagram + the failure branches. Diagrams in Mermaid; rendered by GitLab.

### 5.1 Journey — <name>

```mermaid
sequenceDiagram
    autonumber
    participant U as User (browser)
    participant N as nginx
    participant S as {{SERVICE_SLUG}}
{{#IF HAS_KAFKA}}
    participant K as Kafka
{{/IF}}
    participant D as Postgres
    U->>N: POST /…
    N->>S: forwarded + X-Request-ID
    S->>D: <DbAction>
    S-->>U: 200 { success, data }
```

**Failure branches**

- <e.g. token expired> → **HTTP 401**, error_code `{{SERVICE_SLUG_UPPER}}_<CODE>`. Side effects: none.
{{#IF HAS_KAFKA}}
- <e.g. Kafka publish fails after commit> → row is written, event is **not** dropped; outbox/DLQ retries it (see §7).
{{/IF}}

### 5.2 Journey — <next>
…

---

## 6. Scope & Data Ownership

### 6.1 Features owned

From [`product/docs/features/v{{N}}/all-features.md`](../../../../product/docs/features/v{{N}}/all-features.md) — only `[x]` items:

| Catalog section | Item | Notes |
|---|---|---|
{{#EACH FEATURES_OWNED}}
| §{{this.section_no}} {{this.section_title}} | {{this.item}} | {{this.impl_note}} |
{{/EACH}}

### 6.2 Data ownership

| Resource | Prefix / namespace | Notes |
|---|---|---|
| PostgreSQL tables | `{{SERVICE_SLUG}}__*` | Sole writer. Every business table carries `{{TENANT_NOUN_SNAKE}}_id VARCHAR(50) NOT NULL` (see §8.1). |
{{#IF HAS_REDIS}}
| Redis keys | `{{SERVICE_SLUG}}:*` | Cache, short-lived counters only — never broker / queue / pub-sub. |
{{/IF}}
{{#IF HAS_MINIO}}
| MinIO buckets | `{{SERVICE_SLUG}}-<purpose>` | {{OWNED_BUCKETS_OR_NONE}} — access only via the shared adapter{{#IF HAS_SHARED_LIBRARY}} in `{{SHARED_LIBRARY_NAME}}`{{/IF}}. |
{{/IF}}
{{#IF HAS_KAFKA}}
| Kafka producer slot | `{{SERVICE_SLUG}}-<receiver(s)>-<event>` | See §7. |
{{/IF}}
{{#IF HAS_MEILISEARCH}}
| Meilisearch indexes | `{{SEARCH_OWNER_SLUG}}_<content_type>` | `{{SEARCH_OWNER}}` only — every other {{OWNER_TERM}} writes "owns no indexes" and calls `{{SEARCH_OWNER}}`'s REST API. |
{{/IF}}

### 6.3 Cross-{{OWNER_TERM}} references

ULIDs without FK. Identity columns reconciled via {{#IF HAS_KAFKA}}§7 mirror tables{{#ELSE}}synchronous REST reads{{/IF}} — never via cross-DB SQL.

### 6.4 Money columns

{{#IF PSP_PROVIDER}}
{{#EACH MONEY_COLUMNS}}
- `{{this.table}}.{{this.column}}` — {{this.currency}} in {{this.unit}} ({{this.purpose}}).
{{/EACH}}
{{#ELSE}}
**None — omitted by design.** {{PROJECT_NAME}} v{{N}} has no money-moving operations anywhere on the platform (monetization is out of v{{N}} per architecture §9; the finance/PSP {{OWNER_TERM}} slot is reserved for a future version). Keep this subsection as an explicit omission note — do not model currency in this {{OWNER_TERM}}, and do not delete the heading (numbering integrity).
{{/IF}}

---

## 7. Cross-{{OWNER_TERM}} Contracts{{#IF HAS_KAFKA}} (Kafka & Mirrors){{#ELSE}} (Synchronous REST){{/IF}}

{{#IF HAS_KAFKA}}
### 7.1 Kafka topics

| Direction | Topic | Partition key | Purpose | DLQ |
|---|---|---|---|---|
{{#EACH PRODUCED_TOPICS}}
| Produces | `{{this.topic}}` | `{{this.partition_key}}` | {{this.purpose}} | `{{this.topic}}-dlq` |
{{/EACH}}
{{#EACH CONSUMED_TOPICS}}
| Consumes | `{{this.topic}}` | `{{this.partition_key}}` | {{this.reaction}} | `{{this.topic}}-dlq` |
{{/EACH}}

Receivers are sorted alphabetically and joined with `_` (e.g. `content-search_engagement-article-published`). Producer = single, immutable. Priority is by topic, not by message field. Day-one consumer families platform-wide:{{#IF HAS_SEARCH_INDEXER_FLOW}} search-indexer,{{/IF}}{{#IF HAS_WEBHOOK_FLOW}} webhook dispatcher,{{/IF}}{{#IF HAS_AUDIT_FLOW}} audit-recorded stream,{{/IF}}{{#IF HAS_ASSETS_PURGE_FLOW}} {{ASSETS_OWNER}} CDN-purge,{{/IF}} — state which (if any) this {{OWNER_TERM}} participates in.

Every {{OWNER_TERM}} that owns admin-visible mutations also produces on its audit topic (`{{SERVICE_SLUG}}-{{AUDIT_OWNER}}-audit-recorded`){{#IF ARCH_SHAPE=microservices}} and, when it grants or revokes an editorial / admin role, on `{{SERVICE_SLUG}}-{{AUTH_OWNER}}-admin-role-sync`{{/IF}} — list both here if applicable.

### 7.2 Mirror tables — origin role

For each origin entity this {{OWNER_TERM}} publishes:

- **Entity:** `<entity>` (table `{{SERVICE_SLUG}}__<entity>` or projection over <tables>).
- **Topic:** `{{SERVICE_SLUG}}-<sorted_receivers>-<entity>-mirror`, partitioned by `record_id`.
- **Publish timing:** after the commit of every write that changes the projected fields. Never inside the transaction (infrastructure §3.7).
- **Payload shape (`row`):** <JSON snippet — only the projected fields, no PII the consumer doesn't need>.
- **Full-replay route:** `POST /{{SERVICE_SLUG}}/v{{N}}/admin/mirrors/<entity>:resync` — streams `upsert` events between `resync_started` / `resync_complete` sentinels; idempotent.

### 7.3 Mirror tables — consumer role

| Local table | Origin {{OWNER_TERM}} | Origin entity | Consumed via | Used by |
|---|---|---|---|---|
{{#EACH MIRROR_CONSUMER_TABLES}}
| `{{SERVICE_SLUG}}__mirror_of_{{this.origin}}__{{this.entity}}` | `{{this.origin}}` | `{{this.entity}}` | `{{this.topic}}` | {{this.used_by}} |
{{/EACH}}

> Mirrors are a **read hint only**. Every binding decision still hits the origin. Mirror-side resync uses the shadow-swap pattern (microservice-layout §4.8).
{{#ELSE}}
### 7.1 Cross-{{OWNER_TERM}} REST contracts

| Direction | Target {{OWNER_TERM}} | Endpoint | Purpose | Failure posture |
|---|---|---|---|---|
{{#EACH CROSS_SERVICE_CALLS}}
| Calls | `{{this.target}}` | `{{this.method}} {{this.path}}` | {{this.purpose}} | {{this.failure_posture}} |
{{/EACH}}

> No Kafka in v{{N}}. Cross-{{OWNER_TERM}} coordination is synchronous; post-response side effects run as `starlette.BackgroundTasks` for lightweight work or via a persistent `outbox` table drained by a single in-process worker for durable work.
{{/IF}}

---

## 8. Database schema (v{{N}})

### 8.1 Conventions

- **Engine.** PostgreSQL 17 via `asyncpg` + raw parameterized SQL through `DbAction`{{#IF HAS_SHARED_LIBRARY}} (`{{SHARED_LIBRARY_NAME}}`){{/IF}}. No ORM, no autogeneration.
- **Database isolation.** {{#IF ARCH_SHAPE=microservices}}Sole writer to its own logical DB;{{/IF}}{{#IF ARCH_SHAPE=monolith}}Owns its `{{SERVICE_SLUG}}__` table prefix inside the shared database;{{/IF}}{{#IF ARCH_SHAPE=hybrid}}{{#IF IS_CORE}}Owns `{{SERVICE_SLUG}}__` inside the shared core database;{{#ELSE}}Sole writer to its own logical DB;{{/IF}}{{/IF}} `{{SERVICE_SLUG}}__` prefix; no cross-{{OWNER_TERM}} SQL or FK.
- **Primary keys.** ULID `VARCHAR(50)` generated app-side. Code-seeded lookup tables (`{{SERVICE_SLUG}}__roles`, `{{SERVICE_SLUG}}__configurations`) use a natural key.
{{#IF TENANT_NOUN}}
- **`{{TENANT_NOUN_SNAKE}}_id`.** `VARCHAR(50) NOT NULL` on every business table from day one — v{{N}} is single-{{TENANT_NOUN}}, the column is v{{N+1}}+ multi-tenancy insurance (infrastructure §3.3).
{{/IF}}
- **Timestamps.** `TIMESTAMPTZ NOT NULL DEFAULT NOW()` for `created_at` / `updated_at`. UTC only.
{{#IF CALENDAR=jalali}}
- **Jalali sidecar columns.** Every human-observed date field carries Jalali integer sidecars (`<field>_jalali_year` / `_month` / `_day`) per the locked "Jalali as storage primitive" decision; conversion rules live only{{#IF HAS_SHARED_LIBRARY}} in `{{SHARED_LIBRARY_NAME}}` `jalali_lib`{{#ELSE}} in the workspace calendar module{{/IF}} ([`coding.md`](../../../docs/standards/coding.md) calendar section).
{{/IF}}
{{#IF BLOCK_EDITOR}}
- **Content body.** JSON block tree only — no `body_html` column on any content-type table ([`coding.md`](../../../docs/standards/coding.md) block-tree section).
{{/IF}}
- **Soft delete.** <Status-driven or hard delete per entity — be explicit per table.>
- **Enums.** `VARCHAR + StrEnum` in code + `CHECK` constraint in DB. No catch-all members.
- **Migrations.** Alembic raw SQL only (`op.execute("<raw SQL>")`); no `op.create_table()`, no SQLAlchemy imports (infrastructure §3.5).
- **File layout.** Each entity owns a numbered band `0N1…0N8` under `src/domain/<entity>/database/sql/`. Bands are unique **within the {{OWNER_TERM}}**.

### 8.2 Band map

| Band | Entity | Purpose |
|------|--------|---------|
{{#EACH ENTITY_BANDS}}
| {{this.band}} | `{{SERVICE_SLUG}}__{{this.entity}}` | {{this.purpose}} |
{{/EACH}}

### 8.3 Entity map

```
{{SERVICE_SLUG}}
{{#EACH ENTITY_BANDS}}
   ├── {{SERVICE_SLUG}}__{{this.entity}}
{{/EACH}}
```

### 8.4 Per-entity sections

For each table, repeat this block. DDL here is the **canonical** v{{N}} shape; deployed DDL lives in `src/domain/<entity>/database/sql/0N{1..8}-*.sql` and is the source of truth at runtime.

#### 8.4.<i> `{{SERVICE_SLUG}}__<entity>` — band 0N

**Purpose.** <One sentence — what this row represents in the domain.>

**Lifecycle.** <Created when …, updated when …, deleted/archived when …. The row never disappears via X.>

**DDL**

```sql
CREATE TABLE IF NOT EXISTS {{SERVICE_SLUG}}__<entity> (
    id               VARCHAR(50) PRIMARY KEY,
{{#IF TENANT_NOUN}}
    {{TENANT_NOUN_SNAKE}}_id   VARCHAR(50) NOT NULL,
{{/IF}}
    -- … domain columns …
{{#IF CALENDAR=jalali}}
    -- … Jalali sidecars for human-observed dates: <field>_jalali_year/_month/_day INTEGER …
{{/IF}}
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Plain-language column guide**

| Column | What it is for |
|--------|----------------|
| `id` | ULID — domain identifier. |
{{#IF TENANT_NOUN}}
| `{{TENANT_NOUN_SNAKE}}_id` | ULID of the owning {{TENANT_NOUN}} — single v{{N}}-{{TENANT_NOUN}} value today; multi-tenancy insurance. |
{{/IF}}
| … | … |

**Constraints**

```sql
ALTER TABLE {{SERVICE_SLUG}}__<entity>
    ADD CONSTRAINT {{SERVICE_SLUG}}__<entity>__<rule>__chk
    CHECK (…);
```

**Indexes**

```sql
CREATE INDEX {{SERVICE_SLUG}}__<entity>__<col>__idx
    ON {{SERVICE_SLUG}}__<entity> (<col>);
```

**Seeds (if code-seeded)**

```sql
INSERT INTO {{SERVICE_SLUG}}__<entity> (key, value, description) VALUES
    ('<key>', '<default>', '<one-line description>')
ON CONFLICT (key) DO NOTHING;
```

---

## 9. API Endpoint Specification

Envelope is `{success, message, data}` per [`tech/docs/standards/api-and-data-contracts.md`](../../../docs/standards/api-and-data-contracts.md). Paths are camelCase. ULIDs everywhere. **404 — not 403 — on ownership mismatches.**

### 9.1 RBAC matrix (one-shot, do not repeat per endpoint)

| Endpoint group | {{#EACH ROLE_LIST}}{{this.name}} | {{/EACH}}
|---|{{#EACH ROLE_LIST}}---|{{/EACH}}
| `/{{SERVICE_SLUG}}/v{{N}}/<public-reads>` | {{#EACH ROLE_LIST}}<✅ / —> | {{/EACH}}
| `/{{SERVICE_SLUG}}/v{{N}}/<editorial-writes>` | {{#EACH ROLE_LIST}}<…> | {{/EACH}}
| `/{{SERVICE_SLUG}}/v{{N}}/admin/*` | {{#EACH ROLE_LIST}}<…> | {{/EACH}}
| `/{{SERVICE_SLUG}}/v{{N}}/internal/*` | {{#EACH ROLE_LIST}}<— / ✅ (API key)> | {{/EACH}}

### 9.2 Endpoint catalog

For each endpoint:

#### `POST /{{SERVICE_SLUG}}/v{{N}}/<resource>` — `<verb_resource>`

- **Role.** <one of {{ROLE_LIST_INLINE}}>.
- **What it does.** <One sentence.>
- **Request.** Body schema name `<Verb><Resource>RequestBody`, query schema `<Verb><Resource>QueryParams`. Full shape lives in OpenAPI — link `/{{SERVICE_SLUG}}/v{{N}}/openapi.json#/components/schemas/<Verb><Resource>RequestBody`.
- **Response (2xx).** `<Verb><Resource>Response` — name only; OpenAPI is the canonical contract.
- **Errors.** `400 {{SERVICE_SLUG_UPPER}}_BAD_INPUT`, `404 {{SERVICE_SLUG_UPPER}}_NOT_FOUND`, `409 {{SERVICE_SLUG_UPPER}}_CONFLICT`, `422 {{SERVICE_SLUG_UPPER}}_<VALIDATION_CODE>`. Full list in §11.
- **Rate limit.** <key> @ <N> req / <window> per <subject>. Full table in §12.
{{#IF PSP_PROVIDER}}
- **Idempotency.** `Idempotency-Key` **required on money-moving endpoints** — 24h de-duplication window per key.
{{#ELSE}}
- **Idempotency.** `Idempotency-Key` is **not required on any v{{N}} endpoint** (no money-moving operations) — state the DB uniqueness constraint that makes the retry safe instead.
{{/IF}}
- **Side effects.** Writes <tables>;{{#IF HAS_KAFKA}} emits Kafka <topic>{{/IF}}.
{{#IF HAS_KAFKA}}{{#IF HAS_AUDIT_FLOW}}
- **Audit.** Emits `{{SERVICE_SLUG}}-{{AUDIT_OWNER}}-audit-recorded` with `event_type = "{{SERVICE_SLUG}}.<verb>_<resource>"` (sink: `{{AUDIT_OWNER}}__audit_log`).
{{/IF}}{{/IF}}

> **Style rule.** Do not duplicate the full request/response JSON schema in this document — name the schema and link OpenAPI. The doc rots; OpenAPI doesn't.

---

## 10. Configuration (`{{SERVICE_SLUG}}__configurations`)

All runtime-mutable variables. Startup-only variables live in `.env`.

| Key | Default (v{{N}}) | Type | Mutable by | Hot-reload? | Description |
|-----|--------------|------|------------|-------------|-------------|
{{#EACH CONFIGURATION_KEYS}}
| `{{this.key}}` | `{{this.default}}` | {{this.type}} | {{this.mutable_by}} | {{this.hot_reload}} | {{this.description}} |
{{/EACH}}
{{#IF ARCH_SHAPE=microservices OR ARCH_SHAPE=hybrid}}
| `service_api_key_<other_{{OWNER_TERM}}>` | `<unset>` | secret | ADMINISTRATOR | yes | Inbound API-key for `<other_{{OWNER_TERM}}>` {{OWNER_TERM}}-to-{{OWNER_TERM}} calls. |
{{/IF}}

> Admin can only **UPDATE** `value` and `description` (runtime DB grant is exactly `SELECT, UPDATE (value, description)`). Create/delete of keys is the {{OWNER_TERM}}-startup seeder's job.

---

## 11. Error catalog

Every raised error is `ProjectBaseException` (from{{#IF HAS_SHARED_LIBRARY}} `{{SHARED_LIBRARY_NAME_UNDERSCORE}}.exception`{{#ELSE}} the workspace exception module{{/IF}}) with a stable `error_code` set at the raise site, in the namespace `{{SERVICE_SLUG_UPPER}}_<CODE>`. Constructor: required `status_code, message, error_code`; optional `data`, `extra` (log-only).

| `error_code` | HTTP status | Default message | Raised when |
|--------------|-------------|------------------|-------------|
| `{{SERVICE_SLUG_UPPER}}_NOT_FOUND` | 404 | "<entity> not found" | Lookup by id misses **or** caller does not own the row. |
| `{{SERVICE_SLUG_UPPER}}_BAD_INPUT` | 400 | "invalid payload" | Validation deeper than schema (e.g. business invariant). |
| `{{SERVICE_SLUG_UPPER}}_CONFLICT` | 409 | "conflicting state" | Unique-key violation or illegal state transition surfaced to the user. |
| `{{SERVICE_SLUG_UPPER}}_<VALIDATION_CODE>` | 422 | "<one line>" | Wire-shape validation beyond Pydantic defaults{{#IF BLOCK_EDITOR}} (e.g. `{{CONTENT_OWNER_UPPER}}_UNKNOWN_BLOCK_TYPE`){{/IF}}. |
| `{{SERVICE_SLUG_UPPER}}_RATE_LIMITED` | 429 | "too many requests" | Rate-limit bucket empty. Sets `Retry-After` header AND `data.retry_after` (matching integer). |
| `{{SERVICE_SLUG_UPPER}}_UPSTREAM_FAILED` | 502 | "upstream call failed" | Downstream/dependency ({{#IF OTP_PROVIDER}}{{OTP_PROVIDER}}, {{/IF}}{{#IF CDN_PROVIDER}}{{CDN_PROVIDER}}, {{/IF}}{{#IF CAPTCHA_PROVIDER}}{{CAPTCHA_PROVIDER}}, {{/IF}}{{#IF HAS_MEILISEARCH}}Meilisearch, {{/IF}}sibling {{OWNER_TERM}}) error wrapped at boundary. |
| `{{SERVICE_SLUG_UPPER}}_UPSTREAM_TIMEOUT` | 504 | "upstream timeout" | Dependency call exceeded budget. |

> No raw `500` from business code. `500` is reserved for unhandled exceptions (`UNHANDLED_INTERNAL`) and `503` for the platform-wide breaker.

---

## 12. SLOs & performance

### 12.1 Latency SLOs (measured at the {{OWNER_TERM}} boundary, excludes nginx)

| Endpoint class | p50 | p95 | p99 | Error budget (30d) |
|---|---|---|---|---|
| Read (`GET /…`) | <X ms> | <Y ms> | <Z ms> | 99.9% |
| Write (`POST/PATCH/DELETE`) | <X ms> | <Y ms> | <Z ms> | 99.9% |
| <{{OWNER_TERM}}-specific class — add if applicable> | <X ms> | <Y ms> | <Z ms> | <…> |
{{#IF HAS_KAFKA}}
| Kafka consumer lag (e2e) | — | < 5 s | < 30 s | 99.5% |
{{/IF}}

### 12.2 Capacity assumptions (v{{N}})

- Expected RPS: <number> sustained, <number> peak. {{VM_LAYOUT_DESCRIPTION}} (architecture §8); vertical scale first.
- Expected DB row growth: <number> rows / month for `<largest table>`; partition / retention policy in §8.
{{#IF HAS_MINIO}}
- Expected MinIO growth: <number> GB / month into `<bucket>` — or "owns no buckets".
{{/IF}}

### 12.3 Rate-limit matrix

| Bucket | Subject | Limit | Window |{{#IF HAS_REDIS}} Redis key |{{/IF}} Triggers |
|--------|---------|-------|--------|{{#IF HAS_REDIS}}-----------|{{/IF}}----------|
| `{{SERVICE_SLUG}}:rl:<flow>:<subject>` | per IP / per user / per {{OWNER_TERM}} | <N> | <60s> |{{#IF HAS_REDIS}} `{{SERVICE_SLUG}}:rl:…` |{{/IF}} `429 {{SERVICE_SLUG_UPPER}}_RATE_LIMITED` |

---

## 13. Threat model

STRIDE-lite — only the three to five threats that actually move the needle for this {{OWNER_TERM}}.

| # | Threat | STRIDE | Asset | Attack path | Likelihood | Impact | Mitigation (in code) | Residual risk |
|---|--------|--------|-------|-------------|------------|--------|----------------------|---------------|
| T1 | <threat> | <STRIDE letter> | <asset> | <path> | <L> | <I> | <mitigation> | <residual> |

**Trust boundaries**

- Public → {{#IF CDN_PROVIDER}}{{CDN_PROVIDER}} CDN → {{/IF}}nginx (TLS) → {{OWNER_TERM}}: untrusted; every input revalidated.
{{#IF ARCH_SHAPE=microservices OR ARCH_SHAPE=hybrid}}
- {{OWNER_TERM_PROPER}} → {{OWNER_TERM}}: API key in `{{SERVICE_SLUG}}__configurations` (`Authorization: API_KEY <key>`, constant-time compare); mTLS not yet (see §15 alternatives).
{{/IF}}
- {{OWNER_TERM_PROPER}} → Postgres{{#IF HAS_REDIS}} / Redis{{/IF}}{{#IF HAS_MINIO}} / MinIO{{/IF}}{{#IF HAS_KAFKA}} / Kafka{{/IF}}{{#IF HAS_MEILISEARCH}} / Meilisearch{{/IF}}: trusted; secrets via env / configurations table.

**PII inventory**

| Field | Source | Retention | Redaction in logs / mirrors |
|-------|--------|-----------|------------------------------|
{{#EACH PII_FIELDS}}
| `{{this.field}}` | {{this.source}} | {{this.retention}} | {{this.redaction}} |
{{/EACH}}

---

## 14. Acceptance criteria (release-blocking)

Only Pass/Fail tests for the **critical paths** — everything else is covered by the coverage gate (testing standard).

| # | Scenario | Pass criterion | Test location |
|---|----------|----------------|----------------|
| A1 | <scenario> | <observable result + error_code if applicable> | `tests/integration/api/<area>/test_<flow>.py` |
| A2 | … | … | … |

---

## 15. Alternatives considered

For each meaningful design choice that has a reasonable counter, record what was rejected and why. This is the single highest-value section for future maintainers.

### 15.1 Decision — <name>

- **Chosen.** <one-paragraph statement>.
- **Rejected — <alternative>.** Pro: <…>. Con: <…>. Reason: <…>.
- **Rejected — <alternative>.** Pro: <…>. Con: <…>. Reason: <…>.
- **Trigger to revisit.** <observable metric or external event>.

### 15.2 Decision — <next>
…

---

## 16. Decision log

Append-only. Every entry: date, decision, rationale, owner. Never edit a past entry — append a superseding one.

| Date | Decision | Owner | Supersedes | Rationale (one line) |
|------|----------|-------|------------|----------------------|
| YYYY-MM-DD | <one line> | <name> | — | <why now> |

---

## 17. Open questions

Live list. Closing a question moves it to §16 (Decision log) with a date. A question with no owner has effectively no answer.

| # | Question | Blocking? | Owner | Target close date |
|---|----------|-----------|-------|-------------------|
| Q1 | <question> | yes / no | <name> | YYYY-MM-DD |

---

## 18. Out of scope (v{{N}})

The non-goals from §3.2 are binding. This section lists features that are **plausible v{{N+1}}+** but explicitly not in v{{N}}, with the trigger that would re-open them.

| # | Item | Why not in v{{N}} | Trigger to reconsider |
|---|------|---------------|------------------------|
| O1 | <feature> | <reason> | <metric / external event> |

---

## 19. References

- Platform architecture: [`tech/docs/project-architecture/v{{N}}.md`](../../../docs/project-architecture/v{{N}}.md).
- Cross-cutting standards: [`tech/docs/standards/`](../../../docs/standards/).
- Locked + cross-cutting decisions: architecture-decisions.md (if present in this workspace).
- Feature catalog: [`product/docs/features/v{{N}}/all-features.md`](../../../../product/docs/features/v{{N}}/all-features.md).
- OpenAPI: `/{{SERVICE_SLUG}}/v{{N}}/openapi.json` (runtime canonical).
{{#IF HAS_KAFKA}}
- Topic catalog: [`{{KAFKA_REPO}}/docs/v{{N}}/PRD-TDD.md`](../../../{{KAFKA_REPO_SUFFIX}}/docs/v{{N}}/PRD-TDD.md).
{{/IF}}
{{#IF HAS_SHARED_LIBRARY}}
- Shared library: [`{{SHARED_LIBRARY_NAME}}/docs/v{{N}}/PRD-TDD.md`](../../../{{SHARED_LIBRARY_SUFFIX}}/docs/v{{N}}/PRD-TDD.md).
{{/IF}}

---

## 20. Changelog

Major revisions only. Per-edit history lives in git.

| Date | Revision | Author | Summary |
|------|----------|--------|---------|
| YYYY-MM-DD | v{{N}}.0 | <name> | First binding cut. |
