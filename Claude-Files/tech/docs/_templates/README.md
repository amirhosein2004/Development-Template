---
title: "{{PROJECT_NAME}} — Engineering documentation"
category: "tech"
last_updated: "{{YYYY-MM-DD}}"
owner: "{{PROJECT_NAME}} / <human or model>"
---

# {{PROJECT_NAME}} — Engineering documentation

Engineering standards + platform architecture for **{{PROJECT_NAME}}** v{{VERSION}}.

- **Default branch:** `main`
- **Architecture shape:** {{ARCH_SHAPE}}
- **Positioning:** {{ONE_LINE_PITCH}}

## Layout

```
tech/docs/
├── CLAUDE.md
├── README.md
├── project-architecture/
│   └── v{{VERSION}}.md
└── standards/
    ├── api-and-data-contracts.md
    ├── ci-cd.md
    ├── coding.md
    ├── documentation.md
    ├── errors-and-observability.md
    ├── frontend-layout.md
    ├── frontend.md
    ├── git.md
    ├── infrastructure.md
    ├── {{LAYOUT_FILE}}
    ├── security-and-auth.md
    └── testing.md
```

`{{LAYOUT_FILE}}` is `microservice-layout.md` when `ARCH_SHAPE=microservices`, `monolith-layout.md` when `ARCH_SHAPE=monolith`.

## Related repositories

- `docs/` — umbrella cross-repo baseline.
- `business/docs/` — competitor research, brand assets, strategy.
- `product/docs/` — feature catalog, UI/UX, design system.
- `tech/<repo>/` — engineering repos (see `project-architecture/v{{VERSION}}.md` for the full list).
