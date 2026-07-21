---
title: "Competitor feature catalog — {{YYYY-MM-DD}}"
category: "competitor-analysis"
audited_at: "{{YYYY-MM-DD}}"
auditor: "{{PROJECT_NAME}} / <human or model>"
source: "competitor-analysis/*/{slug}/{{YYYY-MM-DD}}/analysis.md"
---

# Competitor feature catalog — {{YYYY-MM-DD}}

Categorized, bulletized union of every concrete `PRESENT` feature extracted
from the per-competitor `analysis.md` files captured under
`competitor-analysis/*/*/{{YYYY-MM-DD}}/`. Categories are the 28 capability
dimensions defined in `AUDIT_PROMPT.md`. Each feature carries a
**strategic-priority score (1–10)** representing how important it is for
**{{PROJECT_NAME}}** to ship, given its positioning, plus five tags: Kano
class, build effort, moat implication, paywall placement, and personas that
exercise the feature.

Within each dimension, bullets are grouped by segment. Each bullet ends with
`[slug]` naming the competitor(s) it came from. Unverified observations
(🔴 in the source audits) are excluded.

## Scoring axis (1–10, priority to {{PROJECT_NAME}})

- **10** — Wedge / load-bearing differentiator. {{PROJECT_NAME}} loses deals without it.
- **8–9** — Table-stakes for any credible player in this market, where most competitors are weak.
- **6–7** — Important; commonly expected; competitors generally have it.
- **4–5** — Useful, persona-specific, or commonly absent.
- **1–3** — Niche, edge-case, or non-overlapping persona.

**Scoring rules**

- Score reflects **strategic importance to {{PROJECT_NAME}}**, not how many competitors ship the feature. A feature every competitor has may still be a 4 if it is irrelevant to our positioning.
- Every score must trace back to the positioning paragraph in `product/docs/product.md § 9`. When positioning changes, re-score.
- Two people should assign the same score ±1. If a bullet is a coin-flip between two scores, prefer the lower — it forces the "why this is critical" conversation.

## Bullet format (enriched)

Each feature bullet uses this shape:

```
- {feature description} [slug] — priority: {1-10} | kano: {basic|perf|delighter} | effort: {S|M|L} | moat: {none|network|switching|scale} | paywall: {free|pro|enterprise|addon|N/A} | personas: [{persona-slug}, ...]
```

**Tag definitions:**

- **priority (1–10)** — strategic importance to {{PROJECT_NAME}} (see scoring axis above).
- **kano** — Kano-model classification of user reaction:
  - `basic` — expected. Absence causes complaint. Presence is invisible.
  - `perf` — performance / linear. More/better always improves satisfaction.
  - `delighter` — surprise upside. Absence not missed; presence wins deals.
- **effort** — engineering cost to build for {{PROJECT_NAME}}, coarse:
  - `S` — ≤ 1 sprint (single dev, no new infra).
  - `M` — 1–2 quarters (multiple devs, some new infra).
  - `L` — > 2 quarters (new subsystem, external dependency, or research risk).
- **moat** — defensibility implication once shipped:
  - `none` — commodity feature; competitors match easily.
  - `network` — value grows with more users (marketplaces, social graph).
  - `switching` — creates switching cost (data lock-in, integrations, learned muscle-memory).
  - `scale` — economies of scale reduce our unit cost as we grow.
- **paywall** — where the feature sits in the audited competitor's plan tree:
  - `free` — free tier / no signup required.
  - `pro` — paid mid-tier.
  - `enterprise` — enterprise / contact-sales tier.
  - `addon` — separate purchase / usage-metered.
  - `N/A` — not applicable (open-source, no plans, or unknown).
- **personas** — which user roles exercise the feature. Persona slugs come from `{{YYYY-MM-DD}}-roles.md` (same snapshot). One feature may serve several personas; list every one. Common slugs:
  - `platform-admin` — vendor-side operator of the SaaS itself.
  - `tenant-admin` — customer-side account owner / workspace admin.
  - `editor` — editorial / content producer.
  - `developer` — engineer integrating via API / SDK / webhooks.
  - `end-user` — day-to-day consumer of the primary product surface.
  - `reader` / `guest` — anonymous audience-side.
  - `service-account` — non-human programmatic caller.
  - `?` — persona unknown from the source; audit before shipping.

Skipping a tag is allowed only when the source audit lacks the signal.
Prefer `?` over a fabricated value. Example:

```
- Real-time collaborative cursors [notion, figma] — priority: 8 | kano: delighter | effort: L | moat: switching | paywall: pro | personas: [editor, developer]
- Persian ZWNJ-aware search normalization [asr-gooyesh, digikala] — priority: 9 | kano: basic | effort: S | moat: none | paywall: free | personas: [reader, editor]
- Admin role registry with RBAC [wordpress, ghost] — priority: 8 | kano: basic | effort: M | moat: switching | paywall: pro | personas: [tenant-admin]
```

## Persona view (derived from bullets above)

Cross-cut of every bullet by persona. Populated after all dimensions are
filled. For each persona, list its load-bearing features (priority ≥ 8) and
its "important but not urgent" features (priority 5–7). Skip low-priority
tiers.

### {{persona-slug-1}}

**Load-bearing (priority ≥ 8):**
- {feature description} — §{dimension} — priority: {N}

**Important (priority 5–7):**
- {feature description} — §{dimension} — priority: {N}

### {{persona-slug-2}}

**Load-bearing (priority ≥ 8):**
- ...

## Corpus

**Segments audited:** {{list of segment slugs}}
**Competitors scored:** {{N}}
**Stubs (origin unreachable / parked, no features captured):** {{list of slugs}}

---

## 1. Information architecture

### {{segment-a}}
- feature description [slug] — priority: {1-10} | kano: {basic|perf|delighter} | effort: {S|M|L} | moat: {none|network|switching|scale} | paywall: {free|pro|enterprise|addon|N/A} | personas: [{persona-slug}, ...]

### {{segment-b}}
- feature description [slug] — priority: {1-10} | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 2. Internationalization

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 3. Lead generation

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 4. Trust signals

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 5. Service / product presentation

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 6. Resources & content surfaces

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 7. Search & discoverability

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 8. Customer / client portal

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 9. Careers

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 10. Accessibility

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 11. Performance

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 12. Security & privacy

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 13. Technical stack

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 14. Integrations & embeds

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 15. Mobile experience

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 16. Conversion mechanics

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 17. SEO surface

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 18. {{LOCAL_MARKET_DIMENSION}}

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 19. Pricing & packaging

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 20. Onboarding & signup

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 21. Support surface

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 22. Community & social proof

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 23. Legal & compliance

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 24. Third-party ecosystem

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 25. Lifecycle marketing

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 26. Documentation depth

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 27. Analytics & consent

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

## 28. Content freshness

### {{segment-a}}
- feature description [slug] — priority: ... | kano: ... | effort: ... | moat: ... | paywall: ... | personas: [...]

---

## Wedge picks (priority = 10)

Cross-cut of every priority-10 feature. These are what {{PROJECT_NAME}} must
ship to be credible in this market. If more than 8 features land at 10,
scoring is soft — re-anchor against positioning and demote until at most 5–8
survive.

- 1. IA — ... — [slug, slug]
- 2. Internationalization — ...
- ...

## Anti-features (priority ≤ 3, do NOT build)

Explicitly-out-of-scope features some competitors ship. Named here so that
future prompts asking "should we add X?" have a paper trail for "no, and
here's why."

- ... — [slug] — deferred / rejected because ...
