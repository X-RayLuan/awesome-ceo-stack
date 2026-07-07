#!/usr/bin/env bash
# Assemble the silent cut: painpoint clips + recorded UI webms, each trimmed, caption-overlaid,
# normalized to 1080x1920/30fps, then concatenated.
# Adapt the SEGS table. For UI webms, pick ss/dur by PROBING frames (see references/pipeline-gotchas.md):
#   ffmpeg -ss <t> -i build/ui_x.webm -frames:v 1 probe.png   # find when the animation actually completes
set -euo pipefail
cd "$(dirname "$0")/.."
B=build; mkdir -p "$B/seg"

# name | source | ss | dur | caption.png
SEGS=(
  "p1|assets/paintpoint_01.mp4|0|3|$B/cap_p1.png"
  "p2|assets/paintpoint_02.mp4|0|3|$B/cap_p2.png"
  "p3|assets/paintpoint_03.mp4|0|3|$B/cap_p3.png"
  "p4|assets/paintpoint_04.mp4|0|3|$B/cap_p4.png"
  "intro|$B/ui_intro.webm|0.3|9|$B/cap_intro.png"
  "heroA|$B/ui_heroA.webm|0.6|9.4|$B/cap_heroA.png"
  "heroB|$B/ui_heroB.webm|0.6|9.4|$B/cap_heroB.png"
  "heroC|$B/ui_heroC.webm|1.0|13.5|$B/cap_heroC.png"
  "outro|$B/ui_outro.webm|0.3|6.5|$B/cap_outro.png"
)

: > "$B/list.txt"
for s in "${SEGS[@]}"; do
  IFS='|' read -r name src ss dur cap <<< "$s"
  echo ">> $name ($src ss=$ss t=$dur)"
  # NOTE: caption PNG must be a looped input (-loop 1 -t) or a single frame won't fill the timeline.
  ffmpeg -y -v error -ss "$ss" -t "$dur" -i "$src" -loop 1 -framerate 30 -t "$dur" -i "$cap" \
    -filter_complex "[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=30[v];[1:v]format=yuva420p,fade=t=in:st=0:d=0.35:alpha=1[c];[v][c]overlay=0:0:shortest=1[o]" \
    -map "[o]" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -an "$B/seg/seg_$name.mp4"
  echo "file 'seg/seg_$name.mp4'" >> "$B/list.txt"
done

ffmpeg -y -v error -f concat -safe 0 -i "$B/list.txt" -c copy silent.mp4
echo "DONE -> silent.mp4"
ffprobe -v error -show_entries format=duration -of default=nw=1 silent.mp4
