---
title: <Product> — <System name> design system
derived_from: <product>-design-system.html
companion_of: <path/to/brand-source>
scope_source: <path/to/features/vN/all-features.md>
informed_by: <path/to/competitor-analysis/>   # optional
version: 0.1.0                                 # SemVer — bump on token/API change
locale: <bcp47>                                # e.g. fa-IR, en-US
direction: <rtl|ltr>
audited_at: YYYY-MM-DD                         # ISO 8601
license: <SPDX-id>                             # e.g. CC-BY-4.0, MIT
---

# <Product> — <System name>

> The written companion to `<product>-design-system.html`. The HTML is the **visual reference** (open, toggle themes / direction). This file is the **canonical written spec** implementers consume.
>
> Inheritance chain — do not duplicate or contradict upstream:
> - `<brand source>` — palette, mark, lockups. **Inherit verbatim.**
> - `<features source>` — only `[x]` items in scope. Every component here serves one.

**Three foundational principles** (fill with product-specific one-liners — model after Material 3 / Polaris / Carbon single-sentence principles):

1. <principle 1>
2. <principle 2>
3. <principle 3>

**Locale / direction / typography / currency**
- Language: `<bcp47>` · Direction: `<rtl|ltr>` (CSS logical properties only; no `left`/`right`)
- Typography stack: `<text-family>` (body), `<mono-family>` (code/numerics)
- Currency (if applicable): `<unit>` (integer, tabular numerals)

---

## 0. Principles

Every design decision traces to a documented driver (competitor gap, brand voice, or accessibility standard). Use a table:

| Principle | Driver |
|---|---|
| <one-line rule> | <competitor gap / brand voice / WCAG clause> |

---

## 1. Brand essentials

| Field | Value |
|---|---|
| Brand name | `<native>` (canonical) · `<latin>` (technical/legal only) |
| Domains | `<canonical>` + mirrors (`301` → canonical) |
| Palette name | `<name>` |
| Locale posture | Monolingual / Bilingual (parity, not translation) |

**Naming rule:** `<native>` in all human copy; `<latin>` only in URLs, code, legal. No other transliteration.

### 1.1 Domain map (if multi-domain)

| Domain | Role | Behaviour |
|---|---|---|
| `<canonical>` | Primary | Real site. Set `<link rel="canonical">` on every page. |
| `<mirror>` | Mirror | `301` permanent redirect. |

---

## 2. Color

Inherited from `<brand source>` without change. Reference **theme tokens** (`--bg`, `--surface`, `--ink` …), never raw hex. Named swatches appear only where the theme map is defined.

### 2.1 Named brand swatches (constant across themes)

| Token | Hex | Role |
|---|---|---|
| `--brand-<name>` | `#RRGGBB` | <where it's used> |

### 2.2 Constant derivatives (constant across themes)

| Token | Value | Role |
|---|---|---|
| `--brand-<name>-hover` | `<hex \| color-mix()>` | Hover of primary. |

### 2.3 Theme-bound surfaces (per-theme mapping)

**Light**
| Token | Value | Role |
|---|---|---|
| `--bg` | `#…` | Page background. |
| `--surface` | `#…` | Card / panel surface. |
| `--surface-raised` | `#…` | Elevation 2+. |
| `--ink` | `#…` | Primary text (≥ 7:1 vs `--bg` — WCAG AAA). |
| `--ink-muted` | `#…` | Secondary text (≥ 4.5:1 — WCAG AA). |
| `--border` | `#…` | Hairline. |
| `--border-strong` | `#…` | Focused / active. |

**Dark** — mirror the same token names with dark-mode values. Contrast targets identical.

### 2.4 Functional feedback (system-only, not brand)

| Token | Light | Dark | Role |
|---|---|---|---|
| `--success` | `#…` | `#…` | Confirmations. |
| `--warning` | `#…` | `#…` | Reversible risk. |
| `--danger` | `#…` | `#…` | Destructive / error. |
| `--info` | `#…` | `#…` | Neutral notice. |

**Contrast rule:** body text ≥ 4.5:1 (WCAG 2.2 AA); large text ≥ 3:1; non-text UI ≥ 3:1 (SC 1.4.11). Focus indicator ≥ 3:1 vs adjacent (SC 2.4.11).

---

