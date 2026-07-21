# CI/CD, Tooling & Enforcement Standards (tech)

> **Documentation placement.** Cross-repo standard (see [`documentation.md`](./documentation.md) §5).

## Scope

Canonical build, CI gate, deployment, tooling, and enforcement reference for every {{PROJECT_NAME}} {{#IF ARCH_SHAPE=microservices}}backend microservice{{#ELSE}}engineering repo{{/IF}}. Backend-first [BE]; short [FE] sections cover the frontend apps; [INFRA] covers `infra-*` / `devops-*` repos. Out of scope: rule semantics — see [`coding.md`](./coding.md), [`documentation.md`](./documentation.md), [`testing.md`](./testing.md).

Reading conventions: **CURRENT** = today; **v1 STANDARD** = required for v1, in force now. Anything tagged "post-v1 follow-up" is out of scope for v1.

## Project-wide infrastructure facts (authoritative)

- **No cloud infrastructure.** No GCP / AWS / Azure. Services run as containers (Docker / docker-compose) on project-owned infrastructure. Any mention of "host platform" / "container registry" / "secret store" means on-premises hosting.
- **CI/CD is {{CI_HOST}}.** Only `.gitlab-ci.yml` on GitLab Runners. No GitHub Actions, no Jenkins. All gates and build / push / deploy jobs are CI jobs.
{{#IF CDN_PROVIDER}}
- **CDN in front of nginx.** {{CDN_PROVIDER}} sits at the DNS layer in front of nginx; TLS terminates at nginx (Let's Encrypt) and the CDN adds a second edge TLS hop.
{{/IF}}

## Source of truth & precedence

| Source | Role |
|---|---|
| `{{OWNER_TERM}}/.gitlab-ci.yml` | CI/CD pipeline (build / push / deploy + CI gates). Only sanctioned path to production. |
| `{{OWNER_TERM}}/docker/Dockerfile.<role>` | Production image, one per entrypoint role (`api`, `consumer`, `cronjob`, `worker`). |
| `{{OWNER_TERM}}/docker/docker-compose.yml` | Local dev stack. |
| `{{OWNER_TERM}}/.pre-commit-config.yaml` | Local quality gate. |
| `{{OWNER_TERM}}/pyproject.toml` | `[project]` deps + all tool config (no separate `ruff.toml` / `pytest.ini`). |
| `{{OWNER_TERM}}/uv.lock` | uv lockfile, full transitive tree. Committed. |
| `{{OWNER_TERM}}/.vscode/{settings,launch,extensions}.json` | Editor (Pylance) config. |

On disagreement between this doc and the source files, the source files win — update this doc.

## Master enforcement table

| Artifact | Enforces | Backs |
|---|---|---|
| `pyproject.toml` `[tool.ruff]` | Lint families `E,W,F,I,B,C4,UP,ARG,SIM,RUF,D,S,T20,ANN` | [`coding.md`](./coding.md), [`errors-and-observability.md`](./errors-and-observability.md) |
| `pyproject.toml` `[tool.mypy]` | Static typing (`disallow_untyped_defs`) | [`coding.md`](./coding.md) |
| `pyproject.toml` `[tool.pytest.ini_options]` / `[tool.coverage.*]` | Test discovery, coverage | [`testing.md`](./testing.md) |
| `.pre-commit-config.yaml` | `ruff --fix` + `ruff-format` + `mypy` + hygiene{{#IF SECRET_SCANNER}} + `gitleaks`{{/IF}} on commit | [`coding.md`](./coding.md), [`git.md`](./git.md) |
| `pyproject.toml` + `uv.lock`{{#IF ARCH_SHAPE=microservices}} + `GITLAB_PAT`{{/IF}} | Pinned deps via uv{{#IF ARCH_SHAPE=microservices}}; shared-logic install from git{{/IF}} | [`{{#IF ARCH_SHAPE=microservices}}microservice-layout{{#ELSE}}monolith-layout{{/IF}}.md`](./{{#IF ARCH_SHAPE=microservices}}microservice-layout{{#ELSE}}monolith-layout{{/IF}}.md) |
| `docker/Dockerfile.<role>` | Per-entrypoint production images | layout §2 |
| `docker/docker-compose.yml` | Local dev stack | layout doc |
| `.gitlab-ci.yml` | Single-stage `build-push-deploy` via CI/CD | layout doc, [`git.md`](./git.md) |
| `.gitlab-ci.yml` MR pipeline | **v1 STANDARD:** `ruff check` + `ruff format --check` + `mypy src/` + `pytest --cov=src --cov-fail-under={{BE_COVERAGE_FLOOR}}`{{#IF ARCH_SHAPE=microservices}} + shared-logic version-lock{{/IF}} on every MR | [`coding.md`](./coding.md), [`testing.md`](./testing.md), [`git.md`](./git.md) |
| `.gitlab-ci.yml` pre-deploy migration gate | **v1 standard:** `alembic upgrade head` + drift check before the new app revision serves | [`infrastructure.md`](./infrastructure.md), layout doc |

---

## 1. Local quality gate (pre-commit) [BE] — CURRENT

**Wired via `make install`** (`uv sync` + `uv tool install pre-commit==4.0.1` + `uvx pre-commit install --install-hooks`) — the canonical single-command setup per §9, mandatory on every fresh clone. Without it, `.git/hooks/pre-commit` is not created and none of the hooks below fire on `git commit`. Never bypass with `git commit --no-verify`.

| Hook | Source | Args |
|---|---|---|
| `ruff` | `ruff-pre-commit` **v0.14.10** | `--fix` |
| `ruff-format` | same | — |
| `mypy` | `mirrors-mypy` **v1.19.1** | `src/`, `pass_filenames: false` |
| `trailing-whitespace`, `end-of-file-fixer` | `pre-commit-hooks` **v6.0.0** | — |
| `check-json`, `check-yaml` (`--unsafe`), `check-toml` | same | — |
| `detect-private-key` | same | — |
{{#IF SECRET_SCANNER}}
| `gitleaks` | `gitleaks/gitleaks` **v8.18.0** | — |
{{/IF}}

Global: `exclude: ^scripts/`; `default_stages: [pre-commit]`; `fail_fast: false`. Pre-commit is bypassable — the unbypassable counterpart is the MR pipeline (§6).

---

## 2. Tooling configuration (exact values)

### 2.1 Ruff — `pyproject.toml` `[tool.ruff]`

```toml
line-length = 120
target-version = "py313"
```

`[tool.ruff.lint]`:

```toml
select = ["E", "W", "F", "I", "B", "C4", "UP", "ARG", "SIM", "RUF", "D", "S", "T20", "ANN"]
ignore = [
    "E501",               # line length handled by the formatter
    "ARG001", "ARG002",   # unused args common in interfaces / overrides
    "D100", "D104",       # module / package docstrings optional
    "D203", "D212",       # use D211 / D213
    "F401",               # don't auto-remove unused imports
]
```

Per-file ignores:

```toml
[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401", "F403"]
```

Excluded paths: `.git`, `__pycache__`, `venv`, `.venv`, `build`, `dist`, `.vscode`, `scripts`, `migrations`, `tests/**`.

`[tool.ruff.format]`:

```toml
indent-style = "space"
quote-style = "double"
skip-magic-trailing-comma = false
```

### 2.2 Mypy — `pyproject.toml` `[tool.mypy]`

```toml
python_version = "3.13"
exclude = ["scripts/", "migrations/", "tests/"]
explicit_package_bases = true
mypy_path = "."
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
ignore_missing_imports = true
```

### 2.3 Pre-commit — `.pre-commit-config.yaml`

Hooks in order, pinned:

1. `astral-sh/ruff-pre-commit` @ **`v0.14.10`** — `ruff` (`args: [--fix]`), `ruff-format`.
2. `pre-commit/mirrors-mypy` @ **`v1.19.1`** — `mypy` (`args: [src/]`, `pass_filenames: false`).
3. `pre-commit/pre-commit-hooks` @ **`v6.0.0`** — `trailing-whitespace`, `end-of-file-fixer`, `check-json`, `check-yaml` (`--unsafe`), `check-toml`, `detect-private-key`.
{{#IF SECRET_SCANNER}}
4. `gitleaks/gitleaks` @ **`v8.18.0`** — secret scan on staged files.
{{/IF}}

Global: `default_stages: [pre-commit]`, `fail_fast: false`, `exclude: ^scripts/`.

Ruff / Mypy versions in `pyproject.toml` `[dependency-groups.dev]` MUST match `.pre-commit-config.yaml`. Bump in lockstep.

### 2.4 Pytest & coverage — `pyproject.toml`

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
norecursedirs = ["scripts", "migrations"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
pythonpath = ["."]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"
minversion = "7.0"
addopts = ["-v", "--strict-markers", "--tb=short"]
markers = ["unit: ...", "integration: ...", "e2e: ...", "asyncio: ..."]
```

Coverage (`[tool.coverage.*]`): `source = ["src"]`; omits tests / `__init__.py` / venv / scripts / migrations; outputs to `tests/.coverage`, `tests/htmlcov`, `tests/coverage.lcov`.

Rules:

- `--strict-markers` — unknown marker fails the run.
- `asyncio_mode = "auto"` — no marker needed for async tests.
- **Coverage is gated in CI at ≥ {{BE_COVERAGE_FLOOR}}%** via `pytest --cov=src --cov-fail-under={{BE_COVERAGE_FLOOR}}` per [`testing.md`](./testing.md). The gate ratchets up, never down — a PR that lowers the previous number fails the build.

---

## 3. Dependencies{{#IF ARCH_SHAPE=microservices}}, `GITLAB_PAT`, and the shared-logic version lock{{/IF}}

Python deps managed by **uv**. No `requirements.txt`.

- `pyproject.toml` `[project].dependencies` — direct production deps, pinned patch-floating-minor.{{#IF ARCH_SHAPE=microservices}} Shared-logic library installed from a pinned tag in a private repo:

  ```toml
  [project]
  dependencies = [
      "fastapi==0.124.*",
      "asyncpg==0.31.*",
      "backend-shared-logic @ git+https://x-access-token:${GITLAB_PAT}@gitlab.example/{{PROJECT_SLUG}}/backend-shared-logic.git@v1.4.7",
  ]
  ```

- `${GITLAB_PAT}` — deploy token (read-repository scope), passed as a Docker `ARG` from a CI masked variable. Never commit; never bake into the image layer history.{{/IF}}
- `pyproject.toml` `[dependency-groups].dev` — `ruff`, `pytest`, `pytest-asyncio`, `pytest-cov`, `mypy`, `pre-commit`.
- `uv.lock` — committed, hash-verified. Reproducible installs via `uv sync --frozen`.

**Cross-repo version alignment.** Any package that appears in more than one {{PROJECT_NAME}} repository must be pinned to **the same version** across every repository that uses it. Bump in lockstep.

{{#IF ARCH_SHAPE=microservices}}
### 3.1 Shared-logic version-lock CI gate — v1 STANDARD

Shared-logic distributes as a versioned library; every consumer must run at the same version.

Every backend service's `.gitlab-ci.yml` MR pipeline runs the following check:

```yaml
shared-logic-version-lock:
  stage: mr-gates
  image: python:3.13-slim-bookworm
  script:
    - export PINNED=$(grep -oE 'backend-shared-logic[^@]*@v[0-9.]+' pyproject.toml | grep -oE 'v[0-9.]+')
    - export LATEST=$(git ls-remote --tags https://x-access-token:${GITLAB_PAT}@gitlab.example/{{PROJECT_SLUG}}/backend-shared-logic.git 'v*' | awk '{print $2}' | sed 's|refs/tags/||' | sort -V | tail -1)
    - test "$PINNED" = "$LATEST" || (echo "backend-shared-logic pinned to $PINNED but latest is $LATEST — merge the bump MR opened by the shared-logic release job first"; exit 1)
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

Rules:

- **Fails the MR pipeline** if the pinned version is not the latest release tag. Policy is strictly current-release.
- The release process for shared-logic opens an **automated MR into each consumer repo** bumping the pin. Human step is "review + merge".
- Deploy order for a shared-logic change: cut the library release → merge the bump MR in every consumer → deploy consumers in any order.
{{/IF}}

Commands:

```bash
uv sync --frozen                # install from lockfile
uv sync --frozen --group dev    # include dev tools
uv add <pkg>                    # add a runtime dep + relock
uv add --group dev <pkg>        # add a dev dep + relock
uv run pytest                   # run inside the project env
```

Post-v1 follow-up: dependency / vulnerability scanning (`uv-secure` / `pip-audit`) + SBOM (`syft`) in CI.

---

## 4. Docker images [BE]

One Dockerfile per entrypoint the service ships; no cap. Common roles: `api`, `consumer`, `cronjob`, `worker`. Add any others as `src/<role>/main.py` + `docker/Dockerfile.<role>`.

Every role is launched through the root-level dispatcher `__main__.py`: `python __main__.py <role>`. One container runs exactly one role.

| Image | Role |
|---|---|
| `docker/Dockerfile.api` | HTTP API process (`python __main__.py api`). |
{{#IF HAS_KAFKA}}
| `docker/Dockerfile.consumer` | Kafka consumer (`python __main__.py consumer`). |
{{/IF}}
| `docker/Dockerfile.cronjob` | Scheduled-jobs runner (`python __main__.py cronjob`). |
| `docker/Dockerfile.<role>` | Any other entrypoint. |
| `docker/docker-compose.yml` | Local dev stack (app + Postgres{{#IF HAS_REDIS}} + Redis{{/IF}}{{#IF HAS_KAFKA}} + Kafka{{/IF}}{{#IF HAS_MINIO}} + MinIO{{/IF}}{{#IF HAS_MEILISEARCH}} + Meilisearch{{/IF}} + every entrypoint the service ships). |

All Dockerfiles share the base image and the uv-driven install layer; only `CMD` / `ENTRYPOINT` differs.{{#IF ARCH_SHAPE=microservices}} Each takes build-arg `GITLAB_PAT`.{{/IF}}

### 4.1 Production Dockerfile rules

- **Base:** `python:3.13-slim-bookworm`.
- **Multi-stage:** *builder* installs `git` / `curl` + uv, runs `uv sync --frozen --no-dev` to produce a self-contained `.venv` → *final* stage copies only the venv + `src/` + `__main__.py`.
- **Non-root:** runs as `appuser`.
- `ENV PYTHONDONTWRITEBYTECODE=1`, `PYTHONUNBUFFERED=1`, venv on `PATH`.
- `EXPOSE 8080` (API images only).
- **HEALTHCHECK** (API images only): `curl -f http://localhost:8080/<SERVICE_ENDPOINT_PREFIX>{{API_PREFIX}}healthCheck` — interval 300s, timeout 10s, start-period 40s, retries 3.
- `ENTRYPOINT` per role — always the root dispatcher `__main__.py`, role passed as the first positional arg.

### 4.2 Local stack — `docker/docker-compose.yml`

- Each service process built from its `Dockerfile.<role>`, `env_file: ${ENV_FILE_NAME}`, mounts `./src` + `./__main__.py` for live reload.
- Per-{{OWNER_TERM}} Postgres container — `<{{OWNER_TERM}}>-db`: `postgres:17.10-bookworm`, `pg_isready` healthcheck.
- Network `{{PROJECT_SLUG}}-network` is **external** — create once: `docker network create {{PROJECT_SLUG}}-network`.
- Health path / port consistent across services: `GET /<SERVICE_ENDPOINT_PREFIX>{{API_PREFIX}}healthCheck` on port `8080` for every API image.

---

## 5. Deploy pipeline — {{CI_HOST}} [BE] — CURRENT

`.gitlab-ci.yml` is the only sanctioned path to production. **One stage, `build-push-deploy`**, runs one job per `Dockerfile.<role>` present in `docker/`. Each job performs all three steps in sequence:

1. **Build** — `docker build -f docker/Dockerfile.<role>` with `--cache-from <image>:latest`{{#IF ARCH_SHAPE=microservices}} and `--build-arg GITLAB_PAT=$GITLAB_PAT`{{/IF}}. Tag `:<role>-$CI_COMMIT_SHA` and `:<role>-latest`.
2. **Push** — to the project's container registry.
3. **Deploy** — to the project-owned host runtime. Surface `GIT_BRANCH_NAME=$CI_COMMIT_REF_NAME`. Application logs to stdout.

Rules:

- Single pipeline stage; do **not** split build / push / deploy into separate stages. One job per role does all three.
- Each container's `ENTRYPOINT` is the root dispatcher (`python __main__.py <role>`).
- Service composes versioned routers via `app.include_router(v1_router, prefix=...)` in `src/api/main.py` — no `app.mount()` sub-apps.
- Secrets injected by the host environment as plain env vars (from CI masked variables and/or an on-host secret store).

The merge-blocking MR pipeline that runs §6 gates is a separate pipeline triggered on MR events; it does not share the deploy stage.

### 5.1 Pre-deploy migration gate [BE] — v1 STANDARD

Every backend service whose container talks to PostgreSQL gates its rollout on a pre-deploy migration job — **manually triggered** before the `build-push-deploy` job swaps in the new app revision.

| Step | Command | Failure semantics |
|---|---|---|
| Apply migrations | `uv run alembic upgrade head` | Non-zero exit → **deploy fails**; new revision does not start serving. |
| Drift check | Compare declared schema (latest revision + per-entity SQL files) against `alembic_version` head and `information_schema`. | Any mismatch → **deploy fails**. Resolve by writing the missing forward migration; never hand-edit production schema. |

Rules:

- Same CI/CD pipeline as the deploy; sequenced **before** the per-role `build-push-deploy` jobs touch the runtime.
- Same image build context as `Dockerfile.api` (Alembic installed).
- Wrap in Alembic's advisory lock; pair with `op.execute("SET lock_timeout = '5s'")` inside each migration body.
- Migrations applied with the **owner role** scoped to that {{OWNER_TERM}}'s database (DDL privileges), not the runtime app role.

The migration-test suite (clean Testcontainers Postgres + `information_schema` assertions) backing this gate lives in [`testing.md`](./testing.md).

---

## 6. CI gates — every MR [BE] — v1 STANDARD

| Gate | Command | Failure semantics |
|---|---|---|
| Lint | `uv run ruff check src/` | Non-zero exit → MR blocked |
| Format | `uv run ruff format --check src/` | Any diff → MR blocked |
| Types | `uv run mypy src/` | Any error → MR blocked |
| Tests + coverage | `uv run pytest --cov=src --cov-fail-under={{BE_COVERAGE_FLOOR}}` | Failing test, coverage < {{BE_COVERAGE_FLOOR}}%, or regressed → MR blocked |
{{#IF ARCH_SHAPE=microservices}}
| Shared-logic version-lock | §3.1 script | Not-current → MR blocked |
{{/IF}}
{{#IF SECRET_SCANNER}}
| Secret scan | `gitleaks detect --source .` on the full repo | Any secret → MR blocked |
{{/IF}}

Rules:

- Pin `ruff` / `mypy` versions in `pyproject.toml` `[dependency-groups.dev]` to match `.pre-commit-config.yaml`. Bump in lockstep.
- Run on every MR commit, not only on the merge commit.
- `ruff` and `mypy` run on `src/` — `scripts/`, `migrations/`, `tests/` excluded per project config.
- Cache `~/.cache/uv` and `~/.cache/pre-commit` between jobs.
- No `--no-verify` / `--no-check` overrides in CI.
- Required status check on the default branch — MRs cannot merge with a failing pipeline.

---

## 7. Versioning [BE] — CURRENT

- Per-{{OWNER_TERM}} Semantic Versioning (`MAJOR.MINOR.PATCH`) in `pyproject.toml` `[project].version`.
- API is path-versioned (`v1`); a new major version is a new versioned router included alongside the old one — `src/api/v2/router.py` mounted via `app.include_router(v2_router, prefix=...)`. No `app.mount()` sub-apps.
- Each {{OWNER_TERM}} versions and deploys independently.

---

## 8. Frontend [FE] — STANDARD (greenfield)

For every frontend repo (`frontend-landing` = Astro 5 SSG; other frontends = Vite 6 + React 19 static SPA); see [`frontend.md`](./frontend.md):

- **Local gate — installed automatically by `pnpm install`.** Every fresh clone triggers `pnpm install`, which runs the `"prepare": "husky"` script; Husky v9 sets `core.hooksPath=.husky` and wires the checked-in hook files.
- **Hook files (checked in, one per repo):**
  - `.husky/pre-commit` → `pnpm exec lint-staged` — runs `eslint --fix` + `prettier --write` on staged `*.{ts,tsx,js,jsx,astro}`.
  - `.husky/commit-msg` → `pnpm exec commitlint --edit "$1"`.
- **Pinned dev deps (same version across all frontend repos):** `husky ^9.1.0`, `lint-staged ^15.2.0`, `@commitlint/cli ^19.6.0`, `@commitlint/config-conventional ^19.6.0`.
- **Build:** `astro build` (`output: 'static'`) for landing, `vite build` for the SPAs. All produce static assets served by platform nginx — no Node at the edge, no SSR.
- **CI gates:** `pnpm install --frozen-lockfile`, then `lint` + `typecheck` + `test` + `build` + contract-drift + visual-regression must pass before merge.

Per each repo's onboarding hard rules, agents must verify `.husky/pre-commit` exists before running `git commit`; if missing, run `pnpm install` first.

### 8.1 ESLint boundaries [FE] — v1 STANDARD

The vertical-slice ring discipline in [`frontend-layout.md`](./frontend-layout.md) (feature ring ↔ shared ring; no cross-feature imports; no shared-ring import from a feature) is enforced by **`eslint-plugin-boundaries`**. Nothing else in the toolchain catches a `from '@features/<x>/...'` inside `@features/<y>/...`.

| Concern | Setting |
|---|---|
| Pinned dev dep | `eslint-plugin-boundaries ^5.0.0` — same version across every frontend repo. |
| Element definitions (SPA) | `{ type: 'shared', pattern: 'src/shared/*' }`, `{ type: 'feature', pattern: 'src/features/*/*' }`, `{ type: 'router', pattern: 'src/router/*' }`. |
| Element definitions (Astro landing) | `{ type: 'lib', pattern: 'src/lib/*' }`, `{ type: 'components', pattern: 'src/components/*' }`, `{ type: 'layouts', pattern: 'src/layouts/*' }`, `{ type: 'copy', pattern: 'src/copy/*' }`, `{ type: 'feature', pattern: 'src/features/*/*' }`, `{ type: 'page', pattern: 'src/pages/*' }`. |
| Rules | `boundaries/element-types` = **error**; `feature → shared` allowed; `feature → feature` **disallowed**; `shared → feature` **disallowed**; `router → feature` allowed (routes only). |
| Escape hatch | None. Promote to the shared ring, don't `// eslint-disable`. |
| Excluded paths | The generated OpenAPI directory, `dist/`, `coverage/`, `.astro/`. |

Failure semantics: any violation is a **v1 STANDARD** lint error and blocks the MR pipeline via `pnpm lint`.

### 8.2 Contract-drift check (frontend side) [FE] — v1 STANDARD

Every frontend regenerates its typed API client from the live OpenAPI spec of each backend it consumes via `scripts/codegen.ts`, writing into `src/shared/api/generated/` (SPA) or `src/lib/api/generated/` (landing). Drift between the committed generated types and the deployed backend's OpenAPI spec is the single largest cause of "backend deploy → frontend blank screen" incidents.

**Env vars every frontend CI job needs** (masked, one per consumed backend; the list comes from `scripts/codegen.ts`'s `BACKENDS` array). SPA repos use Vite's `VITE_*` prefix; Astro landing uses `PUBLIC_*` (`import.meta.env.PUBLIC_*`) — never `VITE_*`.

`scripts/codegen.ts` `console.warn`s and skips any backend whose env var is unset — unset vars are non-fatal in local dev and hard-fail in CI only if the drift check trips.

#### 8.2.1 MR-time drift check [FE] — v1 STANDARD

Runs on every MR pipeline in every frontend repo:

```yaml
codegen:drift:
  stage: build-deploy
  script:
    - pnpm codegen
    - git diff --exit-code src/shared/api/generated/     # landing: src/lib/api/generated/
    - pnpm typecheck
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

| Step | What it catches | Failure semantics |
|---|---|---|
| `pnpm codegen` | Runs `scripts/codegen.ts` — fetches every consumed backend's `openapi.json` and re-emits `<service>.ts`. | Non-zero exit → MR blocked. |
| `git diff --exit-code` | Deployed schema differs from the schema committed in this MR. | Any diff → MR blocked with the offending file(s) named. |
| `pnpm typecheck` | Fresh generated types break existing frontend code. | Any type error → MR blocked. |

Rules:

{{#UNLESS DEV_BRANCH_CHAIN=main only}}
- Gates every MR into `develop` / `staging` / `main` — the standard three-branch flow per [`git.md`](./git.md).
- **Points at the `develop` environment's backends**, not `staging` or `main`. Because the flow is always `develop → staging → main`, a backend that has landed in `develop` will land in `staging` before any frontend MR gets there.
{{/UNLESS}}
{{#IF DEV_BRANCH_CHAIN=main only}}
- Gates every MR into `main`.
{{/IF}}
- Generated files under the generated directory are **committed to the repo**. `.gitignore` MUST NOT list `generated/`.
- The generated directory is excluded from lint (§8.1) and from coverage.

#### 8.2.2 Scheduled drift check [FE] — v1 STANDARD

A **scheduled pipeline** closes the window when a backend deploys a schema change while no frontend MR is in flight. Same three-step job as §8.2.1, triggered by `$CI_PIPELINE_SOURCE == 'schedule'`. Cadence:

{{#UNLESS DEV_BRANCH_CHAIN=main only}}
| Target branch | Cadence |
|---|---|
| `develop` | every hour, on the hour |
| `staging` | daily at 03:00 (project timezone) |
| `main` | daily at 03:00 (project timezone) |
{{/UNLESS}}
{{#IF DEV_BRANCH_CHAIN=main only}}
| Target branch | Cadence |
|---|---|
| `main` | every hour, on the hour |
{{/IF}}

On failure, the CI emails the scheduled pipeline's owner. The fix is a one-line MR: `pnpm codegen` locally, commit the regenerated files, MR to the affected branch. Schedule configuration is a **`README.md`-linked runbook step**, not a committed YAML. A failing scheduled pipeline does NOT block deploys.

### 8.3 Visual regression [FE] — v1 STANDARD

Neither unit tests, `pnpm typecheck`, nor `pnpm size` catch a design-token that quietly changes a card's contrast, a padding tweak that breaks a modal, or a self-hosted font swap that renders wrong under RTL. The failure mode is "the code is right; the pixels are wrong" — the only sanctioned automation is **Playwright's screenshot diff**.

| Concern | Setting |
|---|---|
| Runner | `@playwright/test` |
| Test location | `tests/e2e/visual/*.visual.spec.ts` |
| Baseline location | `tests/e2e/visual/__screenshots__/*.png` — committed alongside the specs |
| Baseline images tracked with | **Git LFS** — the `.gitattributes` entry `*.png filter=lfs diff=lfs merge=lfs -text` covers this |
{{#IF LOCALE_MODE=farsi-only}}
| Deterministic locale | `use.locale = 'fa-IR'` — RTL and Persian digits render identically across CI and local |
{{/IF}}
{{#IF LOCALE_MODE=bilingual}}
| Deterministic locale | Two Playwright projects — one per locale (`fa-IR`, `en-US`) |
{{/IF}}
| Viewport pinning | Two projects per repo: `visual-desktop` at 1280×800 (`Desktop Chrome`) and `visual-mobile` at 390×844 (`iPhone 14`) |
| Themes | Every surface has TWO screenshots — daylight and midnight — via `page.emulateMedia({ colorScheme: 'dark' })` |
| Update workflow | `pnpm test:e2e --update-snapshots` — the ONLY sanctioned way to change a baseline |
| Failure semantics | Any pixel diff → MR blocked with the failing test's `-diff.png` published as an artifact |
| Tolerance | Playwright default `maxDiffPixels: 100`, `maxDiffPixelRatio: 0.001` |
| Skip triggers | Zero — `test.skip` on a visual spec is a review-blocking defect |

Job wired as a separate CI job (`visual`) with `mcr.microsoft.com/playwright:v1.49.1-jammy`.

---

## 9. First-time setup

1. Install **uv** (`curl -LsSf https://astral.sh/uv/install.sh | sh`).
{{#IF ARCH_SHAPE=microservices}}
2. Export `GITLAB_PAT`.
{{/IF}}
3. **`make install`** — the single-command setup:
   - `uv sync` — installs the project's Python deps + dev tools.
   - `uv tool install pre-commit==4.0.1` — installs `pre-commit` as a workspace-wide global uv tool.
   - `uvx pre-commit install --install-hooks` — writes `.git/hooks/pre-commit` and pre-downloads every hook env.

   Verify with `ls -la .git/hooks/pre-commit`.

4. `docker network create {{PROJECT_SLUG}}-network` (once), then `docker compose --env-file .env.local -f docker/docker-compose.yml up [--build]`.

---

## 10. How this is enforced

| Stage | Gate |
|---|---|
| Edit time | Pylance live in VS Code (`.vscode/settings.json`). |
| Commit time (local) — **backend** | `pre-commit`: `ruff --fix` → `ruff-format` → `mypy src/` → hygiene hooks{{#IF SECRET_SCANNER}} → `gitleaks`{{/IF}}. Requires `make install` on every fresh clone. Bypassable via `--no-verify` — forbidden. |
| Commit time (local) — **frontend** | Husky: `.husky/pre-commit` → `pnpm exec lint-staged`; `.husky/commit-msg` → `pnpm exec commitlint --edit`. Auto-installed by `pnpm install`. |
| MR pipeline — backend | CI MR pipeline gating `ruff check` + `ruff format --check` + `mypy src/` + `pytest --cov=src --cov-fail-under={{BE_COVERAGE_FLOOR}}`{{#IF ARCH_SHAPE=microservices}} + shared-logic version-lock{{/IF}}{{#IF SECRET_SCANNER}} + secret scan{{/IF}}. Blocks merge on failure. |
| MR pipeline — frontend | CI MR pipeline gating `pnpm lint` (includes ESLint boundaries §8.1) + `pnpm typecheck` + `pnpm test --coverage` + `pnpm build` + contract-drift (§8.2.1) + visual-regression (§8.3). Blocks merge on any failure. |
| Scheduled pipeline — frontend | Hourly / nightly scheduled pipeline re-runs the contract-drift job. Emails the pipeline owner on red; does NOT block deploys. |
| Pre-deploy | CI pre-deploy migration gate: `alembic upgrade head` + drift check. Non-zero exit fails the deploy. |
| Deploy time | CI (`.gitlab-ci.yml`) single-stage `build-push-deploy` job per `docker/Dockerfile.<role>`. |

If a value here drifts from config files, the config files win — update this doc.
