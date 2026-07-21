# business-docs template

A reusable, project-agnostic scaffold for the **business/docs** layer of any product workspace. Distilled from three shipping references (Heptapeak, Soradis, Avakav) into a single opinionated structure that answers three recurring prompts:

- **"Analyze this competitor."** → produces one dated `analysis.md` per site under a segment/slug folder, scored on 18 capability dimensions.
- **"Extract the features."** → produces one dated `feature-catalog.md` — union of every concrete feature observed across audits, categorized by the same 18 dimensions, each carrying a strategic-priority score.
- **"Extract the roles."** → produces one dated `roles.md` — every user role, persona, or audience the competitors explicitly model, cited back to the audits that surfaced it.

Everything is snapshot-dated (`YYYY-MM-DD`) so re-audits stack alongside prior runs instead of overwriting them.

## Layout

```
business/docs/
├── CLAUDE.md                                # Agent onboarding — hard rules, conditional reading, workflow
├── README.md                                # This file (human-facing overview)
├── AUDIT_PROMPT.md                          # THE CONSTANT — dimensions, scoring, deliverables
├── brand/                                   # SVG-only logo set + brand reference page (opt-in)
├── documents/                               # Canonical legal/founding documents (opt-in)
├── competitor-analysis/
│   ├── README.md                            # Folder guidance (segments, filename convention)
│   ├── <segment>/<slug>/<YYYY-MM-DD>/
│   │   ├── analysis.md                      # Per-competitor snapshot (18 dimensions × 4 fields + top-5 borrow/gap)
│   │   ├── screenshots/                     # Min 6 PNGs (hero, nav-open, service, careers, contact, mobile-hero)
│   │   └── raw/                             # headers.txt, home.html (first 200 KB), robots.txt, sitemap.xml, lighthouse.json
│   ├── <YYYY-MM-DD>-feature-catalog.md      # Union-of-features, categorized × segments, strategic score 1–10
│   ├── <YYYY-MM-DD>-comparison-and-ranking.md   # 18-dimension scored matrix + category averages + top-3 per dimension
│   └── <YYYY-MM-DD>-roles.md                # Every role competitors explicitly model, cited back to analyses
└── _templates/                              # Copy-and-fill starting points for each artifact
    ├── per-competitor-analysis.md
    ├── feature-catalog.md
    ├── comparison-and-ranking.md
    └── roles.md
```

## How to use

1. **Copy this whole tree** into a new business-docs repo (or a subfolder of your workspace).
2. **Fill in the placeholders** in `CLAUDE.md`, `README.md`, and `AUDIT_PROMPT.md`:
   - `{{PROJECT_NAME}}` — human-readable product name (e.g. `Heptapeak`, `Soradis`, `Avakav`).
   - `{{PROJECT_ID}}` — short slug used in paths (e.g. `heptapeak`, `soradis`, `avakav`).
   - `{{POSITIONING}}` — one-paragraph description of what the product is and who it's for. Drives everything downstream.
   - `{{SEGMENTS}}` — the market segments you group competitors under (e.g. Iranian IT services, global consultancies, cloud/hosting, headless CMS, SaaS publishing, ...). Rename or add rows in `AUDIT_PROMPT.md` to match.
   - `{{DIMENSIONS}}` — the 18 audit dimensions in `AUDIT_PROMPT.md` are a strong default for a website audit. Add / remove / reword to match the domain (e.g. Persian-STT vendors need `engine quality`, `latency`, `bilingual handling` instead of `Iran-specific web signals`).
   - `{{LOCALE_RULES}}` — if the product is Persian-first (RTL, Persian numerals, self-hosted fonts, sanctions-safe assets), keep those hard rules in `CLAUDE.md`. Otherwise strip them.
3. **First audit run:** name a `TARGET` (`competitor-analysis/<segment>/<slug>/`) and a `URL`, then follow `AUDIT_PROMPT.md`. Output lands in `TARGET/YYYY-MM-DD/`.
4. **Synthesis runs:** once you have ≥3 per-competitor `analysis.md` files under a snapshot date, run the feature-catalog / comparison / roles synthesizers. Each reads the same source set (`competitor-analysis/*/*/YYYY-MM-DD/analysis.md`) and writes one dated file at the top of `competitor-analysis/`.

## Snapshot dating (why every file is `YYYY-MM-DD`)

Re-audits **add** a new dated folder or a new dated file — they never overwrite the previous one. This preserves the diff over time (how a competitor evolved, how the market shifted). Never rename a past-dated file "for tidiness"; never edit a past-dated audit. If a factual correction is needed, add a new dated run and let the diff show the delta.

## What lives outside this repo

`business/docs/` owns **market intelligence, brand identity, and canonical legal/founding documents**. It does **not** own:

- **Product scope** — that belongs in `product/docs/features/v{N}/` (only `[x]` items ship).
- **Engineering documentation** — that belongs in `tech/docs/`.
- **Cross-repo standards** (git, branching, MR flow, review rubric) — those belong in the umbrella `docs/standards/`.

When you feel tempted to add a "roadmap" or "architecture" file here, stop and put it in the correct repo.
