# API & Data-Contract — Backend & Frontend

> **Documentation placement.** Cross-repo standard — referenced by every engineering repo (see [`documentation.md`](./documentation.md) §5).

## Scope

Rules for HTTP / REST contracts across Backend (FastAPI / Python / PostgreSQL{{#IF HAS_KAFKA}} / Kafka{{/IF}}{{#IF HAS_REDIS}} / Redis{{/IF}}{{#IF HAS_MEILISEARCH}} / Meilisearch{{/IF}}) and Frontend (TypeScript / Astro 5 landing, Vite 6 + React 19 SPA; static, no SSR). See [`security-and-auth.md`](./security-and-auth.md), [`errors-and-observability.md`](./errors-and-observability.md), [`infrastructure.md`](./infrastructure.md) for adjacent rules.

Applies to **[BE]** and **[FE]**. **[SHARED]** = both.

---

## 1. URL structure & versioning

- Use hierarchical resource URLs. Good: `GET {{API_PREFIX}}<resource>/{id}/<sub>`. Bad: `GET {{API_PREFIX}}get<Sub>?<Resource>Id=...`.
- Pluralise resources. Single resource = `/{resource}/{id}`.
- Path-version at the major level only (`/v1`, `/v2`). Evolve minor versions via additive fields + `Sunset` / `Deprecation` headers.
- Compose each major version as its own versioned router under `src/api/v{N}/router.py`, included into `src/api/main.py` via `app.include_router(v{N}_router, prefix="{{API_PREFIX}}"[:-1])`. **No `app.mount()` sub-apps.** See layout doc.
- Pull {{OWNER_TERM}} prefix and version from env / package metadata. Never hard-code the whole path in a route file.
- No trailing slashes. FastAPI is built with `redirect_slashes=False` so a trailing slash is rejected (404) rather than redirected.
- Path segments are **camelCase** (`/healthCheck`, `/slugHistory`, `/redirectRules`).
- Sub-resources express relationships (`/<resource>/{id}/<sub>`), not query parameters.
- Non-CRUD actions use `POST` with a `:verb` suffix. Examples: `POST /<resource>/{id}:publish`, `POST /auth/tokens:refresh`. Never overload `PATCH` to mean "do an action".

{{#IF LOCALE_MODE=bilingual}}
### 1.1 Locale in the URL

Bilingual content endpoints take `locale` as a **query parameter**, not a path segment on the API side. Path prefixes (`/fa/`, `/en/`) live on the SSG-rendered frontend routes; API endpoints stay locale-agnostic in shape and take the locale explicitly:

```
GET {{API_PREFIX}}<resource>?locale=fa
GET {{API_PREFIX}}search?q=<query>&locale=fa
```

Rejection: `locale` not in `("fa", "en")` → 422. Missing `locale` on an endpoint that requires it → 422 with a clear message.
{{/IF}}

### 1.2 Interactive API docs

- FastAPI's default `/docs`, `/redoc`, `/openapi.json` URLs stay mounted (do not pass `docs_url=None` / `redoc_url=None`). Same gating applies to any introspection surface (internals-exposing health, profiling, PII metrics).
- Gating implementation lives in [`security-and-auth.md`](./security-and-auth.md) §8.

### 1.3 Deprecation

- Set `Deprecation: true` + `Sunset: <RFC 7231 date>` headers on deprecated endpoints (RFC 8594 / RFC 9745).
- Add `Link: <https://.../v2/...>; rel="successor-version"`.
- Set `deprecated: true` in OpenAPI.
- Maintain an internal API change log listing every breaking change and successor ship date.

### 1.4 Frontend

- Base URLs and versions live in one env-driven config module. Never inline.
- Generate a typed client from each backend's OpenAPI (`openapi-typescript`).
- Pin the API version at the call layer.
- On `Deprecation` header: console warning in dev, log-error in prod.
- No string concatenation of URLs in components — always via the typed client.

---

## 2. Response envelope & content negotiation

- Envelope on success: `{success: true, message, data}`. Envelope on failure: `{success: false, message, data, error_code, details?}`. Funnel through a single helper / response class (`ProjectOrjsonResponse`); handlers never hand-build the envelope. Full failure-side contract: §8.
- Envelope is part of OpenAPI (one `ResponseSchema` / `PaginatedDataSchema` base).
- Use `orjson` (Python). On Node, `JSON.stringify` with a streaming layer for very large payloads.
- `Content-Type: application/json; charset=utf-8` explicit. Sitemap / feed endpoints override to `application/xml; charset=utf-8` and skip the envelope. Very large list responses may use `application/x-ndjson`.
- `Vary` on `Accept` / `Accept-Encoding` if multiple representations are served.
- Enable `gzip` / `br` compression at nginx, not in app code.
- Empty collections return `data: []`, never `null`.
- Pagination metadata is part of the contract: `page_size`, `total`, `has_next`. `current_page` is what the client asked for; `total_pages` and `has_prev` are derivable.
- `X-Request-ID` is set by nginx on every response (see §3). The backend does not generate it and does not put server time in the response — server time is logged, not surfaced.

**Don't:**

- Raw error string on failure when success uses an envelope.
- HTML error page when success is JSON.
- `200 OK` with `success: false`.

### 2.1 Frontend

- Unwrap the envelope at the client layer (one `parseEnvelope<T>` helper that throws on `success: false`). Components receive `data`.
- Surface `message` in toasts / banners for non-fatal flows; branch on `error_code`.
- Cache by URL + query + auth scope, not by the envelope.

---

## 3. ID schemes

- **ULID everywhere.** Primary keys, foreign references, trace IDs, idempotency keys — all ULID. No UUID, no integer auto-IDs anywhere (not even internally as a "real" PK behind a ULID surrogate).
- Generate IDs in the service layer, not the database.
- IDs on the wire are opaque strings (`str`, `min_length=1`, `max_length=50`). Never expose raw binary ULID bytes.
- No PII or tenant info in IDs.
- **No prefix-namespacing** on IDs. IDs are bare ULID strings — no `usr_…` / Stripe-style entity tags. Entity type is inferred from context (the field's Pydantic / TypeScript type), not from the ID's shape.
- Validate ULID format on inputs (regex or `python-ulid`) — malformed → 422 before DB.

### 3.1 Trace / correlation IDs

API-surface contract only — generation, propagation, sampling, log injection live in [`errors-and-observability.md`](./errors-and-observability.md).

- Two trace headers ride every API request and response: `X-Request-ID` (human / support reference) and W3C `traceparent` (machine distributed-trace identifier).
- Neither is generated by the API layer. `X-Request-ID` is set by nginx; `traceparent` is managed by the OpenTelemetry SDK.
- **Echoed on every response:** `X-Request-ID`. (`traceparent` is request-only.)
- Length cap on `X-Request-ID`: 64 chars.
- No application-level `request_id` / `session_id` fields anywhere in the contract.

### 3.2 Frontend

- Never generate `X-Request-ID` — read it from response headers (nginx is the source of truth).
- Store the `X-Request-ID` value in client-side error reports so failures can be cross-referenced with backend logs.
- Server-issued IDs in route paths are shareable URLs — treat accordingly.
- IDs are branded types (`type UserId = string & { __brand: 'UserId' }`).

---

## 4. Data-model & schema conventions

### 4.1 Backend (Pydantic v2)

- One DTO per operation × role, named `Model<Op><Kind>For<Role>`. `Op` is the operation (`Create`, `Update`, `List`, `Get`, `Delete`, …); `Kind` is the model's place in the round-trip (`Input` for request, `Output` for response, `Filter` for list query params, `Row` for a list item); `Role` is the caller.

  ```python
  ModelCreate<Entity>InputFor<Role>        # POST /<entity>  — request body
  ModelCreate<Entity>OutputFor<Role>       # POST /<entity>  — response data
  ModelGet<Entity>OutputForAdmin           # GET  /<entity>/{id} — wider field set
  ModelList<Entity>FilterFor<Role>         # GET  /<entity> — query params
  ModelList<Entity>RowFor<Role>            # GET  /<entity> — one row in `data.items`
  ```

  Same operation, different role → different model. Same role, different operation → different model. One file per role variant or grouped by role in `src/api/v1/schemas/<resource>/<op>/<kind>.py`.

- Separate request, response, and envelope models even when identical.
- Every string field has `min_length` and `max_length`.
- Optional fields default to `None`, not `""` / `[]`.
- Request models: `model_config = ConfigDict(extra="forbid")` (unknown fields → 422).
- Response models: `model_config = ConfigDict(extra="ignore")`.
- PATCH uses `model_dump(exclude_unset=True)`. Distinguish explicit `null` from "not provided" via `Optional[T]` + sentinel.
- All datetimes are tz-aware (`AwareDatetime`, UTC). Store UTC; localise on render{{#IF CALENDAR=jalali}} (Jalali via `date-fns-jalali` on human surfaces, ISO-8601 in `<time datetime>` and JSON-LD){{/IF}}{{#IF CALENDAR=dual}} (Jalali sidecar fields travel alongside the UTC field for filter / sort surfaces per [`coding.md`](./coding.md)){{/IF}}.
- `@field_validator` for normalisation (`strip()`, lowercase email, E.164 phone, ULID-format check).
- `@model_validator(mode="after")` for cross-field invariants.
- Shared `BaseModel` base with config.
- No `Any` / broad `dict[str, Any]` in API contracts.
- Composition over deep inheritance for non-role variants.

### 4.2 Backend column-set / allow-list

- Filterable / sortable column sets are explicit code allow-lists, not DB-introspected at runtime.
- CI check parses migration `CREATE TABLE` and asserts every column in `ALL_COLUMNS_NAMES` exists.
- Never accept raw SQL fragments from the client. Advanced filters compile to parameterised SQL via your own AST.
- Document each set: `EQUALITY` (`=` / `IN`), `ILIKE` (`ILIKE '%v%'`), `RANGE` (`BETWEEN` / `>=/<=`).

### 4.3 Frontend (TypeScript)

- Generate types from backend OpenAPI. Never hand-write.
- Validate at the network boundary with `zod`.
- Branded / nominal types for IDs.
- Discriminated unions for response variants: `type Result = { kind: 'ok'; data: T } | { kind: 'err'; code: ErrorCode }`.
- No `any`; use `unknown` and narrow with a schema.
- Dates are `Date` objects inside the app; parse inbound (ISO-8601 UTC), format on render.
- Single `parseEnvelope<T>(response)` helper.

---

## 5. HTTP status & operation contract

| Code | When |
|---|---|
| 200 | Successful read / update with a body |
| 201 | Synchronous resource creation; include `Location: /resource/{id}` |
| 202 | Work queued / async; provide poll mechanism |
| 204 | No body (incompatible with envelope; use `200 + data:null` instead) |
| 301 / 308 | Permanent redirect (`308` preserves method) |
| 400 | Malformed request rejected by framework |
| 401 | Missing / invalid auth; include `WWW-Authenticate` |
| 403 | Authenticated but not authorised |
| **404** | Not found, or not visible to requester (preferred over 403 for ownership) |
| 405 | Method not allowed; include `Allow` |
| 409 | Uniqueness conflict / illegal state transition |
| 410 | Resource permanently removed |
| 412 | `If-Match` / `If-Unmodified-Since` mismatch |
| 415 | Unsupported media type |
| 422 | Validation failure (Pydantic / `field_validator`) |
| 423 | Resource currently locked |
| 429 | Rate limited; include `Retry-After` |
| 500 | Unhandled / unknown |
| 502 / 503 / 504 | Upstream / capacity / timeout |

- 202 includes either a `Location` header to a status endpoint, or a poll-ID + `status` field in `data` (`Cache-Control: no-cache`). The poll ID is a ULID returned in `data`; the request's `X-Request-ID` response header is the trace reference, not the poll handle.
- **429 returns BOTH a `Retry-After: <seconds>` HTTP header (RFC 7231) AND `data.retry_after: <seconds>` in the JSON envelope. The two integers must match.** Optionally include `X-RateLimit-Limit` / `X-RateLimit-Remaining` / `X-RateLimit-Reset` headers when the limit is a quota window.
- **For ownership-scoped resources, return 404, never 403.** Scope all queries at the DB layer.
- Never put stack traces in the body. Log `traceback.format_exc()` server-side; clients use the `X-Request-ID` response header as the support reference.

### 5.1 Idempotency & atomicity

{{#IF PSP_PROVIDER}}
- **`Idempotency-Key` is scoped to finance-only** — used on inter-{{OWNER_TERM}} writes that move money (purchases, refunds, wallet adjustments, referral payouts) so retries don't double-charge or double-credit. Other {{OWNER_TERM}}s don't accept `Idempotency-Key` on their endpoints; they rely on DB uniqueness instead.
- On finance-bound writes that accept `Idempotency-Key: <ulid>`:
  - First request with the key → execute, store response keyed by `(route, idempotency_key, requester)`.
  - Replay within TTL (24 h default) → return stored response without re-execution.
  - Same key, different payload → `409 Conflict`.
{{/IF}}
{{#UNLESS PSP_PROVIDER}}
- **`Idempotency-Key` is not required on any v1 endpoint** — v1 has no money-moving operations. Uniqueness is enforced by DB constraints instead.
{{/UNLESS}}
- All other invariants: DB-level uniqueness constraints + `ON CONFLICT`. No application-level "check then insert".
- Multi-statement invariants in one transaction.
- Hot rows: advisory locks or `SELECT FOR UPDATE`. No application mutexes.
- Outbox pattern for write-then-publish. No in-process `await kafka.send()` after `COMMIT`.

### 5.2 Frontend

- Branch on HTTP status, not message text.
- Surface `retry_after` from 429s and back off automatically.
{{#IF PSP_PROVIDER}}
- Use `Idempotency-Key` on finance-bound mutating calls — generate a ULID per logical user action; same key on retry. Other endpoints don't honour the header.
{{/IF}}
- Debounce destructive actions at the UI level.
- For 202, show resource in `PENDING` state; subscribe via WebSocket / SSE / polling with backoff.
- For 401, run refresh-token flow once globally (Promise lock), not N parallel refreshes.

---

## 6. Filtering, pagination & sorting

| Rule | Value |
|---|---|
| Allowed filter / sort columns | Server-side allow-list; 400 on unknown |
| Default sort | `-created_at` (newest first) |
| Sort tie-breaker | `id` |
| Page size cap | `Query(le=100)` |
| Hot tables / > 100k rows / public APIs | Cursor (keyset) pagination |
| Small admin lists | Offset pagination acceptable |
| Cursor encoding | Opaque `base64(json({created_at, id}))` over indexed `(created_at, id)` |
| Repeat-list params | Compile to `IN (...)`, never `OR` chains |
| Datetime range | `_from` / `_to`, `AwareDatetime` required; reject naive |
{{#IF CALENDAR=dual}}
| Jalali range | Jalali sidecar integer columns map to `>=` / `<=` — no Gregorian round-trip |
{{/IF}}
| Role scoping | Applied in service layer, not router |
| `total` | Return only if cheap; otherwise `has_more` or `Prefer: count=none` (RFC 7240) |

- DB indexes must cover every filter column.

### 6.1 Frontend

- Pagination wrapped in `useInfiniteQuery` / `usePaginatedQuery` hook. Components see `{items, fetchMore, hasMore}`.
- Cache pages by `(filters, sort, cursor)` for cursor APIs.
- Reset pagination when filters change.
- Infinite scroll for content surfaces; explicit pagination for admin tables.
- Filters synchronised with URL.
- Debounce search inputs by 200–400 ms.
- Surface server-side filter validation errors per-field.

---

## 7. Enums & constants

### 7.1 Backend

- `StrEnum` (Python 3.13) for closed string sets. Class `PascalCase`, members `UPPER_SNAKE`.
- Generate a `Literal` alongside the enum.
- Compare to enum members, never bare strings.
- **No catch-all members** — never define an `UNKNOWN`, `OTHER`, `MISC`, or `LEGACY` value. A catch-all hides ingestion bugs (mismatched values silently become "unknown" instead of surfacing as 422), erodes the contract over time, and makes downstream consumers branch on a value that means nothing. Instead: model each state explicitly when introduced, reject unrecognised values at the boundary with 422, and treat an enum mismatch on a downstream consumer as a transport error to investigate.
{{#IF ARCH_SHAPE=microservices}}
- Shared enums live in shared-logic library.
{{/IF}}
- Renaming an enum value is a breaking change: add new value, dual-write through a deprecation window, then remove old.
- Insertion order is meaningful — OpenAPI exposes the order.
- Per-major-version enum variants for closed-but-evolving sets.

### 7.2 Frontend

- TS string-literal unions generated from OpenAPI.
- Enum value → display string in a localisation table, not inline in components.
- Exhaustive `switch` with `assertNever`.
- Store enum literal in state, format at render.
- Unknown enum value = transport error (log it), not a "misc" branch.

---

## 8. Error / exception contract

### 8.1 Backend

- One domain exception type (`ProjectBaseException`). Services raise it; nothing else. Constructor contract (canonical): **required** `status_code, message, error_code`; **optional** `data=None, extra=None`. `success` is **not** a constructor argument — the handler hardcodes `success=False`. `extra` is log-only (never serialised into the HTTP body). Full contract: [`errors-and-observability.md`](./errors-and-observability.md) §2.
- One global handler maps exception → HTTP. Routers and handlers never catch domain exceptions.
- Error envelope:

  ```jsonc
  {
    "success": false,
    "message": "<user-facing message>",
    "data": null,
    "error_code": "<NAMESPACE>_<DETAIL>",
    "details": [
      { "field": "<name>", "code": "REQUIRED", "message": "Missing field." }
    ]
  }
  ```

- `error_code`: stable, `UPPER_SNAKE`, namespaced. Set at the raise site — the handler never invents one (the only handler-injected code is `UNHANDLED_INTERNAL` for non-`ProjectBaseException` crashes).
- `message`: human-readable, optionally localised. No PII, stack traces, or raw DB errors.
- Trace reference for support comes from the `X-Request-ID` **response header** (nginx-issued), not a body field.
- `details[]`: field-level Pydantic errors for 422s.
- Log full stack trace server-side via `traceback.format_exc()`. Never `str(e)`.
- Localise `message` based on `Accept-Language` at the edge. `error_code` stays constant.

### 8.2 Frontend

- Single error type at the client boundary:

  ```ts
  class ApiError extends Error {
    constructor(
      public status: number,
      public code: string,
      public message: string,
      public xRequestId: string,
      public details?: FieldError[]
    ) { super(message); }
  }
  ```

- Catch once; branch on `error.code`, never `error.message`.
- Map field errors to form fields via `setError(name, message)`.
- Show the `X-Request-ID` in error UI (small text, copyable) so users can quote it to support.
- No `console.log(error)` in production. Surface through the design-system error UI.

---

## 9. Authentication & authorization — wire

Full security policy — JWT verifier internals, RBAC tables, ownership scoping, secrets — lives in [`security-and-auth.md`](./security-and-auth.md). This section pins **only the on-the-wire contract**.

### Tokens — on the wire

- **End-user requests:** `Authorization: Bearer <jwt>`. Access tokens short-lived (10–30 min); refresh tokens long-lived and rotated on every use.
- **Inter-{{OWNER_TERM}} requests:** `Authorization: API_KEY <key>`. Constant-time compare server-side.
- **401 envelope:** `{success: false, message: "Your token is invalid" | "Your token is expired", data: null, error_code: "AUTH_INVALID_TOKEN" | "AUTH_TOKEN_EXPIRED"}`. Also sets `WWW-Authenticate: Bearer` (or `API_KEY`).
- **403 envelope:** RBAC miss only; for "resource owned by someone else", return `404`.

### Authorization model — on the wire

- **RBAC by operation, not endpoint.** OpenAPI documents the allowed-role union per operation.
- **Ownership is separate from RBAC** — RBAC = who may call the operation; ownership = which rows it touches.
- v1 stops at RBAC + ownership. No attribute-based / policy-engine layer.

---

{{#IF CURRENCY_UNIT}}
## 10. Money — {{PROJECT_NAME}} currency contract

- **Currency is {{CURRENCY_UNIT}}.**
- Storage: `BIGINT CHECK (>= 0)` (no fractional units).
- Wire: integer as JSON number or `bigint` for TS clients.
- Rendering: locale formatter at the render site only — never in the API layer.
- No currency conversion in v1.

---

{{/IF}}
## 10. Contract testing & governance

### 10.1 Contract testing

- OpenAPI is the contract. Generated from FastAPI; snapshot committed; CI fails on unexpected drift.
- Consumer-driven contract tests (Pact, Schemathesis, Dredd) in CI.
- Property-based testing (Hypothesis, fast-check) for serialisers.
- Snapshot testing on `examples/` JSON files.
- API mocks (Prism, Mockoon, MSW) served from the OpenAPI spec.

### 10.2 Governance

- One team owns the style guide (URL shape, envelope, error codes, headers).
- Spectral / `redocly lint` on OpenAPI gates PRs.
- Per-{{OWNER_TERM}} `CHANGELOG.md` + public API change log for breaking changes.
- Backwards-compat is default: additive ≠ major; removals = major.
- Two-version window: v1 stays usable until v3 ships.

---

## 11. Frontend data-fetching & state contracts

- Data-fetching library (TanStack Query / SWR). No `useEffect(() => fetch(...))` in components.
- Server state ≠ client state. UI state in components / Zustand.
- Optimistic updates for low-risk mutations; roll back on error.
- Query keys mirror REST URLs: `['<resource>', <id>, '<sub>', filters]`.
- Suspense + ErrorBoundary for declarative loading / error states.
- One `apiClient` with auth + retry + envelope unwrap + telemetry. No raw `fetch`.
- Wire fully typed end-to-end.
{{#IF LOCALE_MODE=farsi-only}}
- **i18n / RTL: Farsi-only RTL.** Contract layer uses ISO-8601 dates; rendering does the locale work.
{{/IF}}
{{#IF LOCALE_MODE=bilingual}}
- **Bilingual by parity (Persian RTL + English LTR).** Contract layer uses ISO-8601 dates; rendering does the locale work.
{{/IF}}
{{#IF DIGIT_RULES}}
- **Digit rules:** {{DIGIT_RULES}}
{{/IF}}
{{#IF CURRENCY_UNIT}}
- {{CURRENCY_UNIT}} as `bigint` on the wire; locale-formatter at render.
{{/IF}}

---

## 12. Contract evolution

### Breaking vs non-breaking

- **Additive (non-breaking):** new optional field, new endpoint, new enum value with a default-handling client. Minor release.
- **Subtractive (breaking):** removed field, removed enum value, type change, semantics change, required field added without default. Major release.
- Strict writers: request models use `extra="forbid"`. Tolerant readers: response consumers ignore unknown fields.
- Announce timeline via `Deprecation` + `Sunset` headers; mark surface in OpenAPI.
- Dual-write / dual-read during migration windows.
{{#IF HAS_KAFKA}}
- Schema registry for Kafka events.
{{/IF}}

### CI checks

- Diff OpenAPI spec between PR and main (`openapi-diff`). Flag removed paths, removed required fields, type changes.
- Run the previous version's consumer-driven contract tests against the new server.

---

## 13. Do / Don't

| Topic | Do | Don't |
|---|---|---|
| URL shape | `{{API_PREFIX}}<resource>/{id}` (plural, hierarchical, camelCase segments) | `{{API_PREFIX}}get<Resource>?id=...` |
| Envelope | One shape, every response | Mix `{data}` on success, raw string on failure |
| IDs | ULID, opaque strings, everywhere | UUID or integer (anywhere — wire, DB, code) |
| Status codes | Honour HTTP semantics; **404 over 403 for ownership** | "Always 200" with `success: false` |
| Validation | `extra="forbid"`, bounded strings, `field_validator`s | `Any` / `dict[str, Any]` |
| PATCH | `model_dump(exclude_unset=True)` | Absent fields treated as `None` |
| Pagination | Always; cursor for hot tables; cap `page_size` | Unbounded lists |
| Filters | Server-side allow-list; role-scoped in service | Trust client-provided column names |
| Enums | `StrEnum` + `Literal`; model every state explicitly | Bare strings; `UNKNOWN` / `OTHER` catch-all |
| Errors | One exception → global handler → standard envelope w/ `error_code`; trace ref from `X-Request-ID` response header | Per-handler try / except; stack traces in body |
| Auth header | `Authorization: Bearer <jwt>` for users; `Authorization: API_KEY <key>` for {{OWNER_TERM}}s | Shared API key, `alg=none` |
| Ownership | Service-layer query scoping; 404 not 403 | RBAC alone gates rows |
| Tracing | Propagate W3C `traceparent` + nginx-issued `X-Request-ID` everywhere | Backend / frontend generating its own X-Request-ID |
{{#IF PSP_PROVIDER}}
| Idempotency | `Idempotency-Key` header on finance-bound writes only; DB unique constraints everywhere else | `check_then_act` races; `Idempotency-Key` on non-finance routes |
{{/IF}}
| Frontend types | Generate from OpenAPI; validate with zod at boundary | Hand-write types; `any` |
| Frontend state | TanStack Query / SWR; URL-synced filters | `useEffect(fetch)`; ad-hoc loading flags |
| Deprecation | `Deprecation` + `Sunset` headers; OpenAPI `deprecated: true` | Silent removal |
