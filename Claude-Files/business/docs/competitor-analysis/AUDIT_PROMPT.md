# competitor-site audit instructions

> **This file is the constant.** It is intentionally project-agnostic — no
> product name, no positioning, no market-specific dimension names embedded.
> Every project-specific value is read at runtime from
> `product/docs/product.md` (the single source of truth). This file never
> changes per-project; only the spec itself changes, in its own MR before the
> next snapshot date.
>
> **Runtime context loading** — before any audit work, the calling command
> MUST read from `product/docs/product.md`:
> - **Product name** — §1 Overview → the `Name:` line.
> - **Positioning paragraph** — §9 Positioning paragraph (verbatim, no paraphrase).
> - **Segment slugs** — §6 Market context → `Segment slugs`.
> - **Local-market dimension** — §6 Market context → `Local-market dimension name`.
> - **Locale rules** — §6 Market context → `Locale rules`.
>
> If `product/docs/product.md` is missing, halt and tell the user to run
> `/product-init` first.
>
> Two entry modes:
> - **Directed** — run prompt names a `TARGET` directory and a `URL`. Skip §Discovery, jump to §Per-competitor audit.
> - **Discovery** — run prompt gives no `TARGET`/`URL`, only asks to "analyze competitors". Run §Discovery first, then loop the per-competitor audit over every discovered competitor.
>
> Audits are snapshot-dated. Write root is `{TARGET}/{YYYY-MM-DD}/` (UTC). All
> paths below are relative to that dated root.

## Context

You are auditing competitors for the product described in
`product/docs/product.md`. Every strategic decision (score, borrow, gap,
threat) must trace back to that file's §9 Positioning paragraph.

## Discovery mode (run when no TARGET/URL given)

Goal: turn the positioning paragraph into a concrete list of competitors,
grouped by segment, then audit each one. Do NOT ask the user which competitors
to audit — the discovery is the audit's first job.

### Step 1 — extract search anchors from the positioning paragraph

Pull these from `product/docs/product.md § 9` (do not invent):

- **Domain nouns** — what class of product (CMS, STT, mini-CRM, POS gateway, ...).
- **Buyer** — who buys.
- **Geography / language** — market boundary.
- **Wedge** — the one differentiator.
- **Anti-scope** — what the product is NOT (from §5 Non-features + implicit in positioning).

### Step 2 — sweep four channels

Assemble a candidate list from at least four sources. Do not stop at the first hit:

1. **Local direct** — same-geography players in the same domain. If the
   product is Iran-market, search Google/Zoomit/Digiato in Persian; scan
   Iranian VC portfolios (Sarava, Shezan, Nasr Ventures) and startup
   directories (Shabnam, Evand). Substitute the equivalent local sources for
   other geographies.
2. **Global reference** — 3–5 category leaders worldwide (WordPress /
   Contentful / OpenAI / Stripe-shaped names, not niche).
3. **Regional peers** — MENA / Turkey / SE Asia / LATAM analogues if
   geography is regional.
4. **Adjacent substitutes** — non-obvious tools the buyer might use instead
   (Notion for CMS, WhatsApp+spreadsheet for CRM, Google Docs for a
   collaborative editor).

Add every candidate you actually find. Do not pad the list, do not skip a
segment because it is "obvious."

### Step 3 — write the discovery output

Before auditing anyone, write:

```
competitor-analysis/{YYYY-MM-DD}-discovery.md
```

Frontmatter + one row per candidate:

| slug | segment | url | one-line why-it-matters | verdict |
|---|---|---|---|---|

`verdict` ∈ `audit` (worth full analysis) / `stub` (unreachable / parked /
dead — record as stub, no audit) / `skip` (out of scope, note the reason).

### Step 4 — loop the per-competitor audit

For every row with `verdict: audit`, run §Per-competitor audit with:

- `TARGET = competitor-analysis/<segment>/<slug>/`
- `URL = <url>`

Write each `analysis.md` before moving to the next.

### Sizing (default caps)

- Total corpus per snapshot: **10–30 competitors**. Under 10 means synthesis
  is thin; over 30 means the snapshot never ships.
- Per segment: minimum 3, target 5–8.
- If discovery exceeds 30, keep the top by relevance and move the rest to
  `verdict: skip (deferred to next snapshot)`.

---

## Per-competitor audit (run once per competitor)

You are auditing **one** competitor website.

