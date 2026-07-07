#!/usr/bin/env bash
# Verify the toolchain this skill needs. Run first.
ok(){ printf "  ✓ %s\n" "$1"; }; bad(){ printf "  ✗ %s\n" "$1"; MISS=1; }
echo "== product-branding toolchain =="
command -v ffmpeg >/dev/null && ok "ffmpeg $(ffmpeg -version|head -1|awk '{print $3}')" || bad "ffmpeg missing"
ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libx264 && ok "libx264" || bad "libx264 (needed for H.264 output)"
ffmpeg -hide_banner -filters 2>/dev/null | grep -qw drawtext && ok "drawtext (optional)" || echo "  · no drawtext -> captions via HTML PNG overlay (expected, fine)"
command -v node >/dev/null && ok "node $(node -v)" || bad "node missing"
node -e "require('playwright')" 2>/dev/null && ok "playwright" || echo "  · playwright not installed -> run: npm i playwright"
[ -n "${KIE_API_KEY:-}" ] && ok "KIE_API_KEY set" || bad "KIE_API_KEY unset (real-person B-roll)"
[ -n "${DOUBAO_TTS_KEY:-}" ] && ok "DOUBAO_TTS_KEY set" || bad "DOUBAO_TTS_KEY unset (voiceover)"
command -v lark-cli >/dev/null && ok "lark-cli (Feishu delivery, optional)" || echo "  · lark-cli not found (only needed for Feishu delivery)"
[ -n "${MISS:-}" ] && { echo "-> fix the ✗ items above"; exit 1; } || echo "-> ready"
