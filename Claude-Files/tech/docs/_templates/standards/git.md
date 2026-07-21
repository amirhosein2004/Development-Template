# Git — Engineering-Specific Standards (tech)

> **Documentation placement.** Cross-repo standard — referenced by every engineering repo (see [`documentation.md`](./documentation.md) §5).

Engineering-only layer of {{PROJECT_NAME}}'s git conventions. Applies to every code repository under `tech/` — `backend-*`{{#IF ARCH_SHAPE=microservices}}, `infra-*` / `devops-*`{{/IF}}, `frontend-*` — but **not** to `tech/docs/` itself (which follows the docs-repo baseline).

Extends the cross-repo baseline at [`../../docs/standards/git.md`](../../docs/standards/git.md). Read that document first; this file adds deltas specific to deployed code. If a baseline rule and an engineering rule disagree, the engineering rule wins for code repos.

---

## Table of Contents

1. [Engineering-Specific Repository Hygiene](#1-engineering-specific-repository-hygiene)
2. [Deployment Branch Model](#2-deployment-branch-model)
3. [The Hotfix Multi-MR Protocol](#3-the-hotfix-multi-mr-protocol)
4. [Engineering Branch Scopes](#4-engineering-branch-scopes)
5. [Quality Gates](#5-quality-gates)
6. [The `feature` MR Test Rule](#6-the-feature-mr-test-rule)
7. [Engineering Tooling Stack](#7-engineering-tooling-stack)
8. [SemVer Mapping](#8-semver-mapping)
9. [Tag & Release Conventions](#9-tag--release-conventions)
10. [Engineering Antipatterns](#10-engineering-antipatterns)
11. [Bootstrapping a New Code Repository](#11-bootstrapping-a-new-code-repository)

---

## 1. Engineering-Specific Repository Hygiene

### 1.1 Code-specific `.gitignore` categories

In addition to the baseline (OS metadata, editor scratch files, workspace dirs), engineering repos must ignore:

| Category | Examples |
|---|---|
| Secrets & credentials | `.env`, `.env.*` (except `.env.example`), `*.pem`, `*.key`, `*.p12`, `credentials.json`, `service-account*.json`{{#IF IGNORE_PROVIDER_TOKENS}}, provider tokens ({{IGNORE_PROVIDER_TOKENS}}){{/IF}}, kubeconfig copies |
| Build artifacts | `dist/`, `build/`, `out/`, `target/`, `*.pyc`, `__pycache__/`, `.next/`, `.astro/`, `.vite/`, `*.o`, `*.so`, `.coverage`, `htmlcov/`, `playwright-report/`, `test-results/` |
| Dependencies | `node_modules/`, `vendor/`, `.venv/`, `venv/`, `__pypackages__/` |
| Local-only configs / infra overrides | `*.local`, `.env.local`, `docker-compose.override.yml`, `.dev-secrets/`, generated `kubeconfig` snippets |
| Local data volumes | `data/postgres/`{{#IF HAS_REDIS}}, `data/redis/`{{/IF}}{{#IF HAS_KAFKA}}, `data/kafka/`{{/IF}}{{#IF HAS_MINIO}}, `data/minio/`{{/IF}}{{#IF HAS_MEILISEARCH}}, `data/meilisearch/`{{/IF}} |

Once a secret is in git history, treat it as compromised even after rewrite.

### 1.2 Code-specific `.gitattributes` patterns

Append to the baseline skeleton:

```gitattributes
# Engineering text formats.
*.py      text eol=lf
*.ts      text eol=lf
*.tsx     text eol=lf
*.js      text eol=lf
*.jsx     text eol=lf
*.astro   text eol=lf
*.sh      text eol=lf
*.sql     text eol=lf
*.toml    text eol=lf
*.conf    text eol=lf

# Windows-only scripts keep CRLF.
*.bat     text eol=crlf
*.ps1     text eol=crlf

# Archive / binary types — never diff, never normalize.
*.zip     binary
*.tar.gz  binary
*.woff2   binary

# Binary / LFS-tracked patterns (see §1.5).
*.psd     filter=lfs diff=lfs merge=lfs -text
*.sketch  filter=lfs diff=lfs merge=lfs -text
*.fig     filter=lfs diff=lfs merge=lfs -text
*.mp4     filter=lfs diff=lfs merge=lfs -text
*.png     filter=lfs diff=lfs merge=lfs -text
```

The `*.png filter=lfs` line is load-bearing for visual-regression screenshots on the frontend repos (see [`ci-cd.md`](./ci-cd.md) and [`testing.md`](./testing.md)).

### 1.3 Lockfiles are committed; build outputs are not

**Commit:** `pnpm-lock.yaml`, `uv.lock`, `poetry.lock` (if a repo uses it), `Cargo.lock`, `go.sum`, `composer.lock`.

**Do not commit:** `dist/`, `build/`, `.astro/`, anything produced by `tsc`, `vite build`, `astro build`, `cargo build`, `mvn package`.

### 1.4 Automated secret scanning

Three tiers, mandatory in every engineering code repo:

1. **`pre-commit` hook** with [gitleaks](https://github.com/gitleaks/gitleaks) — refuses the commit if a secret pattern matches staged files.
2. **CI scan on every MR** — full repo scan with allowlist for known false positives.
3. **Periodic full-history scan** — weekly scheduled pipeline over the entire history.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

**If a secret is committed:**

1. Rotate the secret immediately.
2. Rewrite history with `git filter-repo --invert-paths --path <leaked-file>` (or `--replace-text` for inline secrets).
3. Force-push; notify everyone with a clone to re-clone.
4. Audit access logs for the leaked credential.

Never commit-first-then-gitignore. `git rm --cached` does not remove from history.

### 1.5 Git LFS for binaries > 100 KB

Configure at repo init, not retroactively:

```bash
git lfs install
git lfs track "*.psd" "*.sketch" "*.fig" "*.mp4" "*.zip" "*.woff2" "*.png"
git add .gitattributes
git commit -m "maintenance(root): configure git-lfs for binary assets"
```

Repo-specific additions: frontend repos add `public/fonts/*.woff2` and `tests/e2e/visual/__screenshots__/*.png` (visual-regression baselines); design-asset repos add the formats they ship (`*.ai`, `*.indd`, large `*.png` mockups).

Threshold: > 100 KB.

---

## 2. Deployment Branch Model

{{#IF DEV_BRANCH_CHAIN=main only}}
Deployed code repos use a single long-lived branch: `main`. Every change lands via MR from a topic branch cut off fresh `main`; there is no `develop`/`staging` promotion chain.

**Applies to:** every engineering repo in this project (single-repo {{ARCH_SHAPE}} shape).
{{#ELSE}}
Deployed code repos use three long-lived branches: `develop → staging → main`.

| Branch | Audience | Environment served |
|---|---|---|
| `develop` | Engineering integration | develop environment (auth-gated) |
| `staging` | QA / Product review | staging environment (auth-gated) |
| `main` | Production | production environment |

**Three-branch model does not apply to:** docs repos (`docs/`, `business/docs/`, `product/docs/`, `tech/docs/` — use only `main`); libraries / SDKs (use `main` + release tags); solo repos with no QA stage.
{{/IF}}

### 2.1 Protection rules

{{#IF DEV_BRANCH_CHAIN=main only}}
`main` carries the baseline protection rules: no direct push, no force push, required approvals, required green pipeline, required up-to-date branch, linear history, auto-delete source branch on merge.
{{#ELSE}}
All three branches carry the baseline protection rules: no direct push, no force push, required approvals, required green pipeline, required up-to-date branch, linear history on `main`, auto-delete source branch on merge. The hotfix exception (§3) disables auto-delete per MR for `fix/*` branches.
{{/IF}}

### 2.2 Promotion flow

{{#UNLESS DEV_BRANCH_CHAIN=main only}}
```
feature/...  → MR → develop
                     │
                     └─ promotion MR → staging
                                        │
                                        └─ promotion MR → main
```

Merge strategy: **squash for feature MRs into `develop`; merge-commit for promotion across `develop → staging → main`.** Promotion MRs are one-line MRs that carry no code diff of their own; their body cites the release scope (list of merged `feature/*` MRs and their conventional-commit subjects).
{{/UNLESS}}
{{#IF DEV_BRANCH_CHAIN=main only}}
```
feature/...  → MR → main
```

Merge strategy: squash for every MR.
{{/IF}}

---

## 3. The Hotfix Multi-MR Protocol

{{#UNLESS DEV_BRANCH_CHAIN=main only}}
One `fix/*` branch fans out to multiple MRs, one per protected branch that needs the change.

| Bypass case | Cut from | MRs from the same `fix/*` branch |
|---|---|---|
| Staging hotfix | `staging` | → `staging` **AND** → `develop` (2 MRs) |
| Main hotfix | `main` | → `main` **AND** → `staging` **AND** → `develop` (3 MRs) |

**Rules:**

- The same branch tip is the source of multiple open MRs into different targets. Each MR's diff is computed against its target.
- Cross-link every MR. Each description references every other MR in the set (e.g. `Hotfix paired MRs: !123 (→develop), !124 (→staging)`).
- A `fix/*` MR without its required paired companion MR(s) is an automatic block in review.
- Delete the source branch only after every paired MR has merged. Disable "auto-delete source branch on merge" for `fix/*` MRs.
- Rebase each MR on its own target.
- A revert that fixes a regression on a protected branch follows the same fan-out protocol.
{{/UNLESS}}
{{#IF DEV_BRANCH_CHAIN=main only}}
Not applicable — the single-branch model needs no fan-out. Hotfixes are ordinary `fix/*` MRs into `main`.
{{/IF}}

---

## 4. Engineering Branch Scopes

Branch naming follows the baseline shape `<type>/<scope>/<description>`. Engineering repos use a structured scope vocabulary mirroring repo layout.

### 4.1 Scope vocabulary — backend

{{#IF ARCH_SHAPE=microservices}}
Backend microservice repos (`backend-*`) follow the horizontal split from [`microservice-layout.md`](./microservice-layout.md): `src/api/` + optional `src/consumers/` / `src/cronjobs/` / `src/<role>/` + `src/domain/` + `src/infra/{platform,integrations}/`. No `src/v1/` umbrella — versioning lives only inside `src/api/vN/` and per-event / per-message `*_vN.py` files.
{{#ELSE}}
The backend follows the horizontal split from [`monolith-layout.md`](./monolith-layout.md): `src/api/` + `src/modules/<module>/` + optional `src/worker/` / `src/consumers/`. No `src/v1/` umbrella — versioning lives only inside `src/api/vN/` and per-message `*_vN.py` in worker/consumer handlers.
{{/IF}}

- `root` — repo-wide changes (`pyproject.toml`, `.pre-commit-config.yaml`, `.env.example`, `.gitignore`, top-level `Makefile`).
- `migrations` — `migrations/` Alembic revisions.
- `docker` — `docker/Dockerfile.<role>`.
- `deploy` — `deploy/` compose files, deployment scripts.
- `scripts` — `scripts/` operational and dev-helper scripts.
- `tests` — `tests/` (any tier).
- `docs` — service-local `docs/`.
{{#IF ARCH_SHAPE=microservices}}
- `src_infra_platform` (optionally `src_infra_platform_<file>`) — `src/infra/platform/` cross-cutting infra.
- `src_infra_integrations` (optionally `src_infra_integrations_<client>`) — external clients.
- `src_api` — `src/api/main.py`, `lifespan.py`, `middleware/`.
- `src_api_v1_<entity>` — `src/api/v1/routes/<entity>.py` (bump `v1` segment for new majors).
- `src_api_v1_schemas_<entity>` — `src/api/v1/schemas/<entity>.py`.
- `src_api_v1_deps_<topic>` — `src/api/v1/deps/<topic>.py` (FastAPI `Depends()` builders).
- `src_domain_<entity>` — per-entity domain code under `src/domain/<entity>/`. Narrow with `src_domain_<entity>_<layer>`.
- `src_consumers` / `src_consumers_<event>` — `src/consumers/`.
- `src_cronjobs` / `src_cronjobs_<job>` — `src/cronjobs/`.
- `src_<role>` / `src_<role>_<handler>` — any other entrypoint role.
{{#ELSE}}
- `src_shared` — `src/modules/shared/` cross-module foundations.
- `src_api` — `src/api/main.py`, `lifespan.py`, `middleware/`.
- `src_api_v1_<entity>` — `src/api/v1/routes/<entity>.py`.
- `src_api_v1_schemas_<entity>` — `src/api/v1/schemas/<entity>.py`.
- `src_api_v1_deps_<topic>` — `src/api/v1/deps/<topic>.py`.
- `src_modules_<module>` — per-module scope. Narrow with `src_modules_<module>_<entity>` when entity-specific.
- `src_worker` / `src_worker_<handler>` — `src/worker/` background-task handlers.
{{/IF}}

### 4.2 Scope vocabulary — frontend

Frontend repos follow the vertical-slice layout in [`frontend-layout.md`](./frontend-layout.md).

- `root` — repo-wide (`package.json`, `pnpm-lock.yaml`, `tsconfig.json`, `vite.config.ts` / `astro.config.mjs`, `.env.example`).
- `public` — `public/` static assets, fonts, favicons.
- `styles` — `src/styles/` globals, tokens.
- `router` — `src/router/` (SPA only).
- `layouts` — `src/layouts/*.astro` (Astro only).
- `pages` — `src/pages/*.astro` (Astro only).
- `src_features_<area>_<feature>` — `src/features/<area>/<feature>/`.
- `src_shared_<subsystem>` — `src/shared/<subsystem>/` (SPA).
- `src_lib_<subsystem>` — `src/lib/<subsystem>/` (Astro landing).
- `tests` — `tests/e2e/`.
- `docker` / `deploy` — same as backend.

### 4.3 Scope vocabulary — infra

Infra repos use scopes anchored on their layout: `root`, `docker-compose`, `config` (`nginx.conf`, `postgresql.conf`{{#IF HAS_REDIS}}, `redis.conf`{{/IF}}), `scripts`, `docs`.

### 4.4 Examples

- `feature/src_api_v1_<entity>/add-<verb>-endpoint`
- `bugfix/src_infra_platform/fix-connection-leak`
- `test/src_domain_<entity>/add-<what>-tests`
- `document/root/update-onboarding`
- `CICD/root/cache-uv-layer`
- `release/root/v1-4-0`
- `fix/src_domain_<entity>/patch-<what>-crash`
- `feature/src_features_<area>_<feature>/add-<what>`

---

## 5. Quality Gates

### 5.1 Three-tier model

| Tier | Latency budget | Runs |
|---|---|---|
| `pre-commit` | < 5s | Lint, format, type-check on changed files only, secret scan |
| `pre-push` | < 30s | Unit tests on changed packages, commit-message lint on push range |
| MR pipeline | Minutes (parallel) | Full lint + format + types + test + coverage + secret scan{{#IF ARCH_SHAPE=microservices}} + shared-logic version-lock{{/IF}} + (frontend) contract-drift + visual-regression |

If `pre-commit` exceeds ~5s, move slow checks to CI.

### 5.2 Canonical `.pre-commit-config.yaml`

The exact hook list (`ruff` / `ruff-format` / `mypy` / hygiene{{#IF SECRET_SCANNER}} + `gitleaks`{{/IF}}) with pinned versions is documented in [`ci-cd.md`](./ci-cd.md) §1 / §2.3. Add a `commit-msg` stage running `commitlint --edit`.

### 5.3 Merge-blocking MR pipeline

Every backend MR must pass:

- Lint (`ruff`).
- Format check (`ruff format --check`).
- Type-check (`mypy`).
- Full test suite.
- Coverage threshold — **≥ {{BE_COVERAGE_FLOOR}}%**{{#UNLESS BE_COVERAGE_FLOOR}}(project-defined; typical 70–95%){{/UNLESS}}, ratcheting up, never down.
- Secret scan (full repo, not just diff).
{{#IF ARCH_SHAPE=microservices}}
- **Shared-logic version-lock** — pinned shared-logic version matches the current release (see [`ci-cd.md`](./ci-cd.md) §3).
{{/IF}}

Every frontend MR must pass:

- Lint (`eslint`) — includes `eslint-plugin-boundaries`.
- Format check (`prettier --check`).
- Type-check (`tsc --noEmit`).
- Full test suite (`vitest run --coverage`).
- Build (`astro build` for landing, `vite build` for the SPAs).
- Contract-drift job (`pnpm codegen` + `git diff --exit-code` + `pnpm typecheck`).
- Visual regression (Playwright screenshot diff).

Each MR is independently gated, {{#UNLESS DEV_BRANCH_CHAIN=main only}}including each MR in a `fix/*` hotfix fan-out{{/UNLESS}}{{#IF DEV_BRANCH_CHAIN=main only}}including hotfix MRs{{/IF}}.

---

## 6. The `feature` MR Test Rule

`feature` MRs must include a test. Enforce via reviewer checklist (review template lists "feature MR has test? yes / no") and via a CI check that parses the MR type from the branch name and requires at least one `tests/` file in the diff when `feature/*`.

---

## 7. Engineering Tooling Stack

| Tool | Purpose | Lives at |
|---|---|---|
| [commitlint](https://commitlint.js.org/) + `@commitlint/config-conventional` | Machine-enforce commit format. | `commit-msg` hook |
| [Husky](https://typicode.github.io/husky/) | Git-hooks entry point for frontend repos. | `commit-msg`, `pre-commit` |
| [`pre-commit`](https://pre-commit.com/) | Backend equivalent of Husky. | `commit-msg`, `pre-commit` |
| [Commitizen](https://commitizen-tools.github.io/commitizen/) (`cz`) | Interactive commit prompt. | `git cz` / `npx cz` |
| [semantic-release](https://semantic-release.gitbook.io/) | Auto-derives SemVer tag + changelog from typed commits on `main`. | post-merge CI on `main` |
{{#IF SECRET_SCANNER}}
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scanning. | `pre-commit`, MR pipeline |
{{/IF}}
| Host Push Rules + Protected Branches + Required Approvals | Server-side enforcement of branch naming, merge policy, linear history. | project settings |
| CODEOWNERS | Auto-require approvers for sensitive areas. | `.gitlab/CODEOWNERS` |
| MR & Issue templates | Auto-populate description structure. | `.gitlab/merge_request_templates/` |
| Git LFS | Binary asset storage. | configured at repo init, `.gitattributes` patterns |

### 7.1 Minimal `commitlint.config.js`

Enforce: `type-enum` (`document`, `bugfix`, `test`, `CICD`, `feature`, `maintenance`, `revert`), `type-case` lowercase, `subject-empty` / `scope-empty` never, `subject-full-stop` never, `header-max-length` 72, `subject-case` never start/pascal/upper, plus blank-line rules between header/body/footer.

### 7.2 Husky hooks (frontend repos)

Two hooks under `.husky/`: `commit-msg` runs `commitlint --edit "$1"`; `pre-commit` runs `lint-staged`.

### 7.3 `.gitlab/CODEOWNERS`

Combine with branch protection's "require code owner approval". Pattern: `*` defaults to `@maintainers`; security-sensitive paths (auth, OTP, sessions) require `@security-reviewers`; migrations (`migrations/`) require `@dba`; infra (`.gitlab-ci.yml`, `Dockerfile*`, `docker/`, `deploy/`) requires `@infra`.

---

## 8. SemVer Mapping

| Commit type | Bump |
|---|---|
| `feature` | minor (1.X.0) |
| `bugfix` | patch (1.0.X) |
| `BREAKING CHANGE:` footer or `!` after type | major (X.0.0) |
| `document` / `test` / `CICD` / `maintenance` | none |
| `revert` | inherits the reverted commit's bump |

**Perf inside `maintenance`:** user-visible perf improvements trigger a patch bump. Flag manually via a `Performance:` body note + manual bump on the `release/*` branch, or configure `semantic-release` with a custom rule mapping `maintenance` commits with `Performance:` in the body to `patch`.

`semantic-release` runs on every push to `main`: scans new commits, computes the bump, creates the annotated tag, writes the changelog, publishes if configured.

---

## 9. Tag & Release Conventions

### 9.1 Tag format

```
v<MAJOR>.<MINOR>.<PATCH>            v1.4.2
v<MAJOR>.<MINOR>.<PATCH>-<pre>      v1.4.2-rc.1, v2.0.0-beta.3
```

Leading `v` is required. Pre-release suffixes (`-rc.N`, `-beta.N`, `-alpha.N`) trigger pre-release publishing without affecting the stable channel.

### 9.2 Annotated tags only

```bash
git tag -a v1.4.2 -m "Release v1.4.2"
git push origin v1.4.2
```

Lightweight tags (`git tag v1.4.2` without `-a`) are reserved for ephemeral markers — never for releases.

### 9.3 Tags are created by CI, not humans

`semantic-release` runs as a post-merge CI job on `main`, scans the commits since the last tag, computes the bump, creates the annotated tag, writes the changelog, and publishes.

{{#IF ARCH_SHAPE=microservices}}
**Special case — shared-logic library.** Every new tag automatically opens a bump-MR in each consumer repo. The consumer's shared-logic version-lock CI gate fails until the bump-MR is merged.
{{/IF}}

### 9.4 Never re-tag

If a release is bad, ship a new patch (`v1.4.3`). Never move or delete `v1.4.2`. Enable host-side tag protection to prevent deletion or force-update of `v*` tags.

### 9.5 Release notes from typed commits

`semantic-release` groups commits by type into `Features`, `Bug Fixes`, `BREAKING CHANGES` sections.

---

## 10. Engineering Antipatterns

In addition to the cross-repo "never" list:

- Never commit secrets, credentials, `.env*` (except `.env.example`), private keys, or auth tokens (§1.1, §1.4).
- Never commit binaries > 100 KB without Git LFS (§1.5).
- Never commit generated code, build artifacts, or `node_modules/` (lockfiles excepted) (§1.3).
- Never commit hand-edited files in the OpenAPI-generated directory — regenerate via `pnpm codegen`.
- Never skip hooks (`--no-verify`) without a written justification in the MR description (§5).
- Never disable a failing CI check to "unblock" a merge — fix it or revert.
- Never move or delete a release tag — ship a new patch (§9.4).
{{#UNLESS DEV_BRANCH_CHAIN=main only}}
- Never open a `fix/*` MR without its paired companion MR(s) (§3).
{{/UNLESS}}
- Never comment out failing tests to ship.
- Never ship a `feature` MR without a test (§6).
{{#IF ARCH_SHAPE=microservices}}
- Never commit a shared-logic version bump on the consumer side that lowers below the current release (the CI gate rejects it).
{{/IF}}

---

## 11. Bootstrapping a New Code Repository

**Day 0 — decisions:** host, branching model ({{DEV_BRANCH_CHAIN}}), commit vocabulary (cross-repo type set), merge strategy (squash for feature MRs{{#UNLESS DEV_BRANCH_CHAIN=main only}} + merge-commit for promotion{{/UNLESS}}), size limits (100 lines / 10 files hard; 50 / 5 best), license.

**Day 1 — initial commit files:** `.gitignore` (per-language + engineering categories §1.1), `.gitattributes` (baseline LF skeleton + §1.2 + LFS patterns), `.pre-commit-config.yaml` (canonical hooks in [`ci-cd.md`](./ci-cd.md) §2.3) or `.husky/` for frontend, `.gitlab-ci.yml` (lint + test on every push{{#IF ARCH_SHAPE=microservices}} + shared-logic version-lock for backend{{/IF}}), MR template, CODEOWNERS (§7.3), `CONTRIBUTING.md`, repo-overview doc, `LICENSE`, `commitlint.config.js` (§7.1), manifest (`package.json` / `pyproject.toml`).

**Day 1 — host configuration (UI):** protect {{#IF DEV_BRANCH_CHAIN=main only}}`main`{{#ELSE}}`main` / `staging` / `develop`{{/IF}} (no direct push, no force-push, required approvals, required green pipeline, required linear history on `main`); enable auto-delete-source-branch-on-merge; push rules / branch-protection rules matching branch-name regex; protect `v*` tags from delete / force-update; CI required for merge; ≥ 1 required reviewer; webhooks; container registry.

**Day 1 — local developer setup:** `make install` (backend) or `pnpm install` (frontend — Husky auto-installs); shared `.gitconfig` snippet (from baseline); checked-in `.editorconfig`.

**Day 2+:** first feature MR end-to-end;{{#UNLESS DEV_BRANCH_CHAIN=main only}} first simulated hotfix (`fix/*` multi-MR flow);{{/UNLESS}} first release (validate `semantic-release` tagging); for backend, first `alembic upgrade head` against the pre-deploy migration gate (see [`ci-cd.md`](./ci-cd.md) §5.1).
