# Frontend Layout (tech)

> **Documentation placement.** Cross-repo standard defining the canonical project layout for every {{PROJECT_NAME}} frontend repo (see [`documentation.md`](./documentation.md) §5).

## Scope

Canonical directory layout for the {{PROJECT_NAME}} frontend repos: {{FE_REPO_LIST}}. All ship **static output** behind the single platform nginx — no SSR, no Node at the edge, no server logic. This document covers the **vertical-slice feature-folder pattern** shared by every repo, plus the per-stack deltas (Astro pages + islands vs React Router routes).

Out of scope: code style and naming — [`coding.md`](./coding.md); the repo split decision — [`frontend.md`](./frontend.md); testing tooling — [`testing.md`](./testing.md); CI/CD pipeline shape — [`ci-cd.md`](./ci-cd.md); HTTP contract specifics — [`api-and-data-contracts.md`](./api-and-data-contracts.md).

Reading conventions: **CURRENT** = today; **STANDARD** = required, not yet fully in place. Applicability: **[FE]**.

---

## 1. The vertical-slice principle [FE] — STANDARD

**One feature = one folder.** Route descriptor, presentation component(s), local schemas, data-access hooks, copy, error mapping, and tests are **co-located** in the feature's folder. Horizontal split-by-type at the `src/` root (`src/hooks/`, `src/stores/`, `src/schemas/`, `src/types/`, `src/routes/`) is non-compliant: it forces unrelated changes to touch the whole tree and turns rename / delete into a search operation.

