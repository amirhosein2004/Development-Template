# {{INFRA_PREFIX}}-{{SERVICE_SLUG}} — Service design (v{{N}})

> Service design doc for the **{{SERVICE_SLUG}}** infra layer of the {{PROJECT_NAME}} platform.
> Lean by design — describes the **layer itself**, not the workloads it carries.
> Platform architecture: [`tech/docs/project-architecture/v{{N}}.md`](../../../docs/project-architecture/v{{N}}.md).
> Standards: [`tech/docs/standards/infrastructure.md`](../../../docs/standards/infrastructure.md) is authoritative. Link them, don't restate.
> Backend section map: `[[docs prd-tdd-backend]]` (Personas, User Journeys, Database schema, API endpoints, Error catalog). Frontend template: [`TEMPLATE-frontend.md`](TEMPLATE-frontend.md). This file is for **infra only** — the discovered `{{INFRA_PREFIX}}-*` repos in this workspace (roles derived from suffix: `-postgresql`, `-redis`, `-minio`, `-meilisearch`, `-kafka`, `-nginx`, `-observability`).

---

> ## Concision mandate (read before writing a single line)
>
> This is an **infrastructure** design doc, not a product PRD and not a consumer PRD. Nine sections, ≤ 1 screen each, **target ≤ ~250 lines total.** A doc exceeding ~300 lines is almost certainly carrying content that belongs elsewhere — go delete it.
>
> **Do NOT enumerate consumer-side detail.** That content already lives in the consuming backend's PRD-TDD (its Data & storage /{{#IF HAS_KAFKA}} Kafka /{{/IF}} API sections); restating it here duplicates-and-rots.
>
> | If you are tempted to write… | Write this instead |
> |---|---|
> | every Postgres table a {{OWNER_TERM}} holds | only the per-{{OWNER_TERM}} prefix (`<{{OWNER_TERM}}>__`) and the owning {{OWNER_TERM}}. Count, not contents. |
{{#IF HAS_REDIS}}
> | every Redis key | only the namespace (`<{{OWNER_TERM}}>:*`) and TTL class. The redirect read cache gets one row, not a key dump. |
{{/IF}}
{{#IF HAS_KAFKA}}
> | every Kafka topic | only the naming contract + a single representative row + count. The canonical topic/DLQ catalog is §3's job as **counts**, the owning backends' PRD-TDDs as contents. |
{{/IF}}
{{#IF HAS_MINIO}}
> | every MinIO object / key shape | only the bucket and its owner. Objects belong to the producing {{OWNER_TERM}}. |
{{/IF}}
{{#IF HAS_MEILISEARCH}}
> | every Meilisearch document field | only the index name (`{{SEARCH_OWNER_SLUG}}_<content_type>`) and its owner (`{{SEARCH_OWNER}}`). |
{{/IF}}
> | every nginx upstream endpoint | only the upstream pool and target {{OWNER_TERM}}. |
> | every metric / log label / dashboard | only ingest path and cardinality budget. |
>
> **Quote, don't paraphrase.** Naming contracts and "only X" invariants come from [`infrastructure.md`](../../../docs/standards/infrastructure.md) and [`project-architecture/v{{N}}.md`](../../../docs/project-architecture/v{{N}}.md). Quote verbatim with the source §-link.
>
> **What lives elsewhere, not here.** Operational procedures → `<repo>/runbooks/*.md` (link only). Decision records → `<repo>/docs/v{{N}}/adr/*.md` (link only). Configuration keys → `<repo>/config/` (link only). Changelog → `git log`. Threat model → security team's separate doc.

---

## 1. TL;DR

<≤ 6 lines. After this paragraph the on-call engineer should know: what this infrastructure is in one sentence, the single-owner invariant only this layer holds, the biggest operational risk, and the recovery posture (RPO / RTO). Nothing else.>

---

## 2. Role + invariants

### 2.1 What this is

<One sentence — e.g. "The single PostgreSQL 17 cluster hosting one logical database per backend {{OWNER_TERM}}", "The single Redis deployment (per-{{OWNER_TERM}} namespaces + the redirect / slug-history read cache)", "The single Apache Kafka cluster — the platform's only async broker", "The single MinIO deployment", "The Meilisearch deployment owned by `{{SEARCH_OWNER}}`", "The single nginx ingress{{#IF CDN_PROVIDER}} behind {{CDN_PROVIDER}}{{/IF}} — the only public entry point", "The observability stack in one repo for cross-tool atomicity".>

### 2.2 What it is NOT

Bound the responsibility — explicitly name what the platform must NOT use this for. Each "not" line eliminates a recurring misuse.

- <e.g. postgresql: "Not a queue and not a full-text engine — async work is Kafka; search is Meilisearch via `{{SEARCH_OWNER}}`.">
- <e.g. redis: "Not a broker, not a job queue, not pub/sub, not Streams — everything in Redis must be reconstructible from PostgreSQL{{#IF HAS_KAFKA}} + Kafka{{/IF}}.">
- <e.g. kafka: "Not a database — topics are transport, not the system of record; retention is bounded.">
- <e.g. minio: "Not a public general-purpose file store — only `<{{OWNER_TERM}}>-<purpose>` buckets, all access via the shared adapter.">
- <e.g. meilisearch: "Not a datastore of record — every index is rebuildable from the mirror table via shadow-swap resync.">
- <e.g. nginx: "Not a CDN{{#IF CDN_PROVIDER}} ({{CDN_PROVIDER}} fronts it){{/IF}} and not an app layer — no business logic, no per-feature authorization at the edge.">
- <e.g. observability: "Not a product-analytics stack — pageviews live in the analytics {{OWNER_TERM}}; this layer observes the platform, not the readers.">

### 2.3 Single-owner invariants

The "only X in the platform" rules this layer carries. **Quote verbatim from architecture; do not restate.**

{{#EACH SINGLE_OWNER_INVARIANTS}}
- {{this.rule}} — architecture {{this.section}}
{{/EACH}}

### 2.4 Out of scope (v{{N}})

Items that may return in v{{N+1}}+ with a trigger.

| Item | Why not in v{{N}} | Trigger to reconsider |
|---|---|---|
{{#EACH OUT_OF_SCOPE}}
| {{this.item}} | {{this.why}} | {{this.trigger}} |
{{/EACH}}

---

## 3. Consumers

Every backend / frontend that depends on this layer, with the **shape** of the dependency and criticality. One row per consumer.

| Consumer | Dependency shape | Criticality | Notes |
|---|---|:---:|---|
{{#EACH CONSUMERS}}
| `{{this.name}}` | {{this.dependency_shape}} | **{{this.criticality}}** | link to [`{{this.name}}/docs/v{{N}}/PRD-TDD.md`](../../../{{this.name_suffix}}/docs/v{{N}}/PRD-TDD.md) {{this.section_hint}} |
{{/EACH}}

> P0 = a v{{N}} outage stops the public read path or the editorial write path; P1 = significant degradation; P2 = best-effort / batch.
>
> **Reference by namespace / prefix only.** Postgres → `<{{OWNER_TERM}}>__` per row, not tables.{{#IF HAS_REDIS}} Redis → `<{{OWNER_TERM}}>:*` + TTL class.{{/IF}}{{#IF HAS_KAFKA}} Kafka → topic count + the DLQ-pairing rule (`<source-topic>-dlq`), not a topic list — day-one consumer families:{{#IF HAS_SEARCH_INDEXER_FLOW}} search-indexer,{{/IF}}{{#IF HAS_WEBHOOK_FLOW}} webhook dispatcher,{{/IF}}{{#IF HAS_AUDIT_FLOW}} audit-recorded stream,{{/IF}}{{#IF HAS_ASSETS_PURGE_FLOW}} CDN-purge (`{{ASSETS_OWNER}}`),{{/IF}}.{{/IF}}{{#IF HAS_MINIO}} Buckets → name + owner, not objects.{{/IF}}{{#IF HAS_MEILISEARCH}} Meilisearch → index names + owner only.{{/IF}} Nginx → upstream pool and target {{OWNER_TERM}}, not endpoints.

---

## 4. Topology + capacity

### 4.1 Topology

<One paragraph: instance count, container image, storage layout, network surface. Optional Mermaid `flowchart` if it adds clarity over prose.>

```mermaid
flowchart LR
{{#IF CDN_PROVIDER}}
  cdn[{{CDN_PROVIDER}} CDN] -->|HTTPS| nginx[nginx :443]
{{/IF}}
  nginx -->|{{PUBLIC_DOMAIN}}| landing[frontend-landing static]
  nginx -->|{{APP_DOMAIN}}| dashboard[frontend-dashboard static]
  nginx -->|/<service>/v{{N}}/*| svc[backend {{OWNER_TERM}}s]
  svc -->|asyncpg| pg[(postgresql :5432)]
{{#IF HAS_REDIS}}
  svc -->|cache| redis[(redis :6379)]
{{/IF}}
{{#IF HAS_KAFKA}}
  svc -->|produce/consume| kafka[(kafka)]
{{/IF}}
{{#IF HAS_MINIO}}
  svc -->|S3 API| minio[(minio :9000)]
{{/IF}}
{{#IF HAS_MEILISEARCH}}
  search[{{SEARCH_OWNER}}] -->|only client| meili[(meilisearch :7700)]
{{/IF}}
  svc -.->|OTLP| otel[observability]
```

### 4.2 Capacity (v{{N}})

| Dimension | v{{N}} target | Source | Headroom trigger |
|---|---|---|---|
| Instances / brokers / pods | {{VM_LAYOUT_DESCRIPTION}} | architecture §8 | second VM added to topology |
| Storage / retention | <GB / days;{{#IF HAS_KAFKA}} partitions-per-topic for kafka;{{/IF}} monthly-partition drop for analytics tables> | <source> | <disk > 70% used> |
| Sustained throughput | <ops/s or MB/s> | <source> | <…> |
| Peak throughput | <ops/s or MB/s> | <source> | <…> |

> Architecture-declared targets quoted verbatim. Engineering estimates without an architecture anchor get `(target — to verify)` + §9 entry.

---

## 5. Operational runbooks

**Links only — never inline the procedure here.** The runbook file is the contract.

| Runbook | Trigger | File | Owner |
|---|---|---|---|
| Start service | clean boot | [`runbooks/start.md`](../../runbooks/start.md) | <maintainer> |
| Stop service | maintenance | [`runbooks/stop.md`](../../runbooks/stop.md) | <maintainer> |
| Minor upgrade | patch bump | [`runbooks/upgrade-minor.md`](../../runbooks/upgrade-minor.md) | <maintainer> |
| Major upgrade | semver major | [`runbooks/upgrade-major.md`](../../runbooks/upgrade-major.md) | <maintainer> |
| Restore from backup | data loss | [`runbooks/restore.md`](../../runbooks/restore.md) | <maintainer> |
{{#IF ROLE=nginx}}
| Rotate TLS cert | pre-expiry (Let's Encrypt) | [`runbooks/rotate-tls.md`](../../runbooks/rotate-tls.md) | <maintainer> |
| Rotate `.htpasswd` | develop / staging Basic-auth credential change | [`runbooks/rotate-htpasswd.md`](../../runbooks/rotate-htpasswd.md) | <maintainer> |
{{/IF}}
{{#IF ROLE=minio}}
| Rotate bucket policy / access keys | policy drift / key leak | [`runbooks/rotate-bucket-policy.md`](../../runbooks/rotate-bucket-policy.md) | <maintainer> |
{{/IF}}
{{#IF ROLE=kafka}}
| DLQ inspect + replay | consumer failure surfaced in `<source-topic>-dlq` | [`runbooks/dlq-replay.md`](../../runbooks/dlq-replay.md) | <maintainer> |
{{/IF}}
{{#IF ROLE=meilisearch}}
| Rotate master key | key rotation policy | [`runbooks/rotate-master-key.md`](../../runbooks/rotate-master-key.md) | <maintainer> |
{{/IF}}
{{#IF ROLE=observability}}
| Reprovision dashboards / alert rules | provisioning drift | [`runbooks/reprovision.md`](../../runbooks/reprovision.md) | <maintainer> |
{{/IF}}

> If a runbook does not exist yet, leave the row, mark the link `(planned)`, and add a §9 entry pointing at the missing file.

---

## 6. SLOs

| Class | Metric | p95 | p99 | Availability (30d) |
|---|---|---|---|---|
{{#EACH SLOS}}
| {{this.class}} | {{this.metric}} | {{this.p95}} | {{this.p99}} | {{this.availability}} |
{{/EACH}}

> Architecture-declared targets verbatim. Per-metric definitions, scrape paths, and dashboards live in the observability repo — do not restate them here.

---

## 7. Disaster recovery

| Property | v{{N}} target | Mechanism |
|---|---|---|
| **RPO** (max data loss) | < <n> min | {{RECOVERY_MECHANISM}} |
| **RTO** (max time to recover) | < <n> min | runbook §5 (`Restore from backup`) |
| Backup cadence | <every <n>> | <which artifact, where stored — nightly snapshot rsynced to a cold VM at a different provider per architecture §8> |
| Backup retention | <n days / months> | <archive policy> |
| Restore drill cadence | <quarterly> | runbook §5 |

### Loss scenarios (one row each, ≤ 3 rows total)

| Scenario | Detection | Recovery | Data loss |
|---|---|---|---|
| Single-node failure | <signal> | <runbook row> | none |
| VM-wide loss | <signal> | <runbook row> | ≤ RPO |
| Data-volume corruption | <signal> | restore + replay | ≤ RPO |

---

## 8. Security boundaries

### 8.1 Network surface

| From | To | Protocol | Port | Auth |
|---|---|---|---|---|
{{#EACH NETWORK_SURFACE}}
| {{this.from}} | {{this.to}} | {{this.protocol}} | {{this.port}} | {{this.auth}} |
{{/EACH}}
| operator | this infra | ssh / admin port | <n> | key + bastion |

> Workspace hard rule: only the nginx repo holds the public entry point{{#IF CDN_PROVIDER}} (behind {{CDN_PROVIDER}}){{/IF}}. Every other infra is internal-only — state this explicitly when it applies.

### 8.2 Authn / authz model

<One paragraph naming the binding mechanism — per-{{OWNER_TERM}} Postgres role with `REVOKE CONNECT … FROM PUBLIC` + `pg_hba.conf` final-reject;{{#IF HAS_REDIS}} per-{{OWNER_TERM}} Redis namespace;{{/IF}}{{#IF HAS_MINIO}} per-{{OWNER_TERM}} MinIO access key scoped to its bucket family;{{/IF}}{{#IF HAS_MEILISEARCH}} Meilisearch master key held only by `{{SEARCH_OWNER}}`;{{/IF}} nginx HTTP Basic auth (`/etc/nginx/.htpasswd`, injected from GitLab CI/CD variables) on every `develop` / `staging` server block, none on `{{PROD_ENV_NAME}}`; Grafana operator accounts for observability. Detailed grant matrices live in the consuming backend's PRD-TDD, not here.>

### 8.3 PII flow

<One line. If this layer holds no PII at rest and only transports it: "No PII at rest. PII flows through but is owned by the producing {{OWNER_TERM}}." If it does hold PII (e.g. phone numbers in `{{AUTH_OWNER}}__*` for postgresql, request logs for observability), name the fields, where, and the redaction policy in ≤ 3 rows.>

---

## 9. Alternatives & open questions

### 9.1 Decisions made

Two to three decisions max. Each decision: what was chosen, the strongest rejected alternative, the trigger that would force a rethink. **Highest-value section for future maintainers** — invest in the rejected-alternative reasoning, not the chosen one.

#### 9.1.<i> Decision — <name>

- **Chosen.** <one-paragraph statement>.
- **Rejected — <alternative>.** Pro: <…>. Con: <…>. Reason: <…>.
- **Trigger to revisit.** <observable metric or external event>.

### 9.2 Open questions

Live list. Closing a question deletes it from here and surfaces the answer in the section it touches (with a one-line note "decided <YYYY-MM-DD>: …" inline). An ownerless question has effectively no answer.

| # | Question | Blocking? | Owner | Target close date |
|---|----------|-----------|-------|-------------------|
| Q1 | <question> | yes / no | <name> | YYYY-MM-DD |

---

## References

- Platform architecture: [`tech/docs/project-architecture/v{{N}}.md`](../../../docs/project-architecture/v{{N}}.md).
- Infrastructure standard: [`tech/docs/standards/infrastructure.md`](../../../docs/standards/infrastructure.md).
- Consumer PRD-TDDs cited in §3 (link each).
- Repo config tree: `<repo>/docker-compose.yml` + `<repo>/config/` (link when present).
- ADRs (if any): [`<repo>/docs/v{{N}}/adr/`](adr/).
- Runbooks: [`<repo>/runbooks/`](../../runbooks/).
