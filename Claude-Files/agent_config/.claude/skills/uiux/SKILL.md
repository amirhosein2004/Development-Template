---
name: uiux
description: |
  Author UI/UX packs under `product/docs/uiux/<version>/<area>/` — the HTML mockup set + companion `<project-slug>-<area>.md` spec + shared `assets/` (`logos/` copied verbatim from `business/docs/brand/`, `pages.css`, `pages.js`) — from the `[x]` rows of `product/docs/features/v<N>/all-features.md`, the workspace's design system at `product/docs/uiux/<version>/design-system/*.md`, and the frontend-relevant engineering standards. First positional argument is `<scaffold|design|audit>`; the remaining tokens are parsed per sub-op contract. **Locale, direction, calendar, digit rule, brand-mark path, project-slug, palette, typography stack, and the three responsive breakpoint tokens are read from the workspace's design-system spec at call time — never hard-coded to a specific language, calendar, palette, or product name.**

  - `scaffold <area>::<mode>[::companions=<spec>]` — scaffold one multi-page UI/UX area at `product/docs/uiux/<version>/<area>/`. The **fixed read set** (always read, never varies): product feature catalog `product/docs/features/v<N>/all-features.md` (only `[x]` rows delivered on this area's surfaces enter scope; `[ ]` rows are deliberately out of scope and land in §5 with a one-line rationale), the workspace design system `product/docs/uiux/<version>/design-system/*.md` + its HTML twin (tokens, components, locale + direction rules, brand-mark path, project-slug, palette — nothing invented, only composed), brand assets under `business/docs/brand/` (the brand-mark file the design system's §8 Logo names is copied byte-verbatim into `<area>/assets/logos/`; additional brand SVGs copied when present), the **five hard-coded** frontend-relevant standards — `tech/docs/standards/frontend.md` (full — copy-in-markup boundary, block-renderer parity, CSP-allow-listed third-party origins), `tech/docs/standards/frontend-layout.md` (full — responsive contract, mobile-first, token binding, direction-aware layout, breakpoint reorder), `tech/docs/standards/coding.md` §11 calendar / digit boundary + §12 block tree (sections only — the two rules that bind every mockup surface), `tech/docs/standards/documentation.md` (full — companion-spec frontmatter conventions), and `tech/docs/standards/security-and-auth.md` §8 CSP (section only — when the area renders third-party embeds), the platform architecture at `tech/docs/v<N>/project-architecture.md` in full (service map, feature → service map, surfaces, auth posture — the auth posture resolves whether the area is anonymous read-only or auth-gated), — sibling area specs are **not** auto-read; siblings only enter the read set through the `companions=<spec>` slot (or the auth-gated prompt for auth-gated areas). **The other seven standards** — `api-and-data-contracts.md`, `ci-cd.md`, `errors-and-observability.md`, `git.md`, `infrastructure.md`, `microservice-layout.md`, `testing.md` — are deliberately NOT read; UI/UX mockups are static prototypes with no HTTP contracts, no CI pipeline, no backend layout, no test surface. The **optional `companions=<spec>` slot** is the **only** way sibling areas enter the read set. `<spec>` is a **`+`-separated** list of directives (outer separator is `+`, not `,` — the inner `pages=<route1>,<route2>` list uses `,` inside a single directive, so the two never collide) with two forms — `uiux:<sibling-area>` (read `<sibling>/<project-slug>-<sibling>.md` in full **+** every `<sibling>/*.html` in full — the MD carries cross-page conventions + frontmatter shape, the markup carries chrome composition, component wiring, class-name usage, direction-aware structure) and `uiux:<sibling-area>:pages=<route1>[,<route2>…]` (read `<sibling>/<project-slug>-<sibling>.md` in full **+** only the listed HTML pages under `<sibling>/`, page names are kebab-case route filenames without `.html`, e.g. `uiux:landing:pages=index,article-detail`). MD is always included in either form — only HTML scope varies. Multiple directives joined by `+`, so mixing is direct: `companions=uiux:landing:pages=index,article-detail+uiux:system` pulls landing's MD + two named pages plus system's MD + every HTML of system — one line, two sources, targeted per source. When `companions=` is **absent AND** `<area>` resolves as auth-gated (dashboard-shaped or admin-shaped per the architecture's §6-equivalent auth-posture read), the skill **prompts once** at the start of Step 1: `y` adds the workspace's anonymous-shell sibling (typically `landing` — the skill picks the anonymous shell area from the on-disk sibling set) verbatim, `n` proceeds without, `s` opens a follow-up multi-select over sibling areas; the prompt fires only when auth-gated, only on absent `companions=`, and only when at least one sibling area exists. For auth-gated areas the fixed read set **also** pulls the consumed backend PRD-TDDs' route-family sections to name surfaces truthfully. Writes: (a) `product/docs/uiux/<version>/<area>/<project-slug>-<area>.md` as a **minimal companion spec skeleton** — canonical frontmatter (`title:` / `derived_from:` / `companion_of:` / `scope_source:` / `informed_by:` / `audited_at:`) + the section headers (`1. Sitemap and file map` → `2. Why per-page files` → `3. Cross-page conventions` → `4. Per-page composition` → `5. Deliberately out of scope` → `6. Design changelog` → `7. Source of truth & drift`), with **only §1's four-column sitemap code block (URL / Bucket / File / Purpose) and §5's one-line-per-deferred-`[ ]`-feature ledger authored**; every other section is header-only, deferred to `design`; (b) one `<route>.html` per URL in the sitemap — **empty 0-byte files** — flat rows at `<area>/<route>.html`, bucketed rows at `<area>/<bucket>/<route>.html`, mandatory `<area>/system/404.html` + `500.html`. No doctype, no chrome, no canonical, no OG, no theme script, no CSS/JS link — the file exists as an anchor for its sitemap row; (c) `<area>/assets/logos/*.svg` copied verbatim from `business/docs/brand/` — the only non-empty non-spec write; (d) `<area>/assets/pages.css` — **empty 0-byte file**; (e) `<area>/assets/pages.js` — **empty 0-byte file**. Every downstream design constraint (locale-conditional normalization, calendar-conditional date rendering, canonical, OG, self-hosted fonts when the design system so declares, theme init, drawer wiring, tokens-only binding, mobile-first responsive) is deferred to `design`. `<mode>` is `bootstrap` (target directory must not exist — creates from zero) | `merge` (target directory must exist — adds missing files, silent-skip present ones, never overwrites human-authored HTML / MD / assets). Writes files only — no stage / commit / push / MR; ship with `/mr open current`. Refuses if `<area>` missing / non-kebab (`^[a-z][a-z0-9-]*$`) / equal to `design-system` (reserved) / equal to `scaffold`; if `<mode>` missing (stop and ask); if `<mode>` is not `bootstrap` | `merge`; if `<mode>` is `bootstrap` and `product/docs/uiux/<version>/<area>/` exists; if `<mode>` is `merge` and the dir does not exist; if the design-system spec is missing (the token + locale + direction + calendar + digits + brand-mark + palette source of truth — do not proceed without it); if the brand-mark file the design system's §8 Logo names is missing under `business/docs/brand/`; if any proposed sitemap route lacks an `[x]` row AND is not present as `[ ]` (feature absent entirely → refuse, name the missing feature, instruct the operator to add it via `/mr` first).

  - `design <area>::<scope>[::companions=<spec>]` — write / rewrite the concrete design code (HTML, CSS, JS) inside an **existing** area under `product/docs/uiux/<version>/<area>/`. Sibling of `scaffold`; where `scaffold` bootstraps a new area from zero (**empty 0-byte HTML / CSS / JS files** + brand SVGs + minimal companion-spec skeleton), `design` operates on an area that already exists and produces the actual crafted design — the concrete composition inside each page, the CSS composition rules bound to design-system tokens, the vanilla JS interactions. Reuses `scaffold`'s **fixed read set verbatim** (feature catalog `[x]` rows, design system MD + HTML twin, brand assets, the five hard-coded standards `frontend.md` + `frontend-layout.md` + `coding.md` §11+§12 + `documentation.md` + `security-and-auth.md` §8 CSP, full `project-architecture.md`, workspace-root `CLAUDE.md` if present, consumed backend PRD-TDDs' route-family sections for auth-gated areas — sibling area specs are **not** auto-read, only via `companions=`) — the seven excluded standards stay excluded. Also reads the target area's write targets + entry page + shared assets + current spec (the route(s) named by `<scope>` as their baseline, `<area>/index.html` when present as the shell reference, `<area>/assets/pages.css`, `<area>/assets/pages.js`, `<area>/<project-slug>-<area>.md`) since this is a modify operation, not a bootstrap; other sibling flat pages and bucket pages are **not** auto-read — the spec MD's §3 shared conventions + §4.N per-page composition carry cross-sibling context across the area, `index.html` is the shell reference, and the design system is the token source. Adds three **code-writing sources** on top of `scaffold`'s fixed set that `scaffold` does not read (needed because `design` writes real crafted code, not just skeleton shells — without these the skill would hallucinate composition patterns): (a) for every sibling **included via `companions=`** — `<sibling>/assets/pages.css` + `pages.js` in full (sibling assets follow the same gate as sibling MD / HTML — no `uiux:<sibling>` directive → no sibling assets read); (b) `business/docs/brand/brand.html` in full if present — brand rules the SVGs alone do not carry (logo clear-space, palette do / don't, typography scale, script-specific wordmark spacing, contrast); (c) `product/docs/uiux/<version>/design-system/` enumerated in full — every entry under the dir (`design-system.css` if present, `design-system.js` if present, `fonts/`, `icons/` — not just the MD + HTML twin); the `@font-face src:` paths in the generated `pages.css` must point at the exact filenames under `design-system/fonts/`, so drift is caught at read time. All three silent-skip if the source is absent (workspace-bootstrap state may lack them); every skip is logged. Reuses `scaffold`'s **`companions=<spec>` grammar verbatim** — same two directive forms, same `+`-outer / `,`-inner separator, same auth-gated prompt when absent. `<scope>` selects the surface being redesigned — `page:<route>` (one specific HTML file — flat `page:index` or bucketed `page:auth/login`, depth cap = 1), `pages:<route1>,<route2>[,…]` (a curated comma-separated list — minimum two entries, each matching the same shape as `page:<route>`; every listed route must exist on-disk; duplicates and empty entries refused; flat + bucketed mixed allowed), or `all` (every HTML in the area). There is **no separate `assets` scope**; shared `assets/pages.css` + `assets/pages.js` are updated inline as part of the same design run whenever a new area-level rule or interaction is genuinely needed. **The four non-negotiable design rules bind every output surface:** (0) **Feature-catalog fidelity — extended to every design element** — every UI element / block / widget / affordance / form field / table column / filter chip / action / interaction / dashboard tile / admin surface / role-scoped visibility rule that lands in the HTML / CSS / JS MUST map to one or more `[x]` rows; `[ ]` deferred → omit + name in §5; no row → refuse the run and instruct the operator to add the feature via `/mr` first. The design layer NEVER invents scope. (1) **Design-system-only binding** — every color, spacing, radius, typography, shadow, and class name comes from `product/docs/uiux/<version>/design-system/*.md`; no `#RRGGBB` inline, no `bg-[#…]`, no invented class name. (2) **Responsive across three tiers — mobile / tablet / desktop** — the three breakpoint values are pinned from the design system at Step 1 (never hard-coded in this skill's body); every layout that changes across viewports declares its behavior at all three tiers explicitly; single-tier "just desktop" designs are refused. (3) **Mobile-first CSS** — base rules target mobile with no `@media` query; larger tiers add rules via `@media (min-width: <tablet-token>)` and `@media (min-width: <desktop-token>)`; `max-width` media queries and desktop-first cascades are refused. **CSS logical properties throughout** (`margin-inline-start`, `padding-block`, `inset-inline`, `border-inline-end`) — never physical (`margin-left`, `padding-bottom`, `left`, `border-right`). Applies to every project regardless of direction (they collapse to the correct physical direction automatically on LTR). **Locale-conditional operations** apply only when the design-system extract at Step 1 declares the matching mode: script normalization (ZWNJ preservation, Persian/Arabic letter canonicalization — ی/ي, ک/ك — diacritic fold) only when `LOCALE_MODE ∈ {farsi-only, bilingual}`; Jalali date rendering on human copy only when `CALENDAR=jalali` (machine surfaces — `<time datetime>`, JSON-LD, sitemap, RSS — always emit ISO-8601 Gregorian ASCII regardless); Persian digits on human copy only when `DIGITS=persian-human-ascii-machine` (Latin-only projects use ASCII everywhere); RTL-specific letter-spacing quarantine + script-specific wordmark spacing only when `DIRECTION=rtl`. Every conditional step is silently skipped when its mode is not declared, and the skip is logged. **Every design change is reflected in `<project-slug>-<area>.md`** — the touched §4.N sub-section is rewritten (for `page:<route>` the one sub-section; for `pages:<list>` one per listed route, unlisted preserved verbatim; for `all` every sub-section); §3 Cross-page conventions is additionally rewritten only when a shared area rule was introduced or changed; one line per meaningful change is appended to `## 6. Design changelog` (created on first design run if absent; append-only; `- <YYYY-MM-DD> — <scope> — <one-sentence change summary>` — ISO-8601 date, ASCII digits, `<scope>` written verbatim as the arg received). Untouched surfaces preserved verbatim. Writes files only — no stage / commit / push / MR; ship with `/mr open current`. Refuses if `<area>` missing / non-kebab / equals `design-system` / `scaffold` / `design`; if `product/docs/uiux/<version>/<area>/` does not exist (bootstrap first via `scaffold`); if `<area>/<project-slug>-<area>.md` does not exist; if `<scope>` missing (stop and ask `page:<route>` | `pages:<list>` | `all`); if `<scope>` is `assets` (removed dedicated-assets scope) or not one of the three forms; if `page:<route>` where `<area>/<route>.html` does not exist; if `pages:<list>` has fewer than two entries, contains an empty entry, contains a duplicate route, references a route that does not exist on-disk, or contains a route deeper than the two-segment `<bucket>/<route>` shape; if the design-system spec is missing or lacks the three responsive breakpoint tokens (mobile / tablet / desktop); companions refusals identical to `scaffold`; if any proposed UI element is not backed by an `[x]` row AND not present as `[ ]` (feature absent entirely).

  - `audit <area>::<mode>` — reconcile one existing UI/UX area under `product/docs/uiux/<version>/<area>/` against the single feature catalog at `product/docs/features/v<N>/all-features.md`. Enumerate every route, page section, block, widget, form field, table column, filter chip, action, interaction, dashboard tile, admin surface, and role-scoped visibility rule the design ships; anything **not** backed by an `[x]` row is an offender. Offenders split into five classes: **route-level** (a whole HTML file with no `[x]` backing → whole file removal), **element-level** (a DOM subtree inside a kept file with no `[x]` backing → surgical extraction), **orphan CSS** (rules in `<area>/assets/pages.css` whose selector list matches only removed elements → deletion or selector-list rewrite for mixed rules), **orphan JS** (event listeners / DOM queries / init code in `<area>/assets/pages.js` only touching removed elements → deletion, shared wiring preserved), **cross-area broken references** (sibling HTML / spec MD linking to a removed `<area>/<route>.html` → reported, never auto-repaired in the sibling — that is a separate `/uiux design <sibling>::page:<route>` MR). Design-system atoms (every class documented in the design-system spec, every token, every icon under `design-system/icons/`) are pre-approved and **never** offenders — the audit only checks whether a *feature composed of these atoms* is catalogued, never the atoms themselves. `<mode>` is `report` | `prune`. `report` runs the full read pass + enumeration + cross-area sweep and emits a structured operator report (offenders grouped by class, backing feature named, offending line quoted, intended removal + responsive-integrity flag `safe` | `reflow` | `manual`); no file is touched. `prune` performs the writes in a deterministic order: (1) delete route-level offender HTML files (bucket dirs that become empty are removed; `<area>/system/404.html` + `500.html` are **never** removed — mandatory system pages regardless of catalog); (2) surgically remove element-level offenders from surviving HTML files, adjusting parent grid / flex layout attributes only when required to keep remaining children rendering coherently at all three tiers — elements flagged `manual` are left in place and reported as needing a `design` follow-up rather than pruned into a broken layout; (3) sweep `assets/pages.css` — delete orphan rules, rewrite selector lists for mixed rules (never delete `@media` blocks wholesale — walk rules inside); (4) sweep `assets/pages.js` — remove handlers / queries / init for removed elements, preserve shared wiring; (5) rewrite `<project-slug>-<area>.md` — drop §1 sitemap rows for deleted routes, drop §4.N sub-sections for deleted routes, rewrite the §4.N element inventory for surviving files with surgical removals, append every removed feature to §5 «Deliberately out of scope» with the correct rationale (`[ ]`-row offender → «deferred to v<N+1>+ per catalog»; no-catalog-row offender → «feature not in catalog» — the two rationales are the only allowed forms), rewrite §3 Cross-page conventions **only** if a shared area rule died with a removed element; (6) append one line per removal to §6 Design changelog (`- <YYYY-MM-DD> — audit:prune — removed <thing> (<catalog status>).` — ISO-8601 date, ASCII digits, machine-consumed audit line, boundary rule applies universally); (7) verify responsive integrity — every surviving HTML file's `@media` blocks reference only surviving selectors and grid / flex parents render coherently at all three tiers; any regression halts the run (restore last-known-good state, report the failure) rather than shipping a broken tier; (8) emit the cross-area broken-link report. **`audit` does NOT accept `companions=<spec>`** — the reconciliation reads a fixed superset that includes every sibling area's spec MD unconditionally for cross-area link integrity, plus every `<area>/**/*.html`, plus `assets/pages.css` + `pages.js`, plus the design system enumerated in full (to distinguish atoms from features), plus `all-features.md` in full (both `[x]` and `[ ]` rows — `[x]` is the allow-list, `[ ]` is the «should have been in §5 not in markup» set, absent rows are the «feature not in catalog» set), plus `tech/docs/v<N>/project-architecture.md` in full (feature → service map + surfaces + auth posture, so a feature `[x]`-catalogued for another area's surface is not counted as backing `<area>`); passing `companions=` is refused. Writes files only — no stage / commit / push / MR; ship with `/mr open current` afterwards. Refuses if `<area>` missing / non-kebab / equals `design-system` / `scaffold` / `design` / `audit`; if `product/docs/uiux/<version>/<area>/` does not exist (bootstrap first via `scaffold`); if `<area>/<project-slug>-<area>.md` does not exist; if `<mode>` missing (stop and ask `report` | `prune`); if `<mode>` not one of those; if `product/docs/features/v<N>/all-features.md` missing; if the design-system spec missing (without the class inventory the audit would misidentify atoms as un-catalogued features and prune them); if `companions=<spec>` supplied; if `<mode>` is `prune` and the workspace has uncommitted changes touching `product/docs/uiux/<version>/<area>/` (prune is destructive — running on a dirty tree would conflate user edits with tool removals; report mode is safe on a dirty tree).

  Use when the user asks to "scaffold a new UI/UX area", "bootstrap a landing / dashboard / admin / system / emails page set", "add the mockup structure for `<area>`", "generate the HTML page set + companion spec + assets for `<area>`", "set up `product/docs/uiux/<version>/<area>/` from the feature catalog + design system", "copy the brand logos into a new UI/UX area's assets", "add the shared `pages.css` + `pages.js` scaffolds for `<area>`", "merge missing pages into an existing UI/UX area", "write the design code for `<page>`", "redesign the dashboard's `<route>` page", "regenerate the CSS / JS for `<area>`", "apply the design system to the `<area>` mockups", "make `<area>` responsive across mobile / tablet / desktop", "update `<project-slug>-<area>.md` after redesigning a page", "audit `<area>` against the feature catalog", "check whether the `<area>` mockups shipped anything not in `all-features.md`", "prune un-catalogued surfaces from `<area>`", "reconcile the design with the `[x]` list", "remove design elements that were never sanctioned by product", or invokes `/uiux`.

  If the first arg is missing or not one of `scaffold` | `design` | `audit`, stop and ask which sub-op — never default. If the first arg is recognized but the remainder is malformed, refuse with the offending value named.
---

# uiux — author UI/UX page sets

```
/uiux scaffold <area>::<mode>[::companions=<spec>]
/uiux design   <area>::<scope>[::companions=<spec>]
/uiux audit    <area>::<mode>
```

| Sub-op | Anchor | One-liner |
|---|---|---|
| `scaffold` | [`## scaffold`](#scaffold) | Scaffold one multi-page UI/UX area at `product/docs/uiux/<version>/<area>/` — **empty** HTML files at every sitemap route, **empty** `assets/pages.css`, **empty** `assets/pages.js`, brand SVGs copied verbatim into `assets/logos/`, and a **minimal** `<project-slug>-<area>.md` companion spec skeleton (frontmatter + section headers only; §1 sitemap + §5 deferred-scope ledger authored). Bootstraps the directory structure — no chrome, no placeholder content, no stub notes. Every design decision belongs to `design`. |
| `design` | [`## design`](#design) | Write / rewrite the concrete design code (HTML, CSS, JS) inside an **existing** area — mobile-first responsive across three tiers, design-system-token-bound, every change reflected in `<project-slug>-<area>.md` + appended to §6 Design changelog. |
| `audit` | [`## audit`](#audit) | Reconcile an existing area against `product/docs/features/v<N>/all-features.md`. Enumerate every route, section, block, widget, form field, table column, filter chip, action, dashboard tile, admin surface, and role-scoped visibility rule; anything not backed by an `[x]` row is an offender. `report` mode lists offenders + intended removals + cross-area impact (no writes). `prune` mode deletes offender files, surgically removes offender elements, sweeps orphan CSS + JS, verifies responsive integrity, rewrites the spec (§1 sitemap, §4.N sub-sections, §5 deferred-scope ledger, §3 only when a shared rule died), and appends one line per removal to §6 Design changelog. Design-system atoms (classes documented in the design-system spec, tokens, icons) are pre-approved and never offenders. Cross-area broken references are surfaced, never auto-repaired. Does not accept `companions=<spec>`. |

If the first arg is missing or not one of `scaffold` | `design` | `audit`, stop and ask.

## Synopsis

`uiux` is the UI/UX authoring counterpart to `docs` (which authors PRD-TDDs) and `implement frontend-page` (which writes real frontend feature code). Where `docs` writes documentation for engineering and `implement frontend-page` writes framework component code, `uiux` writes the **mockup layer that sits between them** — the visual reference every implementer consumes, the artifact reviewers click through the way a visitor would, and the surface the design system is proven against.

`scaffold` and `design` share the exact same fixed read set and the exact same `companions=<spec>` grammar. Where they diverge: `scaffold` bootstraps a new area (target dir must NOT exist) and writes **empty files at every sitemap route** — no chrome, no design code, no placeholder text — while `design` operates on an existing area (target dir MUST exist) and rewrites the actual design code with three responsive tiers, mobile-first, and reflects every change in the companion MD.

`audit` is the reverse pass — where `scaffold` and `design` compose forward from the catalog to the markup, `audit` walks the current on-disk area and forces it back into alignment with the current `[x]` catalog. It reads a fixed superset (feature catalog in full, target area in full, design system in full, every sibling spec MD for cross-area link integrity, platform architecture for feature → surface resolution) and does NOT accept `companions=<spec>`. `report` is a safe dry-run against any tree; `prune` refuses if the working tree has uncommitted changes touching `<area>` (destructive writes must not conflate user edits with tool removals).

Every sub-op begins with the same workspace probe: the skill reads `product/docs/uiux/<version>/design-system/*.md` in full and extracts locale, direction, calendar, digit rule, brand-mark path, project-slug, palette name, typography stack, and the three breakpoint tokens. Every downstream constraint — `<html lang>` + `dir`, script normalization, calendar-boundary date rendering, digit rule, `<link rel="canonical">` shape, spec filename `<project-slug>-<area>.md`, palette references, CSP third-party allow-list — is **derived from that read**. Nothing is hard-coded to a specific locale, calendar, palette, or product name.

Every sub-op is **read-heavy, write-once, no side effects**. The full read pass completes before generation; generation produces files; no external command runs. Ship with `/mr open current` afterwards.

## scaffold

Scaffold the directory structure of one multi-page UI/UX area at `product/docs/uiux/<version>/<area>/` from the `[x]` feature catalog + design system + brand assets + frontend standards — the **empty skeleton**. Every HTML file is 0-byte; `assets/pages.css` + `assets/pages.js` are 0-byte; the companion `<project-slug>-<area>.md` is a minimal skeleton (frontmatter + section headers only, with §1 four-column sitemap authored as the run's file-map artifact and §5 authored as the deferred-scope ledger). Brand SVGs under `assets/logos/` are the only non-empty non-spec write. Every design decision — chrome, canonical, OG, theme wiring, breadcrumb, block composition, responsive tiers, token binding — is deferred to `design`.

### Argument

`<area>::<mode>[::companions=<spec>]` where:

| Slot | Required | Shape |
|---|---|---|
| `<area>` | yes | `^[a-z][a-z0-9-]*$` — kebab-case domain of the new UI/UX area under `product/docs/uiux/<version>/`. Examples: `landing`, `dashboard`, `admin`, `system`, `emails`. |
| `<mode>` | yes | `bootstrap` \| `merge`. `bootstrap` creates from zero (refuses if the dir exists); `merge` adds missing files (refuses if the dir does not exist); neither overwrites human-authored files. |
| `companions=<spec>` | no | **`+`-separated** list of sibling-area reads on top of the fixed set. Each entry is one of `uiux:<sibling-area>` (sibling's `<project-slug>-<sibling>.md` full + every `<sibling>/*.html` full) \| `uiux:<sibling-area>:pages=<route1>[,<route2>…]` (sibling's MD full + only the listed HTML pages). MD always included; only HTML scope varies. Sibling area specs are **not** auto-read — companions is the only entry path. Absent + area is auth-gated ⇒ skill prompts once at Step 1 start whether to add sibling companions. |

#### `companions=<spec>` grammar

**Outer separator is `+`** (between directives). **Inner separator is `,`** (only inside a single `pages=<route1>,<route2>` list). This lets one `pages=` list carry multiple route filenames without colliding with the top-level directive separator. Whitespace around `+` ignored. Page names are kebab-case route filenames **without** the `.html` extension. Both flat routes (`index`, `article-detail`, `search`, `404`) and bucketed routes (`auth/login`, `settings/profile`, `forms/contact-us`) are accepted — the value maps directly onto the sibling's on-disk path (`<sibling>/<route>.html`). Only the two-segment shape `<bucket>/<route>` is valid; deeper nesting matches the scaffold's cap of one bucket level.

| Directive | Reads |
|---|---|
| `uiux:<sibling>` | `<sibling>/<project-slug>-<sibling>.md` in full **+** every `<sibling>/*.html` file **read in full**. The MD carries the sibling's frontmatter shape, cross-page conventions, spec section grammar. The markup carries chrome composition, component wiring, class-name usage, direction-aware structure, `<time>` machine-attribute pattern, canonical / OG shape, breadcrumb reorder. Inherits route naming, chrome shape, and concrete composition patterns. Refuses if `<sibling>` does not exist or its `<project-slug>-<sibling>.md` is missing. |
| `uiux:<sibling>:pages=<route1>[,<route2>…]` | `<sibling>/<project-slug>-<sibling>.md` in full **+** only the listed HTML pages under `<sibling>/` — `<sibling>/<route1>.html` + `<sibling>/<route2>.html` + … Multiple route names joined by `,` within the single directive. MD always included; HTML scope narrowed. Refuses if any `<sibling>/<route>.html` does not exist. |

**Combining multiple sources.** Every combination is expressed by repeating the directive after `+`. MD is included in every `uiux:` directive (bare or `pages=`) — only HTML scope varies per entry.
- Two full sibling reads (MD + all HTML per sibling): `companions=uiux:landing+uiux:system`
- One sibling MD + a selected HTML pair: `companions=uiux:landing:pages=index,article-detail`
- Two siblings, each MD + one selected page: `companions=uiux:landing:pages=index+uiux:system:pages=404`
- One full sibling + another with narrowed HTML: `companions=uiux:landing+uiux:system:pages=404`

Ordering is preserved — earlier directives read first, later directives compose on top. Duplicate directives (identical form) collapse to one; overlapping directives (`uiux:landing` + `uiux:landing:pages=index`) resolve to the broader read (full sibling wins over page-scoped; MD is identical either way).

Every companion read completes before Step 2 (composition). Companions **augment** the fixed read set — they never replace it.

#### Auth-gated prompt (companions absent + area is auth-gated)

At the start of Step 1, resolve `<area>` against `tech/docs/v<N>/project-architecture.md`'s auth-posture section. If the area is auth-gated (dashboard-shaped, admin-shaped, or any surface whose posture requires cookie + silent refresh) AND at least one sibling area exists under `product/docs/uiux/<version>/`, emit one prompt:

> `<area>` is auth-gated. The anonymous-shell sibling (`landing` when present) carries the shared chrome, theme wiring, brand voice, and reader-side design-system component samples — read it as a companion?
> [y] add `uiux:<anonymous-shell-sibling>` (typically `landing`)
> [n] proceed without companions
> [s] select — pick a curated companion set from the sibling areas

`y` prepends the anonymous-shell sibling directive to the (empty) companion list — the skill picks the anonymous shell area from the on-disk sibling set (`landing` in most workspaces). `n` proceeds with the fixed set only. `s` opens a follow-up multi-select prompt listing every sibling area (with a per-sibling "all pages" vs "specific pages" toggle); the operator's picks build the final companion list. The prompt fires exactly once per run, never for anonymous areas (landing / system), never when `companions=` was explicitly supplied.

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
- Any proposed sitemap route not backed by an `[x]` row in `product/docs/features/v<N>/all-features.md` AND not present as a `[ ]` deferred row (i.e. the feature is absent from the catalog entirely) → refuse with the missing feature named; instruct the operator to add the row via a separate MR through `/mr` before re-running (see the Feature-catalog fidelity hard rule below).

### Hard rules

- **Read first, write last.** No file is composed until every binding input is read in full. The read pass drives the sitemap partition (flat vs. bucketed) and the §5 out-of-scope ledger only; no design output is produced.
- **Locale / direction / calendar / digits / brand-mark / project-slug / palette read from the design-system spec — never hard-coded.** Step 1 extracts these values from `product/docs/uiux/<version>/design-system/*.md`. Every downstream frontmatter default (`<html lang>` + `dir`, `og:locale`, `Content-Language`), every conditional normalization step (script normalization only when `LOCALE_MODE ∈ {farsi-only, bilingual}`), every date rendering (Jalali only when `CALENDAR=jalali`), every digit rule (Persian-human-ASCII-machine boundary only when `DIGITS=persian-human-ascii-machine`), and every asset copy (brand-mark filename from §8 Logo) derives from that read. A Latin-only LTR project produces `<html lang="en" dir="ltr">` outputs with no script-normalization step, silently skipping the conditional pipeline (and logging the skip); a Farsi-only RTL project produces `<html lang="fa" dir="rtl">` outputs with the full normalization pipeline applied. Bilingual projects apply direction + digit rule per-page based on URL prefix.
- **Spec filename prefix = the project slug.** The companion spec filename is `<project-slug>-<area>.md` where `<project-slug>` is detected in this order: (a) the design-system filename's own prefix (`heptapeak-design-system.md` → `heptapeak`; `tizvir-design-system.md` → `tizvir`); (b) if the design-system filename is unprefixed (`design-system.md`), fall back to a `slug` / `project` field in the design-system frontmatter; (c) if neither, use the workspace root directory's basename lowercased and kebab-cased (`ReZa/soradis` → `soradis`). Every sibling area's spec obeys the same prefix — no mixing.
- **Feature-catalog fidelity — non-negotiable.** Every route that lands in the sitemap MUST correspond to one or more `[x]` rows in `product/docs/features/v<N>/all-features.md`. Three cases exhaust every candidate route:
  1. **`[x]` row exists** ⇒ the route enters the sitemap; the spec's §4.N sub-section (later, in `design`) names the row(s) it satisfies.
  2. **`[ ]` row exists** ⇒ the route is omitted from the sitemap AND named in §5 «Deliberately out of scope» with a one-line rationale (deferred to v<N+1>+ / no monetization surface in v<N> / …). Silent omission would read as forgetfulness — explicit omission beats silent omission.
  3. **No row exists (feature is not in the catalog at all)** ⇒ **refuse the run**. Stop, name the missing feature (`the newsroom page`, `the DLQ panel`, `the environment tag in the admin footer`, …), and instruct the operator to add it to `all-features.md` first via a separate MR through `/mr`, then re-run. The mockup layer NEVER invents scope, never anticipates future features, never adds "nice-to-have" surfaces the catalog does not sanction. If the product genuinely needs the surface, adding the feature to the catalog is the first step; drawing it in the mockup is the last step.
- **Every HTML file is empty — 0-byte.** No doctype, no `<html>` / `<head>` / `<body>` tags, no chrome, no canonical, no OG, no theme script, no CSS/JS links, no placeholder text, no «not designed in this run» stub. The file exists as an anchor for its sitemap row and as the write target for a future `design` run.
- **`assets/pages.css` is empty — 0-byte.** No `@import`, no `@font-face`, no token re-declarations, no rules. `design` writes the first CSS content.
- **`assets/pages.js` is empty — 0-byte.** No theme pre-paint, no drawer wiring, no toggle. `design` writes the first JS content.
- **Companion spec `<project-slug>-<area>.md` is a minimal skeleton.** Frontmatter matches the sibling files' shape verbatim (`title` / `derived_from` / `companion_of` / `scope_source` / `informed_by` / `audited_at` — `audited_at` uses the current session date, ISO-8601; add `locale` + `direction` when the design system declares them). Body carries only §N section headers (`## 1. Sitemap and file map` through `## 7. Source of truth & drift`). **§1's four-column sitemap code block (URL / Bucket / File / Purpose) is authored** — it is the file-map artifact of the scaffold run itself, and downstream tools + reviewers need it to trace the bucketing. **§5's one-line-per-`[ ]`-feature ledger is authored** — explicit omission beats silent omission. Every other section is header-only (no chrome table, no §4 sub-sections, no §6 seed line, no §7 prose). `design` fills the rest as it runs.
- **The brand mark + any additional brand SVG are copied byte-verbatim.** The brand-mark file named by the design-system spec's §8 Logo is copied from `business/docs/brand/` into `<area>/assets/logos/` without transformation. Any additional brand SVG in `business/docs/brand/` is copied alongside it. This is the **only** non-empty non-spec write.
- **`merge` never overwrites human-authored files.** If a filename in the sitemap already exists, silent-skip (do not touch); log the skip in the run summary. Only files that do not exist are written. This preserves editorial work between scaffolding runs. An existing empty file at a scaffold-owned path is treated as human-authored — silent-skip.
- **Workspace hard rules apply to the output spec + copied assets.** No `Co-Authored-By:` footers. No references to `CLAUDE.md` / `README.md`. No money surfaces unless the design system explicitly sanctions them in §3.3.
- **Every downstream design constraint is deferred to `design`.** Locale-conditional normalization, calendar-conditional date rendering, self-hosted fonts, canonical, OG + Twitter Card meta, theme persistence pre-paint, tokens-only binding, mobile-first responsive across three tiers, CSS logical properties, breadcrumb reorder — none of these apply to `scaffold`'s output because `scaffold` writes no design output. `design` inherits all of them the first time it runs against the area.

### Step 1 — read every binding input

**Fixed read set (always read, never varies, hard-coded — reading anything outside this set requires `companions=`).**

1. **Existing area** if `<mode>` is `merge`: `product/docs/uiux/<version>/<area>/` — enumerate every present file. Log what will be skipped vs. written.
2. **Design system**: `product/docs/uiux/<version>/design-system/*.md` in full + its HTML twin. The MD is the token / component spec, the HTML is the rendered visual reference — open both. **Extract locale, direction, calendar, digits, brand-mark path, project-slug, palette name, typography stack, and the three breakpoint tokens** — these values drive every downstream conditional and every filename decision. Also extract every component class name (`.site-topbar`, `.site-footer`, `.article-card`, `.cta-band`, `.hero-grad`, `.breadcrumb`, …). No composed page will use a class name outside this set.
3. **Brand assets**: `business/docs/brand/` — enumerate every SVG. The brand-mark file named by the design system's §8 Logo is required; any additional brand SVG is bonus (copy all).
4. **Product feature catalog**: `product/docs/features/v<N>/all-features.md` — filter to `[x]` rows whose delivery surface matches `<area>`. Landing-shaped area → reader-facing rows; dashboard-shaped area → editorial + admin rows (block editor, taxonomy management, comment moderation, workflow queue, …); system-shaped area → error and probe surfaces only. Anything `[ ]` becomes §5 «Deliberately out of scope» prose with a one-line rationale.
5. **Standards — the five hard-coded reads.** No other standard is read; the other seven (`api-and-data-contracts.md`, `ci-cd.md`, `errors-and-observability.md`, `git.md`, `infrastructure.md`, `microservice-layout.md`, `testing.md`) are intentionally out of scope for a static mockup surface.
   - `tech/docs/standards/frontend.md` — full — copy-in-markup boundary (mockup-vs-production delta), block-renderer parity contract, CSP-allow-listed third-party origins, self-hosted-fonts posture.
   - `tech/docs/standards/frontend-layout.md` — full — responsive contract (mobile-first, mockup `@media` queries), token binding rule (no `bg-[#…]`, no invented classes), direction-aware layout via CSS logical properties, breakpoint reorder.
   - `tech/docs/standards/coding.md` — **§11 only** (calendar / digit boundary rule — Jalali + Persian digits on human surfaces, ASCII + ISO-8601 on machine surfaces — applied conditionally per the design-system extract) **+ §12 only** (JSON block-tree contract — content bodies are block trees, `body_html` blocked at the write layer).
   - `tech/docs/standards/documentation.md` — full — companion-spec frontmatter conventions (`title` / `derived_from` / `companion_of` / `scope_source` / `informed_by` / `audited_at`), doc-linking rules.
   - `tech/docs/standards/security-and-auth.md` — **§8 only** — CSP allow-list for embed origins. Only used when the area renders embeds; still read every run so the mockups' `<meta http-equiv="Content-Security-Policy">` samples (if any) stay accurate.
6. **Platform architecture**: `tech/docs/v<N>/project-architecture.md` in **full** — service map, feature → service map, surfaces (URL topology, which frontend serves `<area>`), auth posture (anonymous read on public reader; cookie + silent refresh on dashboard), fixed stack, deployment topology, glossary. Full read — no section-scoped extract. The auth-posture section in particular resolves whether the area is auth-gated or open — this resolution drives the companions prompt at Step 1a below.
7. **Sibling area specs are NOT auto-read.** A sibling only enters the read set through a `uiux:<sibling>` (or `uiux:<sibling>:pages=…`) directive in `companions=<spec>`, or when the auth-gated prompt picks one. The directive pulls the sibling's `<project-slug>-<sibling>.md` in full + its HTML (scoped by `pages=` if present). This keeps the fixed set bounded even as the sibling area count grows.
8. **Consumed backend PRD-TDDs' route-family sections** (conditional — only when the area is auth-gated / dashboard-shaped, resolved from step 6): the relevant backends' `docs/v<N>/PRD-TDD.md` route-family section. Names surfaces truthfully — an "Articles" surface in a dashboard-shaped area binds to the content backend's article routes, not an invented endpoint.
9. **Workspace-root `CLAUDE.md`** if present at the workspace root — read fully; every hard rule applies to the output document. If absent, silent-skip (bootstrap workspaces may not have it yet).

**Step 1a — companions resolution (prompt-or-execute).**

- If `companions=<spec>` was supplied in the argument → parse the spec, validate every directive against the refusal grammar, then execute each read in listed order. No prompt.
- Else if `<area>` resolved as **auth-gated** at step 6 (dashboard-shaped, admin-shaped, or any auth-posture requiring cookie + silent refresh) AND at least one sibling area exists under `product/docs/uiux/<version>/` → emit the auth-gated prompt (`y` / `n` / `s`) documented in the argument section above; act on the operator's answer.
- Else (anonymous area, or auth-gated with no siblings yet) → skip; the fixed set is enough.

**Step 1b — companion reads (only if step 1a resolved a non-empty list).**

Per-directive:
- `uiux:<sibling>` — read `<sibling>/<project-slug>-<sibling>.md` in full **and** every `<sibling>/*.html` file in full. The MD carries frontmatter shape, cross-page conventions, and spec section grammar for consistency of the target `<area>`'s companion spec. The markup is the concrete reference: chrome composition, component wiring, class-name usage, direction-aware structure, `<time>` machine-attribute pattern, canonical / OG shape, breadcrumb reorder. Extract chrome patterns, concrete composition, and any shared class names that are candidates for extraction into a future design-system component.
- `uiux:<sibling>:pages=<route1>[,<route2>…]` — read `<sibling>/<project-slug>-<sibling>.md` in full **and** only the listed HTML pages under `<sibling>/` (`<sibling>/<route1>.html`, `<sibling>/<route2>.html`, …). MD always included; same extraction targets as the bare form, HTML scope narrowed to the listed pages.

Every companion read completes before Step 2. Companions **augment** the fixed read set — they never replace an entry from it, they never override any hard rule, they never introduce a component the design system does not document.

Every read (fixed + companion) completes before Step 2. No section is composed until every binding input has been read in full.

### Step 2 — compose the sitemap

From the `[x]` rows that survived Step 1 filtering, compose the sitemap: one row per URL the area serves. The sitemap carries a **fourth column, `Bucket`**, to record the domain grouping (`—` for flat, the bucket name for grouped rows):

```
URL                                       Bucket        File                         Purpose
──────────────────────────────────────────────────────────────────────────────────────────────
/<route-1>                                —             <route-1>.html               <one-line purpose from the feature catalog>
/<route-2>                                <bucket>      <bucket>/<route-2>.html      <one-line purpose>
…
```

Rules:
- One HTML file per URL. File name equals the URL's last segment (kebab-case).
- Template routes (`/blog/[slug]`, `/authors/[slug]`, …) get one populated instance whose file name is the last static segment (`article-detail.html`, `author-profile.html`) and whose spec entry documents it as a template that production replicates for each concrete slug.
- Every route in scope maps to exactly one `[x]` feature (or a coherent group of them). If a proposed route has no `[x]` backing, drop it — the sitemap only ships what the catalog says ships.
- If the sitemap is empty (no `[x]` rows land here), refuse the run and explain: the catalog delivers nothing on this surface today; nothing to scaffold.

#### Domain grouping — flat vs. subfolder

Once the sitemap rows are gathered, partition them into **top-level pages** (flat under `<area>/`) and **domain buckets** (subfolders `<area>/<domain>/`). Never dump every page flat — a 15-page area rendered as 15 sibling HTML files is unreviewable. Compose the tree the way a real frontend repo composes `src/features/`.

**Bucketing algorithm** (applied per sitemap row):

1. **Top-level pages (flat, no subfolder):**
   - The area entry (`index.html`).
   - Sitemap / directory / area-map pages (`sitemap.html`).
   - Single-purpose pages that do not belong to any multi-page flow (`about.html`, `privacy.html`, `terms.html`, `contact.html` — when contact is a single page, not a flow).
   - Any page that is the only member of its would-be bucket.
   - **`404.html` and `500.html` are NOT flat.** They are mandatory system pages and always land under `<area>/system/` per the rule below.

2. **Domain buckets (`<area>/<domain>/<route>.html`):**
   - When **2 or more** routes share a semantic domain, group into `<domain>/`.
   - Well-known buckets (use these names when applicable — do not invent synonyms):
     - `system/` — **mandatory for every area** — `404.html`, `500.html`, and any future error / maintenance surfaces (`503.html`, `maintenance.html`) live here. Every scaffold writes `<area>/system/404.html` + `<area>/system/500.html` unconditionally, whether the area is anonymous (landing / marketing) or auth-gated (admin / dashboard). No exceptions, no shared top-level `system/` directory across areas. Rationale: each area owns a distinct visual language, a distinct return-home target (anonymous root vs auth-gated root per architecture surfaces), and a distinct asset root (`<area>/assets/`). A shared top-level `system/` would force cross-area asset references and misrepresent the surface the user was actually on when the error fired. If the area is auth-gated, the 500 page's «return» CTA points at the area's own root; anonymous areas match the anonymous shell chrome verbatim.
     - `auth/` — login, signup, otp-verify, password-reset, password-change, magic-link, session flows.
     - `forms/` — multi-step forms, submission wizards, custom form definitions (contact-form, subscription-form, feedback-form when they are part of a form set).
     - `settings/` — profile, account, billing, security, preferences, notifications, api-keys.
     - `content/` — article-detail, article-list, category, tag, author-profile, search-results, when the area has a full content browsing surface.
     - `admin/`-family sub-areas inside a dashboard (`users/`, `roles/`, `moderation/`, `analytics/`) — one per admin domain.
   - Custom buckets are allowed when the sitemap shows a coherent domain not covered above (e.g. `checkout/` for a purchase flow, `onboarding/` for a first-run flow); name must be kebab-case, singular preferred, plural for collections (`users/` not `user/` when it's a management surface).

3. **Nesting depth is capped at one level.** `<area>/<domain>/<route>.html` is allowed. `<area>/<domain>/<sub-domain>/<route>.html` is not — collapse the sub-domain into a kebab-cased route name (`settings/billing-invoices.html`, not `settings/billing/invoices.html`). Deep nesting hides pages from reviewers.

4. **Bucket → URL relationship.** The bucket is a *file organization* concern, not a URL contract. The URL in the sitemap is the source of truth (from the `[x]` catalog); the on-disk path just groups files by domain for reviewability. A page whose URL is `/settings/profile` naturally lands in `settings/profile.html`, but a page whose URL is `/me` can still live under `settings/me.html` if it is functionally a settings surface — document the mapping in the sitemap's third column.

**Sitemap composition — four columns instead of three:**

```
URL                                       Bucket        File                         Purpose
──────────────────────────────────────────────────────────────────────────────────────────────
/                                         —             index.html                   Area entry — hero + primary CTA
/about                                    —             about.html                   About page
/contact                                  —             contact.html                 Contact single page
/login                                    auth          auth/login.html              Login flow entry
/signup                                   auth          auth/signup.html             Signup flow
/otp/verify                               auth          auth/otp-verify.html         OTP verify step
/settings/profile                         settings      settings/profile.html        Profile settings
/settings/security                        settings      settings/security.html       Security settings
/forms/contact-us                         forms         forms/contact-us.html        Contact form (variant of a form set)
/forms/subscribe                          forms         forms/subscribe.html         Subscription form
…
```

The `Bucket` column is `—` for flat top-level pages and the bucket name for grouped pages. Empty buckets never appear — a bucket exists only when 2+ rows populate it.

**Merge-mode behavior.** If `<mode>` is `merge` and the existing area already places some pages flat that this run would bucket (or vice versa), preserve the existing on-disk layout for pages that already exist (never move an existing file), and only apply the bucketing rule to newly-added routes. Log every disagreement between the intended bucket and the on-disk placement so the operator can consolidate manually. Never call `git mv` — the skill is write-only.

### Step 3 — write files

Write in this order (deterministic — resume-safe):

1. **`product/docs/uiux/<version>/<area>/assets/logos/`** — copy every SVG from `business/docs/brand/` verbatim (byte-for-byte; no transformation, no re-minification, no re-formatting). The brand-mark file named by the design-system spec's §8 Logo is required; additional SVGs are copied when present. **This is the only non-empty non-spec write.**
2. **`product/docs/uiux/<version>/<area>/assets/pages.css`** — **empty 0-byte file**. No `@import`, no `@font-face`, no token declarations, no rules. `design` writes CSS content on the first design run against the area.
3. **`product/docs/uiux/<version>/<area>/assets/pages.js`** — **empty 0-byte file**. No theme pre-paint, no drawer wiring, no toggle handler. `design` writes JS content on the first design run.
4. **One HTML file per sitemap row, placed by the bucket resolved in Step 2** — flat rows land at `<area>/<route>.html`; bucketed rows land at `<area>/<bucket>/<route>.html`. **`<area>/system/404.html` + `<area>/system/500.html` are always written** as the mandatory system-page pair — no sitemap `[x]` row is required, they ship by default with every area. **Every one of these files is 0-byte empty** — no doctype, no `<html>` / `<head>` / `<body>` tags, no chrome, no canonical, no OG, no theme script, no CSS/JS link, no placeholder text, no «not designed in this run» stub. The file is an anchor for the sitemap row and the write target for a future `design` run. Bucket directories are created on the first row that lands in each.
5. **`product/docs/uiux/<version>/<area>/<project-slug>-<area>.md`** — the **minimal companion spec skeleton**. Frontmatter matches the sibling files' shape verbatim:

   ```markdown
   ---
   title: <project-name> — v<N> <area> page set
   derived_from: ../design-system/<project-slug>-design-system.md, ../design-system/<project-slug>-design-system.html
   companion_of: <first-route>.html (and the other N files in this directory)
   scope_source: ../../../features/v<N>/all-features.md
   informed_by: ../../../../../tech/docs/standards/frontend-layout.md
   audited_at: <YYYY-MM-DD current session date>
   ---
   ```

   Body sections — headers-only for §2 / §3 / §4 / §6 / §7; §1 and §5 authored:

   1. `# <project-name> — v<N> <area> page set` — one sentence stating the file is the written companion to the (currently empty) HTML files under this directory and that every design decision is deferred to `/uiux design`.
   2. `## 1. Sitemap and file map` — **authored**. The four-column code block (URL / Bucket / File / Purpose) composed in Step 2, listing every route the area serves. This is the file-map artifact of the scaffold run itself.
   3. `## 2. Why per-page files (not one showcase)` — header only. `design` fills in the rationale prose on the first design run.
   4. `## 3. Cross-page conventions` — header only. `design` fills the shared-chrome table + breadcrumb / hero-gradient / theme-persistence rules when they are actually established.
   5. `## 4. Per-page composition` — header only. `design` seeds each `### 4.N <route>` sub-section as the corresponding page is designed. No stub sub-sections are pre-written.
   6. `## 5. Deliberately out of scope for v<N>` — **authored**. One line per `[ ]` feature the area does not carry, each with a one-line rationale (deferred to v<N+1>+ / no monetization / …). Explicit omission beats silent omission.
   7. `## 6. Design changelog` — header only. `design` creates the append-only body + first entry on the first design run.
   8. `## 7. Source of truth & drift` — header only. `design` writes the source-of-truth prose + drift rule once the first design pass lands.

6. **Do not write anything else.** No README, no scripts dir, no build files, no CI file, no gitignore. UI/UX packs are pure documentation; the mockup surface is self-contained.

Silent-skip files that exist in `merge` mode. Log every skip in the run summary so the operator sees what was preserved.

### What it writes — full inventory

- `product/docs/uiux/<version>/<area>/<project-slug>-<area>.md` — **minimal companion spec skeleton** (frontmatter + section headers; §1 four-column sitemap authored; §5 deferred-scope ledger authored; every other section header-only).
- `product/docs/uiux/<version>/<area>/<flat-route>.html` — **empty 0-byte file** per flat sitemap row (index, sitemap, about, contact, privacy, terms, single-purpose pages).
- `product/docs/uiux/<version>/<area>/<bucket>/<sub-route>.html` — **empty 0-byte file** per bucketed sitemap row, grouped by domain (e.g. `auth/login.html`, `settings/profile.html`, `forms/contact-us.html`). Bucket names are kebab-case; nesting depth is capped at one.
- `product/docs/uiux/<version>/<area>/system/404.html` + `.../system/500.html` — **empty 0-byte files**. Mandatory system-page pair.
- `product/docs/uiux/<version>/<area>/assets/logos/*.svg` — brand-mark + any additional brand SVGs from `business/docs/brand/`, copied verbatim.
- `product/docs/uiux/<version>/<area>/assets/pages.css` — **empty 0-byte file**.
- `product/docs/uiux/<version>/<area>/assets/pages.js` — **empty 0-byte file**.

Nothing outside `product/docs/uiux/<version>/<area>/` is written. The skill does not touch other repos, does not stage, does not commit, does not push. After scaffolding, run `/uiux design <area>::all` to fill the empty files with real design code.

## design

Write / rewrite the concrete design code (HTML, CSS, JS) inside an **existing** UI/UX area under `product/docs/uiux/<version>/<area>/`. Mobile-first responsive design across three breakpoint tiers (mobile / tablet / desktop), every surface bound to the workspace's design system, every change reflected in the companion `<project-slug>-<area>.md` spec + appended to §6 Design changelog.

Sibling of `scaffold`. `scaffold` bootstraps (target dir must NOT exist); `design` operates on an area that already exists (target dir MUST exist). Reuses `scaffold`'s fixed read set and `companions=<spec>` grammar verbatim.

### Argument

`<area>::<scope>[::companions=<spec>]` where:

| Slot | Required | Shape |
|---|---|---|
| `<area>` | yes | Kebab-case existing area under `product/docs/uiux/<version>/`. Must already exist — use `scaffold` to bootstrap first. |
| `<scope>` | yes | `page:<route>` \| `pages:<route1>,<route2>[,<route3>…]` \| `all`. `page:<route>` operates on one specific HTML file — `<route>` is the on-disk path under `<area>/` without `.html` (flat: `page:index`, `page:article-detail`; bucketed: `page:auth/login`, `page:settings/profile`; two-segment shape only, depth cap = 1). `pages:<list>` operates on a curated comma-separated list of specific HTML files — each entry matches the same shape as `page:<route>` (flat or two-segment bucketed, depth cap = 1); whitespace around `,` ignored; minimum two entries (one entry ⇒ use `page:<route>`); every listed route must exist on-disk; duplicates + empty entries refused. Flat + bucketed routes can be mixed in one list (`pages:index,auth/login,settings/profile`). Same read pass as `all` (the write targets + `<area>/index.html` shell reference + shared assets + spec MD — other sibling flat pages and bucket pages are **not** auto-read); writes touch only the listed routes and the corresponding §4.N sub-sections. `all` rewrites every HTML in the area (flat and bucketed). There is **no `assets` scope** — shared `assets/pages.css` + `assets/pages.js` are updated inline as part of every design run whenever a new area-level rule or interaction is genuinely needed; never regenerated wholesale as a dedicated pass. |
| `companions=<spec>` | no | Same grammar as `scaffold` verbatim — `+`-separated directives, two forms (`uiux:<sibling>`, `uiux:<sibling>:pages=<route1>[,<route2>…]`), `,` inner list, auth-gated prompt when absent. See `scaffold` for the full grammar. |

### Examples

```
# design one flat page — no companion
/uiux design landing::page:article-detail

# design one bucketed page (auth flow inside admin area)
/uiux design admin::page:auth/login

# design a page inside a two-segment bucket
/uiux design admin::page:settings/profile

# design a curated list of pages together (flat + bucketed mixed)
/uiux design admin::pages:index,about,auth/login

# design several bucketed pages in one run
/uiux design admin::pages:settings/profile,settings/security,settings/notifications

# rewrite every HTML in the area (flat + bucketed)
/uiux design admin::all

# design admin's articles/index, pulling landing's MD + all its HTML for chrome reference
/uiux design admin::page:articles/index::companions=uiux:landing

# design with two full siblings (MD + all HTML each)
/uiux design admin::page:index::companions=uiux:landing+uiux:system

# design pulling only specific pages from a sibling (MD always included)
/uiux design admin::page:index::companions=uiux:landing:pages=index,article-detail

# combine: one sibling scoped by pages= + another sibling in full
/uiux design admin::page:articles/edit::companions=uiux:landing:pages=article-detail+uiux:system
```

**Separator cheatsheet:**

| Position | Separator | Example |
|---|---|---|
| Between the three top-level slots (`<area>` / `<scope>` / `companions=`) | `::` | `admin::page:index::companions=…` |
| Between scope key and value (`page` / `pages` / route path) | `:` | `page:index`, `page:auth/login`, `pages:index,about` |
| Between multiple route names inside one `pages:<list>` scope | `,` | `pages:index,about,contact` |
| Between companion directive key and value (`uiux` / sibling) | `:` | `uiux:landing` |
| Between `pages` and its value list | `=` | `pages=index` |
| Between multiple page names inside one `pages=` list | `,` | `pages=index,article-detail` |
| Between multiple companion directives | `+` | `uiux:landing+uiux:system` |

**Common mistakes to refuse:**

- `pages:index` — inside `companions=<spec>` this is wrong (companion inner list uses `=`, so `companions=uiux:landing:pages=index`); at the top-level `<scope>` slot `pages:index,about` is the curated-list form and uses `:` + `,`. Do not mix the two contexts.
- `pages:index` at the top-level `<scope>` slot with only one entry — refuse; single entry ⇒ use `page:index`.
- `pages:index,` or `pages:,index` — empty entry; refuse.
- `pages:index,index` — duplicate route; refuse.
- `companions=uiux:<target-area>` — self-referential; the target area's own MD + HTML are already read automatically. Companion only accepts a sibling different from `<area>`.
- `page:auth/login/mfa` — three-segment route; depth cap is 1. Collapse to `page:auth/login-mfa` or place under a dedicated route.
- `scope=assets` — the dedicated `assets` scope was removed. Shared `assets/pages.css` + `assets/pages.js` are updated inline as part of the same `page:<route>` or `all` run.

### Refusal conditions

- `<area>` missing / non-kebab / equals `design-system` / equals `scaffold` / equals `design` → refuse.
- `product/docs/uiux/<version>/<area>/` does not exist → refuse (bootstrap first via `scaffold`).
- `<area>/<project-slug>-<area>.md` does not exist → refuse (bootstrap first via `scaffold`; every design run rewrites a sub-section of the spec + appends one line to §6 Design changelog — the spec MD is the target of every design write, not optional).
- `<scope>` missing → stop and ask `page:<route>` | `pages:<list>` | `all`; never default.
- `<scope>` given as `assets` (the removed dedicated-assets scope) → refuse with the offending value named; instruct the operator to use `page:<route>`, `pages:<list>`, or `all` — shared assets are updated inline in the same run when needed.
- `<scope>` not one of the three forms → refuse with the offending value named.
- `page:<route>` where `<area>/<route>.html` does not exist → refuse with the offending route named.
- `pages:<list>` with fewer than two entries (single entry ⇒ use `page:<route>`) → refuse.
- `pages:<list>` containing any empty entry (`pages:index,,about`, `pages:,index`, `pages:index,`) → refuse.
- `pages:<list>` containing a duplicate route (`pages:index,index`, `pages:auth/login,auth/login`) → refuse with the offending route named.
- `pages:<list>` where any listed `<area>/<route>.html` does not exist → refuse with the offending route named.
- `pages:<list>` containing a route deeper than the two-segment `<bucket>/<route>` shape (`pages:settings/security/mfa`) → refuse (depth cap = 1 — collapse to a kebab-cased route name).
- `product/docs/uiux/<version>/design-system/*.md` missing → refuse (token source of truth).
- Design system MD does not declare the three responsive breakpoint tokens (mobile / tablet / desktop pixel values) → refuse (single-tier or two-tier designs are not shippable).
- Companions refusals — identical to `scaffold` (companions empty; separator not `+`; directive form invalid; sibling missing; page name unresolved under `<sibling>/`).
- Any proposed UI element / block / widget / affordance / form field / table column / filter chip / action / dashboard tile / admin surface / role-scoped visibility rule that the design would compose is NOT backed by an `[x]` row in `product/docs/features/v<N>/all-features.md` AND NOT present as a `[ ]` deferred row (i.e. absent from the catalog entirely) → refuse with the missing element named concretely; instruct the operator to add the row via a separate MR through `/mr` before re-running (see the Feature-catalog fidelity hard rule below).

### Hard rules — the four design constraints on top of `scaffold`'s hard rules

**All `scaffold` hard rules still apply** — including the locale/direction/calendar/digit-rule extract from the design system, the spec-filename `<project-slug>` prefix, the brand-mark byte-verbatim rule, the Feature-catalog fidelity rule (which now binds every UI element the design ships, not just the route list), no `body_html`, no `Co-Authored-By:`, no derived-artifact refs, no money surfaces unless the design system sanctions them. On top of those, `design` adds four non-negotiable design constraints:

**0. Feature-catalog fidelity — non-negotiable, extended to every design element.**
- Every UI element, page section, block, widget, affordance, form field, table column, filter chip, action, interaction, dashboard tile, admin surface, and role-scoped visibility rule that lands in the HTML / CSS / JS MUST map to one or more `[x]` rows in `product/docs/features/v<N>/all-features.md`. The rule is not "the route is backed by an `[x]`"; it is "every element inside the route is backed by an `[x]`".
- Three cases exhaust every candidate element:
  1. **`[x]` row exists** ⇒ the element enters the design; the touched §4.N sub-section names the satisfied `[x]` row(s) in its «`[x]` features satisfied» line.
  2. **`[ ]` row exists** ⇒ the element is omitted AND named in §5 «Deliberately out of scope» — explicit omission beats silent omission.
  3. **No row exists (element is not in the catalog)** ⇒ **refuse the run**. Stop, name the missing element concretely (`the newsroom page`, `the DLQ panel on webhooks`, `the environment tag in the admin footer`, `the sparkline on custom-events`, `role-scoped hiding of the webhooks sidebar entry`, …), and instruct the operator to add the feature to `all-features.md` first via a separate MR through `/mr`, then re-run this design pass. The design layer NEVER invents scope, never anticipates future features, never adds an admin action / dashboard tile / form field / block variant / analytics viz / role-visibility rule the catalog does not sanction — however small or "obvious" the addition looks. If the product genuinely needs the element, adding the feature to the catalog is the first step; drawing it in the mockup is the last step.
- Read direction is one-way: the catalog drives the design, never the reverse. A design run that surfaces a gap should stop and hand the gap back to product; it must not fill the gap by inventing a feature inline.

**1. Design-system-only binding — nothing invented.**
- Every color = a design-system swatch or theme-bound surface token. No `#RRGGBB` literal, no `rgb(…)`, no `bg-[#…]`.
- Every spacing = a design-system spacing token. No arbitrary `padding: 13px`.
- Every radius, shadow, typography size, line-height = a design-system token. No arbitrary values.
- Every class name that appears in the HTML output = a class documented in the design-system spec. No invented BEM blocks, no ad-hoc utility classes.
- If the design requires a shape the design system does not document, the run stops and asks — either extend the design system first (through its own authoring path) or defer the shape. Never invent inline.

**2. Responsive across three tiers — mobile / tablet / desktop.**
- Read the three breakpoint values from the design-system spec at Step 1 (they are tokens — do not hardcode `640px` / `1024px` in this skill's body).
- Every layout that changes across viewports declares its behavior at all three tiers explicitly. A layout that only renders on desktop is refused.
- Common patterns per tier:
  - **Mobile** (base — no `@media`): stacked, single-column, hamburger drawer, tap targets ≥ 44 px, chip strips horizontally scrollable, TOC as `<details>` accordion.
  - **Tablet** (`@media (min-width: <tablet-token>)`): two-column where useful, some rails inline, condensed chrome.
  - **Desktop** (`@media (min-width: <desktop-token>)`): full multi-column, sticky rails, TOC as sidebar, full nav visible.
- The generated CSS carries a comment header naming the three token values in effect (documentation for the reader, not a token invention).

**3. Mobile-first CSS cascade — no exceptions.**
- Base styles (outside any `@media`) target the mobile tier.
- Larger tiers add rules via `@media (min-width: <token>)`.
- **`max-width` media queries are refused.** Desktop-first cascades are refused. If a rule needs to fire only below tablet, restructure so the tablet-and-up `@media` block carries the override instead.
- Container queries are acceptable where the design system documents them; still mobile-first inside the container.

**CSS logical properties throughout** — every layout rule uses CSS logical properties (`margin-inline-start`, `padding-block`, `inset-inline`, `border-inline-end`), never physical (`margin-left`, `padding-bottom`, `left`, `border-right`). Grid + flex sizing crosses tiers via logical properties automatically. This applies to every project regardless of direction — an LTR project still emits logical properties (they collapse to the correct physical direction automatically).

**Locale-conditional operations.** The following steps are applied **only** when the design-system extract at Step 1 declares the matching mode; otherwise they are silently skipped and the skip is logged:

- **Persian / Arabic script normalization** (ZWNJ preservation, ی/ي canonicalization, ک/ك canonicalization, diacritic fold): only when `LOCALE_MODE ∈ {farsi-only, bilingual}`.
- **Jalali date rendering on human copy**: only when `CALENDAR=jalali`. Machine surfaces (`<time datetime>`, JSON-LD, sitemap, RSS) always emit ISO-8601 Gregorian ASCII regardless of `CALENDAR` — the boundary rule is universal.
- **Persian digits on human copy, ASCII on machine feeds**: only when `DIGITS=persian-human-ascii-machine`. Latin-only projects use ASCII everywhere.
- **RTL-specific letter-spacing quarantine + script-specific wordmark spacing** from the design system's script-specific rules section: only when `DIRECTION=rtl`.

### Companion-spec update contract — every design change is logged

Every design change touches `<project-slug>-<area>.md` in two places:

**(a) The touched sub-section is rewritten.**
- `page:<route>` → the §4.N sub-section for that route is rewritten (Purpose + Sections + `[x]` features satisfied). Preserve the `[x]` features line unless the feature set actually changed.
- `pages:<list>` → the §4.N sub-section for **each** listed route is rewritten (same rewrite contract as `page:<route>` applied per entry). Sub-sections for routes **not** in the list are preserved verbatim — never touched, never reshuffled.
- `all` → every §4.N is rewritten.
- Whenever the run introduces or changes a **shared area rule** (chrome, breadcrumb reorder, hero gradient, theme wiring, shared class name) — regardless of scope being `page:<route>`, `pages:<list>`, or `all` — **§3 Cross-page conventions is also rewritten** to reflect the new rule (shared chrome table + breadcrumb rule + hero-gradient rule + theme persistence rule). Purely page-local changes leave §3 untouched.

Sub-sections **not** in scope for the run are preserved verbatim — never reshuffled, never touched.

**(b) A one-line entry is appended to `## 6. Design changelog`.**
- §6 is seeded by `scaffold` on the first bootstrap of the area (canonical section grammar) — `design` appends to the existing header + prose. If §6 is somehow absent (an old spec written before the section became canonical), recreate it before appending: header + prose stanza + the new entry.
- Section is append-only. Never rewrite historical entries.
- Line format: `- <YYYY-MM-DD> — <scope> — <one-sentence change summary>`
  - `<YYYY-MM-DD>` = current session date (ISO-8601, ASCII digits — this is a machine-consumed audit line, not a human-surface date; the boundary rule applies universally).
  - `<scope>` = the `<scope>` arg the run received, verbatim (`page:<route>` | `pages:<route1>,<route2>[,…]` | `all`) — the log preserves the exact surface set for auditability.
  - `<one-sentence change summary>` = imperative, past tense, concrete. Not "Refined the design"; instead "Replaced the article-detail TOC from sidebar-only to `<details>` accordion below the tablet breakpoint."
- Multiple changes in one run → multiple lines, one per meaningful change (not one per file).
- `## 7. Source of truth & drift` is **not** rewritten by `design` runs. It is canonical prose seeded by `scaffold` and stays verbatim unless a later scaffold migration touches it.

### Step 1 — read every binding input

Everything `scaffold` reads (fixed set + companions + auth-gated prompt for auth-gated areas). Same order, same rules.

**Plus the target area's write targets + entry page + shared assets + companion spec, regardless of `<scope>`.** Other sibling flat pages and bucket pages are **not** auto-read. Cross-sibling composition survives across the area through three sources already in the read pass: the companion spec MD (§3 shared conventions + §4.N per-page composition), `<area>/index.html` as the area's concrete shell reference, and the design system as the token source. Reading every sibling would grow the read pass linearly with the area's page count without adding signal these three sources do not already carry.

Enumerate the directory first, then read the following in full:

- `<area>/<project-slug>-<area>.md` **in full, always** — the current companion spec; the design change will land in it (touched §4.N sub-section rewrite + §6 changelog append). Refuse the run if this file is missing (bootstrap first via `scaffold`).
- **Every write target** — `<area>/<route>.html` for `page:<route>`; each listed `<area>/<r>.html` for `pages:<list>`; every `<area>/**/*.html` (flat + bucketed) for `all`. Read as the baseline the new design overwrites.
- `<area>/index.html` in full **when present** — the area's concrete shell reference. Silent-skip + log if absent (reserved / bucket-heavy areas may not carry an entry page). A no-op when `index` is already among the write targets above; the file is read once.
- `<area>/assets/pages.css` in full.
- `<area>/assets/pages.js` in full.
- `<area>/assets/logos/*.svg` — enumerate; the brand mark stays verbatim.

**Plus, the three code-writing sources `scaffold` does not read** (needed because `design` writes real code, not just skeleton shells — without these the skill would hallucinate composition patterns instead of following what already ships):

- **For every sibling included via `companions=` — `<sibling>/assets/pages.css` + `<sibling>/assets/pages.js` in full.** Sibling assets follow the same gate as sibling MD / HTML: a sibling only enters the read set when its `uiux:<sibling>` directive is present in `companions=<spec>` (or was picked by the auth-gated prompt). If no sibling was requested, no sibling assets are read — the target `<area>`'s own `assets/pages.css` + `pages.js` (read above) are the only baseline. When a sibling *is* included, its assets are the reference implementation of area-level shared composition — how tokens are re-declared or imported, how the pre-paint theme init is wired, how the mobile drawer is opened, how the breakpoint queries are actually written. Silent-skip a requested sibling that has no `assets/pages.css` or `pages.js` yet (workspace-bootstrap state); log the skip.
- **`business/docs/brand/brand.html` in full** (if present). Brand rules the SVGs alone do not carry — logo clear-space, palette do / don't, typography scale, script-specific wordmark spacing, contrast rules. Without these the skill can misuse the mark (wrong margin, wrong background, wrong pairing). Silent-skip if absent; log the skip.
- **`product/docs/uiux/<version>/design-system/` enumerated in full — every file under the dir, not just the MD + HTML twin.** Read whichever of these are present: `design-system.css` (token exports as CSS custom properties — if this file exists, `<area>/assets/pages.css` **imports** it rather than re-declaring tokens), `design-system.js` (shared behaviors), `fonts/` (self-hosted font files — the `@font-face` `src:` paths in `pages.css` must point at these exact filenames; drift produces broken fonts in production), `icons/` (SVG icon set to compose against, never re-invent). Enumerate every entry, read every text file in full, note every binary asset by path. Silent-skip entries that do not exist yet; log the skip.

**Plus, pinned from the design-system spec at Step 1:**
- The three responsive breakpoint tokens (mobile / tablet / desktop pixel values). Named + pinned before any `@media` rule is composed. If the design system does not declare all three → refuse the run (constraint 2 unmet).

Every read completes before Step 2. No composition until every input is read.

### Step 2 — compose the design plan

For each surface in scope (`page:<route>` = one page; `pages:<list>` = each listed page, one plan per entry; `all` = every page). Shared `assets/pages.css` + `assets/pages.js` are updated alongside the same run when a new area-level rule or interaction is genuinely needed by the page(s) being designed — never as a separate pass, never as a side effect when nothing is actually needed:

1. **Enumerate the components** the design will use — every one traceable back to the design-system spec. If any is missing → stop and surface the gap.
2. **Compose the mobile-tier layout first** — the base state, no `@media`.
3. **Compose the tablet-tier additions** — what changes at `@media (min-width: <tablet-token>)`.
4. **Compose the desktop-tier additions** — what changes at `@media (min-width: <desktop-token>)`.
5. **Compose the interaction layer** for the JS surface — theme init pre-paint, drawer wiring, breadcrumb reorder, focus trap on modal / drawer, keyboard nav. Vanilla only.
6. **Draft the changelog line** — one sentence per meaningful change.

Plan complete before Step 3.

### Step 3 — write

- Write only the files in scope. `page:<route>` writes one HTML file; `pages:<list>` writes exactly N HTML files (one per listed route, flat + bucketed mixed); `all` rewrites every HTML file. In every scope, `assets/pages.css` / `pages.js` are updated inline **only** if a shared rule was genuinely required and no shared rule already covered the case — never as a side effect.
- Update the touched §4.N sub-section(s) of `<project-slug>-<area>.md` — one for `page:<route>`, N for `pages:<list>` (one per listed route), every §4.N for `all`. Additionally rewrite §3 Cross-page conventions **only** when a shared area rule (chrome, breadcrumb, hero gradient, theme wiring, shared class) was actually introduced or changed by this run.
- Append one line per meaningful change to `## 6. Design changelog` (create the section if it does not exist). Multiple lines allowed within one run; the `<scope>` field on every line is the arg received verbatim (`pages:index,about,contact` stays as-is — never collapsed to `all`, never expanded to per-route lines unless the changes themselves are per-route).
- **Do not touch out-of-scope files.** A `page:articles` run never modifies `article-detail.html`. A `pages:articles,article-detail` run touches exactly those two files + their two §4.N sub-sections; every other file + sub-section stays byte-verbatim. Untouched surfaces are preserved verbatim.

### What it writes — full inventory

- Touched `<area>/<route>.html` file(s) — one for `page:<route>`, N for `pages:<list>` (one per listed route, flat + bucketed mixed), all for `all`.
- `<area>/assets/pages.css` — if the run introduced a shared rule needed at the area level; unchanged otherwise.
- `<area>/assets/pages.js` — if the run introduced a shared interaction; unchanged otherwise.
- `<area>/<project-slug>-<area>.md` — the touched sub-section(s) (one §4.N for `page:<route>`, N §4.N for `pages:<list>`, every §4.N for `all`) + §3 Cross-page conventions when a shared rule changed + one appended line per meaningful change under §6.

Nothing outside `product/docs/uiux/<version>/<area>/` is written. No stage, no commit, no push.

## audit

Reconcile one existing UI/UX area under `product/docs/uiux/<version>/<area>/` against the single feature catalog at `product/docs/features/v<N>/all-features.md`. **The catalog is the sole authority.** Every route, page section, block, widget, form field, table column, filter chip, action, interaction, dashboard tile, admin surface, and role-scoped visibility rule the design ships MUST map to one or more `[x]` rows. Anything present in the design but not backed by an `[x]` row is an **offender** — the design layer never invents scope, so the offender was either drawn against a `[ ]` deferred row (should have been in §5 «Deliberately out of scope», not in the markup) or against no row at all (a feature never sanctioned by the catalog). Both cases are removals; the difference is which §5 rationale the prune records.

Sibling of `scaffold` and `design`. Where `scaffold` bootstraps and `design` composes forward from the catalog to the markup, `audit` is the reverse pass — it walks the current on-disk area and forces it back into alignment with the current `[x]` catalog. **`audit` never invents features to justify existing design; the catalog wins every conflict.** If a shipped element is not backed by an `[x]` row, the fix path is «add the `[x]` row via `/mr`, re-run audit», never «keep the element because the design already exists».

### Argument

`<area>::<mode>` where:

| Slot | Required | Shape |
|---|---|---|
| `<area>` | yes | Kebab-case existing area under `product/docs/uiux/<version>/`. Target dir MUST exist — use `scaffold` to bootstrap first. Cannot equal `design-system` (reserved), `scaffold`, `design`, or `audit`. **No `all` sentinel** — audit runs against one area at a time so removals stay reviewable; loop the command per area for a workspace-wide sweep, opening one MR per area. |
| `<mode>` | yes | `report` \| `prune`. `report` — read-only enumeration + cross-area sweep + structured report; no files touched. `prune` — apply the removals, sweep orphan CSS + JS, rewrite the spec, append the changelog, verify responsive integrity. Never defaults; missing → stop and ask. |

**`audit` does NOT accept `companions=<spec>`.** The reconciliation reads a fixed superset that includes every sibling area's spec MD unconditionally for cross-area link integrity. Passing `companions=` is refused with the offending slot named.

### Refusal conditions

- `<area>` missing → stop and ask.
- `<area>` doesn't match `^[a-z][a-z0-9-]*$` → refuse with the offending value named.
- `<area>` equals `design-system` / `scaffold` / `design` / `audit` → refuse (reserved / sub-op collision).
- `product/docs/uiux/<version>/<area>/` does not exist → refuse (bootstrap first via `scaffold`).
- `<area>/<project-slug>-<area>.md` does not exist → refuse (bootstrap first via `scaffold`; the spec is the audit's source of truth for §1 sitemap ownership and every §4.N element inventory).
- `<mode>` missing → stop and ask `report` | `prune`.
- `<mode>` not one of `report` | `prune` → refuse with the offending value named.
- `product/docs/features/v<N>/all-features.md` missing → refuse (nothing to reconcile against; without the catalog every element is an offender, which is not a useful report).
- `product/docs/uiux/<version>/design-system/*.md` missing → refuse. Without the design-system component + class inventory, the audit would misidentify legitimate atoms (`.article-card`, `.cta-band`, `.hero-grad`, `.breadcrumb`, `.chip`, `.tile`, …) as un-catalogued features and prune them.
- `companions=<spec>` supplied → refuse with the offending slot named. Audit's read set is fixed; siblings are always read.
- `<mode>` is `prune` and the workspace has uncommitted changes touching `product/docs/uiux/<version>/<area>/` → refuse. Prune is destructive; a dirty tree conflates user edits with tool removals. Stash or commit first (report mode is safe on a dirty tree).

### Hard rules

- **Read first, decide second, write last.** No file is deleted or modified until the full read pass completes, the offender set is enumerated, and the removal plan is composed. `report` stops after enumeration; `prune` proceeds to writes.
- **The `[x]` catalog is the sole authority.** No inference from adjacent areas, no assumption that «this element is obviously useful», no grandfathering of existing design. The catalog drives the design, never the reverse.
- **Design-system atoms are never offenders.** Every class documented in the design-system spec (component classes, chrome slot classes, chip / card / tile / breadcrumb / band classes, etc.), every token (color / spacing / radius / typography / motion / elevation), and every icon under `design-system/icons/` is pre-approved. The audit only checks whether a *feature composed of these atoms* is catalogued, never the atoms themselves.
- **The offender granularity is the feature, not the DOM node.** A single `[x]` row can back many DOM nodes (a card grid backing «popular posts» is one `[x]`, N cards). Removing a feature removes every DOM node that only exists to serve it — not the shared container the feature happens to sit inside if the container serves other kept features.
- **Responsive integrity is preserved across three tiers.** After every element removal, the parent flex / grid parent must still render coherently at mobile, tablet, and desktop. If removing an element leaves an odd child count that breaks a two-column grid at the tablet tier, the audit either adjusts the `grid-template-columns` for the remaining count or flags the layout as needing a `design` follow-up (`manual` flag) — never leaves a visibly broken tier.
- **CSS + JS orphan sweep is mandatory in `prune` mode.** Every CSS rule whose selector list matches only removed elements is deleted; a selector shared with a kept element is preserved verbatim (mixed-selector rules have their selector list rewritten to drop only the removed ones). Every JS handler / event listener wired to a removed element is deleted; shared wiring is preserved. Never delete an `@media` block wholesale — walk its rules and drop only the orphaned ones.
- **Cross-area references are surfaced, never auto-repaired.** If a sibling area's HTML or spec MD links to a route this audit deletes, the run **reports the broken link** (`landing/index.html:47 references admin/removed-page.html`) but does NOT edit the sibling area. Cross-area repair is a separate MR against the sibling area's own `design` run — auto-editing here would smuggle changes past sibling-area review.
- **Mandatory system pages are never removed.** `<area>/system/404.html` + `<area>/system/500.html` ship by default with every scaffolded area regardless of catalog. The audit skips them at the route-level enumeration.
- **Every removal is logged.** `prune` mode appends one line per removal to `## 6. Design changelog` (scope `audit:prune`, ISO-8601 date, one-sentence «what and why»), moves every removed feature to §5 «Deliberately out of scope for v<N>» with a one-line rationale (`[ ]`-row offender → «deferred to v<N+1>+ per catalog»; no-catalog-row offender → «feature not in catalog» — the two allowed forms), and drops the row from §1 sitemap when a whole route is deleted.
- **Workspace hard rules apply.** No `Co-Authored-By:` on any resulting MR. No references to `CLAUDE.md` / `README.md`. The audit itself writes no MR — ship with `/mr open current` afterwards.

### Step 1 — read every binding input

**Fixed set — always read, never varies. No `companions=` slot; sibling reads are unconditional (needed for cross-area link integrity).**

1. **The single feature catalog**: `product/docs/features/v<N>/all-features.md` in **full** — every `[x]` row AND every `[ ]` row. Partition into three sets used at enumeration time:
   - **Allow-list** — every `[x]` row; anything backed by one of these is a legitimate design element and NOT an offender.
   - **Deferred-but-drawn set** — every `[ ]` row; if a `[ ]` row is drawn in the markup, the element is an offender and the §5 rationale is «deferred to v<N+1>+ per catalog».
   - **Absent set** — features referenced in the markup that have no row (neither `[x]` nor `[ ]`); the §5 rationale is «feature not in catalog» and the operator is instructed to add the row via `/mr` if the feature should exist (or accept the removal if it should not).
2. **The target area, in full**:
   - Enumerate `product/docs/uiux/<version>/<area>/` — every path recorded, including bucketed subfolders.
   - `<area>/<project-slug>-<area>.md` in full — the current claim about what the area ships. The audit checks (a) whether the on-disk markup matches the spec (drift within the area) and (b) whether the spec matches the catalog (drift between the area and the source of truth).
   - Every `<area>/**/*.html` in full — flat, bucketed, and `system/`. This is the actual markup being audited.
   - `<area>/assets/pages.css` in full — for the orphan-rule sweep at Step 5.
   - `<area>/assets/pages.js` in full — for the orphan-handler sweep at Step 5.
   - `<area>/assets/logos/*.svg` — enumerated only. Brand SVGs are asset drops, not features; audit never removes them.
3. **Design system, in full** (component + class + token inventory — the pre-approved atom set):
   - `product/docs/uiux/<version>/design-system/*.md` in full — every class name and token declaration.
   - `product/docs/uiux/<version>/design-system/*.html` in full — the rendered visual reference.
   - `product/docs/uiux/<version>/design-system/` enumerated — read `design-system.css` / `design-system.js` in full if present; enumerate `fonts/` + `icons/`.
4. **Every sibling area's spec MD, in full** (for cross-area link integrity — audit needs to know which sibling routes reference the area being audited, so it can flag broken links after prune): `product/docs/uiux/<version>/*/<project-slug>-*.md` for every `*` ≠ `<area>` ≠ `design-system`. Sibling HTMLs are **grep-scanned** (not read in full) at Step 3 to find hrefs pointing at `<area>/…` — the full read would grow the read pass linearly with the sibling count without adding signal a grep does not provide.
5. **Platform architecture**: `tech/docs/v<N>/project-architecture.md` in **full** — feature → service map + surfaces + auth posture. Used to resolve which features are *supposed* to render on `<area>` (vs. legitimately on a different area). A feature that is `[x]`-catalogued but for a different surface is NOT counted as backing `<area>`'s implementation — treat it the same as an absent row (the fix is either «move the design to the correct area» or «add the feature for `<area>`'s surface»).
6. **Workspace-root `CLAUDE.md`** if present — the workspace hard rules apply to any resulting MR. Silent-skip if absent.

Every read completes before Step 2. No enumeration until every input is read.

### Step 2 — enumerate the five offender classes

Walk the read set and classify:

1. **Route-level offenders** — an entire HTML file whose backing feature has no `[x]` row on `<area>`'s surface (either `[ ]` deferred or absent from the catalog for this surface). The whole file is a removal candidate. The §1 sitemap row and the corresponding §4.N sub-section go with it. `<area>/system/404.html` + `500.html` are excluded from this class unconditionally.
2. **Element-level offenders** — a section, block, widget, form field, table column, filter chip, action button, dashboard tile, admin surface, or role-scoped visibility rule inside a kept HTML file whose backing feature has no `[x]` row on `<area>`'s surface. The specific element is a removal candidate; the containing file survives. The §4.N sub-section's element inventory is rewritten.
3. **Orphan CSS rules** — rules in `<area>/assets/pages.css` whose selector list matches only removed elements. Two shapes:
   - **Pure orphan** — every selector in the list matches only removed elements → delete the whole rule.
   - **Mixed** — some selectors match kept elements, some match removed ones → rewrite the selector list to drop only the removed selectors; keep the rule.
4. **Orphan JS handlers** — event listeners, DOM queries, and initialization code in `<area>/assets/pages.js` that only reference removed elements. Handlers referenced by kept elements survive verbatim.
5. **Cross-area broken references** — after the route-level removal set is finalized, grep every sibling area's HTML + spec MD for hrefs pointing at removed `<area>/<route>.html` paths (both relative and absolute). Every hit is a **broken-link report** — surfaced in the audit output, never auto-edited in the sibling area.

Every offender carries:
- (a) the file + line where it lives,
- (b) the feature it was drawn against (or «no catalog row for this surface» / «feature not in catalog»),
- (c) the intended removal shape (whole file / element extract / selector edit / handler drop / cross-area flag),
- (d) the responsive-integrity flag: `safe` (no parent-layout risk), `reflow` (parent grid / flex needs an attribute adjustment, which prune performs automatically), or `manual` (removing it leaves a shape the audit cannot cleanly resolve — the element is left in place in `prune` mode and reported as needing a `design` follow-up).

### Step 3 — cross-area sweep

For every route-level offender scheduled for removal, grep the following for hrefs pointing at the removed path:

- Every `product/docs/uiux/<version>/<sibling>/**/*.html` (flat + bucketed + system) for every sibling area.
- Every `product/docs/uiux/<version>/<sibling>/<project-slug>-<sibling>.md`.

Both relative (`../admin/removed-page.html`) and absolute (`/admin/removed-page.html`) forms are matched. Every hit is recorded as a **broken-link report entry** with the sibling file path + line number + the exact href text. This list is emitted in the operator report; it is **never** used to auto-edit the sibling area.

### Step 4 — emit the report (both modes)

Emit a structured operator report grouped by offender class, in this order:

1. **Route-level offenders** — one line per file: `<area>/<path>.html — <backing feature> (<catalog status>) — <intended action>`.
2. **Element-level offenders** — one line per element: `<area>/<file>.html:<line> — <element description> — <backing feature> (<catalog status>) — <intended action> [<responsive flag>]`.
3. **Orphan CSS rules** — one line per rule: `<area>/assets/pages.css:<line> — <selector list> — <action: delete | rewrite to `<new selector list>`>`.
4. **Orphan JS handlers** — one line per handler: `<area>/assets/pages.js:<line> — <handler description> — <action: delete>`.
5. **Cross-area broken references** — one line per hit: `<sibling>/<file>:<line> — <href> — points at removed <area>/<route>.html`.
6. **Manual-flag summary** — every element flagged `manual` (`prune` leaves these in place; the operator queues a `design` follow-up).

`report` mode stops here. `prune` mode continues to Step 5.

### Step 5 — prune (apply the removals)

Executed in this deterministic order (resume-safe):

1. **Delete route-level offender HTML files.** Bucket directories that become empty after their last file is removed are also removed. `<area>/system/404.html` + `500.html` are never touched (mandatory system pages).
2. **Surgically remove element-level offenders from surviving HTML files.** Extract the offender DOM subtree, preserve surrounding structure, adjust the parent's layout attributes (`grid-template-columns` count, flex `justify-content`) only when required to keep the remaining children rendering cleanly at all three tiers. Elements flagged `manual` are left in place and appear in the manual-flag summary.
3. **Sweep `<area>/assets/pages.css`.** For every pure-orphan rule, delete the rule. For every mixed rule, rewrite the selector list to drop the removed selectors. Never delete an `@media` block wholesale — walk its inner rules and apply the same delete-or-rewrite logic per rule. Preserve every rule referenced by any kept element verbatim.
4. **Sweep `<area>/assets/pages.js`.** Remove event listeners, DOM queries, and initialization code that only touch removed elements. Preserve shared wiring (a `document.querySelectorAll('.chip')` handler binding to chips across the area is kept unless every `.chip` was removed).
5. **Rewrite `<area>/<project-slug>-<area>.md`.**
   - **§1 Sitemap and file map** — drop the row for every deleted route.
   - **§4.N Per-page composition** — drop the sub-section for every deleted route; rewrite the element inventory for every surviving file whose elements were surgically removed (drop the removed elements' bullets from the section list).
   - **§5 Deliberately out of scope for v<N>** — append one line per removed feature with the correct rationale (the only two allowed forms):
     - `- <feature description> — deferred to v<N+1>+ per catalog.` (for `[ ]`-row offenders)
     - `- <feature description> — feature not in catalog.` (for absent-row offenders)
   - **§3 Cross-page conventions** — rewritten **only** if a shared area rule (chrome slot, breadcrumb, hero gradient, shared class) died with a removed element. Purely local removals leave §3 untouched.
6. **Append §6 Design changelog.** One line per removal (route or element), format `- <YYYY-MM-DD> — audit:prune — removed <thing> (<catalog status>).` The date is the current session date, ISO-8601, ASCII digits (machine-consumed audit line — the boundary rule applies universally). One line per meaningful removal, not one per file.
7. **Verify responsive integrity.** For every surviving HTML file, re-check:
   - Every `@media (min-width: <tablet-token>)` and `@media (min-width: <desktop-token>)` block references only surviving selectors.
   - Every grid / flex parent whose child count changed still renders with a coherent tier layout (no dangling gap at desktop, no broken row at tablet, no wrapping regression at mobile).
   - No CSS custom property is defined but never consumed.

   Any regression at this step **halts the run** — restore the last-known-good state from the pre-run read (in-memory snapshot) and emit a failure report naming the offending file + rule + surviving markup shape. Never ship a broken tier.
8. **Emit the cross-area broken-link report.** The list from Step 3, ready for the operator to queue one `/uiux design <sibling>::page:<route>` MR per affected sibling area.

Nothing outside `product/docs/uiux/<version>/<area>/` is written. The audit does not touch other repos, does not stage, does not commit, does not push, does not edit any sibling area.

### What it writes — full inventory (prune mode)

- Zero or more deleted `<area>/<path>.html` files (route-level offenders; system pages never deleted).
- Zero or more deleted bucket directories under `<area>/` (only when the last file in the bucket was removed).
- Every surviving `<area>/<path>.html` file that had element-level offenders — rewritten with the offender subtrees extracted and parent layout attributes adjusted per Step 5.2.
- `<area>/assets/pages.css` — rewritten with orphan rules deleted and mixed rules' selector lists trimmed. Never deleted wholesale.
- `<area>/assets/pages.js` — rewritten with orphan handlers deleted. Never deleted wholesale.
- `<area>/<project-slug>-<area>.md` — rewritten per Step 5.5: §1 sitemap trimmed, §4.N sub-sections dropped / rewritten, §5 appended, §3 rewritten only when a shared rule died, §6 appended.

`report` mode writes nothing.

## After running

1. **Report mode**: read the structured report end to end. Every offender is either accepted (a `prune` follow-up is queued) or contested (the operator adds the missing `[x]` row via `/mr` against `product/docs/features/v<N>/all-features.md` and re-runs the audit — offenders drawn against the newly-added row disappear from the next report). Manual-flag elements need a `design` follow-up regardless of whether the operator agrees with the removal.
2. **Prune mode**: skim `<area>/<project-slug>-<area>.md` — verify §1 sitemap matches on-disk, §4.N sub-sections match the surviving markup, §5 names every removed feature with the correct rationale (one of the two allowed forms), and §6 changelog line per removal is accurate.
3. **Prune mode — visual check**: open every surviving HTML file at three viewport widths (mobile / tablet / desktop) using the design-system breakpoint tokens. Flip the theme toggle. Verify: no visible layout regression, no orphan whitespace where an element used to sit, no `@media` overrides referencing a removed selector. If `LOCALE_MODE ∈ {farsi-only, bilingual}`, additionally check Persian text still renders without letter-spacing bleed and ZWNJ is preserved. Keyboard nav still works.
4. **Prune mode — cross-area follow-up**: read the cross-area broken-link report and queue one MR per affected sibling area — the shape is `/uiux design <sibling>::page:<route>` from a separate worktree. Do NOT bundle sibling repairs into the audit MR; each sibling area gets its own review pass.
5. Run `/mr open current` — commit shape `docs(uiux): audit <area> prune` (report-only runs never produce an MR since no files change). The MR body's Test Plan lists the three-tier viewport check + the cross-area impact list.
6. On MR approval, squash-merge, `git pull --ff-only`, clean the worktree per `[[mr]]`.

## After authoring

1. Open every touched HTML file in a browser at three viewport widths — mobile, tablet, desktop (use the design-system breakpoint tokens as the resize targets). Flip the theme toggle. Verify: design-system tokens render, no FOUC, no horizontal scroll at any tier, keyboard nav works (Tab through the page, focus trap on drawer / modal). If `LOCALE_MODE ∈ {farsi-only, bilingual}`, additionally check Persian text renders without letter-spacing bleed and ZWNJ is preserved.
2. Skim `<project-slug>-<area>.md` — verify the touched §4.N sub-section(s) reflect the new composition, verify §3 Cross-page conventions was updated **if** a shared area rule changed (otherwise §3 stays verbatim), and the §6 changelog line accurately names what changed.
3. Run `/mr open current` — stages the explicit paths, writes a conventional commit (`docs(uiux): redesign <area> <scope>` — e.g. `docs(uiux): redesign dashboard page:articles` or `docs(uiux): redesign admin pages:index,about,auth/login`), pushes, opens the MR via `glab`.
4. On MR approval, squash-merge, `git pull --ff-only`, clean the worktree per `[[mr]]`.

For a whole-new area, run `scaffold <area>::bootstrap` first, then iterate on the design with `design <area>::<scope>`. Once the area is stable, run `audit <area>::report` periodically (after any batch of `[x]` catalog changes) and `audit <area>::prune` when the report surfaces offenders.

**Writes files only — never stages, commits, pushes, or opens an MR.** Ship with `/mr open current`.
