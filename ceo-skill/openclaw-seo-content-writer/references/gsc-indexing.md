# GSC indexing

## Purpose

Treat Google Search Console as an operational follow-through step, not an afterthought.

## Indexability before submission

Only submit URLs that are:
- live
- self-canonical
- not `noindex`
- present in sitemap
- discoverable from `/blog` or other internal paths

## Submission

Use the Indexing API / Search Console workflow only after the page is `INDEX_READY`.

Minimum outputs:
- GSC submission receipt
- GSC index-status receipt

## Expected early-state behavior

New URLs may initially show:
- `URL is unknown to Google`
- `NEUTRAL`
- `INDEXING_STATE_UNSPECIFIED`

That is not a pipeline failure if submission, sitemap, and live verification are already complete.

## Recovery

If a page is still not indexed after repeated checks, investigate:
- canonical mismatch
- sitemap absence
- weak uniqueness / query overlap
- thin content or low value
- weak internal discovery