## Scope

Audit the site's **capabilities** — what the site does and how it is built.
Do NOT summarize marketing copy, brand voice, case-study narratives, team
bios, or color / typography aesthetics unless they break RTL or accessibility.
We are cataloguing capabilities, not stories.

## Segments (from product.md § 6)

Group competitors by market posture, not by geography alone. The segment
slugs used for this project are defined in `product/docs/product.md § 6
Market context → Segment slugs`. Common shapes:

- `iranian-<domain>` — local direct competitors
- `regional-mena` — regional players in the same space
- `global-<domain>` — global reference players
- `<domain>-adjacent` — non-obvious substitutes worth studying

A per-competitor audit lives at
`competitor-analysis/<segment>/<slug>/<YYYY-MM-DD>/analysis.md`.

## Record format

For each dimension below, record four fields:

- **PRESENT** — what the site has (1 short line)
- **IMPLEMENTATION** — CMS, framework, pattern, vendor signals
- **EVIDENCE** — URL path, response header, page-source signal, observed behavior
- **SCORE** — 0 absent, 1 basic, 2 solid, 3 best-in-class

If a dimension can't be checked (geo-blocked page, requires login, tool
unavailable), record `SCORE: N/A` and note the reason in EVIDENCE. Do not
guess.

## Dimensions (28 total, max score 84)

Adapt this list to the domain. The 28 below are the default set for a
**comprehensive website / product-marketing** audit; for a pure-API-vendor
audit swap in `engine quality`, `latency`, `SDK coverage`, `webhook surface`,
etc. If any dimension is unchecked, use `SCORE: N/A` — max normalizes to
`3 × dimensions_checked`.

1. **Information architecture** — top-nav structure, service taxonomy
   (capability × industry axes), depth, mega-menu vs flat, footer sitemap.
2. **Internationalization** — locales offered, URL pattern (`/fa/`, `/en/`,
   subdomain), language-switch UX, hreflang, RTL handling, self-hosted
   Persian fonts vs Google Fonts.
3. **Lead generation** — contact forms, RFP/RFI intake with file upload, demo
   booking, calendar embed, live chat, WhatsApp / Bale / Eitaa / Rubika links,
   newsletter double-opt-in, gated content, assessment / ROI calculators.
4. **Trust signals** — certifications (ISO, افتا, نظام صنفی رایانه‌ای,
   شورای عالی انفورماتیک), client logos, awards, press, اینماد / ساماندهی,
   شناسه ملی + شماره ثبت + address visible, `security.txt`, vuln disclosure.
5. **Service / product presentation** — page depth per service, industry
   vertical landing pages, comparison tables, pricing transparency,
   SKU / plan structure.
6. **Resources & content surfaces** — blog, whitepapers, case-study index
   (treated as a feature, not the content), webinars, docs / KB, glossary, RSS.
7. **Search & discoverability** — on-site search, filters, Persian
   normalization (ی/ي, ک/ك, ZWNJ), autocomplete, schema.org coverage,
   sitemap, robots, canonical.
8. **Customer / client portal** — login, ticketing, status page, SLA
   dashboards, billing.
9. **Careers** — job board, filtering, application UX, ATS (Greenhouse,
   Lever, Jobinja, Jobvision), candidate experience.
10. **Accessibility** — skip links, alt-text patterns, keyboard nav, contrast,
    `lang` attrs, ARIA landmarks, focus rings.
11. **Performance** — Lighthouse LCP / TBT / CLS, CDN provider (Cloudflare,
    ArvanCloud, DerakCloud, Akamai, Fastly), image formats (WebP, AVIF),
    lazy loading, font-loading strategy.
12. **Security & privacy** — TLS version, HSTS, CSP, `securityheaders.com`
    grade, cookie banner, privacy policy, DPA, processing-locations statement.
13. **Technical stack** — CMS (WordPress, Strapi, Sanity, Directus, headless,
    custom), framework signals (Next, Nuxt, Astro, Remix, Drupal), analytics
    (GA4, PostHog, Matomo, Plausible), tag managers, A/B tools.
14. **Integrations & embeds** — booking widget, chat widget, video host
    (YouTube, Aparat, Vimeo), maps (Google, Neshan, Balad), payment
    (Shaparak PSP), social.
15. **Mobile experience** — responsive vs separate mobile, mobile menu
    pattern, mobile lead-gen, PWA / install prompt.
