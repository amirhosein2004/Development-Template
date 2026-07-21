---
title: "Competitor capability comparison & ranking — {{YYYY-MM-DD}}"
category: "competitor-analysis"
audited_at: "{{YYYY-MM-DD}}"
auditor: "{{PROJECT_NAME}} / <human or model>"
source: "competitor-analysis/*/{slug}/{{YYYY-MM-DD}}/analysis.md"
---

# Competitor capability comparison & ranking — {{YYYY-MM-DD}}

Cross-cuts the per-competitor audits captured under
`competitor-analysis/*/*/{{YYYY-MM-DD}}/` and ranks every competitor across the
28 capability dimensions defined in `AUDIT_PROMPT.md`. Scoring is the
per-dimension 0–3 scale from each audit's `analysis.md` (0 absent, 1 basic,
2 solid, 3 best-in-class). Maximum score **84**.

## Corpus

- **Audits in this snapshot:** {{N_TOTAL}}
- **Scored (used for rankings):** {{N_SCORED}}
- **Unreachable / stub (excluded from rankings):** {{N_STUB}}

## Unreachable / stub audits (excluded)

These audits could not be scored — the origin was unreachable, geo-blocked,
DNS-suspended, or pointed at a wrong / parked domain. They are listed here so
the snapshot is exhaustive, but they do **not** roll into category averages
or rankings.

| Slug | Category | Reason (from `analysis.md`) |
|---|---|---|
| `{{slug}}` | {{segment}} | {{reason}} |

## How to read the matrix

- Columns map to the 28 dimensions of `AUDIT_PROMPT.md`:
  **IA** Information architecture · **i18n** Internationalization · **Lead** Lead generation · **Trust** Trust signals · **Svc** Service / product presentation · **Cont** Resources & content surfaces · **Srch** Search & discoverability · **Port** Customer / client portal · **Care** Careers · **A11y** Accessibility · **Perf** Performance · **Sec** Security & privacy · **Stk** Technical stack · **Intg** Integrations & embeds · **Mob** Mobile experience · **Conv** Conversion mechanics · **SEO** SEO surface · **Local** {{LOCAL_MARKET_DIMENSION}} · **Price** Pricing & packaging · **Onb** Onboarding & signup · **Sup** Support surface · **Comm** Community & social proof · **Legal** Legal & compliance · **Eco** Third-party ecosystem · **Life** Lifecycle marketing · **Docs** Documentation depth · **Ana** Analytics & consent · **Fresh** Content freshness.
- Each cell is the 0–3 score from the source audit. **Σ** is the row total, **%** is `Σ / 84`. Ranks are dense (ties share a rank).
- 🥇 🥈 🥉 in per-dimension breakouts mark the top three for that column; ties in the top three all carry the medal.

## 1. Overall ranking (all categories combined)

Ordered by **Σ** desc, ties broken by slug (alphabetical).

| Rank | Competitor | Category | IA | i18n | Lead | Trust | Svc | Cont | Srch | Port | Care | A11y | Perf | Sec | Stk | Intg | Mob | Conv | SEO | Local | Price | Onb | Sup | Comm | Legal | Eco | Life | Docs | Ana | Fresh | Σ | % |
|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | `{{slug}}` | {{segment}} | 3 | 3 | 3 | 3 | 3 | 3 | 2 | 1 | 3 | 3 | 2 | 2 | 3 | 3 | 3 | 3 | 2 | 0 | 3 | 2 | 3 | 2 | 3 | 2 | 2 | 3 | 2 | 2 | **68** | 81 |

## 2. Category averages

Average Σ per segment, plus size of segment. Uses **scored** competitors only.

| Segment | Competitors scored | Average Σ | Average % |
|---|---:|---:|---:|
| `{{segment-a}}` | {{N}} | {{avg}} | {{pct}} |

## 3. Per-dimension top-3

For each dimension, the three highest-scoring competitors (medal ties share a place).

### IA — Information architecture
🥇 `{{slug}}` (3) · 🥈 `{{slug}}` (3) · 🥉 `{{slug}}` (2)

### i18n — Internationalization
🥇 `{{slug}}` (3) · 🥈 `{{slug}}` (3) · 🥉 `{{slug}}` (2)

### Lead — Lead generation
🥇 · 🥈 · 🥉

### Trust — Trust signals
🥇 · 🥈 · 🥉

### Svc — Service / product presentation
🥇 · 🥈 · 🥉

### Cont — Resources & content surfaces
🥇 · 🥈 · 🥉

### Srch — Search & discoverability
🥇 · 🥈 · 🥉

### Port — Customer / client portal
🥇 · 🥈 · 🥉

### Care — Careers
🥇 · 🥈 · 🥉

### A11y — Accessibility
🥇 · 🥈 · 🥉

### Perf — Performance
🥇 · 🥈 · 🥉

### Sec — Security & privacy
🥇 · 🥈 · 🥉

### Stk — Technical stack
🥇 · 🥈 · 🥉

### Intg — Integrations & embeds
🥇 · 🥈 · 🥉

### Mob — Mobile experience
🥇 · 🥈 · 🥉

### Conv — Conversion mechanics
🥇 · 🥈 · 🥉

### SEO — SEO surface
🥇 · 🥈 · 🥉

### Local — {{LOCAL_MARKET_DIMENSION}}
🥇 · 🥈 · 🥉

### Price — Pricing & packaging
🥇 · 🥈 · 🥉

### Onb — Onboarding & signup
🥇 · 🥈 · 🥉

### Sup — Support surface
🥇 · 🥈 · 🥉

### Comm — Community & social proof
🥇 · 🥈 · 🥉

### Legal — Legal & compliance
🥇 · 🥈 · 🥉

### Eco — Third-party ecosystem
🥇 · 🥈 · 🥉

### Life — Lifecycle marketing
🥇 · 🥈 · 🥉

### Docs — Documentation depth
🥇 · 🥈 · 🥉

### Ana — Analytics & consent
🥇 · 🥈 · 🥉

### Fresh — Content freshness
🥇 · 🥈 · 🥉

## 4. {{PROJECT_NAME}}'s position (self-assessment)

Score {{PROJECT_NAME}}'s current shipping product against the same 28
dimensions using the same 0–3 scale. Insert as an extra row in section 1 and
call out:

- **Dimensions we already dominate** (score 3, competitor top-3 ≤ 2).
- **Dimensions we're at parity** (our score matches segment average).
- **Dimensions where we're behind** (our score < top-3 median). Each becomes a
  candidate roadmap item — cross-reference to the feature catalog for the
  concrete features to build.

## 5. Snapshot delta (vs prior snapshot)

Populated on the second and later snapshots. For each competitor still in the
corpus, show `Σ_prev → Σ_now (Δ)` and highlight the three biggest movers up
and down. New entrants and drop-outs are listed separately.

| Competitor | Σ_prev ({{prev-date}}) | Σ_now ({{YYYY-MM-DD}}) | Δ |
|---|---:|---:|---:|
| `{{slug}}` | 34 | 38 | +4 |