## 3. Typography

### 3.1 Scale (roles, not a pixel sweep)

Modular scale — e.g. Perfect Fourth (1.333) or Major Third (1.25). Assign to **roles**, not raw sizes.

| Role | Size | Line-height | Weight | Usage |
|---|---|---|---|---|
| `display` | `<clamp()>` | `1.1` | `700` | Hero headlines. |
| `h1` | `<rem>` | `1.2` | `700` | Page title. |
| `h2` | `<rem>` | `1.25` | `600` | Section. |
| `h3` | `<rem>` | `1.3` | `600` | Subsection. |
| `body` | `1rem` | `1.6` | `400` | Paragraph. |
| `body-sm` | `0.875rem` | `1.5` | `400` | Meta / helper. |
| `caption` | `0.75rem` | `1.4` | `500` | Micro-labels. |
| `code` | `0.9375rem` | `1.5` | `500` | Monospace body. |

### 3.2 Script-specific rules (fill per language)

- `<script>` normalization pipeline: ZWNJ, canonical letters (e.g. ی/ي, ک/ك), diacritic fold.
- Number system: `<Persian \| Arabic-Indic \| Latin>` on **human surfaces**; ASCII digits + ISO-8601 Gregorian on **machine surfaces** (JSON-LD, RSS, `<time datetime>`).
- Tabular numerals: `font-variant-numeric: tabular-nums;` on all numeric UI.

### 3.3 Financial / numeric display (if applicable)

- Currency: `<unit>` — integer only, thousand-separated by locale, tabular-nums, RTL isolation via `<bdi>`.

---

## 4. Spacing

### 4.1 Base scale (4pt grid)

| Token | Value | Note |
|---|---|---|
| `--space-0` | `0` | |
| `--space-1` | `0.25rem` | 4px |
| `--space-2` | `0.5rem`  | 8px |
| `--space-3` | `0.75rem` | 12px |
| `--space-4` | `1rem`    | 16px |
| `--space-5` | `1.5rem`  | 24px |
| `--space-6` | `2rem`    | 32px |
| `--space-7` | `2.5rem`  | 40px |
| `--space-8` | `3rem`    | 48px |
| `--space-9` | `4rem`    | 64px |
| `--space-10` | `6rem`   | 96px |

### 4.2 Rhythm tokens (cross-area invariants)

| Token | Value | Role |
|---|---|---|
| `--stack-tight` | `--space-2` | Between related lines. |
| `--stack-normal` | `--space-4` | Between paragraphs. |
| `--stack-loose` | `--space-6` | Between sections. |

### 4.3 Breakpoints (mobile-first)

| Token | Min-width | Tier |
|---|---|---|
| `--bp-sm` | `40em` (640px) | Handset landscape. |
| `--bp-md` | `48em` (768px) | Tablet. |
| `--bp-lg` | `64em` (1024px) | Laptop. |
| `--bp-xl` | `80em` (1280px) | Desktop. |

### 4.4 Container

- Content max-width: `<value>` (72ch for prose, up to 1440px for dashboards).
- Gutter: `--space-4` on `<sm`; `--space-6` from `md`.

---

## 5. Radii

### 5.1 Scale

| Token | Value | Role |
|---|---|---|
| `--radius-none` | `0` | Table cells. |
| `--radius-sm` | `4px` | Chips, inputs. |
| `--radius-md` | `8px` | Buttons, cards. |
| `--radius-lg` | `16px` | Modals, hero surfaces. |
| `--radius-pill` | `9999px` | Pills, avatars. |

### 5.2 Per-element binding (closed set)

| Element | Radius |
|---|---|
| Button | `--radius-md` |
| Input / textarea | `--radius-md` |
| Card | `--radius-lg` |
| Badge / pill | `--radius-pill` |
| Modal | `--radius-lg` |

---

## 6. Elevation

Material-style five-step scale — shadow + surface-tint pair. Dark theme reduces shadow opacity, raises surface luminance.