Cross-feature primitives — API client, app shell, auth, theme, formatters, error catalog{{#IF SHARED_RING_EXTRAS}}, {{SHARED_RING_EXTRAS}}{{/IF}} — live in a single shared ring (`src/shared/` in the SPA, `src/lib/` + `src/components/` + `src/copy/` in the Astro landing — see §4 for the per-stack delta). A piece of code is allowed in the shared ring **only when two or more features import it**; otherwise it stays inside the owning feature.

Two invariants follow:

1. **Features never import from other features.** `from @features/<a>/...` inside `@features/<b>/...` is a review-blocking defect. If two features need the same primitive, promote it to the shared ring.
2. **The shared ring never imports from a feature.** `from @features/...` inside `@shared/...` is a layering bug — fix the layering, not the import.

The folder names are nouns from the product domain (the **areas** of the feature catalog), not technical kinds (`forms`, `pages`, `widgets`). One feature-catalog entry → one feature folder.

---

## 2. The two rings [FE] — STANDARD

The layout is **two concentric rings**, mirroring the backend's three-ring discipline but with one fewer level because the frontend has no infrastructure ring of its own (the network, browser, and storage layers belong to the platform).

- **Feature ring** — `src/features/<area>/[<feature>/]`. All product surfaces. Owns its route descriptor, components, queries / mutations, schemas, copy, types, error mapping, and tests. Talks to the backend only through the shared API client.
- **Shared ring** — primitives reused across features: API client (incl. generated OpenAPI types), app shell, auth, error catalog, format helpers, theme{{#IF SHARED_RING_EXTRAS}}, {{SHARED_RING_EXTRAS}}{{/IF}}. Owns the cross-cutting wiring; never imports a feature.

```
┌────────────────────────────────────────────────────────────────────┐
│                                                                    │
│   ┌─────────────────────  FEATURE RING  ─────────────────────────┐ │
│   │                                                              │ │
│   │   features/<area>/[<feature>/]                               │ │
│   │   (Component, route descriptor, queries/mutations,           │ │
│   │    schemas, copy, errors, types, __tests__)                  │ │
│   │                          │                                   │ │
│   │            imports from shared ring only                     │ │
│   │                          │                                   │ │
│   │   ┌───────────────  SHARED RING  ──────────────────────┐     │ │
│   │   │                     ▼                              │     │ │
│   │   │  api/   app-shell/   auth/   copy/                 │     │ │
│   │   │  errors/   format/   theme/                        │     │ │
│   │   │  (cross-cutting primitives — no inline copy,       │     │ │
│   │   │   no feature-specific UI, no fetch site)           │     │ │
│   │   └────────────────────────────────────────────────────┘     │ │
│   └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
                          ▲
                  entrypoint: main.tsx (SPA)
                  / src/pages/*.astro (landing)
```

Path aliases enforce the boundary at the import site (§6). Deep relative imports (`../../../shared/...`) are prohibited by [`coding.md`](./coding.md).

---

## 3. Canonical layout — SPA repos (`{{ROUTE_STACK}}`-shaped)

Vite 6 + React 19, static SPA, React Router 7 in data-mode. No SSR, no server actions. Applies to every SPA repo in `FE_REPO_LIST`.

```
frontend-<name>/
├── .env.example                  # placeholders; only VITE_* / non-secret values bundled
├── .gitignore
├── .prettierrc.json
├── eslint.config.js
├── index.html                    # Vite entry document; loads /src/main.tsx
├── package.json                  # pnpm; scripts: dev, build, test, test:e2e, codegen
├── pnpm-lock.yaml                # committed
├── postcss.config.js
├── tailwind.config.ts
├── tsconfig.json
├── vite.config.ts                # path aliases @, @shared, @features
│
├── docs/
│   └── v1/PRD-TDD.md
│
├── scripts/
│   └── codegen.ts                # openapi-typescript per-backend generator
│
├── public/
│   ├── fonts/                    # WOFF2 — embedded, no CDN
│   ├── favicon.svg
│   └── ...
│
└── src/
    ├── main.tsx                  # ENTRYPOINT — sets <html lang dir>, mounts <App/>
    ├── App.tsx                   # providers (QueryClient, ThemeProvider, RouterProvider)
    ├── vite-env.d.ts
    │
    ├── router/                   # ── route composition (no business logic) ──
    │   ├── index.tsx                # createBrowserRouter — pulls *.route.tsx from each feature
    │   ├── guards.ts                # AuthGuard, RoleGuard
    │   └── RootErrorFallback.tsx
    │
    ├── styles/
    │   ├── global.css               # Tailwind layers
    │   ├── fonts.css                # @font-face for self-hosted fonts
    │   └── tokens.css               # design-system tokens
    │
    ├── test/
    │   └── setup.ts                 # MSW server.listen + jest-dom + cleanup
    │
    ├── features/                 # ── FEATURE RING — one folder per product surface ──
    │   ├── <area>/                   # {{FEATURE_AREAS}}
    │   │   ├── _layout/                 # area-local chrome shared by 2+ siblings ONLY (§5.6)
    │   │   ├── <feature>/
    │   │   │   ├── <Page>.tsx
    │   │   │   ├── <feature>.route.tsx
    │   │   │   ├── forms.schema.ts       # Zod
    │   │   │   ├── queries.ts            # TanStack Query hooks
    │   │   │   ├── mutations.ts
    │   │   │   ├── copy.ts               # user-facing strings
    │   │   │   ├── errors.ts             # error_code → user message
    │   │   │   ├── types.ts              # local types (NOT DTOs)
    │   │   │   └── __tests__/<Page>.test.tsx
    │   │   └── ...
    │   └── system/                     # non-product technical pages (§5.7)
    │       ├── 404/
    │       └── 500/
    │
    └── shared/                   # ── SHARED RING — cross-feature primitives ──
        ├── api/
        │   ├── client.ts                # fetch wrapper: cookie auth, X-Request-Id, envelope unwrap
        │   ├── envelope.ts
        │   ├── query-keys.ts
        │   ├── config.ts
        │   └── generated/               # openapi-typescript output — NEVER hand-edited; coverage excluded
        ├── app-shell/
        │   ├── AppShell.tsx
        │   ├── Sidenav.tsx
        │   ├── Topbar.tsx
        │   ├── queries.ts
        │   └── index.ts
        ├── auth/
        │   ├── client.ts                # silent-refresh-on-401 mutex
        │   ├── guard.tsx
        │   └── session.ts
        ├── copy/
        │   └── index.ts                 # cross-feature strings only
        ├── errors/
        │   └── catalog.ts               # error_code → user message map
        ├── format/
        │   └── ...                      # locale + digit + date helpers
        {{#IF SHARED_RING_EXTRAS}}
        ├── block-renderer/              # {{SHARED_RING_EXTRAS}}
        {{/IF}}
        └── theme/
            ├── ThemeProvider.tsx
            └── tokens.ts
```

**Why no `src/components/`?** Cross-feature primitives that *render* live under `@shared/app-shell/` (Topbar, Sidenav, page chrome). Pure UI atoms (Button, Input, Dialog) come from a `shadcn/ui` install under `@shared/ui/` **only** once a second feature needs to import them — never speculatively.

**Why no `src/hooks/` / `src/stores/` / `src/schemas/` at the root?** Each feature owns its hooks (`queries.ts` / `mutations.ts`), its Zod schema (`forms.schema.ts`), and its local state. A primitive promoted to the shared ring lives under the subsystem that owns it, not in a flat `hooks/` bag.

---

## 4. Canonical layout — Astro landing (`frontend-landing`)

Astro 5 + TypeScript, `output: 'static'`, SSG with rebuild-on-publish. React 19 used **only as islands** inside Astro components for interactive surfaces.

```
frontend-landing/
├── .env.example                  # PUBLIC_* values only — non-secret
├── astro.config.mjs              # output: 'static', integrations: [react(), sitemap()]
├── eslint.config.js
├── package.json                  # pnpm; scripts: dev, build, test, test:e2e, api:gen
├── pnpm-lock.yaml
├── playwright.config.ts
├── tsconfig.json
├── vitest.config.ts              # standalone; aliases @, @components, @layouts, @lib, @copy, @styles
│
├── docs/
│   └── v1/PRD-TDD.md
│
├── scripts/
│   └── codegen.ts                # openapi-typescript per-backend generator
│
├── public/
│   ├── fonts/                    # WOFF2 self-hosted
│   ├── favicon.svg
│   └── ...
│
├── tests/
│   ├── setup.ts
│   └── e2e/                      # Playwright user-critical journeys
│
└── src/
    ├── pages/                    # ── ROUTES — Astro file-based ──
    │   └── ...                      # {{FEATURE_AREAS}} landing pages
    │
    ├── layouts/
    │   └── Base.astro               # <html lang dir>; head, fonts, theme bootstrap
    │
    ├── components/               # ── cross-feature primitives that RENDER ──
    │   └── ThemeBootstrap.astro     # inline pre-hydration theme apply (no flash)
    │
    ├── copy/
    │   └── index.ts                 # cross-feature strings (chrome, footer / header)
    │
    ├── styles/                   # Tailwind + @font-face
    │   └── globals.css
    │
    ├── lib/                      # ── cross-feature non-rendering primitives ──
    │   ├── api/
    │   │   ├── client.ts
    │   │   └── generated/           # openapi-typescript output
    │   ├── errors/
    │   │   └── catalog.ts
    │   ├── format/                  # date, digit, locale helpers
    {{#IF SHARED_RING_EXTRAS}}
    │   ├── block-renderer/          # {{SHARED_RING_EXTRAS}}
    {{/IF}}
    │   └── theme/
    │       └── tokens.ts
    │
    └── features/                 # ── FEATURE RING — one folder per page SECTION ──
        └── landing/
            ├── shared/                  # primitives shared between landing sections only
            ├── header/
            ├── hero/
            ├── ...                      # {{FEATURE_AREAS}} feature folders
            └── footer/
```

**Astro vs React boundary inside a feature.** Pure markup → `.astro`. Anything interactive (form, calculator, accordion that controls JS state) → `.tsx` with a `client:*` directive in the `.astro` parent. A feature can mix both freely. The island is hydrated at the latest plausible time (`client:visible` for below-the-fold, `client:idle` for above).

**Why `src/lib/` and `src/components/` at the root instead of `src/shared/`?** Astro convention treats `layouts/`, `pages/`, `components/` as well-known top-level directories; collapsing them into a single `shared/` would fight the framework and break tooling defaults. Landing therefore keeps the Astro-natural names; the **role** of the shared ring is identical.

---

## 5. The feature folder — canonical anatomy [FE] — STANDARD

Every feature folder is one of these shapes. **Do not invent new top-level file kinds** without extending this document.

### 5.1 File-kind vocabulary

| File | Role | Required? | Cardinality |
|---|---|---|---|
| `<Page>.tsx` / `<Section>.astro` | Presentation component (entry component for the surface). | yes | exactly one entry component; helper children as `<Sub>.tsx` / `<Sub>.astro` siblings |
| `<kebab>.route.tsx` | React Router `RouteObject` exporter (SPA only). Path, element, lazy, loader. | yes (SPA) | one per route this folder exposes |
| `forms.schema.ts` | Zod schema(s). Drives both the form resolver and (when applicable) the API request parsing. | only if the surface has a form | one |
| `mutations.ts` | TanStack Query mutation hooks for write paths. | only if the surface writes | one |
| `queries.ts` | TanStack Query / fetch hooks for read paths, plus query-key constants. | only if the surface reads | one |
| `copy.ts` | All user-facing strings rendered by this folder's components. | yes whenever any string is shown | one |
| `errors.ts` | Map of backend `error_code` → user message for codes specific to this surface. | only if the surface surfaces codes not in the shared catalog | one |
| `types.ts` | Local TS types / interfaces. **Never** re-declare a DTO that exists in the generated directory. | only if needed beyond generated DTOs | one |
| `__tests__/<Component>.test.tsx` | Vitest + RTL tests, co-located. | yes | one per top-level component |

### 5.2 What does NOT belong in a feature folder

- A `<Component>.css` file. Styling is Tailwind on the element; no per-component stylesheets.
- A `hooks/` subfolder. Hooks belong in `queries.ts` / `mutations.ts`; one-off helpers stay in the file that uses them.
- A `utils.ts` grab-bag.
- A `stories.tsx`. Storybook is not part of the v1 toolchain.
- A second-level test folder under `__tests__/`. Deeper nesting indicates the feature should be split.

### 5.3 Naming inside a feature folder

| Item | Convention | Example |
|---|---|---|
| Entry component file + symbol | `PascalCase` | `Login.tsx` exports `LoginPage` |
| Astro entry section | `PascalCase.astro` | `Hero.astro` |
| Route descriptor | `<kebab>.route.tsx` | `login.route.tsx` |
| Route export symbol | `<feature>Route` (camelCase) | `export const loginRoute: RouteObject = { ... }` |
| Hooks file | flat `queries.ts` / `mutations.ts` | not `useLogin.ts`, not `api.ts` |
| Zod schema file | flat `forms.schema.ts` | not `schema.ts`, not `validation.ts` |
| Copy file | flat `copy.ts` | not `strings.ts`, not `messages.ts` |
| Errors file | flat `errors.ts` | one named export `errors` |
| Tests folder | `__tests__/` (double underscore) | per Vitest convention |

### 5.4 Sub-folders inside an area

Areas can nest one level deep when they contain multiple sibling features (e.g. `features/<area>/Home.tsx` plus children `features/<area>/<featureA>/`, `features/<area>/<featureB>/`). **One level of nesting only — with one exception.**

**The list→detail exception (second level allowed).** A list feature whose only legitimate child is the per-item detail page may host that child as `<list>/detail/` — a second level of nesting. This is the *only* shape allowed beyond one level, and the inner folder MUST be named exactly `detail/` (singular, no other token).

The detail folder follows the normal §5.1 vocabulary: its own `<Detail>.tsx`, `<list>-detail.route.tsx`, `queries.ts`, `mutations.ts`, `copy.ts`, `errors.ts`, `types.ts`, `__tests__/`. It may NOT have grand-children.

### 5.5 Feature folder size budget — STANDARD

A feature folder that grows past the budget below is a defect, not a "complex feature." Almost every page that hits the limits can be decomposed.

| Metric | Target | Hard limit |
|---|---|---|
| Component `.tsx` / `.astro` files per folder (excluding `__tests__/`) | ≤ 8 | 12 |
| Lines in a single component file | ≤ 300 | 500 |
| Lines in `copy.ts` | ≤ 200 | 400 |
| Lines in `forms.schema.ts` | ≤ 150 | 300 |
| Lines in `queries.ts` + `mutations.ts` combined | ≤ 250 | 500 |
| Lines in `types.ts` | ≤ 200 | 400 |

Below the target → no action. Between target and hard limit → look for a natural seam and split if one exists. Past the hard limit → split is mandatory before the next MR lands.

**Three kinds of split** (pick the matching one — never invent a fourth):

**A. Split by visible section** (most common). Panels / tabs / cards share no logic. Entry component shrinks to layout + state hoisting; each panel becomes a sibling file `<Page>.<SubArea>.tsx`.

**B. Split by logic** (JSX-light, `useEffect` / helpers have eaten the file). Logic moves to its sanctioned home: server reads → `queries.ts`; server writes → `mutations.ts`; form validation → `forms.schema.ts`; error mapping → `errors.ts`; local types → `types.ts`; user-facing strings → `copy.ts`. No `utils.ts`, no `hooks.ts`, no `helpers.ts`.

**C. Split by static data**. Column descriptors / form field configs / enum maps move to a peer `<Page>.<area>.fields.ts` / `<Page>.<area>.config.ts`.

**Naming + placement**: sibling sub-component file `<Page>.<SubArea>.tsx` — one dot, both PascalCase. All siblings sit **flat in the same folder** — no `components/` subfolder. The entry component is named after the folder and is the only file the route descriptor imports. Sibling sub-components are imported by the entry component **only** — never from outside the folder.

### 5.6 `_layout/` — area-local chrome — STANDARD

An area may host a single `_layout/` folder (leading underscore) for chrome — wrapper components, shared form fragments, shared mutation hooks — that **two or more siblings inside that area** import.

Rules:

- **One per area, max.**
- **No route descriptor.** A `_layout/` folder MUST NOT contain a `*.route.tsx`; it is not routable.
- **Same file vocabulary as a feature folder** (§5.1) but **no `<area>.route.tsx`** and no `errors.ts`.
- **Two-importer rule applies.** A piece of code earns its place in `_layout/` only once a second sibling imports it.
- **`@shared/` still wins for cross-area chrome.** `_layout/` is for *area-local* chrome only.

### 5.7 `system/` — non-product technical pages — STANDARD

Pages that are NOT product surfaces — fall-through HTTP error pages (`404`, `500`), maintenance / coming-soon placeholders — live under `features/system/` (SPA). Each sits in its own sub-folder following the normal §5.1 vocabulary. `system/` is the **only** area whose name is a technical kind rather than a product-domain noun.

---

## 6. Path aliases [FE] — STANDARD

Both repo shapes enforce the ring boundary at the import site using TypeScript path aliases. **No deep relative imports** (`../../../shared/api/client`) — fail the lint instead.

### 6.1 SPA aliases

| Alias | Resolves to | Use for |
|---|---|---|
| `@/` | `src/` | last-resort escape hatch; prefer the narrower aliases |
| `@shared/` | `src/shared/` | every import from the shared ring |
| `@features/` | `src/features/` | route composition in `src/router/index.tsx` only |

Declared in both `vite.config.ts` `resolve.alias` and `tsconfig.json` `paths`.

### 6.2 Landing aliases

| Alias | Resolves to | Use for |
|---|---|---|
| `@/` | `src/` | last-resort |
| `@components/` | `src/components/` | cross-feature renderers |
| `@layouts/` | `src/layouts/` | shared Astro layouts |
| `@lib/` | `src/lib/` | every import from the shared non-rendering ring |
| `@copy/` | `src/copy/` | cross-feature strings |
| `@styles/` | `src/styles/` | global stylesheets |

Declared in `vitest.config.ts` `resolve.alias`; Astro picks up the same aliases via the Vite integration. Astro's `~/` alias is **not** used.

### 6.3 Cross-ring import rules

- `@features/...` may import from `@shared/...` (SPA) / `@lib/`, `@components/`, `@layouts/`, `@copy/`, `@styles/` (landing).
- `@features/<a>/...` may NEVER import from `@features/<b>/...`. If a primitive is needed by both, promote it. The one exception: a feature's `*.route.tsx` may be imported by `src/router/index.tsx`, because the router *is* the composition root.
- `@shared/...` / `@lib/`, `@components/`, `@layouts/`, `@copy/` may NEVER import from `@features/...`. A "shared" thing that needs to know about a feature isn't shared.
- The generated OpenAPI client is imported only by `@shared/api/client.ts` / `@lib/api/client.ts` — features call the typed `client` wrapper, never the raw generated module directly.

---

## 7. Where a new piece of code goes [FE] — STANDARD

```
Is this code USER-FACING UI?
├─ Belongs to one product surface?           → features/<area>/<feature>/<Component>.tsx
├─ Renders site / app chrome reused across surfaces?
│   ├─ SPA?      → shared/app-shell/<Component>.tsx
│   └─ landing?  → components/<Component>.astro
└─ Pure UI atom reused by 2+ features?       → shared/ui/<atom>.tsx (install via `npx shadcn add`)

Is this a ROUTE / PAGE entry?
├─ SPA?      → features/<area>/<feature>/<feature>.route.tsx + one line in router/index.tsx
└─ landing?  → src/pages/<file>.astro

Is this DATA-ACCESS?
├─ One feature?             → features/.../queries.ts | mutations.ts
├─ Cross-feature wrapper?   → shared/api/client.ts (SPA) / lib/api/client.ts (landing)
└─ Generated OpenAPI types? → shared/api/generated/ — regen via `pnpm codegen`; never hand-edit

Is this a FORM SCHEMA?              → features/.../forms.schema.ts
Is this a USER-FACING STRING?
├─ One feature?         → features/.../copy.ts
├─ Chrome?              → shared/copy/index.ts / copy/index.ts (landing)
└─ Backend error map?   → see "errors" below

Is this an ERROR MAPPING?
├─ Shared by 2+?        → shared/errors/catalog.ts / lib/errors/catalog.ts
└─ Feature-specific?    → features/.../errors.ts

Is this a TYPE / INTERFACE?
├─ Matches a backend DTO? → already in generated/ — do not re-declare
├─ Local to a feature?    → features/.../types.ts
└─ Cross-feature, non-DTO? → shared/<subsystem>/types.ts / lib/<subsystem>/types.ts

Is this STATE?
├─ Server cache?          → TanStack Query (queries.ts / mutations.ts)
├─ Route-level?           → URL search params
├─ Form?                  → react-hook-form local state
├─ Auth session?          → HTTP-only cookie + shared/auth/session.ts derivation
├─ Cross-feature UI?      → shared/theme/ or a tiny Zustand slice in shared/
└─ Feature-local UI?      → useState in the component

Is this a TEST?
├─ Unit / component?      → features/.../__tests__/<Component>.test.tsx (co-located)
├─ Shared primitive?      → shared/<sub>/__tests__/<file>.test.ts
├─ E2E journey?           → tests/e2e/<journey>.spec.ts (Playwright)
└─ MSW handler?           → src/mocks/handlers/<resource>.ts

Is this OPERATIONAL?
├─ Build config?          → vite.config.ts (SPA) / astro.config.mjs (landing)
├─ Lint?                  → eslint.config.js
├─ CI pipeline?           → .gitlab-ci.yml
├─ One-off script?        → scripts/<name>.ts
└─ Self-hosted asset?     → public/
```

---

## 8. Tests — co-location [FE] — STANDARD

Tests live next to the code they exercise, in a `__tests__/` sibling folder. **No top-level `tests/` mirror tree for unit / component tests.**

Shared-ring primitives follow the same rule: `shared/format/__tests__/money.test.ts` next to `shared/format/money.ts`.

**The single exception** is E2E: Playwright specs live under `tests/e2e/` at the repo root (not co-located), because each spec exercises a full user journey across many features.

---

## 9. Stack-specific entrypoint discipline [FE] — STANDARD

### 9.1 SPA — single React entrypoint

`src/main.tsx` is the ONLY DOM mount in the app. It:

1. sets `<html lang dir>` on `document.documentElement` before mount (RTL must not flicker on first paint),
2. constructs the `QueryClient` (retry policy, `gcTime`, default `staleTime`),
3. mounts `<App/>` which wraps `<RouterProvider router={router}/>` in `<QueryClientProvider>` + `<ThemeProvider>`.

The route table (`src/router/index.tsx`) imports each feature's `*.route.tsx` and assembles them into the `createBrowserRouter` tree. **The router file is the only place where features are referenced by name** — every other module imports from `@shared/...` only.

### 9.2 Landing — Astro pages + islands

`src/pages/<file>.astro` is the routing primitive — Astro's file-based router maps the file to its URL. Each page composes a `<BaseLayout>` and one or more feature `.astro` components:

```astro
---
import BaseLayout from '@layouts/Base.astro';
import Hero from '@features/landing/hero/Hero.astro';
import Pricing from '@features/landing/pricing/Pricing.astro';
---
<BaseLayout>
  <Hero />
  <Pricing />
</BaseLayout>
```

Interactive islands (`.tsx` under a feature folder) hydrate via `client:visible` / `client:idle` / `client:load` from the parent `.astro` composition.
