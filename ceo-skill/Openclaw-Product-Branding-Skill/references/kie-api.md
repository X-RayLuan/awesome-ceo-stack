# KIE.ai — real-person B-roll (image + image-to-video)

Unified async "jobs" API. Auth: `Authorization: Bearer $KIE_API_KEY`. Docs: https://docs.kie.ai

## Create task
`POST https://api.kie.ai/api/v1/jobs/createTask`
```json
{ "model": "<model-id>", "input": { ... } }
```
Returns `{ "code":200, "data": { "taskId": "..." } }`.

## Poll
`GET https://api.kie.ai/api/v1/jobs/recordInfo?taskId=<id>`
`data.state` ∈ `waiting|queuing|generating|success|fail`. On success, output URLs are in
`JSON.parse(data.resultJson).resultUrls[0]`. **URLs expire in ~24h — download immediately.**
Poll with 3–4s backoff; images ~15–40s, Seedance video ~1–4 min.

## Models used by this skill
### Image — `nano-banana-2`
```json
{ "model":"nano-banana-2",
  "input":{ "prompt":"...", "image_input":[], "aspect_ratio":"9:16", "resolution":"2K", "output_format":"png" } }
```
`aspect_ratio`: 1:1 / 2:3 / 3:2 / 3:4 / 4:3 / 9:16 / 16:9 / 21:9 / auto …  ·  `resolution`: 1K / 2K / 4K.

### Image-to-video — `bytedance/seedance-2`
```json
{ "model":"bytedance/seedance-2",
  "input":{ "prompt":"<camera+motion>", "first_frame_url":"<image url>",
            "resolution":"720p", "aspect_ratio":"9:16", "duration":5,
            "generate_audio":false, "nsfw_checker":false } }
```
Feed the image URL straight from the `img` step. Keep motion subtle for realism (a sigh, a glance, a slow push-in). `bytedance/seedance-2-fast` is a cheaper/faster variant.

## Prompting for believable painpoint B-roll
- Photorealistic, cinematic, 35mm, shallow DOF, **vertical upper-body framing**, natural light.
- The subject is a real target user overwhelmed by the status quo (papers, late night, confused call).
- **No readable brand names / logos / model numbers / text anywhere** — say so explicitly, and re-check the result (AI loves to stamp a real product label on machines/screens).
- Generate 1 portrait per scene, animate 5s, use 3s. If a scene has a real brand slip in, regenerate with "plain unbranded … no logos, no readable text".

`scripts/kie.sh img|vid` wraps all of this.