| Token | Role | Shadow (light) | Shadow (dark) |
|---|---|---|---|
| `--elev-0` | Flat | `none` | `none` |
| `--elev-1` | Card resting | `0 1px 2px rgb(0 0 0 / .06)` | `0 1px 2px rgb(0 0 0 / .4)` |
| `--elev-2` | Card hover | `0 2px 6px rgb(0 0 0 / .08)` | `0 2px 6px rgb(0 0 0 / .5)` |
| `--elev-3` | Popover | `0 8px 24px rgb(0 0 0 / .12)` | `0 8px 24px rgb(0 0 0 / .6)` |
| `--elev-4` | Modal | `0 16px 48px rgb(0 0 0 / .18)` | `0 16px 48px rgb(0 0 0 / .7)` |

---

## 7. Motion

### 7.1 Tokens

| Token | Value | Role |
|---|---|---|
| `--dur-instant` | `80ms`  | Micro-hover. |
| `--dur-fast`    | `160ms` | Buttons, chips. |
| `--dur-base`    | `240ms` | Cards, popovers. |
| `--dur-slow`    | `400ms` | Modals, page transitions. |
| `--ease-standard` | `cubic-bezier(.2, 0, 0, 1)` | Default. |
| `--ease-emphasized` | `cubic-bezier(.3, 0, 0, 1)` | Entering. |
| `--ease-exit` | `cubic-bezier(.4, 0, 1, 1)` | Leaving. |

### 7.2 Per-element mapping (closed set)

| Element | Duration | Easing |
|---|---|---|
| Button hover / press | `--dur-fast` | `--ease-standard` |
| Card hover | `--dur-base` | `--ease-standard` |
| Modal enter | `--dur-slow` | `--ease-emphasized` |
| Modal exit | `--dur-base` | `--ease-exit` |

### 7.3 Reduced motion

`@media (prefers-reduced-motion: reduce)` — replace transitions with opacity-only fades ≤ `--dur-fast`. No parallax, no auto-play, no continuous loops (except essential status indicators reduced to a single frame).

---

## 8. Logo

- **Assets:** `logo/light.svg`, `logo/dark.svg`, `logo/mono.svg`, `logo/motion.svg` (if any).
- **Safe area:** ≥ `<unit>` clear space around mark on all sides.
- **Minimum size:** `<px>` — below this, use icon-only variant.
- **Lockups:** primary, stacked, icon-only. Fixed proportions.
- **Misuse (each = automatic 🔴 in review):** recolor, skew, stretch, drop-shadow, gradient swap, background contrast fail, rotation.

---

## 9. Components

Every component:
- Cites the `[x]` feature it serves.
- Declares variants, sizes, states, disabled rule, focus-visible ring, ARIA pattern (WAI-ARIA APG).
- Ships a keyboard interaction spec.

### 9.1 Buttons (`.btn`)

- **Variants:** primary, secondary, tertiary/ghost, danger.
- **Sizes:** sm (`32px`), md (`40px`), lg (`48px`). Touch target ≥ `44×44` (WCAG 2.5.5).
- **States:** rest, hover, active, focus-visible, loading, disabled.
- **Disabled rule:** single, unified — `[disabled] { opacity: .5; cursor: not-allowed; pointer-events: none; }`. No color swap.
- **Focus ring:** `outline: 2px solid var(--focus); outline-offset: 2px;`. Never `outline:none` without a replacement.
- **ARIA:** native `<button>`; loading state pairs with `aria-busy="true"`.

### 9.2 Forms and fields

- Label above, associated by `for`/`id`. Never placeholder-as-label (WCAG 3.3.2).
- Error message linked via `aria-describedby`; role via `aria-invalid`.
- Required marked programmatically (`aria-required`) and visually.
- Fieldset + legend for grouped controls.

### 9.3 Badges, chips, pills

**Taxonomy split (closed set):**
- **Badge** — passive status of an object (`Draft`, `Approved`).
- **Chip** — filter / selection with dismiss.
- **Pill** — clickable navigational tag.

### 9.4 Alerts and banners

- Roles: `success`, `warning`, `danger`, `info`.
- Live regions: `role="alert"` (assertive) or `role="status"` (polite).
- Icon paired with text (never color-only signal — WCAG 1.4.1).

### 9.5 Tabs, accordion, breadcrumb, pagination

Follow WAI-ARIA APG patterns verbatim. Cite the pattern URL when implementing.

### 9.6 Cards

