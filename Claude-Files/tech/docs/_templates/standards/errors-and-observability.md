# Errors, Logging & Observability Standards (tech)

> **Documentation placement.** Cross-repo standard — referenced by every engineering repo (see [`documentation.md`](./documentation.md) §5).

## Scope

Canonical rules for how errors are raised, caught, logged, surfaced, and tracked in every {{PROJECT_NAME}} backend {{OWNER_TERM}}. Backend-first **[BE]** — Python 3.13 / FastAPI / `asyncpg`{{#IF ARCH_SHAPE=microservices}} / `backend-shared-logic`{{/IF}}. A short **[FE]** note covers frontend error surfacing.

Out of scope: product analytics, frontend observability beyond error surfacing, SLO definitions.

Reading conventions: **CURRENT** = in place today. **v1 STANDARD** = required for v1. **STANDARD GOING FORWARD** = required target, not yet fully in place.

## Source of truth & precedence

| Source | Role |
|--------|------|
| {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic.exception` / `backend_shared_logic.fastapi_exception_handler`{{#ELSE}}`src/modules/shared/platform/exceptions/`{{/IF}} | Canonical exception type + global handler. |
| {{#IF ARCH_SHAPE=microservices}}`src/infra/platform/logging.py`{{#ELSE}}`src/modules/shared/platform/logging/logger.py`{{/IF}} | Logger + JSON formatter setup. |
| {{#IF ARCH_SHAPE=microservices}}`src/infra/platform/exceptions.py`{{#ELSE}}`src/modules/shared/platform/exceptions/handler.py`{{/IF}} | Global exception handler registration. |
{{#IF HAS_OBSERVABILITY_STACK}}| `tech/infra-observability/docs/v1/PRD-TDD.md` | Grafana panels, Loki rules, Alertmanager routes, blackbox probes, OTel Collector config. |
{{/IF}}

---

## 1. Observability surfaces

v1 has **no Sentry / no dedicated APM**. Error tracking rides on the same pipeline as the rest of the logs.

| Surface | Mechanism | Destination | Purpose |
|---------|-----------|-------------|---------|
| Structured logs | stdlib `logging` + `python-json-logger` → stdout | Promtail tails container stdout → Loki → Grafana | Debug timeline, log-based queries, **error aggregation** |
| Distributed traces | OpenTelemetry SDK + auto-instrumentation → OTLP → OTel Collector | Tempo (via Grafana) | Per-request latency + dependency map |
| Metrics | Prometheus-format exporters | Prometheus → Grafana | RED per route, dependency health |
| Alerts | Loki rules + Prometheus rules | Alertmanager → {{ALERTMANAGER_ROUTES}} | Page on error-rate / latency / availability |

Error tracking is **a Loki query, not a separate product**: ERROR-level log lines grouped by `service` × `service_version` × `error_code` drive the Grafana panels and Alertmanager rules. {{#IF HAS_OBSERVABILITY_STACK}}The single observability repo (`infra-observability`) owns the panels, Loki rules, and Alertmanager routes.{{/IF}}

---

# Part 1 — Errors

## 2. One exception type: `ProjectBaseException` [BE] — v1 STANDARD

- Services raise **only** `ProjectBaseException` (or a subclass) from {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic.exception`{{#ELSE}}`src.modules.shared.platform.exceptions`{{/IF}}.
- Constructor args (canonical):
  - **Required:** `status_code` (int), `message` (str, user-safe), `error_code` (stable `UPPER_SNAKE`, namespaced — see [`api-and-data-contracts.md`](./api-and-data-contracts.md) §8).
  - **Optional:** `data=None` (serialised into the response envelope), `extra=None` (dict of diagnostic context attached to the ERROR log line only — **never serialised into the HTTP body**).
- `error_code` is set **at the raise site**, not by the handler. The only default is `UNHANDLED_INTERNAL` for non-`ProjectBaseException` crashes (see §11.1).
- The handler hardcodes `success=False` in the envelope. It is **not** a constructor argument.
- Never raise bare Python exceptions (`ValueError`, `KeyError`, …) or `fastapi.HTTPException` from a service. An `HTTPException` in a service is a review-blocking defect.

```python
raise ProjectBaseException(
    status_code=404,
    message="<Entity> not found.",
    error_code="<{{OWNER_TERM_UPPER}}>_<ENTITY>_NOT_FOUND",
    data=None,
    extra={"requested_id": <id>, "caller_user_id": current_user.id},
)
```

Subclass per {{OWNER_TERM}} for grep-ability (`<{{OWNER_TERM}}>Exception(ProjectBaseException)`).

## 3. Global exception handler [BE]

- Registered once per {{OWNER_TERM}} in {{#IF ARCH_SHAPE=microservices}}`src/infra/platform/exceptions.py`{{#ELSE}}`src/api/main.py` via `src.modules.shared.platform.exceptions.handler.register`{{/IF}} — using FastAPI's `app.add_exception_handler(...)`, **not** ASGI middleware. Middleware-style error handling is a review-blocking defect.
- The registration call passes:
  - `source = ENVS.SERVICE_NAME` — the {{OWNER_TERM}} identifier.
  - `source_version = SERVICE_VERSION` — the per-build release string (see below).
- Handler renders the `{success, message, data, error_code}` envelope, emits one ERROR-level structured log line for every unexpected failure — full traceback, `error_code`, `x_request_id`, `route`, `status_code`, `source`, `source_version`, request context, `extra`.
- Routers do not `try / except` for domain errors — `ProjectBaseException` propagates to the handler.
- Never expose stack traces or raw DB / driver errors in the response body.

### Service version format

`SERVICE_VERSION` is composed at boot from two env vars injected by CI/CD:

| Env var | Source | Example |
|---|---|---|
| `SERVICE_MAJOR_VERSION` | committed per-{{OWNER_TERM}} config | `v1` |
| `SERVICE_BUILD_VERSION` | injected by GitLab CI/CD on every pipeline run, UTC pipeline timestamp `YYYY.MM.DD.HH.MM` + 7-char short SHA after `+` | `2026.06.01.13.05+a1b2c3d` |

Concatenated: **`v1.2026.06.01.13.05+a1b2c3d`**.

Rules:

- Times are **UTC**. The CI/CD job uses `date -u`.
- The `+<short-sha>` suffix is the collision-breaker and the click-through to the exact commit.
- `service_version` is a **log field, not a Loki stream label** — its cardinality blows the Loki index otherwise. Same for `trace_id` and `x_request_id`.

---

## 4. Status-code mapping [BE]

Aligned with [`api-and-data-contracts.md`](./api-and-data-contracts.md) §5.

| Status | When |
|--------|------|
| 400 | Malformed / invalid user input Pydantic didn't reject |
| 401 | Missing / expired / invalid token; bad `API_KEY` |
| 403 | Authenticated but role not permitted |
| 404 | Resource missing **or not owned by the requester** |
| 409 | Uniqueness / duplicate conflict or illegal state transition |
| 422 | Request-shape validation failure (Pydantic / `field_validator`) |
| 429 | Rate limit exceeded — set `Retry-After` header AND `data.retry_after` (matching integer) |
| 500 | Unexpected internal failure (wrapped at a boundary) |
| 502 | Downstream dependency (peer service / SaaS) failed |
| 504 | Downstream dependency timed out |

- Return **404, not 403**, for a resource the requester doesn't own.
- 400 is for bad user input only. Dependency refusals are 502 / 504.
- **Never return an opaque 500 for a dependency failure.**

---

## 5. Exception specificity & wrap-at-boundary [BE]

### 5.1 Catch the narrowest type at every external boundary

| Call site | Catch type |
|-----------|------------|
| `asyncpg` / raw SQL (`DbAction`) | `asyncpg.PostgresError` (e.g. `UniqueViolationError` for conflicts) |
| `httpx` / inter-service agents | `httpx.HTTPError` (+ `httpx.TimeoutException`) |
| Pydantic model construction | `pydantic.ValidationError` |
| Response / dict / attr parsing | `(KeyError, TypeError, AttributeError)` |
| JSON parsing | `json.JSONDecodeError` |

### 5.2 Wrap pattern — CURRENT

Re-raise a `ProjectBaseException` as-is; wrap everything else with `from e`. Prefer specific library types over broad `except Exception`. Map dependency failures to 502 / 504, not 500.

```python
try:
    response = await self.<provider>_agent.call(command)
except ProjectBaseException:
    raise
except httpx.TimeoutException as e:
    raise ProjectBaseException(
        status_code=504,
        message="<Dependency> timed out.",
        error_code="<{{OWNER_TERM_UPPER}}>_<DEP>_TIMEOUT",
        extra={"upstream": "<provider>"},
    ) from e
except httpx.HTTPError as e:
    raise ProjectBaseException(
        status_code=502,
        message="<Dependency> unavailable.",
        error_code="<{{OWNER_TERM_UPPER}}>_<DEP>_UNAVAILABLE",
        extra={"upstream": "<provider>", "upstream_status": getattr(e, "response", None) and e.response.status_code},
    ) from e
```

- `from e` is mandatory when wrapping. `B904` is enabled.
- The `except ProjectBaseException: raise` guard is mandatory whenever a broad `except Exception` follows it.

---

## 6. Broad `except` discipline [BE]

`BLE` is not in the ruff `select` — broad `except Exception` is a review rule.

Acceptable only when one of:

1. Re-raises as a `ProjectBaseException` (the wrap-at-boundary fallback, §5.2).
2. A background supervisor loop (§8) that records the outcome (DB status + structured log), never silently passes.

Prohibited: `except Exception: pass` / `: continue`; silent partial-success in multi-leg operations; re-raising a dependency failure as a misleading `500`.

---

## 7. Data integrity (no ORM) [BE]

- **Conflicts:** DB constraint + `asyncpg.UniqueViolationError`; re-raise as `ProjectBaseException(status_code=409, ...)`. Never check-then-act across two queries.
- **Multi-statement invariants:** run inside a single transaction on one connection / `DbAction` call path.
- **Idempotency:** create-type writes must be idempotent through a natural unique key + `ON CONFLICT`. {{#IF PSP_PROVIDER}}The `Idempotency-Key` header is reserved for finance-bound writes (purchase, refund, wallet adjust, payout).{{#ELSE}}The `Idempotency-Key` header is not required on any v1 endpoint.{{/IF}}

---

## 8. Post-response work, retries & DLQ [BE]

**{{PROJECT_NAME}} does not use FastAPI `BackgroundTasks`** for anything durable. Post-response work is handed off to {{#IF HAS_KAFKA}}the **shared-logic Kafka worker template** — the Kafka consumer base plus `tenacity` retry (`wait_exponential_jitter`, bounded attempts) plus a per-topic DLQ `<topic>-dlq`{{#ELSE}}the **transactional outbox → in-process worker**{{/IF}}. The HTTP response is returned before the worker runs; the worker's outcome cannot affect that response.

### 8.1 Producer / consumer pattern

- Producer (request path) calls the entity's `<Entity>Service` for the synchronous work, then {{#IF HAS_KAFKA}}emits a Kafka event{{#ELSE}}inserts a row into `shared__outbox_tasks` inside the same DB transaction as the entity write{{/IF}}.
{{#IF HAS_KAFKA}}- Topic name follows `<sender>-<receiver(s)>-<event>` (see [`infrastructure.md`](./infrastructure.md) §5).
- Consumer is a handler on the shared-logic Kafka worker template. The template owns retry / backoff / DLQ routing; the handler body owns business-level idempotency and terminal-state persistence.
- Idempotency key on the event payload (natural key).
{{/IF}}{{#IF ARCH_SHAPE=monolith}}- The worker polls `shared__outbox_tasks WHERE status = 'PENDING' ORDER BY created_at LIMIT N`, executes each handler from `src/worker/handlers/`, marks the row `SUCCEEDED` or bumps `attempts` and sets `FAILED` after N retries.
- Failed rows past the retry cap move to `shared__outbox_tasks_dlq`.
{{/IF}}

Rules:

- Never block the request worker on post-response work.
- Retry via `tenacity` — `retry_if_exception_type` on the transient classes, `wait_exponential_jitter`, `stop_after_attempt` (bounded attempts) — never hand-rolled loops.
{{#IF HAS_KAFKA}}- Offsets commit only after the handler completes (at-least-once); a crashed worker re-delivers.
- **DLQ per source.** Handlers that exhaust retries route the event to `<topic>-dlq`. DLQ depth is alertable.
{{/IF}}- Persist terminal state.

### 8.2 Retry mechanism — `tenacity` for third-party API calls

Inside a worker handler (or anywhere in service code), retry transient failures on **outbound third-party API calls** with `tenacity`. Never hand-roll a `for attempt in range(...)` loop.

Third-party APIs in v1: {{OTP_PROVIDER}}{{#IF CAPTCHA_PROVIDER}}, {{CAPTCHA_PROVIDER}}{{/IF}}{{#IF CDN_PROVIDER}}, {{CDN_PROVIDER}}{{/IF}}{{#IF PSP_PROVIDER}}, {{PSP_PROVIDER}}{{/IF}}{{#IF VIDEO_EMBED_PROVIDER}}, {{VIDEO_EMBED_PROVIDER}}{{/IF}}.

Rules:

- `retry_if_exception_type` enumerates the transient classes (timeout, transient 5xx, vendor transient-error subclass).
- `wait_exponential_jitter` — exponential with jitter. Fixed waits cause thundering herds.
- `stop_after_attempt(N)` is total attempts, not "retries past the first."
- No `time.sleep` on the event loop.
- Reserve `tenacity` for third-party APIs. {{#IF ARCH_SHAPE=microservices}}Internal {{PROJECT_NAME}}-to-{{PROJECT_NAME}} calls go through the circuit-breaker pattern (§8.3).{{/IF}}

{{#IF ARCH_SHAPE=microservices}}### 8.3 Circuit-breaker around internal / inter-service agent calls

Every outbound call to a sibling {{PROJECT_NAME}} service via a `backend-shared-logic` agent goes through a circuit breaker. While the breaker is open the agent raises a dependency error mapped to 502 / 504 — no retries in that window.

- Implementation lives once in `backend-shared-logic`'s agent base.
- Defaults: trip after 5 consecutive failures within 30 s; half-open after 15 s; close after 2 consecutive successes. Tunable per agent via `<service>__configurations`.
- Compose with `tenacity`, not against it. `tenacity` retries reserved for third-party APIs (§8.2); the breaker handles sibling-service outages.
- Emits open / close transitions as ERROR-level structured logs with `error_code = CIRCUIT_OPENED` / `CIRCUIT_CLOSED`.
{{/IF}}

---

## 9. Dependency & inter-service failure contract [BE / SHARED]

### 9.1 Rules

- Map downstream rejection to 502, timeout to 504, rate-limit to 429 — never 500 or 400.
- Forward dependency's own message in `data` / `message` **after stripping secrets, internal IDs, and stack traces**.
- No silent auto-retry on deterministic failures; only retry transient classes per §8.
- Carry the `X-Request-ID` (§12) where it can be quoted in a bug report.
- Wrap at the boundary: catch `httpx.HTTPError` / `httpx.TimeoutException`, re-raise as `ProjectBaseException`.

### 9.2 Status map

| Condition | `status_code` |
|-----------|:-------------:|
| Dependency timeout (connect / read) | 504 |
| Dependency rate-limit | 429 — re-emit both `Retry-After` header and `data.retry_after` from the upstream response (pass-through) |
| Any other dependency failure (4xx / 5xx, bad / empty payload) | 502 |
| The user's own input was invalid | 400 |

### 9.3 Frontend surfacing [FE]

- Use a persistent inline error for dependency failures the user must act on. Reserve toasts for incidental issues.
- Neutral styling, not alarming red, for failures originating in an external system.
- Surface at least one concrete unblock path and the `X-Request-ID` as the support reference.
- Never show "something went wrong / try again" with no information.

---

# Part 2 — Logging & observability

## 10. Structured logs

| Rule | Detail |
|------|--------|
| Use `logger`, never `print()` | `print()` is banned (`ruff` `T20`). |
| Structured JSON in production | `python-json-logger`'s `JsonFormatter`. Toggled by `ENVS.SERVICE_LOG_IN_JSON_FORMAT`. |
| Level from config | Root logger level = `ENVS.SERVICE_LOG_LEVEL`. |
| Log to stdout only | Single `StreamHandler(sys.stdout)`. Do not write log files. |
| Full traceback on unexpected failures | `logger.exception(...)` or `logger.error(..., exc_info=err)`. Never log only `str(e)`. |
| Never log secrets or PII | No tokens, passwords, API keys, OTP codes, phone numbers, or names in any log line or `extra`. |
| Never leak internals to client | Stack traces and raw DB errors → structured logs only. |
| Structured `extra={...}` | Thread the nginx-issued `X-Request-ID` as `x_request_id` (§12). |

### PII scrubbing

The shared `JsonFormatter` in {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic`{{#ELSE}}`src/modules/shared/platform/logging/`{{/IF}} runs a formatter-level PII scrub before every log line lands in stdout. Field names that match `password`, `password_hash`, `credential`, `token`, `refresh_token`, `access_token`, `api_key`, `secret`, `otp_code`, `code_hash`, `authorization`, `cookie`, `set-cookie` are replaced with `"[REDACTED]"`. Redaction is deep — nested dicts too. Phone numbers (Iranian shape `09xxxxxxxxx` / `+989xxxxxxxxx`) are redacted to `09xxx****xxx`. Token-shaped strings (JWT-shaped, 32+ hex, `Bearer` prefix) are redacted.

### Log levels

| Level | Use for |
|-------|---------|
| DEBUG | Local detail; disabled in `staging` / `product`. |
| INFO | Lifecycle + one per request outcome (`request_completed`), one per successful post-response task, one per state transition. |
| WARNING | Recoverable degradation (a retry succeeding after N attempts; a circuit-breaker half-open; a fallback path taken). |
| ERROR | `ProjectBaseException` with `status_code >= 500`, or the global handler caught an unhandled exception. Always accompanied by `traceback.format_exc()` in `extra.traceback`. |
| CRITICAL | Process-terminating condition (DB pool exhausted, key material unreadable, config table unreachable). Alertable. |

---

## 11. Error aggregation — logs + Loki + Alertmanager

There is no Sentry / GlitchTip / Bugsnag in v1. Error tracking is a thin layer on top of the existing observability stack{{#IF HAS_OBSERVABILITY_STACK}} (`infra-observability`){{/IF}}: Promtail ships container stdout into Loki, Grafana queries Loki, Prometheus rules over Loki (and metrics) fire into Alertmanager.

### 11.1 What an "error event" is

A single ERROR-level structured log line emitted by the global exception handler (§3) for any unhandled exception that becomes a 5xx. Required fields:

| Group | Field | Source |
|---|---|---|
| Identity | `level` | `"ERROR"` |
| | `error_code` | The exception's `error_code` (or `UNHANDLED_INTERNAL`) |
| | `service` | `ENVS.SERVICE_NAME` |
| | `service_version` | `SERVICE_VERSION` |
| | `environment` | `ENVS.ENVIRONMENT` (`local` / `develop` / `staging` / `product`) |
| Correlation | `x_request_id` | nginx-issued (§12) |
| | `trace_id`, `span_id` | OTel formatter (§14.1) |
| Request | `route` | matched FastAPI route template |
| | `method` | HTTP method |
| | `path_params` | resolved path variables — PII-scrub |
| | `query_params` | query string parsed to dict — PII-scrub |
| | `request_headers` | safe subset only — `User-Agent`, `Accept-Language`, `Content-Type`, `X-Request-ID`, `X-Forwarded-For`, `Referer`. **Never** `Authorization`, `Cookie`, `API_KEY` |
| | `client_ip` | right-most public IP in `X-Forwarded-For` |
| | `user_agent` | echo |
| | `body_size_bytes` | request `Content-Length` |
| Identity-of-caller | `user_id` | `CurrentUser.id` if authenticated |
| | `role` | `CurrentUser.role` if authenticated |
| Response | `status_code` | `500` / `502` / `504` for unexpected; `429` for rate-limited |
| | `exception` | full traceback via `logger.exception(...)` |
| Diagnostic | `extra` | the exception's `extra=` dict — domain-specific context. **Never serialised into the HTTP body.** PII-scrub |

`ProjectBaseException` 4xx outcomes are **not** errors; they're domain results at INFO / WARN. Only 5xx flow through this surface. (Rate-limited 429s land at WARN, sampled.)

### 11.2 Grouping & dashboards

- Group key: `service` + `error_code` + `service_version`. A new `error_code` first-seen on a release is a release-regression signal.
- Per-{{OWNER_TERM}} Grafana dashboard panels:
  - Error rate over `service` × `service_version` × `route`, last 1h / 24h / 7d.
  - Top `error_code`s by count.
  - "First seen this release" — `error_code`s appearing only for the current `service_version`.
- A click from any error panel deep-links to Loki (full traceback + `x_request_id`) and to Tempo (via `trace_id`).

### 11.3 Alerts

- Loki ruler / Prometheus rules evaluate over Loki:
  - **High error rate:** `count_over_time({service="X", level="ERROR"}[5m]) > N` → page ({{ALERTMANAGER_ROUTES}}).
  - **New error_code regression:** first sighting of an `error_code` on the current `service_version` within Y minutes of a deploy.
  - **Dependency-wrap surge:** 502 / 504 wrap rate per {{OWNER_TERM}} over 5m.
- {{#IF HAS_OBSERVABILITY_STACK}}Alert routes live in `infra-observability`, not in the FastAPI {{OWNER_TERM}}s.{{/IF}}
- **No alert is fired from app code.**

### 11.4 Per-environment gating

The platform has **four** running environments. `ENVS.ENVIRONMENT` takes one of these four values:

| Environment | Branch behind it | ERROR logs emitted? | Alert routes |
|---|---|---|---|
| `local` | developer laptops | yes (stdout only) | none |
| `develop` | `develop` branch | yes (to Loki) | none |
| `staging` | `staging` branch | yes (to Loki) | warning channel only |
| `product` | `main` branch | yes (to Loki) | full Alertmanager routing |

The environment name and the branch name are not the same on production — the protected branch stays `main`, but the `ENVIRONMENT` value the app sees is `product`.

### 11.5 Error-code registry

Every `error_code` in the codebase appears in a versioned registry. Naming: `<{{OWNER_TERM_UPPER}}>_<DETAIL>` in UPPER_SNAKE_CASE. A missing catalog entry fails a CI check (STANDARD GOING FORWARD). Examples (project-specific; extend per {{OWNER_TERM}}):

{{ERROR_CODE_CATALOG_EXAMPLES}}

### 11.6 Frontend errors

Both frontends `POST` a small structured event on unhandled errors and unhandled promise rejections{{#IF FE_ERROR_ENDPOINT}} to `POST {{FE_ERROR_ENDPOINT}}`{{/IF}}. Payload: `{route, message, x_request_id (from the last response), stack (truncated to 4 KB), user_agent, locale}`. Unauthenticated, rate-limited at nginx (`limit_req_zone` — 10/min per IP). The backend route emits a normal ERROR-level structured log line with `source = "frontend"`, `service_version = <frontend-build-sha>`, and the payload fields. Loki dashboards aggregate `source="frontend"` as a side stream.

---

## 12. Trace ID

Every request carries one trace identifier:

| Header | Meaning |
|--------|---------|
| `X-Request-ID` | This single HTTP request — generated **by nginx at the edge**, never by the frontend, never by the backend |

Rules:

- nginx generates a fresh `X-Request-ID` per inbound request. Format: uppercase base32 ULID — 26 chars.
- Backend reads it from the request header into `CurrentUser.x_request_id` (or a `ContextVar`) and threads it into every structured log line as `x_request_id`.
- Every response header echoes `X-Request-ID`.
- Inter-{{OWNER_TERM}} calls (HTTP, {{#IF HAS_KAFKA}}Kafka, {{/IF}}{{#IF HAS_REDIS}}Redis, {{/IF}}etc.) forward the inbound `X-Request-ID` unchanged. W3C `traceparent` carries the broader distributed-trace context where present.
- No legacy `request_id` / `session_id` fields anywhere.

---

## 13. Health, readiness & warm-up

Three orthogonal endpoints. Each answers a different question for a different caller.

| Endpoint | Question it answers | Caller | Behavior |
|---|---|---|---|
| `GET /<PREFIX>/v1/healthCheck` | "Is the process alive?" | container runtime **liveness probe** | Shallow — returns `{"status": "ok"}` with no I/O. |
| `GET /<PREFIX>/v1/readiness` | "Can this pod take traffic right now?" | container runtime **readiness probe** + ingress | Verifies the `asyncpg` pool is open and `SELECT 1` succeeds. |
| `GET /<PREFIX>/v1/warmup` | "Wake every dependency so the next user-facing request doesn't pay the cold-start tax." | Frontend on app-boot, peer backends before their first call{{#IF HAS_OBSERVABILITY_STACK}}, observability cron, blackbox probe{{/IF}}. | Touches every outbound dependency in parallel; returns per-dependency status map. Always 200. |

### 13.1 What `/warmup` does vs what it doesn't

**Does:**

- Open one asyncpg connection, run `SELECT 1`, return it.
- HEAD on MinIO with a short timeout.
{{#IF HAS_REDIS}}- Read a fixed Redis key (`<service>:warmup`), then set it back.
{{/IF}}- HEAD or short GET on every peer-service the {{OWNER_TERM}} routinely calls.
{{#IF HAS_KAFKA}}- Produce a no-op tombstone Kafka message to a per-{{OWNER_TERM}} `<service>-self-warmup` topic.
{{/IF}}- Return per-dependency status map (always 200).

**Does not:**

- Mutate user data.
- Affect circuit-breaker / retry state for real user traffic.
- Page on its own.
- Require authentication (unauthenticated so the frontend can fire it before login completes). Rate-limit at the ingress.
- Cascade through the whole graph — service A's `/warmup` calls B's `/healthCheck`, not B's `/warmup`.

---

## 14. Metrics & tracing

Distributed tracing is **OpenTelemetry-based**; metrics are Prometheus-format.

### 14.1 Distributed tracing — OpenTelemetry + W3C Trace Context

- **Library: OpenTelemetry SDK.** Never hand-roll W3C `traceparent` parsing.
- **Auto-instrumentation only.** Contrib packages for FastAPI, httpx, asyncpg{{#IF HAS_KAFKA}}, aiokafka{{/IF}}{{#IF HAS_REDIS}}, Redis{{/IF}}{{#IF HAS_MEILISEARCH}}, Meilisearch (via httpx auto-instrumentation){{/IF}}.
- **Propagator: `TraceContextTextMapPropagator`** set globally.
- **First-hop spans:** if `traceparent` is absent on inbound (only possible when nginx is bypassed in local dev), the SDK creates a fresh root span.
- **Sampling: decide once at the first hop, propagate via flags.** Set `OTEL_TRACES_SAMPLER` to `parentbased_traceidratio`. Production ratio: 5–10% baseline; always-sample on errors (tail-based) via the OTel Collector. Develop / staging: 100%.
- **Backend: OTel Collector → Tempo.** Tempo is the only trace store in v1.
- **`tracestate` is reserved.** Don't put business data or PII in it.
- **Log ↔ trace correlation.** The JSON formatter pulls the active span's `trace_id` and `span_id` and injects them into every log record.

### 14.2 Why `X-Request-ID` AND `traceparent`

| Aspect | `X-Request-ID` | `traceparent` |
|---|---|---|
| Generated by | nginx edge | OpenTelemetry SDK on root hop |
| Audience | Humans (support, user-visible error UI) | Machines (Tempo trace stitching) |
| Shape | ULID (26 chars, easy to read / copy) | 55-char hex string |
| In response headers | Yes (echoed) | No (request-only) |
| Same value across hops | Yes | trace-id constant; parent-id refreshes per hop |
| Visible in error UI | Yes (support reference) | No |

### 14.3 Metrics

- **RED per endpoint** (Rate, Errors, Duration). Exported in Prometheus format.
- **Baseline metrics:** `http_requests_total{method, route, status_code}` counter; `http_request_duration_seconds{method, route}` histogram; {{#IF HAS_KAFKA}}Kafka consumer lag per topic; {{/IF}}{{#IF HAS_REDIS}}Redis hit ratio; {{/IF}}DB pool size gauges.
- **Alerts on rate, not on instances.**

---

## 15. Summary rules

- Services raise `ProjectBaseException` only with `status_code`, `message`, `error_code`; `extra` is log-only.
- The global handler shapes `{success, message, data, error_code}` and emits one ERROR log line with full request context.
- Narrow catch → re-raise as `ProjectBaseException` with `from e`. Prefer specific library types over `except Exception`.
- Dependency failures → 502 / 504 / 429, not 500 / 400.
- Post-response work runs on {{#IF HAS_KAFKA}}the shared-logic Kafka worker template{{#ELSE}}the transactional outbox + worker{{/IF}} — never FastAPI `BackgroundTasks`.
- Logs to stdout only; Promtail ships them to Loki.
- `x_request_id`, `trace_id` / `span_id`, and `service_version` enrich every log line via the shared formatter; PII scrubbing is formatter-level defense-in-depth.
- Error aggregation is a Loki query, not a separate product.
- PII never leaves the process in a log or HTTP body.
- Three orthogonal probes: liveness (`/healthCheck`), readiness (`/readiness`), warm-up (`/warmup`).

---

## How this is enforced

| Standard | Enforcement |
|----------|-------------|
| Only `ProjectBaseException` raised from services with `status_code`, `message`, `error_code` | Reviewer rule; global handler assumes it |
| `error_code` set at raise site | Reviewer rule (§2) |
| Global handler maps every error → envelope + ERROR log line | Canonical handler from {{#IF ARCH_SHAPE=microservices}}`backend_shared_logic.fastapi_exception_handler`{{#ELSE}}`shared/platform/exceptions/handler.py`{{/IF}} |
| `raise ... from e` when wrapping | `B904` ruff rule (enabled) |
| No `print()` for diagnostics | `T20` in ruff `select` |
| No `except: pass` / `: continue` | `S110` / `S112` + reviewer rule |
| No stack traces / raw DB errors in responses | Reviewer rule; handler returns user-safe `message` |
| No secrets / PII in logs or HTTP body | Formatter-level PII scrubbing (§10); reviewer-enforced |
| 404-not-403 for unowned resources | Reviewer rule |
| Post-response work via {{#IF HAS_KAFKA}}shared-logic Kafka worker template{{#ELSE}}outbox + worker{{/IF}} | Reviewer rule (§8.1) |
| Retries via `tenacity` reserved for third-party APIs | Reviewer rule (§8.2) |
{{#IF ARCH_SHAPE=microservices}}| Circuit breaker around every internal / inter-service agent call | `backend-shared-logic` agent base; reviewer rule (§8.3) |
{{/IF}}| Dependency failures → 502 / 504 / 429 | Reviewer rule (§9) |
| Structured JSON logging enriched with `x_request_id`, `trace_id`, `service_version` | Shared `JsonFormatter` |
| Frontend errors POSTed to a single backend endpoint | Reviewer rule (§11.6) |
| Liveness / readiness / `/warmup` exposed by every {{OWNER_TERM}} | Reviewer rule (§13); `/warmup` is unauthenticated and idempotent |
