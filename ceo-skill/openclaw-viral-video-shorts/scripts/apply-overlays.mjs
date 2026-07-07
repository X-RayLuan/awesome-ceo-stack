#!/usr/bin/env node
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { spawnSync } from "node:child_process";
import { createCanvas, registerFont } from "canvas";

function usage() {
  console.error(`Usage:
  node scripts/apply-overlays.mjs overlays.json --output final.mp4

overlays.json:
{
  "video": "seedance.mp4",
  "captions": [
    {"text":"Clear caption", "start":0.2, "end":2.8, "position":"bottom"}
  ],
  "images": [
    {"src":"app-ui.png", "start":3, "end":6, "x":560, "y":410, "width":300}
  ]
}`);
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const spec = args[0];
  const outputIndex = args.indexOf("--output");
  if (!spec || outputIndex === -1 || !args[outputIndex + 1]) {
    usage();
    process.exit(2);
  }
  return { spec: resolve(spec), output: resolve(args[outputIndex + 1]) };
}

function defaultFontFile() {
  const candidates = [
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/Library/Fonts/Arial Unicode.ttf",
  ];
  return candidates.find((file) => existsSync(file));
}

function wrapLines(ctx, text, maxWidth) {
  const chars = Array.from(String(text ?? "").replace(/\s+/g, " ").trim());
  const lines = [];
  let line = "";
  for (const char of chars) {
    const test = line + char;
    if (line && ctx.measureText(test).width > maxWidth) {
      lines.push(line);
      line = char.trimStart();
    } else {
      line = test;
    }
  }
  if (line) lines.push(line);
  return lines;
}

function renderCaptionPng(item, index, tmpDir) {
  const width = 720;
  const height = 1280;
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext("2d");
  const fontFile = item.fontFile || defaultFontFile();
  const family = `CaptionFont${index}`;
  if (fontFile) {
    registerFont(fontFile, { family });
  }
  const fontSize = Math.max(12, Number(item.fontSize) || 58);
  ctx.font = `700 ${fontSize}px ${fontFile ? family : "Helvetica"}`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.lineJoin = "round";
  const lines = wrapLines(ctx, item.text, Number(item.maxWidth) || 620);
  const lineHeight = fontSize * 1.16;
  const blockHeight = lines.length * lineHeight;
  const yBase = Number.isFinite(Number(item.y))
    ? Number(item.y)
    : item.position === "top"
      ? 150
      : item.position === "center"
        ? height / 2
        : height - 180;
  const x = Number.isFinite(Number(item.x)) ? Number(item.x) : width / 2;
  const startY = yBase - blockHeight / 2 + lineHeight / 2;
  lines.forEach((line, lineIndex) => {
    const y = startY + lineIndex * lineHeight;
    ctx.strokeStyle = item.borderColor || "rgba(0,0,0,0.92)";
    ctx.lineWidth = Number(item.borderWidth) || 10;
    ctx.strokeText(line, x, y);
    ctx.fillStyle = item.color || "#ffffff";
    ctx.fillText(line, x, y);
  });
  const out = join(tmpDir, `caption-${index}.png`);
  writeFileSync(out, canvas.toBuffer("image/png"));
  return out;
}

function run(cmd, args) {
  const res = spawnSync(cmd, args, { cwd: tmp, stdio: "inherit" });
  if (res.status !== 0) {
    process.exit(res.status || 1);
  }
}

const { spec, output } = parseArgs(process.argv);
const root = dirname(spec);
const config = JSON.parse(readFileSync(spec, "utf8"));
const inputVideo = isAbsolute(config.video) ? config.video : resolve(root, config.video);
mkdirSync(dirname(output), { recursive: true });

const tmp = mkdtempSync(join(tmpdir(), "viral-overlays-"));

const captionOverlays = (Array.isArray(config.captions) ? config.captions : [])
  .filter((item) => item && item.text && Number(item.end) > Number(item.start));
const captionImages = captionOverlays.map((item, index) => renderCaptionPng(item, index, tmp));
const imageOverlays = [
  ...(Array.isArray(config.images) ? config.images : []),
  ...captionOverlays.map((item, index) => ({
    src: captionImages[index],
    start: item.start,
    end: item.end,
    x: 0,
    y: 0,
    width: 720,
  })),
];
const args = ["-y", "-i", inputVideo];
for (const image of imageOverlays) {
  const src = isAbsolute(image.src) ? image.src : resolve(root, image.src);
  args.push("-i", src);
}

const filters = [];
let current = "[0:v]";
imageOverlays.forEach((image, index) => {
  const input = `[${index + 1}:v]`;
  const scaled = `[img${index}]`;
  const out = `[v${index}]`;
  const width = Math.max(1, Number(image.width) || 300);
  const x = Number.isFinite(Number(image.x)) ? Number(image.x) : 0;
  const y = Number.isFinite(Number(image.y)) ? Number(image.y) : 0;
  const start = Number.isFinite(Number(image.start)) ? Number(image.start) : 0;
  const end = Number.isFinite(Number(image.end)) ? Number(image.end) : 99999;
  filters.push(`${input}scale=${width}:-1${scaled}`);
  filters.push(`${current}${scaled}overlay=${x}:${y}:enable='between(t,${start},${end})'${out}`);
  current = out;
});

const finalVideo = "[vout]";
filters.push(`${current}format=yuv420p${finalVideo}`);
args.push("-filter_complex", filters.join(";"));
args.push("-map", finalVideo, "-map", "0:a?", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", "-movflags", "+faststart", output);

run("ffmpeg", args);
