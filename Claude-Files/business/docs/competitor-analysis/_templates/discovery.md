---
title: "Competitor discovery — {{YYYY-MM-DD}}"
category: "competitor-analysis"
audited_at: "{{YYYY-MM-DD}}"
auditor: "{{PROJECT_NAME}} / <human or model>"
positioning_snapshot: "{{one-line paraphrase of the POSITIONING used at discovery time}}"
---

# Competitor discovery — {{YYYY-MM-DD}}

Output of the **discovery mode** run of `AUDIT_PROMPT.md`. Enumerates the
competitor set that will be audited under snapshot `{{YYYY-MM-DD}}`, along
with the anchors used to find them and the verdict for each candidate.

## Search anchors (extracted from POSITIONING)

- **Domain nouns:** {{e.g. CMS, headless CMS, publishing platform}}
- **Buyer:** {{e.g. Iranian publishers, small salons, banks}}
- **Geography / language:** {{e.g. Iran + Persian; global reference; MENA regional}}
- **Wedge:** {{e.g. Jalali-first, phone-first, low-latency bilingual}}
- **Anti-scope (what we are NOT):** {{e.g. not enterprise, not headless-only, not multi-language wedge}}

## Channels swept

Confirm each of the four channels was actually consulted. List the concrete
sources (search query, directory URL, VC portfolio) — not "I searched
Google."

1. **Local direct** — {{source(s)}}
2. **Global reference** — {{source(s)}}
3. **Regional peers** — {{source(s)}}
4. **Adjacent substitutes** — {{source(s)}}

## Candidate table

| slug | segment | url | why it matters (1 line) | verdict |
|---|---|---|---|---|
| `{{slug}}` | `iranian-<domain>` | https://... | ... | `audit` |
| `{{slug}}` | `global-<domain>` | https://... | ... | `audit` |
| `{{slug}}` | `regional-mena` | https://... | ... | `stub` |
| `{{slug}}` | `<adjacent>` | https://... | ... | `skip` |

**verdict values**

- `audit` — worth a full per-competitor `analysis.md` this snapshot.
- `stub` — origin unreachable / parked / geo-blocked. Recorded as stub, no
  audit. Listed in `<YYYY-MM-DD>-comparison-and-ranking.md` exclusion table.
- `skip` — out of scope for this snapshot; note the reason (deferred,
  duplicate of another, positioning mismatch).

## Coverage summary

- **Discovered:** {{N_TOTAL}}
- **To audit:** {{N_AUDIT}}
- **Stubs:** {{N_STUB}}
- **Skipped:** {{N_SKIP}} (see reasons in table)

Per segment:

| Segment | Discovered | To audit |
|---|---:|---:|
| `iranian-<domain>` | {{N}} | {{N}} |
| `global-<domain>` | {{N}} | {{N}} |
| ... | ... | ... |

## Deferred (candidates for next snapshot)

Anything cut for sizing (>30 total) or `verdict: skip (deferred)` lives here
so the next snapshot's discovery starts from a known backlog rather than a
blank slate.

- `{{slug}}` — {{one-line reason}}

## Next action

Run the per-competitor audit (`§Per-competitor audit` of `AUDIT_PROMPT.md`)
for every row with `verdict: audit`, in order. Do not run synthesis
(`feature-catalog`, `comparison-and-ranking`, `roles`) until every scheduled
audit has produced an `analysis.md`.
