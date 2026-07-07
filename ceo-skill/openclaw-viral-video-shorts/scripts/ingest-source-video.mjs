#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, resolve } from 'node:path';

function argValue(flag, fallback = null) {
  const index = process.argv.indexOf(flag);
  return index === -1 ? fallback : process.argv[index + 1] || fallback;
}

function hasFlag(flag) {
  return process.argv.includes(flag);
}

function fail(message) {
  console.error(`[ingest-source-video] ${message}`);
  process.exit(1);
}

function runYtDlp(args) {
  return execFileSync('yt-dlp', args, {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    timeout: 180_000,
  });
}

function safeName(value) {
  return String(value || 'source-video')
    .toLowerCase()
    .replace(/https?:\/\//g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80) || 'source-video';
}

const url = argValue('--url');
if (!url) fail('Usage: ingest-source-video.mjs --url <instagram|tiktok|youtube-url> [--out <dir>] [--metadata-only]');

const outDir = resolve(argValue('--out', resolve(process.cwd(), 'viral-shorts', safeName(url), new Date().toLocaleDateString('sv-SE', { timeZone: 'Asia/Shanghai' }))));
mkdirSync(outDir, { recursive: true });

let metadata;
try {
  metadata = JSON.parse(runYtDlp(['--dump-json', '--no-playlist', url]));
} catch (error) {
  fail(`yt-dlp metadata read failed. If this is a private/login-gated video, download/upload the mp4 manually. ${error.stderr || error.message}`);
}

const metadataPath = resolve(outDir, 'source-metadata.json');
writeFileSync(metadataPath, `${JSON.stringify(metadata, null, 2)}\n`);

let videoPath = null;
if (!hasFlag('--metadata-only')) {
  try {
    runYtDlp([
      '--no-playlist',
      '-f',
      'bv*+ba/b',
      '--merge-output-format',
      'mp4',
      '-o',
      resolve(outDir, 'source.%(ext)s'),
      url,
    ]);
    const candidates = readdirSync(outDir)
      .filter((file) => /^source\.(mp4|mov|webm|mkv)$/i.test(file))
      .map((file) => resolve(outDir, file));
    videoPath = candidates.find((path) => existsSync(path)) || null;
  } catch (error) {
    fail(`yt-dlp video download failed after metadata succeeded. Try --metadata-only or upload the video file. ${error.stderr || error.message}`);
  }
}

const summaryPath = resolve(outDir, 'source-analysis-seed.md');
const title = metadata.title || 'Untitled source video';
const duration = metadata.duration ?? null;
const uploader = metadata.uploader || metadata.channel || metadata.creator || 'unknown';
const webpageUrl = metadata.webpage_url || url;
writeFileSync(summaryPath, [
  `# Source Video Analysis Seed`,
  ``,
  `- URL: ${webpageUrl}`,
  `- Title: ${title}`,
  `- Uploader: ${uploader}`,
  `- Duration: ${duration == null ? 'unknown' : `${duration}s`}`,
  `- Local video: ${videoPath || 'metadata-only'}`,
  `- Metadata: ${metadataPath}`,
  ``,
  `Next step: sample frames from the local video, then extract viral structure. Do not copy the creator identity, exact wording, audio, or scene content.`,
].join('\n'));

console.log(JSON.stringify({
  ok: true,
  url: webpageUrl,
  title,
  uploader,
  duration,
  outDir,
  metadataPath,
  videoPath,
  summaryPath,
}, null, 2));
