# Frontend — {{PROJECT_NAME}} (tech)

> **Documentation placement.** Cross-repo standard — referenced by every engineering repo (see [`documentation.md`](./documentation.md) §5).

Version: v1
Status: ratified.

Related: [`frontend-layout.md`](./frontend-layout.md) · [`coding.md`](./coding.md) Part 2 · [`git.md`](./git.md)

Canonical reference for the frontend side of {{PROJECT_NAME}}: the **repository split**, the **technology stack** for each repo, and the **{{#IF LOCALE_MODE=bilingual}}bilingual / RTL{{#ELSE IF LOCALE_MODE=farsi-only}}Persian-first / RTL{{#ELSE}}locale{{/IF}} rules** that constrain every visual surface.

---

## 1. Repositories

### 1.1 Decision

{{FE_REPO_LIST}}

All frontend repos sit **behind the single project nginx** (the only ingress for the platform — see [`../project-architecture/v1.md`](../project-architecture/v1.md)). There is no separate frontend edge. Every repo produces **static output** — no Node at the edge, no server logic in any of these repos.

### 1.2 Where does a change go?

| Change | Repo |
|---|---|
| Marketing copy, home page, landing forms UI | `frontend-landing` |
| Login / OTP page UI | see the repo notes in §1.1 |
| Authenticated product surfaces | the regular-user SPA |
| Admin screens (if a dedicated admin SPA ships) | the admin SPA |
| Shared design tokens / components | see note below |

**Shared code.** Every repo follows the same design system (`product/docs/uiux/v1/design-system/`). v1 keeps them independent — duplicate the few shared primitives rather than introduce a cross-repo package. Promote to a published package as a follow-up only if duplication becomes painful.

---

## 2. Stack

### 2.1 Decision — fixed for v1

- `frontend-landing` — **Astro 5** (islands) + TypeScript — `output: 'static'`, SSG with rebuild-on-publish.
- Each SPA — **Vite 6 + React 19** + TypeScript — static SPA (`vite build` → hashed assets).

> **Constraint:** no frontend repo contains **any server logic** — no API routes, no SSR, no Node runtime. Every frontend is a pure client that talks (through nginx) to the backend.

### 2.2 Cross-cutting picks — fixed for v1

| Concern | Pick |
|---|---|
| Language | **TypeScript (strict)** |
| Typed API client | **openapi-typescript** (generated from OpenAPI via `pnpm codegen`) |
| Styling | **Tailwind CSS** bound to design-system tokens (`product/docs/uiux/v1/design-system/`) |
{{#IF LOCALE_MODE=bilingual}}| Bilingual model | **path-prefixed URLs** — `/fa/...` and `/en/...`; `<html lang dir>` set at build time per route; user-facing strings centralised in `src/copy/fa/*.ts` and `src/copy/en/*.ts` |
{{/IF}}{{#IF LOCALE_MODE=farsi-only}}| Copy / language | **Farsi-only, no i18n.** `<html lang="fa" dir="rtl">`; user-facing strings in `src/copy/`. |
{{/IF}}| Fonts | **{{FONT_STACK}} self-hosted** — woff2 in-repo `public/fonts/`, loaded via local `@font-face` (no third-party font origin) |
{{#IF CALENDAR=jalali}}| Calendar | **date-fns-jalali** on human surfaces; `Intl.DateTimeFormat` only for machine feeds |
{{/IF}}{{#IF CALENDAR=dual}}| Calendar | **date-fns-jalali** on `/fa/`; `Intl.DateTimeFormat('en-US', …)` on `/en/` |
{{/IF}}{{#IF CALENDAR=gregorian}}| Calendar | **`Intl.DateTimeFormat`** everywhere |
{{/IF}}| Number formatting | **`Intl.NumberFormat('fa-IR')`** on Persian surfaces{{#IF LOCALE_MODE=bilingual}}; `en-US` on English{{/IF}} — Persian digits in human copy; ASCII digits in machine feeds; never auto-convert on render |
{{#IF BLOCK_EDITOR}}| Rich-text editor (SPA) | **{{BLOCK_EDITOR}}** — pinned in the SPA's `docs/v1/PRD-TDD.md`; serializes to / from the canonical JSON block tree per [`coding.md`](./coding.md) §12 |
{{/IF}}| Testing — unit | **Vitest** (+ **React Testing Library** for React surfaces) |
| Testing — E2E | **Playwright** |
| Package manager | **pnpm** |
| Linter / formatter | **ESLint + Prettier + `prettier-plugin-tailwindcss`** |
| CI | **GitLab CI/CD** — see [`ci-cd.md`](./ci-cd.md) |

Per-repo libraries (React Router, TanStack Query, RHF + Zod, shadcn/Radix, per-page media libraries, etc.) are pinned in each repo's own `docs/v1/PRD-TDD.md`, not here.

### 2.3 {{#IF LOCALE_MODE=bilingual}}Bilingual + RTL{{#ELSE IF LOCALE_MODE=farsi-only}}Persian-first / RTL{{#ELSE}}Localization{{/IF}}

{{#IF LOCALE_MODE=bilingual}}
- `dir="rtl"` on `<html>` for `/fa/*`; `dir="ltr"` for `/en/*`. Set at build time in Astro's layout `.astro`; set before mount in Vite/React's `main.tsx` (RTL must not flicker on first paint).
- Tailwind **logical properties** (`ms-*` / `me-*`, `ps-*` / `pe-*`, `start` / `end`) instead of physical `left` / `right`. Spacing mirrors automatically in RTL.
- **Path prefix on every route.** `/fa/about`, `/en/about`. No cookie-based locale switch, no auto-geo redirect. `hreflang` alternates on every page including `x-default`.
{{#IF CALENDAR=jalali}}- **Jalali** calendar via `date-fns-jalali` on `/fa/`; Gregorian via `Intl.DateTimeFormat('en-US', …)` on `/en/`.
{{/IF}}{{#IF CALENDAR=dual}}- **Jalali** dates on `/fa/`, **Gregorian** on `/en/`. Never round-trip a Jalali date through Gregorian.
{{/IF}}- **Persian numerals** (`۰۱۲۳۴۵۶۷۸۹`) in Persian copy; **Latin numerals** in English copy. Never auto-convert on render — the copy file already carries the right glyphs. Enforce via a lint rule that rejects Latin digits inside `src/copy/fa/*.ts`.
- Mono / code fragments stay LTR even inside RTL blocks: wrap in `<span dir="ltr" style="unicode-bidi: isolate">` or the equivalent Tailwind class.
{{/IF}}
{{#IF LOCALE_MODE=farsi-only}}
- `dir="rtl"` on `<html>`, `lang="fa"`.
- Tailwind **logical properties** (`ms-*` / `me-*`, `ps-*` / `pe-*`, `start` / `end`) instead of physical `left` / `right`.
{{#IF CALENDAR=jalali}}- **Jalali** calendar via `date-fns-jalali` on human surfaces; ISO-8601 / Gregorian on machine feeds (JSON-LD, sitemap, RSS, `<time datetime>`).
{{/IF}}- **Persian digits** on human surfaces via `Intl.NumberFormat('fa-IR')`; **ASCII digits** in machine feeds. Currency (where present) formatted as integer Toman.
{{/IF}}
{{#IF LOCALE_MODE=latin-only}}
- `dir="ltr"` on `<html>`, `lang="en"`. No RTL surface in v1.
{{/IF}}
- **Fonts** — {{FONT_STACK}}, self-hosted per §4. A Persian-numeral variant (`Vazirmatn-FaNum-*.woff2`) is available for digit-heavy Persian surfaces (statistics, dates, price lists) where the default weight's digits render as Latin.

### 2.4 Sanctions-safe self-hosting

- **Every repo builds to static output** served by the project nginx; no Node runtime at the edge.
- **No runtime requests to non-{{PROJECT_NAME}} servers.** Fonts embedded; no Google Fonts / no third-party analytics CDN / no remote map tiles / no remote icon CDN. If a dependency wants to fetch from outside the project, flag it.
{{#IF CAPTCHA_PROVIDER}}- **{{CAPTCHA_PROVIDER}}** on public forms — the client injects the challenge; the backend server-side verifies. Documented in the CSP allow-list.
{{/IF}}- **Images.** Landing uses Astro's built-in `<Image>` component (compiles at build time, zero runtime). SPAs use plain `<img>` against assets served by the backend through nginx passthrough; no image CDN.

---

## 3. PWA / TWA considerations

Status: **{{PWA_STANCE}}.**

If a future version introduces an installable-app surface, that repo will follow a PWA discipline documented at that time. Do not add `vite-plugin-pwa`, service worker registration, or `manifest.webmanifest` to any v1 frontend.

---

## 4. Assets & fonts

### 4.1 Fonts

{{FONT_STACK}} is self-hosted in each frontend repo's `public/fonts/`. Loaded via `@font-face` in `src/styles/fonts.css`:

```css
@font-face {
  font-family: "Vazirmatn";
  src: url("/fonts/Vazirmatn-Regular.woff2") format("woff2");
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
```

Preload the specific weights each page uses:

```html
<link rel="preload" href="/fonts/Vazirmatn-Regular.woff2" as="font" type="font/woff2" crossorigin>
```

Subsetting is done at repo-build time — the checked-in files may be full-glyph woff2, and the build step generates subsets and preloads the relevant subset per locale.

### 4.2 Images

- Public-served asset variants (backend-owned) are exposed through nginx passthrough. Frontends embed these URLs as `<img srcset>`.
- Static assets in each frontend's `public/` are served with content-hashed filenames and long `Cache-Control: max-age=31536000, immutable`.
- Landing uses Astro's `<Image>` for its own hero / logo images; SPAs use plain `<img>` because the SPA surface has no SEO benefit from image optimisation.

### 4.3 Icons

Inline SVGs, not an icon font, not a remote icon CDN. Each frontend's design system ships a small icon set as `.svg` components. Duplicate across repos in v1; consolidate to a shared package when the duplication becomes painful.

---

## 5. Where the design system lives

- **Brand tokens** (colour, type, spacing primitives, motion timing): `business/docs/brand/tokens.md`. Machine-readable; the source of every named value.
- **Design system implementation** (component library, page composition rules, RTL + accessibility discipline): `product/docs/uiux/v1/design-system/`.
- **Page mockups**: per-frontend, rendered from the shared design system. HTML mockups live under `product/docs/uiux/v1/`; UI assets in each frontend repo's `public/`. **Never reference a hosted-design-tool asset URL in code or markup.**
- **Frontend Tailwind config** in each repo (`tailwind.config.ts`) maps 1:1 to the design system — never redeclare a colour or spacing value outside the design-system tokens file.
