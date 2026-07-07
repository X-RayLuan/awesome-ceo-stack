---
name: openclaw-viral-video-shorts
description: Create viral short-form videos by analyzing Instagram/TikTok/Reels source videos, extracting reusable viral structure, generating an original avatar image with Kie GPT Image 2, and generating 720p vertical video clips with Ark Seedance 2. Use when the user asks for viral video generator, viral shorts, TikTok/Reels scripts, avatar video ads, Kie image generation, Seedance 2 video generation, VOMO-style product videos, or product-led UGC short videos.
---

# OpenClaw Viral Video Shorts

## Purpose

Turn a source viral short video into an original product-led short video package.

Core principle:
- **learn structure, do not copy identity/content**
- extract pacing, hook mechanics, emotion, and scene logic
- create a new avatar, new script, and new product story
- default video path: **Kie GPT Image 2 → Ark Seedance 2 → 720p vertical clips**

## Default stack

### Image generation
Use Kie:

```text
model: kie/gpt-image-2-text-to-image
aspectRatio: 9:16
```

Kie auth should be available through env:

```bash
KIE_API_KEY
```

If unavailable, verify Keychain / launch env before falling back.

### Video generation
Use Ark Seedance 2, not OutAI Seedance credits, unless explicitly requested.

Default command:

```bash
python3 skills/ark-video-gen/scripts/ark_video.py create \
  --prompt "..." \
  --ratio 9:16 \
  --resolution 720p \
  --duration 5
```

Defaults:
- model: `doubao-seedance-2-0-260128`
- fast model: `doubao-seedance-2-0-fast-260128` with `--fast`
- ratio: `9:16`
- resolution: `720p`
- duration: `5` seconds per clip

Poll and download:

```bash
python3 skills/ark-video-gen/scripts/ark_video.py wait --id <task_id>
python3 skills/ark-video-gen/scripts/ark_video.py download --id <task_id> --out <path>.mp4
```

### Audio (voiceover + music)
A finished short is not done until it has a voice and a music bed. Default audio stack:

- **Voiceover:** ElevenLabs TTS (`ELEVENLABS_API_KEY`). One line per scene, `model_id: eleven_multilingual_v2` (covers EN/zh/ja/es). No-key fallback: macOS `say -v Samantha`.
- **Background music:** Pixabay royalty-free. Pixabay's public API does NOT include music — read the direct CDN mp3 URL from the rendered music page with a headless browser, then download it.
- **Mix:** sidechain ducking (music dips under the voice, rises in the gaps) + `alimiter`, then mux onto the silent assembled video.

Full curl/ffmpeg snippets for each are in `README.md` (Stages 5–7).

## Output folder

Write every project to:

```text
viral-shorts/<product-or-campaign>/<YYYY-MM-DD>/
```

Minimum files:

```text
source-analysis.md
viral-structure.json
avatar-profile.md
avatar-image-prompt.md
product-brief.md
script-v1.md
shot-list.md
seedance-prompts.md
captions.md
voiceover-lines.md
audio/        (voiceover lines, bgm, mixed track)
metadata.json
receipts.json
```

If images/videos are generated, save paths in `metadata.json` and `receipts.json`.

## Workflow

### 1. Capture source viral video

Input may be:
- Instagram Reel URL
- TikTok URL
- YouTube Shorts URL
- uploaded video file
- transcript / rough description

For Instagram Reel / TikTok / YouTube Shorts URLs, do **not** ask the model to read the platform page directly. Do **not** start with browser or fetch; Instagram is often blocked by browser policy while `yt-dlp` can still ingest the source. First ingest the source with the local helper:

```bash
node ~/.openclaw/skills/openclaw-viral-video-shorts/scripts/ingest-source-video.mjs \
  --url "https://www.instagram.com/reels/DUwX-lfjit8/" \
  --out viral-shorts/<campaign>/<YYYY-MM-DD>/source
```

This writes:

```text
source/source-metadata.json
source/source.mp4
source/source-analysis-seed.md
```

If only metadata is needed:

```bash
node ~/.openclaw/skills/openclaw-viral-video-shorts/scripts/ingest-source-video.mjs \
  --url "<source-url>" \
  --metadata-only
```

If ingest fails because the platform requires login or blocks download, ask for an uploaded mp4/screen recording or a user-provided transcript. Do not fake exact source analysis. If browser/fetch fails but this ingest succeeds, proceed with the local `source.mp4`; do not report the source as unreadable.

Record:
- creator / URL
- platform
- product/category if visible
- video length
- visual style
- audio style if known
- hook text if available

