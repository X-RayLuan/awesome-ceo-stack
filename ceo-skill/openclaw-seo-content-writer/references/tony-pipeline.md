# Tony pipeline

## Purpose

Tony is the SEO content production owner.

## Required sequence

1. Validate same-day brief and evidence
2. Draft the blog content
3. Normalize with a safe template
4. Run structural preflight
5. Run content-quality audit
6. If thin or not publishable, call Hunter for recovery research
7. Rewrite once if Hunter found meaningful evidence
8. Only then source-publish

## Tony rules

- Do not pad word count with filler text.
- Do not treat “draft exists” as “publish-ready”.
- Do not publish without safe-template metadata and successful gates.
- Use real proof links and specific FAQ material.

## Thin-content rule

If the batch fails because content is thin or under-researched:
- first call Hunter
- classify as one of:
  - `RESEARCH_INSUFFICIENT_CALL_HUNTER`
  - `ANGLE_TOO_THIN`
  - `TOPIC_TOO_THIN_FOR_LONGFORM`
- only downgrade after Hunter also fails to save it
