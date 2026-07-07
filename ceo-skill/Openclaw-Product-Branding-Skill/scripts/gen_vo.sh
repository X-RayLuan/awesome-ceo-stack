#!/usr/bin/env bash
# Per-segment TTS narration -> align to segment start offsets -> mix with BGM -> mux into video.
# Adapt LINES (offset must match the cumulative segment starts in build.sh). Put music at assets/bgm.mp3.
set -euo pipefail
cd "$(dirname "$0")/.."
B=build; mkdir -p "$B/vo"
VID="silent.mp4"; DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VID")

# id | offset(ms into the video) | spoken text
# Fast-cut sections (e.g. 4x3s painpoints): use ONE continuous line spanning the whole section,
# NOT one per clip — short lines are 5-6s each and would overlap into mush.
LINES=(
  "open|300|把痛点段用一句连贯开场白盖满，别逐条配。"
  "intro|12000|你的产品，一句话定位。"
  "heroA|21000|卖点A：最直观的证明。"
  "heroB|30400|卖点B。"
  "heroC|39800|卖点C：自动化爽点。"
  "outro|53300|信任点收尾，过红线。"
)

echo ">> TTS"
for l in "${LINES[@]}"; do IFS='|' read -r id off text <<< "$l"; ./scripts/tts.sh "$text" "$B/vo/vo_$id.mp3" >/dev/null; done

echo ">> align voiceover track"
inputs=(); fc=""; labels=""; i=0
for l in "${LINES[@]}"; do
  IFS='|' read -r id off text <<< "$l"
  inputs+=(-i "$B/vo/vo_$id.mp3"); fc+="[$i:a]adelay=${off}|${off}[a$i];"; labels+="[a$i]"; i=$((i+1))
done
fc+="${labels}amix=inputs=$i:normalize=0:dropout_transition=0[vo]"
ffmpeg -y -v error "${inputs[@]}" -filter_complex "$fc" -map "[vo]" -ac 2 "$B/voiceover.mp3"

echo ">> mux voiceover (+ BGM) into video"
if [ -f assets/bgm.mp3 ]; then
  ffmpeg -y -v error -i "$VID" -i "$B/voiceover.mp3" -i assets/bgm.mp3 \
    -filter_complex "[1:a]volume=2.0,apad[v0];[2:a]atrim=0:$DUR,asetpts=PTS-STARTPTS,volume=0.18,afade=t=in:st=0:d=0.8,afade=t=out:st=$(python3 -c "print($DUR-2)"):d=2[bg];[v0][bg]amix=inputs=2:normalize=0:dropout_transition=0,atrim=0:$DUR[a]" \
    -map 0:v:0 -map "[a]" -c:v copy -c:a aac -b:a 192k final.mp4
else
  ffmpeg -y -v error -i "$VID" -i "$B/voiceover.mp3" -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k final.mp4
fi
echo "DONE -> final.mp4"
ffprobe -v error -show_entries format=duration:stream=codec_type -of default=nw=1 final.mp4
