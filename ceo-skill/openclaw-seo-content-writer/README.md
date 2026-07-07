<p align="center"><img src="assets/banner.png" alt="SEO Content Writer — an awesome-ceo-stack agent skill" width="820"></p>

# OpenClaw SEO Content Writer

OpenClaw SEO Content Writer is a publishable skill for running a **Tony + Peter SEO blog pipeline** in OpenClaw.

It is designed for teams that do not want “write a blog post” to stop at drafting.

Instead, it treats SEO content as an operational lane:

- **Tony** owns drafting, safe-template normalization, structural QA, content-quality gating, and source publish readiness.
- **Peter** owns deployment, live verification, indexability checks, Google Search Console submission, and indexing-status tracking.

## What this skill covers

### Tony lane
- draft generation
- safe-template normalization
- preflight checks
- content-quality audit
- Hunter recovery-research before downgrade / topic replacement
- source publish readiness

### Peter lane
- production deploy
- live URL verification
- `/blog` visibility checks
- canonical / sitemap / noindex / discovery checks
- blog indexability gate
- Google Search Console submission
- indexing-status receipts

## Why this exists

Most “SEO writing” workflows stop too early:
- a draft exists
- maybe it looks polished
- but it is not truly publish-ready
- not deployed
- not indexed
- not tracked

This skill exists to prevent that failure mode.

## Core workflow

1. Gather keyword / topic / audience / proof inputs
2. Draft the post batch
3. Normalize with a safe SEO template
4. Run structural preflight
5. Run content-quality audit
6. If thin or not publishable, call Hunter for more research
7. Source-publish only after gates pass
8. Deploy and verify production
9. Run indexability checks
10. Submit index-ready URLs to GSC
11. Track indexing status with receipts

## Installation

### ClawHub
- <https://clawhub.ai/x-rayluan/openclaw-seo-content-writer>

### GitHub
- <https://github.com/X-RayLuan/openclaw-seo-content-writer>

## Skill name
- `openclaw-seo-content-writer`

## Use when
Use this skill when the task is to:
- write and ship SEO blog posts
- run safe-template blog production
- enforce publish readiness QA
- deploy and verify blog updates
- submit URLs to Google Search Console
- operate a repeatable SEO content pipeline for OpenClaw / ClawLite style sites

## Notes

This repository is the GitHub home of the published skill. The runtime behavior is defined primarily by:
- `SKILL.md`
- `references/tony-pipeline.md`
- `references/peter-closeout.md`
- `references/gsc-indexing.md`
- `references/receipt-contracts.md`
