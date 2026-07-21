# Development Template

Two things live here:

1. **Git conventions** — commit, branch, and workflow rules for clear, traceable history. Full docs in [`git-conventions/`](git-conventions/).
2. **Claude-Files/** — reusable working template for AI projects built with Claude (Claude Code / Claude Agent SDK). Full docs in [`Claude-Files/`](Claude-Files/).

## Repository Layout

```
Development-Template/
├── README.md                     # This file (index)
├── git-conventions/              # Git commit / branch / command standards
│   ├── quick-reference.md
│   ├── commit-message-convention.md
│   ├── branch-naming-convention.md
│   └── git-commands-reference.md
└── Claude-Files/                 # Copy-and-fill scaffold for Claude AI projects
    ├── agent_config/             # .claude/ (commands, skills, hooks, settings)
    ├── business/docs/            # Market research, brand, legal
    ├── product/docs/             # Product scope, features, UI/UX
    ├── tech/docs/                # Engineering standards + architecture
    ├── docs/standards/           # Cross-repo standards
    ├── pipeline-flow.md
    └── pipeline-flow.html
```

## 1. Git Conventions

### Commit Format
```
<type>(<scope>): <subject>
```

### Branch Format
```
<type>/<scope>
```

### Types (priority order)
1. **document** — Documentation updates
2. **bugfix** — Bug fixes
3. **test** — Test additions / modifications
4. **CICD** — CI/CD pipeline changes
5. **feature** — New features
6. **maintenance** — Refactoring, optimization, dependencies

### Scopes
`root`, `helpers`, `migrations`, `src_v2_app_comments`, `src_v2_manager`, `src_v2_app_comments_data_model` — always use the smallest applicable scope.

### Minimum Workflow
```bash
git checkout -b feature/src_v2_app_comments
git add .
git commit -m "feature(src_v2_app_comments): add new feature"
git push -u origin feature/src_v2_app_comments
```

### Key Rules
- **Type selection:** check types in priority order, take first match
- **Smallest scope:** use most specific scope applicable
- **One concern per commit** and per branch
- **Atomic commits:** logically complete on their own
- **Reference issues** in commit body / footer when relevant

### Detailed Docs
- [Quick Reference](git-conventions/quick-reference.md) — one-page cheat sheet
- [Commit Message Convention](git-conventions/commit-message-convention.md) — full format, examples, guidelines
- [Branch Naming Convention](git-conventions/branch-naming-convention.md) — branch patterns and review branches
- [Git Commands Reference](git-conventions/git-commands-reference.md) — everyday Git commands

## 2. Claude-Files/ — AI Project Working Template

`Claude-Files/` is a copy-and-fill scaffold for projects built around **Claude AI agents**. Drop it into a new workspace to get a consistent structure across every Claude-powered project — commands, skills, hooks, and standards already wired up.

### Layers

| Layer | Purpose |
|-------|---------|
| [`agent_config/`](Claude-Files/agent_config/) | `.claude/` — commands, skills, hooks, `settings.json`, onboarding `CLAUDE.md` |
| [`business/docs/`](Claude-Files/business/docs/) | Market research, competitor analysis, brand assets, legal documents |
| [`product/docs/`](Claude-Files/product/docs/) | Product scope, feature catalog, UI/UX design system templates |
| [`tech/docs/`](Claude-Files/tech/docs/) | Engineering standards, project architecture, backend / frontend / infra scaffolds |
| [`docs/standards/`](Claude-Files/docs/) | Cross-repo standards (git, MR flow, review rubric) shared by every layer |
| [`pipeline-flow.md`](Claude-Files/pipeline-flow.md) | Reference diagram of how the layers feed each other |

### How to Use

1. Copy `Claude-Files/` into a new project (or use it as the umbrella of an AI workspace).
2. Fill placeholders: `{{PROJECT_NAME}}`, `{{PROJECT_ID}}`, `{{POSITIONING}}`, `{{SEGMENTS}}`, `{{DIMENSIONS}}`, `{{LOCALE_RULES}}`.
3. Run the agent commands (`/init`, `/setup`, `/audit`, `/docs`, `/implement`, `/mr`, …) defined under `agent_config/.claude/commands/`.

Everything under `Claude-Files/` is a template surface — the Git conventions above still govern how you commit and branch when working on it.
