<!-- LANGS -->
**English** · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Español](README.es.md)

# OpenClaw Viral Video Shorts

An OpenClaw skill + end-to-end pipeline for turning a **supplier / product page** into a **30-second vertical (9:16) viral short**, by:

1. **Discovering** real viral references on Instagram / TikTok / Shorts
2. **Extracting** their reusable viral *structure* (hook → pain → demo → payoff → CTA) into an original script
3. **Generating** the video from real product material — AI image-to-video clips + real footage + AI voiceover + royalty-free music — and assembling it with `ffmpeg`

> Core principle: **learn structure, never copy identity/content.** Transfer pacing, hook mechanics, emotion and scene logic — create a new script, new visuals, new voice.

This README documents the full **discover → script → generate** pipeline as actually run end-to-end (case study: a ZekSmart LED-mirror short). `SKILL.md` holds the agent-facing workflow; this file is the human/operator runbook.

---

## Pipeline at a glance

```
[1] Discover viral refs      Exa + Tavily  → IG/TikTok reels
        ↓
[2] Extract structure        hook/pain/demo/payoff/CTA → script + captions
        ↓
[3] Gather product material  Alibaba product images  /  uploaded footage (zip)
        ↓
[4] Generate clips           Volcengine Ark "Seedance 2.0" image-to-video (9:16, 720p, 5s each)
        ↓
[5] Voiceover                ElevenLabs TTS (per-caption lines, timed to 5s slots)
        ↓
[6] Background music         Pixabay royalty-free (direct CDN mp3)
        ↓
[7] Assemble                 ffmpeg: normalize → captions (PNG overlay) → concat → sidechain-duck mix → mux
        ↓
[8] (optional) Deliver       upload / send the final mp4
```

---

## Prerequisites

**CLI tools**

