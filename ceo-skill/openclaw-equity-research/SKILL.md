---
name: openclaw-equity-research
description: Use when Codex needs to create, review, or update equity research work products such as earnings previews, post-earnings notes, model updates, initiating coverage, sector overviews, catalyst calendars, thesis trackers, idea generation screens, valuation memos, investor briefs, or public-company research that requires filings, transcripts, market data, spreadsheet work, citations, and analyst-review guardrails.
---

# OpenClaw Equity Research

## Operating Rule

Draft analyst work product for human review. Do not present output as investment, legal, tax, accounting, or trading advice. Do not claim a buy/sell/hold recommendation unless the user explicitly asks for a draft recommendation and the assumptions, valuation, risks, and sources support it.

## First Pass

1. Identify the deliverable type and audience: earnings note, preview, model update, initiation, sector overview, catalyst calendar, thesis tracker, idea screen, or one-off memo.
2. Confirm the ticker/company, exchange, coverage universe, geography, currency, date range, and output format if missing.
3. Use fresh sources for public-company facts, estimates, prices, filings, calendar events, executives, market data, and news. Browse when the answer depends on current information.
4. Prefer primary sources: SEC/company filings, investor relations releases, earnings call transcripts, presentations, exchange notices, and company websites. Use reputable secondary sources only to triangulate or fill gaps.
5. Separate fact, calculation, inference, and opinion. Label uncertainty and stale data.
6. Produce a concise decision-ready artifact with citations, assumptions, and next checks.

## Workflow Selection

- **Earnings analysis**: read release, presentation, transcript, and filing; compare actuals to consensus or prior guide; isolate beats/misses, guide changes, margin drivers, cash flow, balance sheet, segment trends, and management tone.
- **Earnings preview**: map consensus, guidance, buyside debate, expected KPIs, risks, and likely stock-moving questions before the print.
- **Model update**: update actuals, guidance, forecast assumptions, valuation outputs, and sensitivity tables. Use spreadsheet tools for `.xlsx` work.
- **Initiating coverage**: build company profile, industry structure, competitive position, financial history, forecast drivers, valuation, risks, catalysts, and final note/deck.
- **Morning note**: summarize overnight news, earnings, rating changes, macro/sector moves, and actionable implications.
- **Sector overview**: define market map, demand/supply drivers, unit economics, regulation, competitive landscape, valuation dispersion, and stock implications.
- **Thesis tracker**: maintain thesis, evidence, catalysts, counterevidence, kill criteria, conviction, and unresolved questions.
- **Catalyst calendar**: list dated events, expected impact, source, confidence, and prep needed.
- **Idea generation**: screen for dislocations, estimate revisions, quality, momentum, valuation gaps, catalysts, short-interest, ownership changes, or variant perception.

For detailed checklists, read `references/workflows.md`. For quality gates and output patterns, read `references/research-standard.md`.

## Deliverable Standard

Every research output should include:

- **Snapshot**: company/ticker, date, source freshness, base currency, market data timestamp if used.
- **Key takeaways**: 3-5 bullets that answer what changed, why it matters, and what to watch.
- **Evidence table**: metric/event, source, reported value, comparison point, implication.
- **Model/valuation assumptions**: explicit drivers, ranges, sensitivities, and what would change the conclusion.
- **Risks and counterarguments**: strongest opposing case, missing data, and near-term failure modes.
- **Source list**: links or file names for every material claim.
- **Human review note**: checks needed before external distribution.

## Tooling

- Use web search/browsing for current filings, releases, transcripts, market data, calendars, and news.
- Use `spreadsheets` when creating or editing financial models, forecast tables, comps, sensitivities, or `.xlsx` files.
- Use `documents` when producing professional `.docx` notes or redlines.
- Use `presentations` when producing an investment committee deck, company overview, or sector deck.
- If a user provides local files, inspect them first and preserve source provenance in the final artifact.

## Guardrails

- Do not invent consensus estimates, market prices, valuation multiples, or filing data.
- Do not use a single unsourced chart or article as the basis for a financial conclusion.
- Do not hide assumptions inside prose; put them in a table or bullet list.
- Do not mix currencies, fiscal years, adjusted/non-GAAP metrics, or segment definitions without labeling them.
- Do not externalize or post research without explicit user approval.
