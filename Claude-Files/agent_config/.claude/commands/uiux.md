---
description: uiux — scaffold | design | audit. Authors UI/UX packs under `product/docs/uiux/<version>/<area>/`. `scaffold` bootstraps a new area (empty HTML files at every sitemap route, empty `assets/pages.css`, empty `assets/pages.js`, brand SVGs copied verbatim into `assets/logos/`, and a minimal `<project-slug>-<area>.md` companion spec skeleton — frontmatter + section headers only, §1 sitemap + §5 deferred-scope ledger authored; no chrome, no placeholder content, no stub notes; every design decision belongs to `design`). `design` writes / rewrites the concrete design code (HTML, CSS, JS) inside an existing area — mobile-first responsive across three tiers, design-system-token-bound, every change reflected in `<project-slug>-<area>.md` + appended to §6 Design changelog. `audit` reconciles an existing area against `product/docs/features/v<N>/all-features.md` — enumerates every route, section, block, widget, form field, table column, tile, action, chip, and role-visibility rule; anything not backed by an `[x]` row is an offender. `report` mode lists offenders only (no writes); `prune` mode removes the offending files / elements, sweeps orphan CSS + JS, rewrites the spec (§1 sitemap, §4.N sub-sections, §5 deferred-scope ledger), appends one §6 Design changelog line per removal, and verifies responsive integrity + cross-area references. Locale, direction, calendar, digit rule, palette, brand-mark path, spec-filename prefix, and breakpoint tokens are all read from the workspace's `product/docs/uiux/<version>/design-system/*.md` at call time — never hard-coded. Writes files only (no stage / commit / push / MR).
argument-hint: <scaffold|design|audit> <area>::<mode-or-scope>[::companions=<spec>]
---

# uiux — author UI/UX page sets

Routed command covering UI/UX authoring under `product/docs/uiux/<version>/`. The first positional argument selects the sub-op; the remainder is parsed per the matching contract. `scaffold` bootstraps an empty skeleton at a new area; `design` writes / rewrites the concrete design code inside an existing area; `audit` reconciles an existing area back against the `[x]` feature catalog. Every sub-op is read-heavy, write-once, and produces no side effects — no stage, no commit, no push, no MR.

## Synopsis

```
/uiux scaffold <area>::<mode>[::companions=<spec>]
/uiux design   <area>::<scope>[::companions=<spec>]
/uiux audit    <area>::<mode>
```