| Tool | Used for | Notes |
|------|----------|-------|
| `ffmpeg` / `ffprobe` | all video/audio work | **may lack `drawtext`** (no libfreetype) — captions are rendered as PNG overlays instead, see [Pitfalls](#pitfalls--lessons) |
| `python3` + `Pillow` | caption PNGs, API calls | `pip install --break-system-packages Pillow` |
| Playwright (browser) | Pixabay music URL extraction | only needed for the BGM step |
| `yt-dlp` *(optional)* | ingest a source reel as a local mp4 | optional; structure can also be extracted from search snippets |

**API keys (export as env vars — never commit them)**

```bash
export EXA_API_KEY=...          # viral reference discovery
export TAVILY_API_KEY=...       # search + page extraction (Alibaba, Pixabay fallback)
export ARK_API_KEY=...          # Volcengine Ark / Seedance 2.0 video generation
export ELEVENLABS_API_KEY=...   # voiceover TTS
export KIE_API_KEY=...          # optional: GPT-Image avatar generation (skill default path)
```

---

## [1] Discover viral references

Find real, currently-performing short videos in the niche. Use **both** engines — they have different coverage.

```bash
# Exa — semantic discovery (note: Exa does NOT serve the instagram.com domain;
# include tiktok/youtube, let Tavily cover instagram)
curl -s -X POST https://api.exa.ai/search -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"viral LED mirror smart mirror short video reel",
       "numResults":8,
       "includeDomains":["tiktok.com","youtube.com"]}'

# Tavily — covers instagram.com + returns snippet text
curl -s -X POST https://api.tavily.com/search -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",
       \"query\":\"viral LED mirror tiktok instagram reel hook\",
       \"search_depth\":\"advanced\",\"max_results\":6,
       \"include_domains\":[\"tiktok.com\",\"instagram.com\"]}"
```

Optionally ingest one reference to a local mp4 for frame-level analysis (needs `yt-dlp`):

```bash
node scripts/ingest-source-video.mjs --url "<reel-url>" --out source
```

---

## [2] Extract viral structure → script

Distill the references into a reusable structure, then write an **original** product script on top of it.

```json
{
  "viral_pattern": "boring-vs-wow → demo → proof → CTA",
  "emotional_driver": "aspiration + satisfaction",
  "structure": ["0-5 hook", "5-15 demo", "15-25 proof", "25-30 CTA"]
}
```

A reliable 30s product layout (6 × 5s scenes), each with one short caption / voice line:

| t | scene | caption / VO |
|---|-------|--------------|
| 0–5 | hook (most scroll-stopping shot) | "Your bathroom mirror? So boring." |
| 5–10 | feature demo | "Touch to dim. Three light colors." |
| 10–15 | variety / scale | "Round, oval, any shape, any size." |
| 15–20 | **real proof** (factory / QC) | "Made in our own factory." |
| 20–25 | trust features | "Anti-fog, bluetooth, memory function." |
| 25–30 | CTA | "OEM/ODM — DM us for wholesale pricing!" |

---

## [3] Gather product material

Two real sources work well:

**A. Product images from an Alibaba / 1688 storefront** (extract full-res, strip the CDN size suffix):

```bash
curl -s -X POST https://api.tavily.com/extract -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",\"urls\":[\"<storefront-listing-url>\"],\"extract_depth\":\"advanced\"}" \
  | python3 -c "import sys,json,re; t=json.load(sys.stdin)['results'][0]['raw_content']; \
[print(re.sub(r'_\d+x\d+\.jpg$','.jpg',u)) for u in set(re.findall(r'https://s\.alicdn\.com/@sc04/kf/[^\"\s]+?\.jpg', t))]"
# download with a browser UA + referer or the CDN may 403
curl -sL -A "Mozilla/5.0" -e "https://example.en.alibaba.com/" "<image-url>" -o img01.jpg
```

**B. Real footage uploaded by the client** (e.g. a factory-inspection `.zip`). Chinese-Windows zips use **GBK** filenames that macOS `unzip` chokes on — extract with Python and re-encode names:

```python
import zipfile, os
z = zipfile.ZipFile("footage.zip"); os.makedirs("ex", exist_ok=True); i = 0
for info in z.infolist():
    if info.is_dir(): continue
    try: name = info.filename.encode('cp437').decode('gbk')   # fix GBK names
    except Exception: name = info.filename
    if os.path.splitext(name)[1].lower() in ('.mp4', '.mov'):
        i += 1
        open(f"ex/clip{i:02d}.mp4", "wb").write(z.open(info).read())
```

---

## [4] Generate clips — Volcengine Ark "Seedance 2.0" (image-to-video)

Feed each product image in as the first frame; Seedance animates it (lights turning on, push-in, anti-fog clearing, color shift…).

```bash
# Create a task — image-to-video. image_url may be a public URL or data:base64.
# Generation params go as text flags appended to the prompt.
curl -s -X POST "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks" \
  -H "Authorization: Bearer $ARK_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"doubao-seedance-2-0-fast-260128",
       "content":[
         {"type":"text","text":"LED mirror lights turn on, slow cinematic push-in, premium reveal --resolution 720p --ratio 9:16 --duration 5 --camerafixed false"},
         {"type":"image_url","image_url":{"url":"<public-image-url>"}}
       ]}'
# → {"id":"cgt-..."}

# Poll until status == "succeeded", then read content.video_url
curl -s "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks/<id>" \
  -H "Authorization: Bearer $ARK_API_KEY"
```

- Models: `doubao-seedance-2-0-260128` (quality) / `doubao-seedance-2-0-fast-260128` (faster, cheaper).
- **Fire all scene tasks in parallel** then poll together — generation (~3–6 min/clip) is the bottleneck.
- Each clip returns 9:16 720p ~5s.

---

## [5] Voiceover — ElevenLabs

Generate one short line per scene, then place each at its 5-second mark.

```bash
# pick a female creator voice, e.g. "Jessica" (playful, bright, warm)
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/cgSgspJ2msm6clMCkdW9?output_format=mp3_44100_128" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
  -d '{"text":"Your bathroom mirror? So boring.",
       "model_id":"eleven_multilingual_v2",
       "voice_settings":{"stability":0.4,"similarity_boost":0.8,"style":0.45,"use_speaker_boost":true}}' \
  -o vo1.mp3
```

`eleven_multilingual_v2` also covers Chinese / Japanese / Spanish for localized voiceovers. (A no-key fallback is the macOS `say -v Samantha` voice.)

Lay the lines onto a 30s track with `adelay` at 0.3s, 5.3s, 10.3s … then `amix`.

---

## [6] Background music — Pixabay (royalty-free)

Pixabay's **public API only covers images & video — music is not in the API**, and the search page loads track URLs via JS. Use a headless browser to read the direct CDN mp3 URL, then download it (no key needed for the CDN file):

```js
// after navigating to https://pixabay.com/music/search/upbeat/
() => {
  const found = new Set();
  document.querySelectorAll('script').forEach(s => {
    const m = (s.textContent||'').match(/https:\/\/cdn\.pixabay\.com\/audio\/[^"' ]+?\.mp3/g);
    if (m) m.forEach(u => found.add(u));
  });
  const btn = document.querySelector('button[aria-label*="Play" i]'); if (btn) btn.click();
  document.querySelectorAll('audio,source').forEach(a => a.src && found.add(a.src));
  return [...found];
}
```

```bash
curl -sL -A "Mozilla/5.0" -e "https://pixabay.com/" "<cdn-audio-url>" -o bgm.mp3
```

---

## [7] Assemble with ffmpeg

**Normalize every clip to 720×1280, 30fps.** Vertical AI clips are crop-filled; landscape footage gets a blurred-background fit:

```bash
# vertical AI clip
ffmpeg -y -i scene.mp4 -t 5 -vf "scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,fps=30" -an seg.mp4
# landscape footage → blurred-bg 9:16
ffmpeg -y -ss 30 -t 5 -i factory.mp4 -filter_complex \
  "[0:v]scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,boxblur=24:6[bg];\
   [0:v]scale=720:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2,fps=30" -an seg4.mp4
```

**Captions via PNG overlay** (this build of ffmpeg has no `drawtext`). Render transparent caption strips with Pillow, then `overlay`:

```python
from PIL import Image, ImageDraw, ImageFont
f = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 46)
img = Image.new("RGBA", (720, 160), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
d.rounded_rectangle([60, 10, 660, 150], radius=24, fill=(0, 0, 0, 150))
d.text((360, 80), "Touch to dim", font=f, fill="white", anchor="mm")
img.save("cap.png")
```
```bash
ffmpeg -y -i seg.mp4 -i cap.png -filter_complex "[0:v][1:v]overlay=x=(W-w)/2:y=H-360" -an final_seg.mp4
ffmpeg -y -f concat -safe 0 -i concat.txt -c:v libx264 -pix_fmt yuv420p -r 30 video.mp4   # concat all
```

**Audio: sidechain ducking** so the music dips under the voice and rises in the gaps:

```bash
ffmpeg -y -i voice30.wav -i bgm_seg.wav -filter_complex \
 "[1]volume=0.55[bg];[bg][0]sidechaincompress=threshold=0.03:ratio=8:attack=15:release=350[duck];\
  [0][duck]amix=inputs=2:normalize=0,alimiter=limit=0.95[m]" -map "[m]" mixed.wav
# mux onto the silent video
ffmpeg -y -i video.mp4 -i mixed.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -t 30 final.mp4
```

Verify levels with `volumedetect`: target full-mix mean ≈ −15 dB, and confirm the BGM is audible (≈ −22 dB) inside a voice gap.

---

## [8] Deliver (optional)

Export `final.mp4` (720×1280, ~30s) to wherever the client consumes it. Add a **trending in-app sound** in CapCut / 剪映 before posting — platforms favor native trending audio over any bundled track.

---

## Pitfalls & lessons

Real issues hit while running this pipeline — each one will bite you too:

- **ffmpeg without `drawtext`** → don't burn text with `drawtext`; render captions as **PNG overlays** (Pillow) and `overlay`.
- **`zsh` arrays are 1-based**, not 0-based like bash → `${arr[1]}` is the first element; off-by-one silently drops/duplicates lines.
- **Exa rejects `instagram.com`** in `includeDomains` (`SOURCE_NOT_AVAILABLE`) → use Tavily for Instagram coverage.
- **Alibaba CDN images 403** without a browser `User-Agent` + `Referer`; strip the `_480x480.jpg` suffix for full-res originals.
- **GBK zip filenames** from Chinese Windows break macOS `unzip` → extract via Python with `cp437→gbk` re-encode.
- **Pixabay music is not in the public API** → render the page with a headless browser and read the CDN mp3 URL from JS / `<audio>`.
- **BGM inaudible after mixing** → it's a *level* bug: normalize the music to a known loudness (e.g. `loudnorm I=-22`) and check `volumedetect` in a voice gap; don't trust a raw `volume=0.18`.
- **Seedance latency** → fire all clip tasks in parallel and poll together; a serial loop wastes minutes.

---

## Output structure

```
viral-shorts/<campaign>/<YYYY-MM-DD>/
  source-images/      # product stills
  real-footage/ex/    # client footage (normalized names)
  clips/              # generated Seedance clips
  audio/              # voiceover, bgm, mixes
  caps/               # caption PNGs
  final.mp4           # the deliverable
  receipts.json       # models, task ids, file paths, notes
```

---

## Contents

- `SKILL.md` — agent-facing workflow instructions
- `scripts/ingest-source-video.mjs` — source URL → local mp4 ingest helper
- `scripts/apply-overlays.mjs` — caption / UI overlay renderer

## Safety & compliance

- **Learn structure, not identity** — never copy a creator's wording, scenes, voice, or likeness.
- Use only royalty-free / licensed music; don't bundle copyrighted trending audio.
- Don't claim product capabilities not supported by the product page.
- **Do not commit** generated videos, screenshots, receipts, API keys, or local `.env` files.
