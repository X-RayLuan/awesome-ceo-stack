#!/bin/zsh
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <deck.html> <output.pptx> [template.pptx]" >&2
  exit 1
fi

HTML_PATH="$1"
OUTPUT_PATH="$2"
TEMPLATE_PATH="${3:-$HOME/Desktop/Cornerstone Wiki/柯纳仕咨询与培训 Intro_CN 咨询版 V1.2.pptx}"

python3 "$HOME/.openclaw/workspace-smart/html_to_pptx.py" "$HTML_PATH" "$OUTPUT_PATH" --template "$TEMPLATE_PATH"