- Base card, raised card, glass card (if used — declare backdrop-filter fallback).
- Interactive cards wrap the entire hit area in one `<a>` or `<button>` (Fitts's law).

### 9.7 Navigation

- Sidenav (right in RTL, left in LTR — via logical properties).
- Topbar (with breadcrumb / search / theme toggle / avatar menu).
- Command palette (`⌘K` / `Ctrl+K`) — cite `kbd` styling.
- Skip-to-content link (WCAG 2.4.1).

### 9.8 Data display

- Stat card (KPI + delta indicator).
- Chart card (chart + legend + caption).
- Table (sticky header, sortable columns, empty state).

### 9.9 Iconography

- Grid: 24×24 default, 16 / 20 / 32 variants.
- Stroke: 1.5px (or 2px pair — pick one).
- Style: outline / filled — one system-wide default.
- RTL: direction-sensitive icons mirror via `transform: scaleX(-1)` under `[dir="rtl"]`.

### 9.10 Loading, empty, error states

Every data surface declares all three. Loading uses skeleton (never spinner alone for >200ms). Empty offers a next action. Error offers retry.

### 9.11 Microcopy — voice and format

- Voice: `<one-line>` (e.g. plainspoken, no jargon).
- Numbers: locale digits on human UI; ASCII in machine feeds.
- Dates: locale calendar on human UI; ISO 8601 in machine feeds.
- Sentence case for buttons and headings (unless brand dictates title case).

---

## 10. RTL / bidirectional rules

- CSS logical properties only: `margin-inline-start`, `padding-inline-end`, `inset-inline-start` — never `left` / `right`.
- Sidenav sits on the reading-start edge (right in RTL, left in LTR).
- Directional icons (arrows, chevrons, back / forward) mirror by direction.
- Numbers, code, URLs isolate via `<bdi>` or `unicode-bidi: isolate`.
- Machine feeds (JSON-LD, sitemap, RSS, `<time datetime>`) always use ASCII digits + Gregorian ISO 8601 dates, regardless of UI locale.

---

## 11. Accessibility (WCAG 2.2 AA baseline)

- **Contrast:** body ≥ 4.5:1; large ≥ 3:1; UI ≥ 3:1 (SC 1.4.11); focus ≥ 3:1 (SC 2.4.11).
- **Focus:** visible ring on every focusable; never suppress without replacement (SC 2.4.7 / 2.4.11).
- **Keyboard:** every action reachable + operable by keyboard; logical tab order (SC 2.1.1).
- **ARIA:** follow WAI-ARIA APG patterns. Never invent roles.
- **Motion:** respect `prefers-reduced-motion` (SC 2.3.3).
- **Contrast preference:** respect `prefers-contrast: more`.
- **Transparency preference:** respect `prefers-reduced-transparency`.
- **Target size:** ≥ 24×24 CSS pixels (SC 2.5.8), 44×44 recommended.
- **Language:** `<html lang>` set; per-block override for mixed content.
- **Skip link:** first focusable element on every page.
- **Form errors:** identified (SC 3.3.1), described (SC 3.3.3), programmatically linked.

---

## 12. Performance

- Fonts: `font-display: swap`; self-host — no third-party CDN fonts.
- `backdrop-filter`: pair with `@supports not (backdrop-filter: blur(1px))` fallback.
- Images: modern format first (AVIF / WebP), `<img loading="lazy">`, explicit `width`/`height` (CLS).
- Render priority: LCP element preloaded; non-critical CSS deferred.
- Cap animation to composited properties (`transform`, `opacity`).

---

## 13. Print

- Dedicated `@media print` — hide chrome, unwrap collapsibles, force black-on-white ink.
- Numeric surfaces (invoice, statement) use monospace + tabular-nums.

---

## 14. Region-specific delivery (optional)

Fill only if applicable — e.g. sanctions posture (self-hosted fonts, no Google CDN), calendar (Jalali as storage), captcha (Arcaptcha), PSP integration.

---

## 15. Full token reference

### 15.1 Shared tokens (theme-invariant)

```css
:root {
  /* space / radii / motion / type — see §4, §5, §7, §3 */
}
```

### 15.2 Light theme map

```css
:root, [data-theme="light"] {
  --bg: #…;
  --surface: #…;
  --ink: #…;
  /* … */
}
```

### 15.3 Dark theme map

```css
[data-theme="dark"] {
  --bg: #…;
  --surface: #…;
  --ink: #…;
  /* … */
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) { /* mirror the dark map */ }
}
```

---

## 16. Source of truth and drift

- `<product>-design-system.html` is the **visual** source of truth.
- This file is the **written** source of truth.
- Any disagreement between the two = automatic 🔴 in review. Fix the drift, do not paper over.
- Bump `version` (SemVer) on any token add / rename / removal or component API change.
- Update `audited_at` on every re-audit against the upstream brand or features source.
- Deprecations: mark the token/component `@deprecated` in a code comment, keep working for one minor version, remove in the next major.

---

## 17. Layout decisions (TEMPLATE DEFAULTS — REPLACE per product)

> ⚠️ **THIS ENTIRE SECTION IS PLACEHOLDER.**
> Every value below is a **template default** chosen to make the skeleton runnable. It is **not a recommendation** for your product. When authoring a real design system from this template:
> - Override every default with a value grounded in the product's brand, scope, and user research.
> - Keep the **structure** (the token names, the closed-set tables). Change the **values**.
> - Delete this warning block only after every row has been reviewed and consciously accepted or overridden.
> - Mark reviewed rows by removing the `⟨default⟩` tag next to the value.

The foundational tokens (§2–§7) don't answer layout questions like "how tall is the header" or "how many footer columns". This section pins the closed set so two teams building from the same tokens produce visually consistent surfaces. **Every row below must be re-decided per product.**

### 17.1 Page grid + content width

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| `--page-max` | `1200px` ⟨default⟩ | App shell max width. |
| `--content-max-prose` | `72ch` ⟨default⟩ | Article body — readable measure. |
| `--content-max-dash` | `1200px` ⟨default⟩ | Dashboard body — wide surfaces. |
| `--content-max-form` | `480px` ⟨default⟩ | Single-column form. |
| `--sidebar-w` | `280px` ⟨default⟩ | Fixed sidebar width. |
| Layout templates | `1fr` · `1fr 280px` · `280px 1fr` ⟨default⟩ | The closed set of shell templates. |

### 17.2 Card grid

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| `--gap-cards` | `--space-5` (24px) ⟨default⟩ | Gap between cards. |
| Columns — mobile (<640) | `1` ⟨default⟩ | |
| Columns — tablet (≥640) | `2` ⟨default⟩ | |
| Columns — desktop (≥1024) | `3` ⟨default⟩ | |
| Columns — wide (≥1280) | `4` ⟨default⟩ | Only for dense grids. |

### 17.3 Header / topbar

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| `--header-h` | `64px` ⟨default⟩ | Sticky topbar height. |
| Header padding-inline | `--space-4` ⟨default⟩ | |
| Nav item gap | `--space-4` ⟨default⟩ | |
| CTA position | End of nav ⟨default⟩ | |
| Scroll behavior | Sticky, `--elev-2` after 8px scroll, no shrink ⟨default⟩ | |
| Mobile nav | Hamburger → drawer from reading-start edge ⟨default⟩ | |
| Search | Icon in topbar → opens `⌘K` palette ⟨default⟩ | |
| Theme toggle | Icon-only in topbar, before avatar ⟨default⟩ | |

### 17.4 Footer

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| Columns — desktop | `4` ⟨default⟩ | |
| Columns — tablet | `2` ⟨default⟩ | |
| Columns — mobile | `1` (stacked) ⟨default⟩ | |
| Column order | Sitemap → Product → Company → Contact ⟨default⟩ | |
| `--footer-pad-y` | `--space-8` (48px) ⟨default⟩ | Footer padding block. |
| Footer background | `--surface` ⟨default⟩ | |
| Border-block-start | `1px solid var(--border)` ⟨default⟩ | |
| Copyright | Own row below columns ⟨default⟩ | |
| Trust seals (regional) | Own row above copyright, seal height `80px` ⟨default⟩ | Only if regional trust marks apply. |

### 17.5 Hero

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| `--hero-min-h` | `480px` desktop · `auto` mobile ⟨default⟩ | |
| Text alignment | `start` (reading-start edge) ⟨default⟩ | |
| Eyebrow position | Above heading ⟨default⟩ | |
| CTA stacking (mobile) | Vertical stack, primary first ⟨default⟩ | |
| Media | Illustration on end-edge desktop; hidden mobile ⟨default⟩ | |

### 17.6 Card internals

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| `--card-pad` | `--space-5` (24px) ⟨default⟩ | |
| Card radius | `--radius-lg` ⟨default⟩ | |
| Thumbnail ratio | `16 / 9` ⟨default⟩ | |
| Meta position | Below title, above body ⟨default⟩ | |
| Category label position | On thumbnail, top-inline-start ⟨default⟩ | |
| Hover translate | `translateY(-2px)` + `--elev-2` ⟨default⟩ | |
| Border | `1px solid var(--border)` ⟨default⟩ | |

### 17.7 Typography rhythm (vertical)

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| `--rhythm-h-to-p` | `--space-2` ⟨default⟩ | Heading → paragraph gap. |
| `--rhythm-p-to-p` | `--space-4` ⟨default⟩ | Paragraph → paragraph gap. |
| `--section-gap-y` | `--space-8` ⟨default⟩ | Section → section gap. |
| Eyebrow | Optional; `--fs-xs`, `--fw-medium`, `--ink-muted` ⟨default⟩ | |
| Display size | `clamp(2.5rem, 4vw + 1rem, 4rem)` ⟨default⟩ | |
| Body `text-align` | `start` (never `justify` — hurts readability) ⟨default⟩ | |

### 17.8 Button internals

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| Padding (md) | block `--space-2` · inline `--space-4` ⟨default⟩ | |
| Padding (sm) | block `--space-1` · inline `--space-3` ⟨default⟩ | |
| Padding (lg) | block `--space-3` · inline `--space-5` ⟨default⟩ | |
| `--btn-min-w` | `88px` ⟨default⟩ | Prevents single-word buttons from looking cramped. |
| Icon-text gap | `--space-2` ⟨default⟩ | |
| Hero button width | `auto` desktop · `100%` mobile ⟨default⟩ | |

### 17.9 Form internals

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| `--input-h` | `40px` ⟨default⟩ | |
| Input padding-inline | `--space-3` ⟨default⟩ | |
| Label position | Above input, all breakpoints ⟨default⟩ | |
| Form container width | `--content-max-form` (480px) ⟨default⟩ | |
| Field gap | `--space-4` ⟨default⟩ | |
| Error position | Below input, linked via `aria-describedby` ⟨default⟩ | |

### 17.10 Table

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| Row padding | block `--space-3` · inline `--space-4` ⟨default⟩ | |
| Sticky header | On ⟨default⟩ | |
| Row divider | `border-block-end: 1px solid var(--border)` ⟨default⟩ (no zebra) | |
| Row hover bg | `color-mix(in srgb, var(--ink) 4%, transparent)` ⟨default⟩ | |
| Bulk-action bar position | Above table (replaces header row when selection active) ⟨default⟩ | |

### 17.11 Media grid

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| Columns — mobile / tablet / desktop | `2 / 3 / 4` ⟨default⟩ | |
| Thumbnail ratio | `4 / 3` ⟨default⟩ | |
| Gap | `--space-3` ⟨default⟩ | |
| Focal-point indicator | Center dot, `--brand` fill ⟨default⟩ | |

### 17.12 Iconography

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| Stroke width | `1.5px` ⟨default⟩ | |
| Size scale | `16 / 20 / 24 / 32` ⟨default⟩ | |
| Vertical align with text | `middle` ⟨default⟩ | |
| Style | Outline (default) · Filled (for state indication) ⟨default⟩ | |

### 17.13 Empty / loading / error

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| Illustration position | Centered inline, above message ⟨default⟩ | |
| Message length | One short sentence + one supporting line ⟨default⟩ | |
| Empty CTA | Primary button, single action ⟨default⟩ | |
| Skeleton pattern | Shimmer (translateX gradient) ⟨default⟩ | |
| Loading threshold | Show spinner only if wait > 200ms; show skeleton immediately ⟨default⟩ | |

### 17.14 Microcopy voice (product-agnostic template defaults)

| Rule | ⟨default⟩ |
|---|---|
| Tone | Neutral, task-oriented (avoid slang and overly formal) ⟨default⟩ |
| Error format | "What went wrong + what to do next" (never blame the user) ⟨default⟩ |
| Placeholder format | Example format (e.g. `example@domain.com`) — never repeat the label ⟨default⟩ |
| Button copy | Verb + noun (`Save changes`), sentence case ⟨default⟩ |

### 17.15 Section chrome

| Token | ⟨default⟩ | Purpose |
|---|---|---|
| Section title alignment | `start` ⟨default⟩ | |
| Eyebrow | Optional ⟨default⟩ | |
| Section divider | Spacing only (no visible line) ⟨default⟩ | |

### 17.16 SEO markup

| Rule | ⟨default⟩ |
|---|---|
| `<link rel="canonical">` | First in `<head>` (after `<meta charset>` + `<meta viewport>`) ⟨default⟩ |
| OG image ratio | `1200 × 630` ⟨default⟩ |
| Twitter Card | `summary_large_image` ⟨default⟩ |
| JSON-LD placement | End of `<body>` (does not block render) ⟨default⟩ |
| Breadcrumb JSON-LD | Emitted on every non-home page ⟨default⟩ |
| Machine feeds | ASCII digits + ISO 8601 UTC — always ⟨default⟩ |

### 17.17 Motion mapping (closed set)

| Element | Duration | Easing | Transform |
|---|---|---|---|
| Button hover | `--dur-fast` | `--ease-standard` | none ⟨default⟩ |
| Button press | `--dur-instant` | `--ease-standard` | `translateY(1px)` ⟨default⟩ |
| Card hover | `--dur-base` | `--ease-standard` | `translateY(-2px)` ⟨default⟩ |
| Dropdown open | `--dur-base` | `--ease-emphasized` | opacity + `translateY(-4px→0)` ⟨default⟩ |
| Modal enter | `--dur-slow` | `--ease-emphasized` | opacity + `scale(.96→1)` ⟨default⟩ |
| Modal exit | `--dur-base` | `--ease-exit` | opacity ⟨default⟩ |
| Drawer | `--dur-slow` | `--ease-emphasized` | `translateX` from edge ⟨default⟩ |
| Nav / topbar | none | — | Never animates ⟨default⟩ |
| Stagger in lists | Off ⟨default⟩ | | |

### 17.18 Elevation mapping (closed set)

| Element | Elevation |
|---|---|
| Card resting | `--elev-1` ⟨default⟩ |
| Card hover | `--elev-2` ⟨default⟩ |
| Sticky topbar (scrolled) | `--elev-2` ⟨default⟩ |
| Dropdown | `--elev-3` ⟨default⟩ |
| Popover | `--elev-3` ⟨default⟩ |
| Drawer | `--elev-3` ⟨default⟩ |
| Modal | `--elev-4` ⟨default⟩ |
| Toast | `--elev-3` ⟨default⟩ |

### 17.19 Override checklist

When adapting this template for a product, tick each item after a conscious decision:

- [ ] Page grid (17.1)
- [ ] Card grid + columns per breakpoint (17.2)
- [ ] Header (17.3)
- [ ] Footer (17.4)
- [ ] Hero (17.5)
- [ ] Card internals (17.6)
- [ ] Typography rhythm (17.7)
- [ ] Button internals (17.8)
- [ ] Form internals (17.9)
- [ ] Table (17.10)
- [ ] Media grid (17.11) — delete if no media surface
- [ ] Iconography (17.12)
- [ ] Empty / loading / error (17.13)
- [ ] Microcopy voice (17.14)
- [ ] Section chrome (17.15)
- [ ] SEO markup (17.16)
- [ ] Motion mapping (17.17)
- [ ] Elevation mapping (17.18)

An untouched `⟨default⟩` tag anywhere in §17 = automatic 🔴 in review.

---

## Appendix — references

- **WCAG 2.2** — https://www.w3.org/TR/WCAG22/
- **WAI-ARIA Authoring Practices** — https://www.w3.org/WAI/ARIA/apg/
- **W3C Design Tokens Community Group** — https://www.w3.org/community/design-tokens/
- **Material Design 3** — token roles, elevation model.
- **Shopify Polaris** — component API discipline.
- **IBM Carbon** — motion + grid rigor.
- **Apple HIG / Google Material** — 4pt / 8pt grid, 44×44 touch target.
- **CSS Logical Properties (Level 1)** — https://www.w3.org/TR/css-logical-1/