| Sub-op | Anchor | One-liner |
|---|---|---|
| `scaffold` | [`## scaffold`](#scaffold) | Bootstrap one multi-page UI/UX area — empty HTML files at every sitemap route, empty `assets/pages.css`, empty `assets/pages.js`, brand SVGs verbatim, minimal companion-spec skeleton (§1 sitemap + §5 deferred-scope ledger authored, every other section header-only). |
| `design` | [`## design`](#design) | Write / rewrite the concrete design code (HTML, CSS, JS) inside an existing area — mobile-first responsive across three tiers, design-system-token-bound, every change reflected in `<project-slug>-<area>.md` + appended to §6 Design changelog. |
| `audit` | [`## audit`](#audit) | Reconcile an existing area against `all-features.md`. `report` lists offenders (no writes); `prune` removes offenders, sweeps orphan CSS + JS, rewrites the spec, appends §6 changelog per removal, verifies responsive integrity + surfaces cross-area broken links. |

If the first arg is missing or not one of `scaffold` | `design` | `audit`, stop and ask — never default.

## Shared workspace probe

Every sub-op begins with the same probe: the skill reads `product/docs/uiux/<version>/design-system/*.md` in full (§1 Brand essentials) and extracts **locale, direction, calendar, digit rule, brand-mark path, project-slug, palette name, typography stack, and the three breakpoint tokens**. Every downstream constraint — `<html lang>` + `dir`, script normalization, calendar-boundary date rendering, digit rule, `<link rel="canonical">` shape, spec filename `<project-slug>-<area>.md`, palette references, CSP third-party allow-list — is **derived from that read**. Nothing is hard-coded to a specific locale, calendar, palette, or product name.

---

## scaffold

Scaffold the directory structure of one multi-page UI/UX area at `product/docs/uiux/<version>/<area>/` — the **empty skeleton**. Every HTML file is 0-byte; `assets/pages.css` + `assets/pages.js` are 0-byte; the companion `<project-slug>-<area>.md` is a minimal skeleton (frontmatter + headers only, with §1 four-column sitemap authored as the run's file-map artifact and §5 authored as the deferred-scope ledger). Brand SVGs under `assets/logos/` are the only non-empty non-spec write. Every design decision — chrome, canonical, OG, theme wiring, breadcrumb, block composition, responsive tiers, token binding — is deferred to `design`.

### Argument

`<area>::<mode>[::companions=<spec>]` where:

| Slot | Required | Shape |
|---|---|---|
| `<area>` | yes | `^[a-z][a-z0-9-]*$` — kebab-case domain of the new UI/UX area. Examples: `landing`, `dashboard`, `admin`, `system`, `emails`. |
| `<mode>` | yes | `bootstrap` \| `merge`. `bootstrap` creates from zero (refuses if the dir exists); `merge` adds missing files (refuses if the dir does not exist); neither overwrites human-authored files. |
| `companions=<spec>` | no | `+`-separated list of sibling-area reads on top of the fixed set. Sibling area specs are **not** auto-read — companions is the only entry path. Absent + area is auth-gated ⇒ skill prompts once at Step 1 start. |

### `companions=<spec>` grammar

**Outer separator `+` between directives; inner `,` only inside a single `pages=<r1>,<r2>` list.** Two directive forms — both include the sibling's spec MD:

- `uiux:<sibling>` — sibling's `<project-slug>-<sibling>.md` in full **+** every `<sibling>/*.html` in full.
- `uiux:<sibling>:pages=<route1>[,<route2>…]` — sibling's MD in full **+** only the listed HTML pages. Route names are kebab-case without `.html`; two-segment `<bucket>/<route>` shape max (depth cap = 1).

Full procedure: [`../skills/uiux/SKILL.md#scaffold`](../skills/uiux/SKILL.md).

### Refusal conditions

- `<area>` missing → ask.
- `<area>` doesn't match `^[a-z][a-z0-9-]*$` → kebab-case required; ask with the offending value named.
- `<area>` equals `design-system` → reserved (has its own separate authoring path; do not scaffold via this skill). Refuse.
- `<area>` equals `scaffold` → uniqueness with the sub-op name. Refuse.
- `<mode>` missing → stop and ask `bootstrap` | `merge`; never default.
- `<mode>` given but not `bootstrap` | `merge` → refuse with the offending value named.
- `<mode>` is `bootstrap` and `product/docs/uiux/<version>/<area>/` exists → refuse (use `merge`).
- `<mode>` is `merge` and `product/docs/uiux/<version>/<area>/` does not exist → refuse (use `bootstrap`).
- `product/docs/uiux/<version>/design-system/*.md` missing → refuse. The design system is the token + locale + direction + calendar + digits + brand-mark + palette source of truth; without it every mockup would invent tokens.
- The brand-mark file named by the design-system spec's §8 Logo is missing under `business/docs/brand/` → refuse. The brand mark is the single non-token asset every mockup consumes.
- `companions=` present but `<spec>` empty (`companions=`) → refuse (omit the slot instead).
- Any directive in `<spec>` not matching one of the two forms in the grammar table → refuse with the offending directive named. `sections:<…>`, `repo:<…>`, `repo:<…>:paths=<…>`, `path:<file>`, and `path:<file>:sections=…` are **not** valid forms.
- Outer separator anything other than `+` (e.g. `,`, `;`, `&`, `|`) → refuse with the offending directive named. Only `+` separates top-level directives; `,` is reserved for the inner `pages=` list.
- `uiux:<sibling>` (either form) where `product/docs/uiux/<version>/<sibling>/` does not exist → refuse with the offending sibling named.
- `uiux:<sibling>` (either form) where `<sibling>/<project-slug>-<sibling>.md` does not exist → refuse (the sibling exists but is not a complete UI/UX area; nothing to inherit).
- `uiux:<sibling>:pages=<route-list>` where any `<sibling>/<route>.html` does not exist → refuse with the offending page name named.
- Any proposed sitemap route not backed by an `[x]` row in `product/docs/features/v<N>/all-features.md` AND not present as a `[ ]` deferred row (i.e. the feature is absent from the catalog entirely) → refuse with the missing feature named; instruct the operator to add the row via a separate MR through `/mr` before re-running.

---

## design

Write / rewrite the concrete design code (HTML, CSS, JS) inside an **existing** UI/UX area under `product/docs/uiux/<version>/<area>/`. Mobile-first responsive across three tiers, every surface bound to the workspace's design system, every change reflected in the companion `<project-slug>-<area>.md` spec + appended to §6 Design changelog. Sibling of `scaffold`; where `scaffold` bootstraps a new area, `design` operates on one that already exists. **Reuses `scaffold`'s fixed read set and `companions=<spec>` grammar verbatim.**

### Argument

`<area>::<scope>[::companions=<spec>]` where:

| Slot | Required | Shape |
|---|---|---|
| `<area>` | yes | Kebab-case existing area under `product/docs/uiux/<version>/`. Must already exist — use `scaffold` to bootstrap first. |
| `<scope>` | yes | `page:<route>` \| `pages:<route1>,<route2>[,<route3>…]` \| `all`. `page:<route>` operates on one specific HTML file (flat `page:index` or bucketed `page:auth/login`, two-segment shape only, depth cap = 1). `pages:<list>` is a curated comma-separated list — minimum two entries, same shape as `page:<route>` per entry, flat + bucketed mixed allowed, duplicates + empty entries refused. `all` rewrites every HTML in the area. There is **no `assets` scope** — shared `assets/pages.css` + `assets/pages.js` are updated inline as part of the same run. |
| `companions=<spec>` | no | Identical grammar to `scaffold` — `+`-separated directives, two forms (`uiux:<sibling>`, `uiux:<sibling>:pages=…`), `,` inner list, auth-gated prompt when absent. |

### `companions=<spec>` grammar

Identical to `scaffold` — see the `scaffold` section above. Both directive forms include the sibling's spec MD; only HTML scope varies. Sibling area specs are **not** auto-read outside of `companions=` (or the auth-gated prompt).

Full procedure: [`../skills/uiux/SKILL.md#design`](../skills/uiux/SKILL.md).

### Refusal conditions

- `<area>` missing / non-kebab / equals `design-system` / `scaffold` / `design` → refuse with the offending value named.
- `product/docs/uiux/<version>/<area>/` does not exist → refuse (bootstrap first via `scaffold`).
- `<area>/<project-slug>-<area>.md` does not exist → refuse (bootstrap first via `scaffold`; every design run rewrites a sub-section of the spec + appends to §6 changelog).
- `<scope>` missing → stop and ask `page:<route>` | `pages:<list>` | `all`.
- `<scope>` not `page:<route>` | `pages:<list>` | `all` (the removed `assets` scope is not accepted).
- `page:<route>` where `<area>/<route>.html` does not exist.
- `pages:<list>` with fewer than two entries (single entry ⇒ use `page:<route>`).
- `pages:<list>` with any empty entry (`pages:index,,about`) or duplicate route.
- `pages:<list>` where any listed `<area>/<route>.html` does not exist — refuse with the offending route named.
- Any route in `pages:<list>` deeper than the two-segment `<bucket>/<route>` shape.
- Design-system MD missing.
- Design-system MD does not declare the three responsive breakpoint tokens (mobile / tablet / desktop).
- Companions refusals — identical to `scaffold`.
- Any proposed UI element / block / widget / affordance / form field / table column / filter chip / action / dashboard tile / admin surface / role-scoped visibility rule lacks an `[x]` row in `product/docs/features/v<N>/all-features.md` AND is not present as `[ ]` (absent entirely) → refuse, name the missing element concretely, instruct the operator to add the row via `/mr` first.

---

## audit

Reconcile an existing UI/UX area under `product/docs/uiux/<version>/<area>/` against the single feature catalog at `product/docs/features/v<N>/all-features.md`. **Every route, page section, block, widget, form field, table column, filter chip, action, interaction, dashboard tile, admin surface, and role-scoped visibility rule that the design ships MUST map to one or more `[x]` rows.** Anything present in the design but not backed by an `[x]` row is an **offender** — drawn against a `[ ]` deferred row (should have been in §5, not markup) or against no row at all (feature never sanctioned). Both are removals; the difference is which §5 rationale the prune records. Sibling of `scaffold` and `design`; where they compose forward from the catalog to the markup, `audit` is the reverse pass. `audit` never invents features to justify existing design; the catalog wins every conflict.

### Argument

`<area>::<mode>` where:

| Slot | Required | Shape |
|---|---|---|
| `<area>` | yes | Kebab-case existing area under `product/docs/uiux/<version>/`. Target dir MUST exist. Cannot equal `design-system` (reserved), `scaffold`, `design`, or `audit`. No `all` sentinel — audit runs against one area at a time so removals stay reviewable; loop the command per area for a workspace-wide sweep. |
| `<mode>` | yes | `report` \| `prune`. `report` — read-only enumeration of offenders + intended removals + cross-area impact; no files touched. `prune` — apply the removals, sweep orphan CSS + JS, rewrite the spec, append the changelog. Never defaults; missing → stop and ask. |

**`audit` does NOT accept `companions=<spec>`.** The reconciliation reads a fixed superset (every sibling area's spec MD is read unconditionally for cross-area link integrity). Passing `companions=` is refused.

Full procedure: [`../skills/uiux/SKILL.md#audit`](../skills/uiux/SKILL.md).

### Refusal conditions

- `<area>` missing → stop and ask.
- `<area>` doesn't match `^[a-z][a-z0-9-]*$` → refuse with the offending value named.
- `<area>` equals `design-system` / `scaffold` / `design` / `audit` → refuse.
- `product/docs/uiux/<version>/<area>/` does not exist → refuse (bootstrap first via `scaffold`).
- `<area>/<project-slug>-<area>.md` does not exist → refuse (bootstrap first via `scaffold`; the spec is the audit's source of truth for §1 sitemap ownership and every §4.N element inventory).
- `<mode>` missing → stop and ask `report` | `prune`.
- `<mode>` not one of `report` | `prune` → refuse.
- `product/docs/features/v<N>/all-features.md` missing → refuse (nothing to reconcile against).
- `product/docs/uiux/<version>/design-system/*.md` missing → refuse (without the design-system component + class inventory, the audit would misidentify legitimate design-system atoms — `.article-card`, `.cta-band`, `.hero-grad`, `.breadcrumb`, `.chip`, `.tile`, etc. — as un-catalogued features and prune them).
- `companions=<spec>` supplied → refuse with the offending slot named; audit's read set is fixed and includes every sibling area's spec MD automatically.
- `<mode>` is `prune` and the workspace has uncommitted changes touching `product/docs/uiux/<version>/<area>/` → refuse. Prune is destructive; running it on a dirty tree would conflate user edits with tool removals. Ask the operator to stash or commit first (report mode is safe on a dirty tree).

---

Writes files only. Ship afterwards with `/mr open current`.
