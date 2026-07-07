# Pipeline gotchas (read before building)

These are the failure modes that actually cost time. Each has a fix.

## 1. ffmpeg often lacks `drawtext` and `subtitles`/`ass`
Many Homebrew/static ffmpeg builds ship without libfreetype (`drawtext`) or libass (`subtitles`). Check:
`ffmpeg -filters | grep -Ew 'drawtext|subtitles'`. If missing, **don't** try to burn text with ffmpeg. Render each caption as a **transparent PNG** from `assets/caption.html` (Playwright `screenshot({omitBackground:true})`) and overlay it. Bonus: HTML captions look better (rounded pill, brand highlight, proper CJK font) and are trivially restyled.

## 2. Playwright `recordVideo` duration metadata is inflated / playback looks slow
The webm's reported `duration` can be ~1.5–2× the wall-clock you waited, and motion can look slower than real time. **Do not** trim UI segments using the millisecond values you set in `capture.js`. Instead probe the actual clip:
`ffmpeg -ss <t> -i build/ui_x.webm -frames:v 1 probe.png` at a few `t` values, eyeball where the animation *completes*, then set `build.sh`'s `ss`/`dur` to show the motion + a short hold and cut the static tail. Long typewriter/record animations finish much later in clip-time than you'd guess — verify, don't assume.

## 3. Chrome instance conflict → navigation timeouts
`capture.js` uses `channel:'chrome'` (system Chrome). If another Chrome is holding the default profile — most commonly an **MCP/agent browser** you used to read docs — the record run times out on the first `page.goto`. Close that browser before recording (or give capture its own `--user-data-dir`). Also use `waitUntil:'load'`, not `'networkidle'` (favicon polling never idles → 30s timeout).

## 4. Caption PNG overlay needs a looped input
A single still image passed as `-i cap.png` only exists at t=0 and won't overlay across the segment. Feed it as `-loop 1 -framerate 30 -t <dur> -i cap.png` and overlay with `overlay=...:shortest=1`.

## 5. Fast-cut sections: one narration line, not one-per-clip
A 12s painpoint montage is 4×3s clips, but each clip's TTS line is ~5–6s. Placing 4 lines at 0/3/6/9s makes them **overlap into mush**. Use a single continuous opening sentence spanning the whole section; keep the per-clip text as on-screen captions only. For the slower UI segments (~9–13s each) per-segment lines are fine — just confirm each line ends before the next segment starts.

## 6. Everything gets desensitized
Anything entering a model or the final video: real hospital/customer names, competitor model numbers, prices → replace with plausible fictional values. Check AI-generated B-roll for accidental real brand logos/model text in the scene (e.g. a labelled analyzer) and regenerate if found. Add a logo watermark to the whole film.

## 7. Secrets
`KIE_API_KEY`, `DOUBAO_TTS_KEY` come from env only. Never hardcode a key in a script, and never commit one — this repo is public.

## Timing math
Segment start offsets for `gen_vo.sh` must equal the cumulative sum of `build.sh`'s segment durations. If you change any `dur`, recompute the offsets. A clean default that sums to ~60s: painpoints 4×3=12, intro 9, heroA 9.4, heroB 9.4, heroC 13.5, outro 6.5 → offsets 0/3/6/9/12/21/30.4/39.8/53.3.

## Audio sanity
`volumedetect` prints its stats at **info** log level — run ffmpeg with `-hide_banner` (not `-v error`) or you'll see nothing and think the track is silent. Target: final peak < 0 dB (no clip), BGM ~0.15–0.2, voiceover +6 dB over raw.
