# Development Template

This project provides two things:

1. **Git conventions** — structured commit, branch, and workflow rules for clear, traceable history.
2. **Claude-Files/** — a reusable working template for **AI-driven projects built with Claude** (agent workspaces powered by the Claude Agent SDK / Claude Code). Copy it into a new project to seed an opinionated agent scaffold (`agent_config/`, `business/`, `product/`, `tech/`, `docs/`) with commands, skills, hooks, and standards already wired up.

## Quick Start

### Commit Format
```
<type>(<scope>): <subject>
```

### Branch Format
```
<type>/<scope>
```

### Types (in order of priority)
1. **document** - Documentation updates
2. **bugfix** - Bug fixes
3. **test** - Test additions/modifications
4. **CICD** - CI/CD pipeline changes
5. **feature** - New features
6. **maintenance** - Refactoring, optimization, dependencies

### Scopes
- `root` - Project root level
- `helpers` - helpers/ directory
- `migrations` - migrations/ directory
- `src_v2_app_comments` - src/v2/app_comments/
- `src_v2_manager` - src/v2/manager/
- `src_v2_app_comments_data_model` - src/v2/app_comments/data_models/

## Examples

### Feature
```
feature(src_v2_app_comments): add pagination support to comments listing
```

### Bug Fix
```
bugfix(src_v2_manager): resolve authentication token validation error
```

### Documentation
```
document(root): update GUIDE.md with v2 API architecture details
```

### Testing
```
test(src_v2_app_comments_data_model): add unit tests for config validation
```

### CI/CD
```
CICD(root): update Dockerfile-cloud base image to python:3.12
```

### Maintenance
```
maintenance(src_v2_app_comments): optimize comment fetching with query caching
```

## Workflow Example

```bash
# Create feature branch
git checkout -b feature/src_v2_app_comments

# Make changes
git add .
git commit -m "feature(src_v2_app_comments): add new feature"

# Push to remote
git push -u origin feature/src_v2_app_comments
```

## Key Rules

- **Type selection:** Check types in priority order, select first match
- **Smallest scope:** Use most specific scope applicable
- **One concern per commit:** Each commit addresses single concern
- **Atomic commits:** Changes should be logically complete
- **Reference issues:** Include related issue numbers in commit body

## Documentation

- **Commit Message Convention.md** - Detailed commit message rules
- **Branch Naming Convention.md** - Branch naming standards
- **Git Commands Reference.md** - Common Git commands

## Claude-Files/ — AI project working template

`Claude-Files/` is the working template for projects built around **Claude AI agents** (Claude Code / Claude Agent SDK). It is not documentation about Git — it is a copy-and-fill scaffold you drop into a new AI-driven workspace to get a consistent structure across every Claude-powered project.

### Layers

- **`agent_config/`** — the `.claude/` directory: commands, skills, hooks, `settings.json`, and onboarding `CLAUDE.md` for the agent.
- **`business/docs/`** — market research, competitor analysis, brand assets, legal documents.
- **`product/docs/`** — product scope, feature catalog, UI/UX design system templates.
- **`tech/docs/`** — engineering standards, project architecture, backend/frontend/infra scaffolds.
- **`docs/standards/`** — cross-repo standards (git, MR flow, review rubric) shared by every layer.
- **`pipeline-flow.md` / `.html`** — reference diagram of how the layers feed each other.

### How to use

1. Copy `Claude-Files/` into a new project (or use it as the umbrella of an AI workspace).
2. Fill the placeholders: `{{PROJECT_NAME}}`, `{{PROJECT_ID}}`, `{{POSITIONING}}`, `{{SEGMENTS}}`, `{{DIMENSIONS}}`, `{{LOCALE_RULES}}`.
3. Run the agent commands (`/init`, `/setup`, `/audit`, `/docs`, `/implement`, `/mr`, …) defined under `agent_config/.claude/commands/`.

Everything under `Claude-Files/` is a template surface — the Git conventions above still govern how commits and branches are made when you work on it.