### 2. Extract viral structure

Analyze:
- first 3-second hook
- emotional driver
- viewer retention device
- conflict / curiosity gap
- scene progression
- proof/reveal moment
- CTA style
- caption density
- cut rhythm

Output schema:

```json
{
  "viral_pattern": "pain-shock-demo-payoff",
  "hook_mechanic": "...",
  "emotional_driver": "curiosity|fear|relief|aspiration|status|humor",
  "structure": [
    "0-3s hook",
    "3-8s pain setup",
    "8-18s demo/reveal",
    "18-28s payoff",
    "28-35s CTA"
  ],
  "visual_formula": "...",
  "copy_formula": "...",
  "why_it_works": "..."
}
```

### 3. Build target product brief

For the product, capture:
- what it does
- who it helps
- strongest pain point
- proof points / key features
- demoable moment
- simple before/after
- CTA

For VOMO-style AI voice notes product, default positioning:

```text
Turn messy voice notes, meetings, and thoughts into summaries, action items, and clean notes.
```

### 4. Create avatar profile

Avatar must be original.
Do not imitate a real influencer, celebrity, or source creator.

Default avatar pattern:

```text
Name: Mia
Role: overloaded founder / consultant / creator
Vibe: smart, fast, slightly overwhelmed but competent
Visual: modern casual outfit, phone in hand, bright workspace
Tone: practical productivity hack, not corporate ad
```

### 5. Generate avatar image with Kie

Use a 9:16 vertical portrait prompt.

Template:

```text
Create a realistic vertical 9:16 UGC creator avatar: [gender/age/role], smart and expressive, casual modern outfit, holding a phone, bright home office, authentic TikTok/Reels style, natural lighting, original identity, not a celebrity, no text, no watermark. Any phone, laptop, tablet, book, poster, or screen in the image must be blank, dark, blurred, or show abstract color blocks only. Do not render letters, words, numbers, UI labels, chat bubbles, app names, subtitles, or readable interface text inside the generated image.
```

Call:

```text
image_generate model="kie/gpt-image-2-text-to-image" aspectRatio="9:16"
```

If Kie is unavailable, stop and report the auth/config blocker unless user approves fallback.

### 6. Write product-led short script

Script length:
- 20–45 seconds for one complete short
- 5–8 seconds for individual Seedance clips

Default structure:

```text
0-3s: Hook
3-8s: Pain
8-15s: Product reveal
15-25s: Demo / before-after
25-35s: Payoff
35-45s: CTA
```

Rules:
- first line must be scroll-stopping
- show product outcome before feature explanation
- make captions short and punchy
- avoid generic startup jargon
- avoid unverifiable claims
- never rely on the image/video model to render readable text on phones, computers, whiteboards, notebooks, posters, or product UI
- if readable text is needed, generate it as separate captions/overlays in post-production; keep generated screens blank, blurred, or abstract

### 7. Create Seedance 2 clip prompts

Split full script into 5-second scenes.
For each scene write:
- visual prompt
- spoken line / caption
- camera style
- motion
- product/UI overlay if needed

Seedance prompt template:

```text
Vertical 9:16 UGC-style short video, 720p. [Avatar description] speaks directly to camera in [setting]. [Action]. Fast TikTok/Reels pacing, natural handheld phone camera, realistic lighting, subtle zoom cuts. No readable text generated inside the video frame except later post-production captions. Phones, laptops, tablets, books, posters, and product screens must be blank, dark, blurred, or abstract UI blocks only. Product may be shown as a clean non-readable UI mockup/overlay. Original avatar, no celebrity likeness, no watermark.

Scene goal: [hook/pain/demo/payoff/CTA]
Post-production caption to add later: "..."
```

### 8. Generate video with Ark Seedance 2

Create each clip:

```bash
python3 skills/ark-video-gen/scripts/ark_video.py create \
  --prompt "<scene prompt>" \
  --ratio 9:16 \
  --resolution 720p \
  --duration 5
```

Then wait and download:

```bash
python3 skills/ark-video-gen/scripts/ark_video.py wait --id <task_id>
python3 skills/ark-video-gen/scripts/ark_video.py download --id <task_id> --out viral-shorts/<campaign>/<date>/clip-01.mp4
```

### 9. Apply readable overlays

Do not ask Seedance or the avatar image model to render readable UI text. After downloading clean no-text clips, add captions and phone/computer UI screenshots with the local overlay tool.

Create `overlays.json` next to the generated video:

