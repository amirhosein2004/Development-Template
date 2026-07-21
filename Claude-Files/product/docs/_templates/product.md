---
title: "{{PROJECT_NAME}} — product overview"
category: "product"
last_updated: "{{YYYY-MM-DD}}"
owner: "{{PROJECT_NAME}} / <human or model>"
---

# {{PROJECT_NAME}} — product overview

> **Single source of truth.** This file is the anchor for every downstream artifact
> (business/docs, competitor analysis, roadmap, marketing). When any fact here
> changes, update this file first, then re-run the downstream commands so their
> derived files refresh.

## 1. Overview

**Name:** {{PROJECT_NAME}}
**Slug:** {{PROJECT_ID}}
**One-line pitch:** {{ONE_LINE_PITCH}}

{{OVERVIEW_PARAGRAPH}}

## 2. Problem & target user

**Buyer / target user:** {{TARGET_USER}}

**Problem it solves:**

{{PROBLEM_STATEMENT}}

## 3. Value proposition & wedge

**Wedge (the one differentiator that wins deals):** {{WEDGE}}

**Why {{PROJECT_NAME}} over alternatives:**

{{VALUE_PROP}}

## 4. Key features (what the product DOES)

Concrete, shipped capabilities. Not roadmap items. Not aspirational.

- {{FEATURE_1}}
- {{FEATURE_2}}
- {{FEATURE_3}}
- {{FEATURE_4}}
- {{FEATURE_5}}

## 5. Non-features (what the product does NOT do)

Explicit anti-scope. Prevents future scope drift and gives competitor analysis
a paper trail for "should we add X?" decisions.

- {{NON_FEATURE_1}}
- {{NON_FEATURE_2}}
- {{NON_FEATURE_3}}

## 6. Market context

- **Geography:** {{MARKET_GEOGRAPHY}}
- **Language(s):** {{PRODUCT_LANGUAGES}}
- **Segment slugs (for competitor analysis):** {{SEGMENT_SLUGS}}
- **Local-market dimension name (dimension 18 in audits):** {{LOCAL_MARKET_DIMENSION}}
- **Locale rules:** {{LOCALE_RULES}}

## 7. Business model (optional — fill when known)

- **Pricing model:** {{PRICING_MODEL}}
- **Revenue streams:** {{REVENUE_STREAMS}}
- **Willingness-to-pay signal:** {{WTP_SIGNAL}}

## 8. Success metrics (optional — fill when known)

- **North-star metric:** {{NORTH_STAR_METRIC}}
- **Key KPIs:** {{KEY_KPIS}}

## 9. Positioning paragraph (verbatim — the anchor for every downstream score)

> This paragraph is copied verbatim (no paraphrase) into every downstream file
> that references positioning. It must combine: **domain nouns** + **buyer** +
> **geography/language** + **wedge** + **anti-scope**. Two-to-four sentences.

{{POSITIONING}}
