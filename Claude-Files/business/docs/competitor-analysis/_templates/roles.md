---
title: "Roles competitors recognise — {{YYYY-MM-DD}}"
category: "competitor-analysis"
audited_at: "{{YYYY-MM-DD}}"
auditor: "{{PROJECT_NAME}} / <human or model>"
source: "competitor-analysis/*/{slug}/{{YYYY-MM-DD}}/analysis.md, {{YYYY-MM-DD}}-feature-catalog.md"
---

# Roles competitors recognise — {{YYYY-MM-DD}}

A synthesis of the user roles (audiences / personas / customer types) that
the competitor sites in this directory **explicitly model** — i.e. either
route them to a dedicated nav bucket, a dedicated subdomain / portal, a
dedicated landing, a dedicated form intent, or a dedicated mega-menu under a
persona switch.

**Inclusion rule.** "Implicit" audiences (everyone who reads the homepage)
are **not counted**. Only roles the site has a name for and a destination for.

**Evidence rule.** Every role lists the competitors that surface it and the
**concrete artefact** that proves it (URL, nav label, form intent, subdomain,
mega-menu tab). No artefact → no role.

**Grouping.** Roles are grouped by the frame that best explains "who is being
addressed?" The starting frames below are a strong default — reorder / add /
remove to match the market you're auditing. A single human may hold multiple
roles; roles are not strictly hierarchical.

---

## 1. End-customer roles (who is buying)

### 1.1 Personal / home consumer (B2C)

- **`{{slug}}`** — {{concrete artefact proving the role exists on this site}}.
- ...

### 1.2 Business / enterprise organisation (B2B)

- **`{{slug}}`** — ...
- ...

### 1.3 Small business / startup (SMB)

- **`{{slug}}`** — ...
- ...

### 1.4 Government / public sector

- **`{{slug}}`** — ...
- ...

### 1.5 Industry-vertical buyer (banking, retail, health, energy, telecom, ...)

- **`{{slug}}`** — ...
- ...

## 2. Money-flow roles (only if relevant to the market)

### 2.1 Merchant / acceptor

- **`{{slug}}`** — ...

### 2.2 Payer / end-user paying with the product

- **`{{slug}}`** — ...

### 2.3 Partner / reseller / affiliate

- **`{{slug}}`** — ...

## 3. Producer / operator roles (who is doing work inside the product)

Sourced from the dashboard / admin surfaces competitors expose. Cite the
feature-catalog section that surfaces each role.

### 3.1 Owner / account admin

- **`{{slug}}`** — nav label, portal URL, or `roles` docs page.
- Drawn from feature-catalog §{{N}}.

### 3.2 Workspace / tenant admin

- **`{{slug}}`** — ...

### 3.3 Editorial / content producer roles

- **`{{slug}}`** — ...

### 3.4 Reviewer / approver / moderator

- **`{{slug}}`** — ...

### 3.5 Developer / integrator

- **`{{slug}}`** — ...

### 3.6 Analyst / reporting-only

- **`{{slug}}`** — ...

## 4. Non-human principals

Roles competitors surface for **service accounts, bots, and automation**
rather than named humans.

### 4.1 API-key clients / M2M callers

- **`{{slug}}`** — API keys page, service-token issuance UI, docs role table.

### 4.2 Webhook receivers

- **`{{slug}}`** — outbound-webhook config, signing-secret rotation UI.

### 4.3 AI agents / MCP clients (where applicable)

- **`{{slug}}`** — MCP server surface, agent-scoped tokens.

## 5. Ecosystem / community roles (adjacent, not paying)

Where competitors model roles that aren't customers but are part of the
distribution or contribution story.

### 5.1 Job seeker / candidate

- **`{{slug}}`** — careers portal, ATS integration (Greenhouse / Lever /
  Jobinja / Jobvision).

### 5.2 Investor / shareholder

- **`{{slug}}`** — IR page, shareholder portal, dedicated subdomain.

### 5.3 Journalist / press

- **`{{slug}}`** — press page, media kit, PR contact form intent.

### 5.4 Community contributor / OSS user (if the product is or wraps OSS)

- **`{{slug}}`** — GitHub link in nav, contributor guide, community forum.

---

## Roles {{PROJECT_NAME}} should model (recommendation)

For each role above, one of three verdicts, with a one-line rationale:

- **✅ Model as a first-class role** — dedicated nav / portal / permission set
  in v{{N}}.
- **🟡 Recognise as a persona** — no dedicated nav, but marketing pages,
  form intent, or targeting should acknowledge it.
- **⛔ Ignore for v{{N}}** — not part of our positioning; document why.

| Role | Verdict | Rationale (one line) |
|---|---|---|
| End-consumer (B2C) | ⛔ | We are B2B-only. |
| Workspace admin | ✅ | ... |
| Section editor | ✅ | ... |
| API-key client | 🟡 | Recognise in v1, formalise in v1.1. |

## Cross-references

- Feature catalog: `{{YYYY-MM-DD}}-feature-catalog.md` — §9 (RBAC), §18 (Local).
- Comparison & ranking: `{{YYYY-MM-DD}}-comparison-and-ranking.md` — Port
  (portal) and Care (careers) dimensions.
- Product-side role definition (if it exists): `product/docs/users/`.
