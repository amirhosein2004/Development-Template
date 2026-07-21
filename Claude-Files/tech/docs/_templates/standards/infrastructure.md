# Infrastructure Standards (tech)

> **Documentation placement.** Cross-repo standard — referenced by every engineering repo (see [`documentation.md`](./documentation.md) §5).

## Scope

Backend standards for how {{PROJECT_NAME}} consumes the shared data-plane components: **PostgreSQL** (schema, queries, raw-SQL Alembic migrations){{#IF HAS_REDIS}}, **Redis** (caching only — not a broker, not a queue){{/IF}}{{#IF HAS_KAFKA}}, **Kafka** (the only async broker){{/IF}}, **MinIO** (S3-compatible object storage){{#IF HAS_MEILISEARCH}}, **Meilisearch** (owned by `backend-search`){{/IF}}, and **nginx** (single ingress). Operational details — cluster topology, capacity, backup schedule, bootstrap — live in the corresponding `tech/infra-<x>/docs/v1/PRD-TDD.md`; this file owns only the **contract every backend {{OWNER_TERM}} must follow** when consuming them.

Reading conventions: **CURRENT** = today. **v1 STANDARD** = required for v1, in force now. **STANDARD GOING FORWARD** = required target, not yet fully in place.

---

## 1. Source of truth & precedence

| Source | Role |
|---|---|
| {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic.database.DbAction`{{#ELSE}}`src/modules/shared/platform/database/action.py`{{/IF}} | Canonical Postgres data-access base class. |
{{#IF HAS_REDIS}}| {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic` Redis client wrapper{{#ELSE}}`src/modules/shared/integrations/redis.py`{{/IF}} | Canonical cache client. |
{{/IF}}{{#IF HAS_KAFKA}}| {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic` Kafka producer / consumer base{{#ELSE}}`src/modules/shared/integrations/kafka.py`{{/IF}} | Canonical broker client. |
{{/IF}}| {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic` MinIO adapter{{#ELSE}}`src/modules/shared/integrations/object_storage.py`{{/IF}} | Sole object-storage client. |
{{#IF HAS_MEILISEARCH}}| `backend_shared_logic` Meilisearch client (only used inside `backend-search`) | Sole search-engine client. |
{{/IF}}| `tech/backend-<{{OWNER_TERM}}>/docs/v1/PRD-TDD.md` | Per-{{OWNER_TERM}} catalog of tables{{#IF HAS_REDIS}}, Redis keys{{/IF}}{{#IF HAS_KAFKA}}, Kafka topics{{/IF}}, MinIO buckets. |
| `tech/infra-postgresql/docs/v1/PRD-TDD.md` | Postgres cluster ops + per-{{OWNER_TERM}} DB-role isolation grants, `pg_hba.conf`. |
{{#IF HAS_REDIS}}| `tech/infra-redis/docs/v1/PRD-TDD.md` | Redis cluster ops, deployment topology. |
{{/IF}}{{#IF HAS_KAFKA}}| `tech/infra-kafka/docs/v1/PRD-TDD.md` | Kafka cluster ops, canonical topic catalog. |
{{/IF}}| `tech/infra-minio/docs/v1/PRD-TDD.md` | MinIO cluster ops, canonical bucket catalog. |
{{#IF HAS_MEILISEARCH}}| `tech/infra-meilisearch/docs/v1/PRD-TDD.md` | Meilisearch cluster ops. |
{{/IF}}| `tech/infra-nginx/docs/v1/PRD-TDD.md` | Ingress config, TLS, rate limits, upstream pools. |

---

## 2. Common naming discipline

Every component uses the **{{OWNER_TERM}} name as the prefix** so ownership is grep-able everywhere:

| Component | Pattern | Example |
|---|---|---|
| PostgreSQL table | `{{#IF ARCH_SHAPE=microservices}}<service>{{#ELSE}}<module>{{/IF}}__<entity>` (double underscore) | see per-{{OWNER_TERM}} PRD-TDD |
{{#IF HAS_MIRROR_TABLES}}| PostgreSQL mirror table | `<consumer_service>__mirror_of_<origin_service>__<origin_entity>` (see §5.5) | `search__mirror_of_content__articles` |
{{/IF}}{{#IF HAS_REDIS}}| Redis key | `<{{OWNER_TERM}}>:<...>` (colon-separated) | `<service>:otp:<phone>:<usage>`, `<service>:rate_limit:<ip>` |
{{/IF}}{{#IF HAS_KAFKA}}| Kafka topic | `<sender_service>-<receiver_service(s)>-<event>` (receivers sorted alphabetically, joined by `_`) | `<sender>-<receiver>-<event>` |
{{/IF}}| MinIO bucket | `<{{OWNER_TERM}}>-<purpose>` (S3-safe; lowercase + digits + dashes; **no underscores**) | `<service>-<purpose>` |
{{#IF HAS_MEILISEARCH}}| Meilisearch index | `<owner_service>_<content_type>` (only `search` owns any Meilisearch index; single-underscore, not double — Meilisearch does not accept `__` in index UIDs) | `search_articles` |
{{/IF}}

Same `<{{OWNER_TERM}}>` token across all components. Never share a name across {{OWNER_TERM}}s; never reuse a name across components.

---

## 3. PostgreSQL — schema, access, migrations

{{#IF ARCH_SHAPE=microservices}}Every service is a FastAPI app that owns its own PostgreSQL tables via **raw, parameterized SQL** over `asyncpg` (no ORM, no SQLAlchemy).{{#ELSE}}The monolith owns **one logical Postgres database** in v1. Every module's tables share that database but are prefix-isolated by `<module>__` naming. All SQL is raw, parameterised over `asyncpg` (no ORM, no SQLAlchemy).{{/IF}} Schema is authored as per-entity numbered SQL files (one set per entity folder) and applied **only through Alembic with raw SQL**. All data access goes through a per-entity `DbAction` (subclass of the shared base).

### 3.1 Engine & connection model

| Aspect | Rule |
|---|---|
| Database | **PostgreSQL 17** (image pin `postgres:17.10-bookworm`). {{#IF ARCH_SHAPE=microservices}}Database-per-service ownership.{{#ELSE}}One logical DB for the monolith in v1.{{/IF}} |
| DB user | {{#IF ARCH_SHAPE=microservices}}Each service connects with its **own dedicated Postgres role** scoped to its own database{{#ELSE}}The monolith connects with its own dedicated Postgres role scoped to that database{{/IF}}; no shared / superuser credentials at runtime. |
| Driver | `asyncpg` only; no blocking DB calls on the event loop. |
| Pool | One `asyncpg` pool per process, created in lifespan, closed in `finally`. |
| Pool sizing | `ENVS.POSTGRES_MINIMUM_NUMBER_OF_CONNECTION` / `..._MAXIMUM_NUMBER_OF_CONNECTION` / `..._MAXIMUM_QUERIES_TO_RESTART_CONNECTION` / `..._MAXIMUM_INACTIVE_CONNECTION_LIFETIME_IN_SECOND`. |
| Acquisition | `async with pool.acquire()` per `DbAction` call. |
| DSN | `ENVS.POSTGRES_DATABASE_URI`; never committed. |

**STANDARD GOING FORWARD:** put PgBouncer (transaction pooling) in front of Postgres before scaling API workers past ~4; set server-side `statement_timeout` and `lock_timeout`.

### 3.2 Role isolation

{{#IF ARCH_SHAPE=microservices}}The cluster hosts one logical database per service. Each service must connect with **its own dedicated, database-scoped role**. Two independent layers enforce isolation:

- **Privilege layer.** `REVOKE CONNECT ON DATABASE <db> FROM PUBLIC`; only the database owner can connect. The per-database `public` schema also has `USAGE` / `CREATE` held only by the owning service role.
- **Connection layer.** `pg_hba.conf` lists explicit `database` ↔ `user` rules with a final `reject` line, so a connection attempt with mis-matched DB and user is dropped before authentication runs — a leaked password for `<service_a>_app` still cannot reach the `<service_b>` database.
{{#ELSE}}The cluster hosts one logical database for the monolith. The monolith connects with its own dedicated role (`{{PROJECT_SLUG}}_app`) — never `postgres` and never a superuser. `infra-postgresql/docs/v1/PRD-TDD.md` owns the concrete `CREATE ROLE` SQL, `pg_hba.conf` template, and rotation runbook.
{{/IF}}

### 3.3 ID scheme

- **Primary keys are ULIDs** generated app-side (`str(ULID())`), stored as `VARCHAR(50)`. Never binary.
- Never reuse a primary key. IDs are globally unique across {{OWNER_TERM}}s.
{{#IF ARCH_SHAPE=microservices}}- **No cross-service foreign keys.** Reference another service's entity by storing its ULID without a DB FK; integrity is enforced at the service layer.
{{#ELSE}}- No cross-module foreign keys in v1 SQL; integrity is enforced at the service layer. Same-module FKs are fine.
{{/IF}}
- **No `LISTEN / NOTIFY` eventing.** Reach another {{OWNER_TERM}} via REST{{#IF HAS_KAFKA}}, Kafka{{/IF}}{{#IF HAS_MIRROR_TABLES}}, or a mirror table{{/IF}}.

#### 3.3.1 Exception — code-seeded natural-key lookup tables

Two tables per {{OWNER_TERM}} use a **natural key as PK** instead of a ULID:

- `<{{OWNER_TERM}}>__roles` — PK `name VARCHAR(50)`. Carries permission set and `is_default BOOLEAN` (exactly one row is default). **Fully immutable at runtime** — no API writes; DB grant for runtime role excludes `INSERT` / `UPDATE` / `DELETE`.
- `<{{OWNER_TERM}}>__configurations` — PK `key VARCHAR(255)`. Holds runtime, admin-tunable settings. **Rows are immutable at runtime** (no `INSERT`, no `DELETE`, no `UPDATE` on `key`), but **`value` and `description` are admin-updatable**. DB grant for runtime role is exactly `GRANT SELECT, UPDATE (value, description) ON <{{OWNER_TERM}}>__configurations`.

Common qualifying rules: populated exclusively from the version-controlled `0N8-seeds.sql` (inlined into the entity's bootstrap Alembic revision); `CHECK` constraint pins natural-key format; assignment tables (`<{{OWNER_TERM}}>__user_roles`, etc.) still use ULID PKs.

### 3.4 Schema definition — numbered SQL files

Per-entity numbered files (under `{{#IF ARCH_SHAPE=microservices}}src/domain/<entity>{{#ELSE}}src/modules/<module>{{/IF}}/database/sql/`), executed in fixed order:

```
0N1-extensions          -- CREATE EXTENSION IF NOT EXISTS …
0N2-enums               -- domain enums (or VARCHAR + StrEnum)
0N3-tables              -- CREATE TABLE IF NOT EXISTS …
0N4-constraints         -- constraints not inlined in the table
0N5-functions_and_triggers
0N6-indexes
0N7-comments            -- COMMENT ON …
0N8-seeds               -- idempotent seed data
```

Rules:

- **Numeric banding per entity** — the `N` in `0N1 … 0N8` is the entity's band. {{#IF ARCH_SHAPE=microservices}}Bands need not be coordinated across services (each service owns its own database){{#ELSE}}Coordinate bands across modules; the monolith reserves bands per module range{{/IF}}.
- **Table naming is `{{#IF ARCH_SHAPE=microservices}}<service>{{#ELSE}}<module>{{/IF}}__<entity>`** (double underscore).
- **Idempotent DDL.** `CREATE TABLE IF NOT EXISTS`, `CREATE EXTENSION IF NOT EXISTS`; seeds use `ON CONFLICT DO NOTHING` or guarded inserts.
- **Timestamps:** `TIMESTAMPTZ NOT NULL DEFAULT NOW()` for `created_at` / `updated_at`. UTC only; never naive.
{{#IF CALENDAR=jalali}}- **Jalali storage columns.** Every table with a date column that a human observes also stores the Jalali components alongside the UTC `TIMESTAMPTZ` — `jalali_year INTEGER`, `jalali_month INTEGER`, `jalali_day INTEGER`. See [`coding.md`](./coding.md) §11.
{{/IF}}- **Flexible payloads:** `JSONB` (never `JSON` or `TEXT`).
{{#IF PSP_PROVIDER}}- **Money columns:** `BIGINT CHECK (>= 0)` — integer Toman, platform-wide.
{{/IF}}- **Enums:** native PostgreSQL `ENUM` types are allowed and encouraged for fixed value sets — `VARCHAR + StrEnum` is also acceptable. Pick per case; do not mix.
- **Seeds ship with Alembic.** `0N8-seeds.sql` is inlined into the entity's bootstrap revision and applied by `alembic upgrade head`. There is no app-side seeder and no seed-on-boot.

### 3.5 Schema evolution — Alembic with raw SQL

The lifespan opens the pool and stops. **No startup-time DDL, ever.** Only Alembic, only raw SQL.

Rules:

- **New {{OWNER_TERM}}:** bootstrap revision concatenates each entity's `0N1 … 0N8` (in band order, seeds included) into one `op.execute("<raw SQL>")`; applied to an empty DB via `alembic upgrade head`.
- **New entity on existing {{OWNER_TERM}}:** entity's `0N1 … 0N8` (seeds included) are inlined into a new revision `<{{OWNER_TERM}}>__bootstrap_<entity>` whose `upgrade()` calls `op.execute(...)`. Files stay in the repo as reference.
- **Subsequent changes:** new Alembic revision; never retro-edit `0N` files.
- **No SQLAlchemy ORM, no `Base.metadata`, no autogeneration.**
- **No `op.create_table()`.** Migration bodies are `op.execute("<raw SQL>")` only.
- **File name:** `YYYYMMDD_HHMM__{{OWNER_TERM}}__<description>.py` (sorts chronologically).
- **One concern per migration.** `expand` and `contract` live in separate migrations.
- **No SQLAlchemy at all.** SQLAlchemy is not a project dependency; the only import in any migration is `from alembic import op`. Anything that would pull in `sqlalchemy.*` — including `sqlalchemy.text` — is forbidden.
- **Never run `alembic revision --autogenerate`.**
- **Run migrations as a manually-triggered CI/CD pre-deploy step**, never in app boot and never on an automatic schedule.
- **Once committed / applied, migrations are immutable** — never edit; write a new one to correct course.

### 3.6 Data-access patterns — `DbAction`

All queries go through a per-entity `DbAction` subclass with a module-level singleton `db_action`.

| Method | Purpose |
|---|---|
| `insert_one(inputs, pool, returning_fields)` | Single insert with `RETURNING`. |
| `insert_many_without_transact / _with_transact(...)` | Batched bulk insert. Respect asyncpg's 32767-parameter limit. |
| `fetch / fetch_many(where_clause, values, pool, returning_fields, order_by, page)` | Read with parameterized `WHERE`, ordering, pagination. |
| `update(inputs, where_clause, pool, returning_fields, add_updated_at=True)` | Auto-sets `updated_at = now(UTC)` unless disabled. |
| `count(pool, where_clause, values)` | `COUNT(*)` with parameterized filter. |
| `delete(where_clause, values, pool)` | Hard delete. |
| `is_exist / is_exist_or_raise / is_absent_or_raise(...)` | Existence checks; `_or_raise` variants raise `ProjectBaseException`. |
| `paginated_fetch_by_filter(...)` | Generic list endpoint engine. |

#### 3.6.1 Filter engine

`paginated_fetch_by_filter` compiles equality (`= $N` or `IN (...)`), fuzzy (`ILIKE %$N%`), and range (`>= / <=`) fragments with parameterised binds against three allow-lists (`EQUALITY_COLUMNS_NAMES`, `ILIKE_COLUMNS_NAMES`, `RANGE_COLUMNS_NAMES`). Sort column must be in `ALL_COLUMNS_NAMES`; direction is `ASC` or `DESC` only. Emits a total-count query alongside the page query so the wire response includes `total`.

**Pagination modes** — pick by table size:

- **Keyset (seek) pagination — required for high-cardinality lists.** `WHERE (sort_col, id) < ($last_sort, $last_id) ORDER BY sort_col DESC, id DESC LIMIT n`. Cursor is an opaque base64-encoded JSON of the last sort key + `id`. Page cost stays constant regardless of depth.
- **Offset pagination — only for bounded admin lists.** `LIMIT page_size OFFSET (current_page-1)*page_size`.

Every column that participates in a keyset `ORDER BY` must be covered by a btree index that also includes the `id` tie-breaker.

### 3.7 Query safety & race safety

- **Parameterized values only** (`$1, $2, …`). Never f-string or concatenate user input into SQL.
- **Identifiers from allow-lists only.** Table / column names come from entity constants — never from request data.
- **Use `RETURNING`** to read back rows in one round-trip.

### 3.8 Soft vs hard delete

| Entity kind | Policy |
|---|---|
| Domain / business entities | **Soft delete.** Table has `deleted_at TIMESTAMPTZ NULL`; "delete" issues an `UPDATE` that sets the timestamp; all reads filter `deleted_at IS NULL` by default. |
| Ephemeral rows (OTP codes, expired sessions, idempotency keys) | Hard delete. |
| Append-only high-volume (pageviews, custom events) | Hard partitioning by time (monthly), no per-row soft delete; old partitions dropped wholesale by cronjob. |

### 3.9 Migration operations

- **CI/CD runs `alembic upgrade head`** against a throwaway DB per MR (integration test suite bootstraps the schema each run), and the **pre-deploy migration gate** — `alembic upgrade head` + drift check — against the target environment's database before the new app revision serves; non-zero exit on either fails the deploy. See [`ci-cd.md`](./ci-cd.md).
- **Never run migrations from a developer laptop against staging or production.** Only CI/CD.
- **Downgrade migrations are best-effort.** Every `upgrade()` gets a matching `downgrade()`, but production rollbacks go through container-image rollback + a forward migration if needed, not through `alembic downgrade`.

### 3.10 Backup, recovery & drift

- Automated `pg_basebackup` + WAL archive to MinIO; nightly snapshot rsync to a cold VM at a different provider.
- Drift detection enforced as a pre-deploy gate alongside `alembic upgrade head`.
- Recovery ordering: restore DB, then deploy the app revision whose schema matches the restored `alembic_version` head.

---

{{#IF HAS_REDIS}}## 4. Redis — cache only

A single Redis deployment used by every backend {{OWNER_TERM}} for caching and short-lived counters. **Not a message broker. Not a job queue.** {{#IF HAS_KAFKA}}The broker is Kafka (§5).{{/IF}}

### 4.1 Per-{{OWNER_TERM}} namespace

Each {{OWNER_TERM}} uses its **own logically-isolated namespace** (own DB index / own keyspace prefix). Two {{OWNER_TERM}}s must not share keys.

**Key naming: `<{{OWNER_TERM}}>:<...>`** — colon-separated, standard Redis convention. Examples: `<{{OWNER_TERM}}>:otp:<phone>:<usage>`, `<{{OWNER_TERM}}>:rate_limit:<ip>`, `<{{OWNER_TERM}}>:revoked_jwt:<jti>`.

### 4.2 Permitted uses (only)

- **Cache** (read-through, write-through, edge short-lived caches).
- **OTP TTL** (per-phone, per-usage).
- **Rate-limit counters** (token-bucket / sliding-window).
- **Idempotency keys** (for `POST` retries and webhook handlers).

### 4.3 Explicitly forbidden

- **Not a message broker** — domain events do not flow through Redis.
- **Not a job queue** — {{#IF HAS_KAFKA}}the queue is Kafka with priority-by-topic (§5.3){{#ELSE}}the queue is the transactional outbox drained by an in-process worker{{/IF}}.
- **No pub/sub fan-out for app events**, no Streams as an event log.
- **Not a database** — everything in Redis must be reconstructible from PostgreSQL{{#IF HAS_KAFKA}} + Kafka{{/IF}}.

### 4.4 Access through the shared adapter

{{OWNER_TERM}}s consume Redis through the shared wrapper. No per-{{OWNER_TERM}} Redis client; no duplicated credential plumbing.

---

{{/IF}}{{#IF HAS_KAFKA}}## 5. Kafka — the only async broker

A single Apache Kafka cluster for the entire platform. **All async work** — domain events, fan-out — runs through Kafka. There is no second broker.

### 5.1 Topic naming — `<sender_service>-<receiver_service(s)>-<event>`

- Each topic has **exactly one designated sender** and **one or more designated receivers**.
- Single receiver: middle segment is that receiver's service name. Multiple receivers: **sorted alphabetically** and **joined by `_` (underscore)**.
- The receiver set is **closed at design time** — no wildcards.

### 5.2 DLQ per source

DLQ topic per source, named **`<source-topic>-dlq`**. Admin surface inspects and replays from DLQs.

### 5.3 Priority is encoded by topic, not by message field

When a workflow has priority lanes, ship one topic per lane (`<sender>-<receiver>-<event>-{free,normal,high}`). Never branch on a `priority` field inside a single topic.

{{#IF ARCH_SHAPE=microservices}}### 5.4 v1 canonical day-one flows

Four real day-one consumer flows in a v1 microservices platform:

1. **search-indexer** — search consumer reindexes on `content-search-*` events.
2. **webhook dispatcher** — content publishes `<content>-webhookdispatcher-webhook-triggered`; a consumer delivers HMAC-signed payloads to publisher-configured URLs.
3. **audit-recorded sink** — every service publishes `<sender>-<audit>-*-audit-recorded`; the sink appends to the audit log.
4. **CDN purge on replace-in-place** — assets publishes `assets-cdnpurge-asset-replaced`; a consumer calls the CDN purge adapter.
{{/IF}}

### 5.5 Access through the shared adapter

{{OWNER_TERM}}s consume Kafka through the shared producer / consumer base classes. Inbound Kafka handlers live in `src/consumers/`.

---

{{/IF}}## {{#IF HAS_KAFKA}}6{{#ELSE}}{{#IF HAS_REDIS}}5{{#ELSE}}4{{/IF}}{{/IF}}. MinIO — object storage

A single MinIO deployment provides S3-compatible object storage to every backend {{OWNER_TERM}} that needs to persist files.

### Bucket naming — `<{{OWNER_TERM}}>-<purpose>`

- **S3-compatible names only**: lowercase, digits, dashes; **no underscores**.
- One bucket family per {{OWNER_TERM}}, every bucket starts with `<{{OWNER_TERM}}>-`.

### Access through the shared adapter

Any {{OWNER_TERM}} that reads / writes object storage MUST use the shared MinIO adapter. No per-{{OWNER_TERM}} S3 client; no duplicated credential plumbing.

### Per-{{OWNER_TERM}} access keys

Each {{OWNER_TERM}} authenticates with its own MinIO access key scoped to its own bucket family. A leaked key for one {{OWNER_TERM}} cannot list or read another's buckets.

### Bucket policies

- Private buckets — no anonymous read. Signed URLs for internal preview only.
- Public-served variant buckets — public read (via nginx passthrough). CDN caches with `Cache-Control: public, max-age=31536000, immutable`.

---

{{#IF HAS_MEILISEARCH}}## 7. Meilisearch — search engine (owned by `backend-search`)

Meilisearch is the v1 search backend. Image pin **`getmeili/meilisearch:v1.15`**. Runs as its own deployment (`infra-meilisearch`), port `7700` internal-network-only. **Only `backend-search` talks to Meilisearch directly** — every other service that needs search calls `backend-search`'s REST API.

### 7.1 Index naming — `<owner>_<content_type>`

Underscore, not double-underscore — Meilisearch does not accept `__` in index UIDs.

### 7.2 Persian normalization is applied at index time

The normalization pipeline lives in `backend-search`:

1. Zero-width non-joiner canonicalization (ZWNJ).
2. Character folding: ی ↔ ي, ک ↔ ك.
3. Diacritic fold.
4. Persian → ASCII digit fold on numerically indexed fields.

Applied to every document before it lands in the index; applied to every incoming query. The wrapper never re-normalizes per request — index and query are guaranteed already-canonical.

### 7.3 Not a datastore of record

Every index is rebuildable from `search__mirror_of_content__articles` via shadow-swap resync (RPO = 0).

---

{{/IF}}{{#IF HAS_MIRROR_TABLES}}## Mirror tables — Kafka-driven cross-service replication

Mirror tables (the consumer-side replica of an entity owned by another service — e.g. `search__mirror_of_content__articles`) follow this v1 STANDARD.

### Roles

| Role | What it owns | What it does |
|---|---|---|
| **Origin** | The source-of-truth table (`<owner_service>__<entity>`). | On every create / update / delete, publishes the change as a Kafka event on the shared topic. Also exposes a resync route. |
| **Mirror** | A read-only mirror table named `<consumer_service>__mirror_of_<origin_service>__<origin_entity>`. | Subscribes to the topic; upserts events into the mirror table. Never writes via any other path. |

The table name carries **both** sides of the replication.

### Topic

- Topic name follows §5.1: `<owner>-<consumer(s)>-<entity>-mirror`.
- **Partition key = `record_id`** so updates for the same row are processed in order.
- Payload: `{schema_version, op ("upsert" | "delete"), record_id, updated_at, row}`.
- DLQ per source: `<topic>-dlq`.

### Mirror-side idempotency

- The mirror schema **always** carries `record_id` (PK), `updated_at TIMESTAMPTZ NOT NULL`, and an `INDEX` on `record_id`.
- Upsert uses `INSERT … ON CONFLICT (record_id) DO UPDATE … WHERE EXCLUDED.updated_at > <mirror_table>.updated_at`.

### Sync route — full-table replay

Every origin service exposes an **admin-gated sync route**: `POST /<owner_prefix>/v1/admin/mirrors/<entity>:resync`. Publishes a `resync_started` sentinel, then normal `upsert` events, then a `resync_complete` sentinel.

### Mirror-side resync — shadow-swap (atomic, zero read outage)

Consumer creates `<mirror>_new` under the sentinel, routes resync events into it, and on `resync_complete` takes a Postgres advisory lock and atomically swaps via three `ALTER TABLE … RENAME` statements inside one transaction. Reads against the live mirror never see an empty table during the swap. **RPO = 0.**

### Constraints

- A mirror is **read-only to the rest of the consuming service**.
- A mirror table is **not the source of truth for any decision that affects another service's state**.
- Sync route is **admin-gated and idempotent**.

---

{{/IF}}## nginx — single ingress

Single ingress (the only VM with a public IP); TLS termination via Let's Encrypt; global rate limits; nginx-injected `X-Request-Id`; two upstream pools (REST + realtime where used); `develop` / `staging` additionally gated by HTTP Basic auth; `main` (production) is open. No business logic, no SSR, no per-feature authorization at the edge.

Cluster ops (config templates, TLS renewal, upstream pool config) live in `tech/infra-nginx/docs/v1/PRD-TDD.md`.

---

## How this is enforced

- **Code review rejects:**
  - **Postgres:** non-parameterized SQL or user input in f-strings; request-derived identifiers; tables not following `{{OWNER_TERM}}__<entity>`; {{#IF ARCH_SHAPE=microservices}}cross-service FKs; {{/IF}}DDL in lifespan or outside an Alembic revision; multi-step invariants left non-transactional; high-cardinality list endpoint using `OFFSET` pagination instead of keyset; Alembic migration importing **anything** from `sqlalchemy` or using `op.create_table()` instead of `op.execute("<raw SQL>")`; runtime DB grant on `<{{OWNER_TERM}}>__configurations` exceeding `SELECT, UPDATE (value, description)`.
{{#IF HAS_REDIS}}  - **Redis:** keys without a `<{{OWNER_TERM}}>:` prefix; Redis used as a broker, queue, or durable store; per-{{OWNER_TERM}} ad-hoc client bypassing the shared wrapper.
{{/IF}}{{#IF HAS_KAFKA}}  - **Kafka:** topic names not matching `<sender>-<receiver(s)>-<event>`; multi-receiver topics whose receiver segment is not alphabetically-sorted, `_`-joined; a consumer subscribing to a topic that does not list it; priority encoded in payload instead of in topic name; consumer wired up without a corresponding DLQ.
{{/IF}}  - **MinIO:** bucket names with underscores or without the `<{{OWNER_TERM}}>-` prefix; per-{{OWNER_TERM}} S3 client bypassing the shared adapter; shared access keys across {{OWNER_TERM}}s.
{{#IF HAS_MEILISEARCH}}  - **Meilisearch:** any service other than `backend-search` importing a Meilisearch client; a document ingested without the Persian normalization pipeline.
{{/IF}}- **`ruff` security rules (`S`)** flag risky SQL string construction; **pre-commit** blocks non-conforming code locally.
- **Startup fail-fast:** missing `POSTGRES_DATABASE_URI`{{#IF HAS_REDIS}}, missing Redis URL when the cache file exists{{/IF}}{{#IF HAS_KAFKA}}, missing Kafka bootstrap when the messaging file exists{{/IF}}, missing MinIO credentials — all fail boot.
- **Pre-deploy migration gate (v1):** the GitLab CI/CD pre-deploy job runs `alembic upgrade head` and a drift check. A failure on either fails the deploy. See [`ci-cd.md`](./ci-cd.md).
