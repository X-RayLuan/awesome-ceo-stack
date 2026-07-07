# Reproducing the product UI as a recordable prototype

Goal: a single self-contained HTML file per screen that (a) looks exactly like the product's design, (b) plays the "hero" animations on command, and (c) has a `?rec=1` mode that stages it for 1080×1920 recording.

## Fidelity first
Read the product's screenshots and copy its **actual design language** — colors, radii, fonts, icons, spacing. For an iOS-style app use `-apple-system, "PingFang SC"`. Do NOT impose a new brand look; the whole point is "this is that App". Desensitize any real names/data shown.

## Recording mode (`?rec=1`)
Add to each page:
```css
body.rec{ background:radial-gradient(120% 90% at 50% 0%,#12224a,#0b1020 60%,#070a14);
          padding:0; overflow:hidden; }
body.rec .controls{ display:none; }          /* hide any dev/demo dock */
body.rec .phone   { transform:scale(1.82); } /* enlarge the device to fill the vertical stage */
```
```js
if (location.search.includes('rec')) document.body.classList.add('rec');
```
The page body IS the recorded 1080×1920 frame: the device/console sits centered on a dark brand backdrop. `capture.js` navigates here and calls your animation functions.

## Hero animations (expose as window.fn)
Trigger each with a global function so `capture.js` can drive it precisely (`window.playSearch()` etc). Reset-then-play, using a cancellation token so re-runs don't overlap. Patterns that read well on camera:
- **Ask → answer**: focus input → voice waveform bars → typewriter the query → result card slides up → rows stagger in.
- **Long-press → generate**: button scales + turns "recording" + waveform → release → typewriter fills a structured record → a green "已写入/done" check.
- **Dashboard登场**: boot logo → nav items stagger → KPI cards rise → numbers roll 0→target (requestAnimationFrame ease-out) → progress bars fill.
- **Trust close-up**: dim the screen, scale one KPI (e.g. "合规拦截 24") up with a colored ring + shield — the片尾 payoff.

Keep motion deliberate and a little slow; product demos win on clarity, not flash.

## Number roll (reusable)
```js
function roll(el,to,ms){const s=performance.now();(function f(n){const p=Math.min(1,(n-s)/ms),e=1-Math.pow(1-p,3);
  el.textContent=Math.round(to*e); if(p<1)requestAnimationFrame(f);})(performance.now());}
```

## Serve + record
Serve the folder (`python3 -m http.server 8731`), then `node scripts/capture.js`. Each segment records to `build/ui_<name>.webm`. Then `build.sh` trims/captions/concats. See `pipeline-gotchas.md` for the timing-probe step — it's essential.