```json
{
  "video": "clip-01.mp4",
  "captions": [
    {
      "text": "I stopped rewriting meeting notes by hand",
      "start": 0.2,
      "end": 2.8,
      "position": "bottom"
    }
  ],
  "images": [
    {
      "src": "app-ui.png",
      "start": 3.0,
      "end": 6.0,
      "x": 420,
      "y": 360,
      "width": 240
    }
  ]
}
```

Run:

```bash
node ~/.openclaw/skills/openclaw-viral-video-shorts/scripts/apply-overlays.mjs overlays.json --output final.mp4
```

Overlay rules:
- use captions for all readable text
- use real screenshots, HTML-rendered PNGs, or manually designed PNGs for phone/computer UI
- keep generated video screens blank, blurred, dark, or abstract before overlay
- if screen placement needs perspective tracking, produce a clean first pass with this tool, then do final tracking in CapCut, After Effects, or Remotion

### 9b. Add voiceover, music, and final mix

A short with captions but no audio is not finished. After the visual cut exists, add a voice track and a music bed, then mix and mux. Keep voiceover lines tight (3–8 words), one per scene, matching the captions.

**1. Voiceover — ElevenLabs.** One line per scene, then place each at its scene start with `adelay` and `amix`.

```bash
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/<voice_id>?output_format=mp3_44100_128" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
  -d '{"text":"<scene line>","model_id":"eleven_multilingual_v2",
       "voice_settings":{"stability":0.4,"similarity_boost":0.8,"style":0.45,"use_speaker_boost":true}}' \
  -o vo<i>.mp3
```
- Default female creator voice: `Jessica` = `cgSgspJ2msm6clMCkdW9`. `eleven_multilingual_v2` handles EN/zh/ja/es for localized versions.
- Fallback when no key: `say -v Samantha -o vo.aiff "<line>"`.

**2. Background music — Pixabay (royalty-free).** Music is NOT in Pixabay's public API. Render the music search page in a headless browser, read the direct CDN mp3 URL from `<script>`/`<audio>`, then download it (CDN file needs no key):

```js
() => { const f=new Set();
  document.querySelectorAll('script').forEach(s=>{const m=(s.textContent||'').match(/https:\/\/cdn\.pixabay\.com\/audio\/[^"' ]+?\.mp3/g); if(m)m.forEach(u=>f.add(u));});
  const b=document.querySelector('button[aria-label*="Play" i]'); if(b)b.click();
  document.querySelectorAll('audio,source').forEach(a=>a.src&&f.add(a.src)); return [...f]; }
```

**3. Mix with sidechain ducking + mux.** Music ducks under the voice, rises in the gaps:

```bash
ffmpeg -y -i voice30.wav -i bgm_seg.wav -filter_complex \
 "[1]volume=0.55[bg];[bg][0]sidechaincompress=threshold=0.03:ratio=8:attack=15:release=350[duck];\
  [0][duck]amix=inputs=2:normalize=0,alimiter=limit=0.95[m]" -map "[m]" mixed.wav
ffmpeg -y -i video.mp4 -i mixed.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -t 30 final.mp4
```

**Level check (do not skip):** with `ffmpeg -i mixed.wav -af volumedetect -f null -`, the full-mix mean should be ≈ −15 dB and the BGM must still be audible (≈ −22 dB) inside a voice gap. If the music measures −40 dB or lower it is effectively silent — normalize it first (`loudnorm I=-22`), don't trust a raw `volume=0.x`.

Record voice_id, music URL, and the mixed/final paths in `receipts.json`. Full multilingual walkthrough: `README.md` Stages 5–7.

### 10. Optimize avatar consistency and screen quality

Use this loop after the first generated batch, especially for high-school/student avatars, product demo videos, and any video where the same character must appear across clips.

Pressure scenarios this prevents:
- source URL was browser/fetch blocked but local ingest worked
- generated screens contained gibberish text
- avatar drifted into a different age/style/person across clips
- one clip became a phone-only close-up and lost the character
- final proof was claimed before live files/receipts existed

#### A. Review before assembling

After each clip downloads, extract a middle frame:

```bash
ffmpeg -y -ss 2.5 -i clip-02.mp4 -frames:v 1 -update 1 clip-02-frame.jpg
```

Open the frame and check:
- same face/hair/glasses/clothing/backpack as the avatar profile
- age-appropriate and non-sexualized styling for student avatars
- no readable generated text on clothing, screens, notebooks, posters, books, or UI
- product scene role still matches the shot list
- no all-phone-closeup clip unless the shot list explicitly asked for it

#### B. Regenerate only failed clips