16. **Conversion mechanics** — primary CTAs per page, sticky CTAs,
    exit-intent, social-proof placement, urgency.
17. **SEO surface** — title / meta patterns, OG / Twitter cards, structured
    data, hreflang correctness, sitemap structure, internal linking.
18. **Local-market dimension (name from `product.md § 6`)** — market-specific
    signals for the product's geography. Example for Iran: Aparat embeds,
    Neshan / Balad maps, Shaparak PSP, Eitaa / Bale / Soroush / Rubika links,
    self-hosted Persian fonts, sanctions-safe asset origins (no blocked
    CDNs). The exact dimension name for the current project is defined in
    `product/docs/product.md § 6 Market context → Local-market dimension name`.
19. **Pricing & packaging** — plan matrix (free / pro / enterprise),
    per-seat vs usage-based vs one-time, annual discount, currency per
    locale, transparent pricing page vs contact-sales gate, free trial or
    freemium boundary, add-ons.
20. **Onboarding & signup** — signup friction (email-only, SSO, social),
    email verification flow, empty-state guidance, sample data / demo
    workspace, time-to-first-value, guided tour, checklists.
21. **Support surface** — help center depth, chatbot, ticketing, response
    SLA statement, status page, community forum, in-app help, contact
    channels.
22. **Community & social proof** — third-party review scores (G2, Capterra,
    Trustpilot), testimonials, case-study count, user forum / Discord /
    Slack, ambassador program, user-generated content.
23. **Legal & compliance** — GDPR / CCPA / local privacy banner, terms
    clarity, DPA download, subprocessor list, data-residency statement,
    SOC 2 / ISO 27001 / HIPAA claims with evidence, DMCA policy.
24. **Third-party ecosystem** — plugin / app marketplace, integrations
    directory, partner program, developer portal, referral / affiliate
    program.
25. **Lifecycle marketing** — email nurture sequences, transactional email
    quality, in-app messaging, push notifications, retention campaigns,
    win-back flows, referral loops.
26. **Documentation depth** (dev-facing / API surface) — API reference,
    quickstart, tutorials, code samples per language, changelog with
    versions, API status, SDK repos, OpenAPI / GraphQL schema published.
27. **Analytics & consent** — first-party vs third-party analytics, tag
    inventory, consent management (CMP), cookie categorization, pixel
    disclosure, opt-out UX.
28. **Content freshness** — last-updated stamps on articles / docs,
    editorial cadence signal (blog frequency), archive strategy, dead-page
    handling (redirects vs 404), broken-link count.

## Deliverables — write to disk, do NOT paste into chat

```
{TARGET}/{YYYY-MM-DD}/analysis.md
  Frontmatter: { site, url, category, audited_at, auditor }.
  One section per dimension with the 4-field record (PRESENT, IMPLEMENTATION,
    EVIDENCE, SCORE).
  "Top 5 features worth borrowing" — concrete, not generic.
  "Top 5 gaps" — features the audited site lacks that the product should have.
  "Overall maturity" — sum of scores / 84 (or / (3 × dimensions_checked) if
    any were N/A).

{TARGET}/{YYYY-MM-DD}/screenshots/
  Minimum 6 PNGs: hero, nav-open, a services page, careers, contact,
  mobile-hero.

{TARGET}/{YYYY-MM-DD}/raw/
  headers.txt      (curl -I)
  home.html        (first 200 KB)
  robots.txt
  sitemap.xml
  lighthouse.json  (if you can run it)
```

## Tooling notes

- Use `curl` / `wget` for headers, HTML, robots, sitemap.
- Use a headless browser (Playwright / Puppeteer) for screenshots and
  Lighthouse; if unavailable, note "screenshot tooling unavailable" and
  continue with text-only signals.
- If the site is geo-blocked or unreachable, write a stub `analysis.md`
  listing which dimensions could not be checked and stop. Stubs are counted
  toward the snapshot coverage but excluded from rankings.

## Verification bar

- Every `PRESENT` bullet needs an `EVIDENCE` line (URL, header, source
  snippet, or observed behavior). No unsourced claims.
- Every `IMPLEMENTATION` guess needs at least one signal (response header,
  script src, DOM class, cookie name). No inferences from marketing copy alone.
- If a bullet can't be evidenced, mark it 🔴 unverified and exclude it from
  downstream synthesis.
