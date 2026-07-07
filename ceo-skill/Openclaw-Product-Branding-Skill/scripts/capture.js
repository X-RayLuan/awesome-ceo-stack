// Record UI-animation segments to webm + render caption PNGs, via headless Chrome.
// Adapt SEGMENTS / CAPTIONS to your project, serve your HTML on :8731, then: node capture.js
// IMPORTANT: close any other Chrome using the default profile (e.g. an MCP browser) first,
// or you'll get navigation timeouts fighting over the same Chrome instance.
const { chromium } = require('playwright');
const fs = require('fs'); const path = require('path');

const BASE = 'http://localhost:8731';           // where your prototype HTML is served
const OUT  = path.join(__dirname, '..', 'build');
const W = 1080, H = 1920;

// One entry per UI segment: [name, url(with ?rec=1), window.fn to trigger, record ms, pre-trigger ms]
const SEGMENTS = [
  ['intro',  'dashboard.html?rec=1', 'playIntro',      9000, 400],
  ['heroA',  'index.html?rec=1',     'playSearch',    12000, 500],
  ['heroB',  'index.html?rec=1',     'playPrep',      11000, 500],
  ['heroC',  'index.html?rec=1',     'playRecord',     8000, 400],
  ['outro',  'dashboard.html?rec=1', 'playCompliance', 8000, 400],
];

// One line per FINAL segment (order = timeline). **bold** renders as highlight color.
const CAPTIONS = [
  ['p1', '第一条痛点，一句话戳中'],
  ['p2', '第二条痛点'],
  ['p3', '第三条痛点'],
  ['p4', '第四条痛点'],
  ['intro',  '**你的产品**——一句话定位'],
  ['heroA',  '**卖点A**：最直观的证明'],
  ['heroB',  '**卖点B**'],
  ['heroC',  '**卖点C**：自动化爽点'],
  ['outro',  '信任点收尾，**过红线**'],
];

const sleep = ms => new Promise(r => setTimeout(r, ms));

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ channel: 'chrome' });  // reuse system Chrome (no download)

  for (const [name, url, fn, dur, pre] of SEGMENTS) {
    const ctx = await browser.newContext({
      viewport: { width: W, height: H }, deviceScaleFactor: 1,
      recordVideo: { dir: OUT, size: { width: W, height: H } },
    });
    const page = await ctx.newPage();
    await page.goto(`${BASE}/${url}`, { waitUntil: 'load' });   // 'load', NOT 'networkidle' (favicon polling hangs)
    await sleep(pre);
    await page.evaluate(f => window[f] && window[f](), fn);
    await sleep(dur);
    const video = page.video();
    await ctx.close();                                          // finalizes the webm
    fs.renameSync(await video.path(), path.join(OUT, `ui_${name}.webm`));
    console.log('recorded ui_' + name);
  }

  const cap = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  for (const [id, text] of CAPTIONS) {
    await cap.goto(`${BASE}/caption.html?t=${encodeURIComponent(text)}`);
    await sleep(150);
    await cap.screenshot({ path: path.join(OUT, `cap_${id}.png`), omitBackground: true }); // transparent
    console.log('caption cap_' + id);
  }
  await browser.close();
  console.log('CAPTURE DONE');
})().catch(e => { console.error('CAPTURE ERROR', e); process.exit(1); });
