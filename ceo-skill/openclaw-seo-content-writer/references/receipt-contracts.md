# Receipt contracts

Use receipts to separate real progress from wishful narration.

## Minimum receipt categories

- `preflight`
- `content-quality-audit`
- `source-publish`
- `deploy`
- `blog-indexability`
- `gsc-submit`
- `gsc-index-status`

## Useful truth states

### Content lane
- `DRAFTS_GENERATED`
- `PREFLIGHT_FAILED`
- `QUALITY_AUDIT_FAILED`
- `SOURCE_PUBLISH_VERIFIED`

### Deploy lane
- `CODE_READY_NOT_DEPLOYED`
- `DEPLOY_PENDING`
- `DEPLOYED_NOT_VERIFIED`
- `LIVE_VERIFIED`
- `BLOCKED_DEPLOY`

### Indexing lane
- `INDEX_READY`
- `BLOCKED_SITEMAP_MISSING`
- `BLOCKED_NOINDEX`
- `BLOCKED_CANONICALIZED_AWAY`
- `SUBMITTED`
- `SUBMITTED_PENDING`
- `INDEXED`
- `CRAWLED_NOT_INDEXED`

## Core principle

Every lane should be able to answer:
- what exists
- what passed
- what failed
- who owns the next move