Do not regenerate the whole video if only one or two clips drift. Keep good clips and create versioned prompts:

```text
clip-02-v2-prompt.txt
clip-02-v3-prompt.txt
clip-04-v3-prompt.txt
```

Strengthen prompts with stable identity anchors:

```text
Same character as avatar-kie.png and clip 1: Ava, an 18-year-old high school senior, modest oversized PLAIN gray school hoodie with absolutely no logo, no letters, no brand marks, round black glasses, straight shoulder-length dark hair with soft bangs, blue backpack strap, natural student posture, non-glamorous, age-appropriate.
```

For clips that turned into phone-only shots, add:

```text
Ava is clearly visible at her desk for most of the clip. Do not turn the whole clip into a phone close-up. Phone screen must face away from camera or be fully blurred.
```

For gibberish prevention, add:

```text
Strict text/screen/clothing rule: no readable text anywhere in the frame. No text on hoodie, no brand logo, no readable phone/laptop/notebook/poster/book/UI text. Screens and paper must be blank, dark, blurred, or abstract blocks only.
```

#### C. Assemble a consistent cut

Create a versioned concat file instead of overwriting originals:

```text
file '/abs/path/clip-01.mp4'
file '/abs/path/clip-02-v3.mp4'
file '/abs/path/clip-03.mp4'
file '/abs/path/clip-04-v3.mp4'
file '/abs/path/clip-05.mp4'
```

Build the base:

```bash
ffmpeg -y -f concat -safe 0 -i concat-consistent.txt -c copy final-consistent-base.mp4
```

Point a versioned overlay spec at the consistent base:

```json
{
  "video": "final-consistent-base.mp4",
  "captions": [],
  "images": []
}
```

Render:

```bash
node ~/.openclaw/skills/openclaw-viral-video-shorts/scripts/apply-overlays.mjs \
  overlays-consistent.json \
  --output final-consistent-with-overlays.mp4
```

#### D. Final QA

Verify:
- `ffprobe` duration and file size are sane
- final video exists in the project folder
- final video is copied to the user-facing video folder if requested
- `receipts.json` marks the recommended final path
- receipt notes explain which clips were regenerated and why

Example recommended receipt fields:

```json
{
  "status": "recommended_consistent_final_rendered",
  "final_videos": [
    {
      "type": "recommended_consistent_with_overlays",
      "path": "final-consistent-with-overlays.mp4",
      "duration_seconds": 25.33,
      "copied_to": "/Users/m1/Desktop/video/<campaign>/final-consistent-with-overlays.mp4"
    }
  ],
  "notes": [
    "Regenerated clip 2 and clip 4 as v3 for stronger avatar consistency."
  ]
}
```

### 11. Write receipts

Every generated asset needs a receipt.

`receipts.json` should include:

```json
{
  "source_url": "...",
  "product_url": "...",
  "avatar_image_model": "kie/gpt-image-2-text-to-image",
  "video_model": "doubao-seedance-2-0-260128",
  "resolution": "720p",
  "ratio": "9:16",
  "generated_images": [],
  "video_tasks": [],
  "downloaded_videos": [],
  "overlay_specs": [],
  "final_videos": [],
  "status": "draft|generated|blocked",
  "blockers": []
}
```

## Compliance rules

- Do not copy the source creator’s wording, exact scene, likeness, voice, or jokes.
- Do not use original audio unless user owns rights.
- Do not claim product capabilities not supported by source/product page.
- If source video cannot be accessed, mark source analysis as `blocked_platform_access` and use uploaded media or user summary.
- Use structure transfer only: hook mechanics, pacing, emotional logic, scene role.

## Quality bar

A good output includes:
- clear viral structure analysis
- one original avatar profile
- one avatar image prompt
- one product-led short script
- 3–6 Seedance clip prompts
- captions
- overlay spec for readable captions/UI
- a voiceover track (one line per scene) + a royalty-free music bed, mixed with sidechain ducking and level-checked (BGM audible in voice gaps)
- receipts with task IDs and file paths

## Fast path for VOMO-style product

Use this product angle:

```text
Your voice notes are not notes. They are raw thoughts. The product turns them into summaries, action items, and shareable decisions.
```

Hooks:
- “I stopped writing meeting notes manually.”
- “Your voice notes are probably where good ideas go to die.”
- “This turns a messy 10-minute voice memo into a clean action plan.”
- “I record once. AI cleans it into notes, tasks, and decisions.”

CTA:
- “Record once. Let AI clean it up.”
- “Turn messy thoughts into usable notes.”
- “Stop replaying voice memos. Start extracting decisions.”
