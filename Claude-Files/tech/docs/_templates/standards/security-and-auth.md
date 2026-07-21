# Security & Authentication Standards (tech)

> **Documentation placement.** Cross-repo standard — referenced by every engineering repo (see [`documentation.md`](./documentation.md) §5).

## Scope

Canonical security & authentication reference for every {{PROJECT_NAME}} backend {{OWNER_TERM}}. **[BE]** = backend (Python 3.13 / FastAPI / `asyncpg`{{#IF ARCH_SHAPE=microservices}} / shared-logic library{{/IF}}). **[FE]** = frontend. **[SHARED]** = both.

> **Terminology.** "**Login session**" = the authentication artifact (browser session attached to a JWT, owned by {{JWT_SIGNER_OWNER}} in `auth__login_sessions`).

> **Reading convention:** **CURRENT** = how the code works today. **STANDARD GOING FORWARD** = required target state, not yet implemented.

## Source of truth & precedence

| Source | Role |
|---|---|
| `<{{OWNER_TERM}}>__configurations` table | Runtime source for JWT public key, incoming API keys, bcrypt cost{{#IF OTP_PROVIDER}}, {{OTP_PROVIDER}} API key ({{JWT_SIGNER_OWNER}} in v1){{/IF}}{{#IF CDN_PROVIDER}}, {{CDN_PROVIDER}} API token{{/IF}}{{#IF CAPTCHA_PROVIDER}}, {{CAPTCHA_PROVIDER}} secret{{/IF}}. (JWT algorithm is code-pinned per §2.) |

## 1. Authentication — `check_auth` [BE]

Every endpoint resolves the caller through the single `check_auth` dependency. The JWT verify + API-key plumbing lives in `src/infra/platform/security.py` (or `src/modules/shared/platform/security/jwt.py` in monolith); the FastAPI `Depends()` wrapper that exposes it to routes lives in `src/api/v{N}/deps/auth.py`. **Never decode a JWT or read the `Authorization` header by hand in a router or service.**

```python
if not auth_header:                                  # no header
    return self._create_anonymous_user()             # role = ANONYMOUS
if auth_header.lower().startswith("bearer "):        # Bearer <jwt>
    return await self._authenticate_bearer_token()   # role from roles table
if auth_header.lower().startswith("api_key "):       # API_KEY <key>
    return await self._authenticate_api_key()        # role = SERVICE
self._raise_invalid_token_error()                    # 401
```

`CurrentUser` shape:

```python
CurrentUser(id=<str|None>, role=<UserRoleEnum value>, x_request_id=<str>)
```

Rules:

- `id` is a **string** (a ULID from JWT `uid`); `None` for anonymous and service callers. No integer ids anywhere.
- `x_request_id` is read from the `X-Request-ID` request header (nginx-issued at the edge — see [`api-and-data-contracts.md`](./api-and-data-contracts.md) §3). If absent (only possible when nginx is bypassed in local dev), the backend reads it as `None` and surfaces a warning log — it does not synthesize one.
{{#IF ANONYMOUS_ROLE}}
- Anonymous is a first-class role; not an error.
{{/IF}}

## 2. JWT model [BE]

- **{{JWT_SIGNER_OWNER}} is the only minter of tokens.** {{JWT_SIGNER_OWNER}} holds the private key; every other {{OWNER_TERM}} holds only the public key.
- **Signing algorithm: RS256** (asymmetric). Symmetric (HS256) signing is not permitted cross-{{OWNER_TERM}} in v1.
- Decoding uses PyJWT with a **code-pinned algorithm allow-list**. Never read the algorithm from a mutable config value, never accept `alg=none`, never pass `algorithms=None` or `verify=False`.
- Public key may be read from the config table or a key file mounted at deploy time; the **algorithm constant is in code**.

  ```python
  payload = decode(jwt=token, key=PUBLIC_KEY, algorithms=["RS256"])
  ```

- Payload must contain `uid`; otherwise `401`.
- **Role is NOT looked up inside JWT-verify.** Verification only authenticates; each {{OWNER_TERM}} performs its own role lookup (see §4) after the dependency returns.
- Failure mapping: `ExpiredSignatureError` → `401 "Your token is expired"`; any other decode error → `401 "Your token is invalid"`. Both via `ProjectBaseException`.
- {{JWT_SIGNER_OWNER}} issues tokens (login flow + refresh-token rotation, §2.2); other {{OWNER_TERM}}s only validate.

### 2.1 Claims — v1 access + refresh tokens

| Claim | Required? | Purpose |
|---|---|---|
| `uid` | **required** on access + refresh | ULID of the user. Read into `CurrentUser.id`. Missing → 401. |
| `exp` | **required** on both | Expiration time (Unix seconds). PyJWT auto-checks on `decode`; an expired token raises `ExpiredSignatureError` mapped to 401. |
| `sid` | **required** on refresh | ULID of the Login Session (`auth__login_sessions.id`). Enables the refresh handler to load the session row and compare the version (§2.2). |
| `v` | **required** on refresh | Integer session version (§2.2). Single-use rotation hinge. |
| `iat` | optional | Issued-at (Unix seconds). Useful for debugging. |
| `iss` / `aud` / `nbf` / `jti` | not used in v1 | Don't mint, don't check. |

JWKS / `kid` header lookup is **not used in v1.** The public key is loaded once at boot; key rotation in v1 is "deploy the new key, restart the {{OWNER_TERM}}".

### 2.2 Refresh-token rotation — session-version compare

Refresh tokens are **stateless JWTs**: nothing is stored on the server (no DB row, no Redis entry, no hash) for the refresh token itself. The single-use / instant-revoke property comes entirely from a counter on the Login Session row.

Schema ({{JWT_SIGNER_OWNER}}-only):

- `auth__login_sessions.version INTEGER NOT NULL DEFAULT 1` — the per-session refresh counter.
- `auth__login_sessions.revoked_at TIMESTAMPTZ` — set on explicit logout or on refresh-replay detection.

Flow:

1. **Login.** {{JWT_SIGNER_OWNER}} creates a new `auth__login_sessions` row with `version = 1`, mints a refresh token carrying `{sid, v: 1, uid, exp}`, and returns it (along with the access token). The refresh JWT is the only copy that exists.
2. **Refresh request.** Client posts the refresh token to `POST /auth/v1/tokens:refresh`. {{JWT_SIGNER_OWNER}} decodes it (signature + `exp` + algorithm), reads `sid` and `v` from the payload, loads `auth__login_sessions WHERE id = sid`.
   - **Match** (`payload.v == row.version`): in a single transaction, `UPDATE auth__login_sessions SET version = version + 1 WHERE id = sid`; mint a new refresh token with `v = row.version + 1`; return new access + refresh.
   - **Mismatch** (`payload.v != row.version`): the token has been replayed. Revoke the whole session — `UPDATE auth__login_sessions SET revoked_at = now() WHERE id = sid` — and respond `401`.
   - **Session already revoked / absent / expired:** `401`.
3. **Access tokens** are validated by every {{OWNER_TERM}} via signature + `exp` (no session lookup, no DB call). Their TTL is short (10–30 min) so a revoked session stops issuing access within that window.

This pattern gives single-use rotation, replay detection, and per-session revocation **without ever storing the refresh token server-side.**

### 2.3 Revocation surfaces

- **Log out one session:** `UPDATE auth__login_sessions SET revoked_at = now() WHERE id = ?`. Next refresh on that session → 401; access tokens die when they expire.
- **Log out everywhere (a user):** `UPDATE auth__login_sessions SET revoked_at = now() WHERE user_id = ? AND revoked_at IS NULL`.

{{#IF OTP_PROVIDER}}
### 2.4 v1 identity

Identity in v1 is **phone number** with SMS OTP verification. Login is phone + password **or** phone + one-time SMS OTP (passwordless).

- **OTP SMS delivery in v1 goes through the {{OTP_PROVIDER}} client** — called from {{JWT_SIGNER_OWNER}}. {{OTP_PROVIDER}} is a v1 dependency: server-side verify only, API key stored in the config table and rotated via runtime config (never committed).
- 2FA / TOTP deferred — SMS OTP is not a true second factor when it is also the sole login credential.
{{/IF}}

## 3. Service-to-service auth [BE]

- Header: `Authorization: API_KEY <key>` (not `X-Internal-API-Key`). Validated against `INCOMING_SERVICES_API_KEYS` (comma-separated, from config table); role = `SERVICE`.

  ```python
  valid_api_keys = {k.strip() for k in config_values["INCOMING_SERVICES_API_KEYS"].split(",")}
  if api_key not in valid_api_keys:
      self._raise_invalid_token_error()              # 401
  ```

- Caller reads target base URL + outgoing key from its own config table; sent via a typed agent. Never hard-coded, never ad-hoc `httpx`.
- `SERVICE`-role calls run with elevated trust and are not user-scoped; the calling {{OWNER_TERM}} is responsible for scoping requested data.

**STANDARD GOING FORWARD:**

- Constant-time API-key compare (`hmac.compare_digest`).
- One key per caller; regular rotation; never expose service keys to end users or the browser.

## 4. Authorization / RBAC [BE] — per-{{OWNER_TERM}} roles

Each {{OWNER_TERM}} owns its own RBAC tables. There is **no global role catalog and no shared role table.** A user can be admin in one {{OWNER_TERM}} and a regular user in another by design.

Every {{OWNER_TERM}} has two RBAC tables:

| Table | Purpose | Mutability |
|---|---|---|
| `<{{OWNER_TERM}}>__roles` | Role definitions (`regular_user`, `admin`, `editor`, …) with permission set and `is_default` (exactly one row). PK is `name`. | Read-only at runtime. Populated from a version-controlled seed file. See [`infrastructure.md`](./infrastructure.md). |
| `<{{OWNER_TERM}}>__user_roles` | Role assignments `{user_id, role_name}` + audit columns. At most one row per user. Sparse: default-role users have no row. | Writable by admin endpoints in this {{OWNER_TERM}}. |

Request flow on every {{OWNER_TERM}} (except {{JWT_SIGNER_OWNER}}'s own auth flows):

1. `check_auth` verifies the JWT and attaches a `CurrentUser` with id + trace IDs — **no role information**.
2. {{OWNER_TERM}} looks up the caller in `<{{OWNER_TERM}}>__user_roles`. **If no row exists, the user is treated as having the role with `is_default = true`.**
3. Role name is resolved against `<{{OWNER_TERM}}>__roles` (cached lookup) for the permission set.
4. Authorization (RBAC + ownership) is decided locally.

### 4.1 Base roles every {{OWNER_TERM}} must support

| Role kind | Granted to | Sees |
|---|---|---|
{{#IF ANONYMOUS_ROLE}}
| `ANONYMOUS` | no token | only explicitly public ops |
{{/IF}}
| `CLIENT` | logged-in user (Bearer), no admin role in this {{OWNER_TERM}} | own data only. Default role; sparse. |
| `SERVICE` | another {{OWNER_TERM}} (API_KEY) | per calling {{OWNER_TERM}}'s scoping |
| `ADMIN` (one or more flavours per {{OWNER_TERM}}) | logged-in user with admin row in this {{OWNER_TERM}}'s `<{{OWNER_TERM}}>__user_roles` | full admin surface, scoped by the role's permission set |

`ADMIN` is per-{{OWNER_TERM}}: admin in one {{OWNER_TERM}} grants nothing in another.

### 4.2 Operation gating

- Per-operation, least-privilege. A role-to-service-class map (e.g. `BaseGetServiceDependency`) rejects with `403` **before any business logic runs**. Keys are this {{OWNER_TERM}}'s own role values; not a project-wide enum.
- **Ownership scoping is enforced in the service**, not the router (e.g. `CLIENT` fetch forces `user_id = current_user.id`; the `ADMIN` variant overrides to a no-op). A `CLIENT` can never widen its scope via query params. See [`api-and-data-contracts.md`](./api-and-data-contracts.md) §6.
- **Return `404`, not `403`, for a resource the requester doesn't own.** RBAC `403` from the map miss is different (the role may not use this operation at all).
{{#IF ARCH_SHAPE=microservices}}
- No cross-{{OWNER_TERM}} foreign keys. {{JWT_SIGNER_OWNER}} owns user identity; other {{OWNER_TERM}}s fetch via typed shared-logic agent.
{{/IF}}

### 4.3 RBAC API surface for the admin panel

Every {{OWNER_TERM}} exposes the same three endpoints against its own `<{{OWNER_TERM}}>__roles` / `<{{OWNER_TERM}}>__user_roles` tables:

| Endpoint | Returns | Used for |
|---|---|---|
| `GET /<{{OWNER_TERM}}>/roles/{name}` | Full role definition. | Admin tooling listing / inspecting roles. |
| `GET /<{{OWNER_TERM}}>/userRoles/user/{userId}` | User's assigned role name (or default). | Admin tooling auditing assignments. |
| `GET /<{{OWNER_TERM}}>/me/permissions` | `{role: {name, permissions}}` for the calling user. | Dashboard panel on section click. |

Admin panel pattern:

- **Sidebar sections** come from {{JWT_SIGNER_OWNER}}'s cross-{{OWNER_TERM}} registry (§4.4) — fetched on dashboard load and full page refresh.
- **Tabs within a section** are lazy-fetched from the owning {{OWNER_TERM}} via `/<{{OWNER_TERM}}>/me/permissions` on click; cached in client state for the session; refetched on full refresh.

### 4.4 Cross-{{OWNER_TERM}} admin registry

{{JWT_SIGNER_OWNER}} keeps a cross-{{OWNER_TERM}} mirror of who-is-admin-where as a **JSONB column `admin_roles` on `auth__users`** (no separate table). Shape: `{{{OWNER_TERM}}: role_name}`. **No `role_id`** — names are the stable cross-environment identifier.

Rules:

- Sparse: only {{OWNER_TERM}}s where the user holds a non-default role appear.
- Owning {{OWNER_TERM}} is the source of truth. On promote / demote, the {{OWNER_TERM}} {{#IF HAS_KAFKA}}**publishes a Kafka event** consumed by {{JWT_SIGNER_OWNER}}, which updates the JSONB dictionary{{#ELSE}}calls the {{JWT_SIGNER_OWNER}} admin-role-sync endpoint, which updates the JSONB dictionary{{/IF}}. Eventual consistency.
- The registry is a UI hint only, never the authorization decision. The receiving {{OWNER_TERM}} always re-checks against its own `<{{OWNER_TERM}}>__user_roles` on every admin call.
- Admin panel is shown iff `admin_roles` is non-empty. Sections the user is not admin in are not rendered.
- Demote-to-default publishes a `null`-role event so {{JWT_SIGNER_OWNER}} removes the key, keeping it sparse.
{{#IF HAS_KAFKA}}
- **Topic naming:** single per-{{OWNER_TERM}} topic (`<producer>-auth-admin-role-sync`), following `<producer>-<consumer>-<purpose>`. Event payload `{user_id, {{OWNER_TERM}}, role_name | null}`. DLQ per platform convention.
{{/IF}}

### 4.5 Bootstrapping the first admins

Single repo-root project handles bootstrap: `scripts/initializer/` exposing the `{{PROJECT_SLUG}}-init bootstrap` CLI.

Rules:

- **Input:** admin identifier (email or phone) + target role per {{OWNER_TERM}}. Identifier comes from a deploy-time env var (`SUPER_ADMIN_EMAIL`, `SUPER_ADMIN_PHONE`); never hard-coded in the seed file.
- **API-preferred, DB-fallback.** Script calls normal admin endpoints where possible; writes directly to the DB with admin credentials only where no admin API exists.
- **Idempotent.** Re-running with the same identifier never duplicates rows or fails.
- **No bootstrap tokens.** Script's authority is its possession of admin DB credentials, supplied through the same deploy-time secret channel (§5.1).

## 5. Secrets & configuration [BE]

Configuration is two-tiered:

1. **Boot config — `ENVS` (`pydantic-settings`).** Process-level. Env-var names carry no special prefix; secrets and non-secrets share the same naming. Secret handling (vault, CI masked variables) is out-of-band of the variable name.
2. **Runtime config — {{CONFIG_TABLE_NAME}} table.** Rotatable: incoming API keys allow-list, `BCRYPT_ROUNDS`, OTP TTLs, peer base URLs + outgoing keys, JWT public key{{#IF OTP_PROVIDER}}, {{OTP_PROVIDER}} API key{{/IF}}{{#IF CDN_PROVIDER}}, {{CDN_PROVIDER}} API token{{/IF}}{{#IF CAPTCHA_PROVIDER}}, {{CAPTCHA_PROVIDER}} secret{{/IF}}. (Signing algorithm is code-pinned — §2.)

### 5.1 `.env` files per environment

The platform has four running environments: `local` (developer laptops), `develop`, `staging`, `product`. `ENVS.ENVIRONMENT` takes one of those four values. The branch name (`main`) and the environment name (`product`) are not the same on production — keep them straight.

| Environment | Branch | `.env` policy |
|---|---|---|
| `local` | any feature branch on a laptop | `.env.local` is gitignored; created from `.env.example`; placeholder secrets only. |
{{#UNLESS DEV_BRANCH_CHAIN=main only}}
| `develop` | `develop` | Real `.env`; never committed; injected from CI/CD variables and/or host secret store. |
| `staging` | `staging` | Real `.env`; never committed; injected from CI/CD variables and/or host secret store. |
{{/UNLESS}}
| `product` | `main` | Real `.env`; never committed; injected from CI/CD variables and/or host secret store. |

No managed-cloud secret manager is used. Missing required boot settings fail boot.

Rules:

- Never hard-code secrets. `detect-private-key` pre-commit is a backstop.
- Never commit credentials; never log them (§9).
- **Docs credentials (production only):** `SERVICE_DOCS_USERNAME`, `SERVICE_DOCS_PASSWORD`. Required when `ENVS.ENVIRONMENT == "product"`; ignored on other environments (the site-level nginx Basic auth covers `/docs` / `/redoc` / `/openapi.json` on non-production).

### 5.2 Database access — per-{{OWNER_TERM}} DB roles

The shared Postgres cluster hosts one logical database per {{OWNER_TERM}}. Each {{OWNER_TERM}} must connect with **its own dedicated, database-scoped role** — never a shared role, never a superuser, never another {{OWNER_TERM}}'s role. The DSN in `ENVS.POSTGRES_DATABASE_URI` carries that role's credentials and reaches only that database. Isolation is enforced in **two independent layers** at the cluster — both must hold:

- **Privilege layer.** Default `PUBLIC.CONNECT` is revoked on every database. The {{OWNER_TERM}}'s app role owns its database, which implies `CONNECT` plus full DDL/DML; no other role gets `CONNECT`.
- **Connection layer.** `pg_hba.conf` lists explicit `database` ↔ `user` pairs with a final `reject` line, so a cross-database connection attempt is dropped **before authentication runs** — defence in depth in case a grant ever drifts.

Cluster setup details — `CREATE ROLE` SQL, `pg_hba.conf` template — live in the infrastructure repo's PRD-TDD.

## 6. Password & OTP hashing, replay & rate-limit [BE]

- Passwords and OTP codes hashed with **bcrypt** via passlib `CryptContext`; cost factor is config-driven (`BCRYPT_ROUNDS`, `BCRYPT_SCHEMES`).
- OTPs never stored in plaintext; only `code_hash`. Verification via `hasher.verify_value(provided, code_hash)`.
- **Replay protection:** after a successful verify, all OTPs for `identifier + usage_type` are purged. Expired matches deleted on encounter.
- **Rate limiting:**
  - **OTP resend** throttled by `RESEND_OTP_TTL`; returns `429` with `Retry-After` header AND `data.retry_after` body field (same integer). See [`api-and-data-contracts.md`](./api-and-data-contracts.md) §5.
  - **Login (phone + password)** throttled per-IP and per-identifier{{#IF HAS_REDIS}} (`auth:login_ratelimit:<ip>` and `auth:login_ratelimit:<phone>` in Redis){{/IF}}. Escalating lockout window on repeated failures.
{{#IF CAPTCHA_PROVIDER}}
  - **Anonymous form submissions** throttled per-IP plus **{{CAPTCHA_PROVIDER}} verify** on every submission. `{{CAPTCHA_PROVIDER}}` verified server-side; the verified-token result may be cached briefly to avoid double-charging on retry.
{{/IF}}

**STANDARD GOING FORWARD:**

- Account-enumeration-safe OTP request / verify responses (uniform response / timing regardless of identifier existence).
- Broad rate-limiting / lockout on auth endpoints (per-IP and per-identifier), not just resend.
- `BCRYPT_ROUNDS` ≥ 12; review periodically.
- Constant-time behaviour around verify failures.

## 7. Injection & input safety [BE]

- All SQL is parameterized (`$1, $2 …`) through `DbAction`. Filter / sort columns gated by `constants/db.py` allow-lists. See [`api-and-data-contracts.md`](./api-and-data-contracts.md) §4.
- Validate at the edge: Pydantic request models + `field_validator`s. Request models bound field lengths.
- Authorization context comes only from `check_auth` / `CurrentUser`. Never trust client-supplied user id, role, or scope in the body / query.

**STANDARD GOING FORWARD:** set `extra="forbid"` on request models (`422` on unknown fields).

## 8. Transport, CORS & docs [BE]

- **CORS:** explicit per-environment allow-list (`ENVS.CORS_ALLOW_ORIGINS`), `allow_credentials=True`, explicit method list, explicit header allow-list (notably `X-Request-ID`), `max_age` (`CORS_MAX_AGE_IN_SEC`). **Never pair `allow_credentials=True` with a wildcard origin.**
- **API docs gating:** keep FastAPI's default `/docs`, `/redoc`, `/openapi.json` mounted. On non-production the site-level nginx HTTP Basic auth covers them. On `product` gate them with app-level HTTP Basic using docs credentials from `ENVS` (§5.1).
- **TLS at the edge:** nginx via Let's Encrypt.
- **Security headers emitted at nginx:**

| Header | Value |
|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `SAMEORIGIN` |
| `Content-Security-Policy` | Restrictive CSP allow-listing self{{#IF CDN_PROVIDER}} + {{CDN_PROVIDER}} CDN edges{{/IF}}{{#IF VIDEO_EMBED_PROVIDER}} + {{VIDEO_EMBED_PROVIDER}} embed origin{{/IF}}{{#IF CAPTCHA_PROVIDER}} + {{CAPTCHA_PROVIDER}}{{/IF}}. Never `unsafe-inline` on scripts. |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Deny geolocation, camera, microphone by default. |

The backend does not set any of these — nginx is the sole source.

## 9. Logging & PII [BE / SHARED]

- **Never log:** tokens, passwords, OTP codes, API keys, JWT contents, PII (emails, names, phone numbers), request bodies of auth endpoints.
- **Never expose** stack traces or raw DB / driver errors in HTTP responses; the global handler returns user-safe `message` only. Full diagnostics land in the structured log line that flows to Loki via Promtail (see [`errors-and-observability.md`](./errors-and-observability.md) §1).
- Use structured logging with the nginx-issued `X-Request-ID` value as `x_request_id`. It is safe to surface to users / support as the trace reference.

## 10. Idempotency, atomicity & TOCTOU [BE]

- **No check-then-act (TOCTOU).** Enforce uniqueness / invariants with DB constraints; handle `asyncpg.UniqueViolationError` → `ProjectBaseException(status_code=409, error_code="<NAMESPACE>_CONFLICT", message=...)`.
- **Atomic multi-write** runs inside a single transaction on one connection / `DbAction` call path.
- **Idempotent state transitions:** transition to current state is a no-op success, not an error.

**v1 STANDARD:**

- Circuit breaker around every outbound agent call.

{{#IF PSP_PROVIDER}}
**STANDARD GOING FORWARD:**

- Accept an `Idempotency-Key` on finance-bound inter-{{OWNER_TERM}} writes (purchase, refund, wallet adjust, payout). Non-finance writes rely on DB uniqueness — see [`api-and-data-contracts.md`](./api-and-data-contracts.md) §5.
{{/IF}}

## 11. Frontend [FE]

- **Prefer httpOnly, `Secure`, `SameSite` cookies** for session / refresh token (set by {{JWT_SIGNER_OWNER}} on login response). If a token must be JS-readable, scope it tightly in the persisted client-state session slice; never in plain component state.
- Send `Authorization: Bearer <token>` + trace headers on authenticated requests; centralise in the API client / fetch wrapper. Never scatter raw `fetch` with hand-set auth headers.
- On `401`, clear the session and redirect to login; drive token refresh through a single refresh path.
- **Only bundler-public env vars** reach the browser (Astro: `PUBLIC_*` / `import.meta.env.PUBLIC_*`; Vite: `VITE_*` / `import.meta.env.VITE_*`). Never put a token, API key, or any secret behind these prefixes.
- Lock CORS and cookie domains to known frontend origins per environment.
{{#IF CAPTCHA_PROVIDER}}
- **{{CAPTCHA_PROVIDER}} widget** on anonymous submission forms. Widget script comes from the provider — the only third-party runtime script allowed by CSP. Verified server-side per §6.
{{/IF}}

## 12. PR-review security checklist [SHARED]

- [ ] Auth only via `check_auth` / role dependency — no manual JWT decode.
- [ ] Role looked up in this {{OWNER_TERM}}'s own roles table after `check_auth`; never from the JWT or another {{OWNER_TERM}} on the request path.
- [ ] Every ownership-scoped query is scoped in the service; unowned resources return **404, not 403**.
- [ ] Operation's role map lists exactly the roles allowed (least privilege).
- [ ] Inter-{{OWNER_TERM}} endpoints accept `API_KEY` and run as `SERVICE`; keys / base-URLs from config, never hard-coded.
- [ ] On promote / demote, this {{OWNER_TERM}} publishes the admin-role-sync event; demote-to-default emits `null`.
- [ ] `<{{OWNER_TERM}}>__roles` not modified at runtime — no write endpoints; runtime DB role has no `INSERT` / `UPDATE` / `DELETE` grant on it.
- [ ] {{CONFIG_TABLE_NAME}} rows are immutable at runtime (no `INSERT`, no `DELETE`, no `UPDATE` on `key`); admin can update only `value` and `description`.
- [ ] Default-role users have **no row** in `<{{OWNER_TERM}}>__user_roles`.
- [ ] JWT `decode` uses RS256 with code-pinned `algorithms` allow-list (no `none`, no `verify=False`).
- [ ] All SQL parameterized; filter / sort columns from `constants/db.py` allow-lists.
- [ ] No secrets / PII / tokens / OTP in logs; no raw DB errors or stack traces in responses.
- [ ] Secrets from `ENVS` / config table; nothing hard-coded; production docs credentials required (`SERVICE_DOCS_USERNAME` / `SERVICE_DOCS_PASSWORD`).
- [ ] DB DSN uses the {{OWNER_TERM}}'s own dedicated Postgres role (never a shared / superuser role); the role can `CONNECT` only to this {{OWNER_TERM}}'s database (no `PUBLIC.CONNECT`; `pg_hba.conf` rejects cross-database attempts). See §5.2.
- [ ] Passwords / OTP hashed (bcrypt, config rounds); OTPs purged after verify; resend rate-limited (429).
- [ ] Invariants via DB constraint + `UniqueViolation` → 409 (no TOCTOU); multi-writes in one transaction.
- [ ] CORS allow-list minimal for the environment; `allow_credentials` never paired with `*`.

## 13. How this is enforced

| Standard | Enforcement |
|---|---|
| Single auth entry; per-{{OWNER_TERM}} role gate before logic | `check_auth` (verify only) + local role-to-service-class map (403 on miss) |
| Parameterized SQL; no injection | `DbAction` (`$1,$2`) + ruff `S` (bandit) + review |
| No secrets in code | `detect-private-key` pre-commit + `ENVS` / config-table convention |
| Uniform error envelope; no leaked internals | Global exception handler; `ProjectBaseException(status_code, error_code, message, data=None)` only |
| 404-not-403 scoping; ownership in service | Reviewer rule (checklist) |
| RS256 JWT, code-pinned `algorithms`; expiry → 401 | `check_auth._decode_access_token` |
| bcrypt hashing; OTP replay purge; resend 429 | `BcryptHasher` + OTP verify / resend services |
| CORS allow-list; docs gated | CORS middleware + `product`-only docs Basic-auth dependency |
| Security headers at nginx | nginx config; verified by a Playwright header-assertion smoke test |

**STANDARD GOING FORWARD:** dependency scanning + SBOM in CI; constant-time key compare; secret-manager sourcing.
