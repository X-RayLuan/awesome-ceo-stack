#!/usr/bin/env bash
# KIE.ai: image gen (nano-banana-2) + image-to-video (bytedance/seedance-2)
# usage:
#   ./kie.sh img "<prompt>" [aspect] [resolution]        -> prints image url
#   ./kie.sh vid <first_frame_url> "<prompt>" [aspect] [dur]  -> prints video url
# Requires: KIE_API_KEY in env.  Docs: https://docs.kie.ai
set -euo pipefail
KEY="${KIE_API_KEY:?set KIE_API_KEY}"
BASE="https://api.kie.ai/api/v1/jobs"

create () { # $1 = json body -> echoes taskId
  curl -s -X POST "$BASE/createTask" \
    -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" -d "$1" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("data",{}).get("taskId") or ("ERR "+json.dumps(d)))'
}
poll () { # $1 = taskId -> echoes first result url (polls ~6 min)
  local id="$1" i resp state
  for i in $(seq 1 90); do
    resp=$(curl -s "$BASE/recordInfo?taskId=$id" -H "Authorization: Bearer $KEY")
    state=$(printf '%s' "$resp" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("data",{}).get("state",""))' 2>/dev/null || echo "")
    if [ "$state" = "success" ]; then
      printf '%s' "$resp" | python3 -c 'import sys,json;d=json.load(sys.stdin)["data"];print(json.loads(d["resultJson"])["resultUrls"][0])'; return 0
    elif [ "$state" = "fail" ]; then
      echo "FAIL: $(printf '%s' "$resp" | python3 -c 'import sys,json;d=json.load(sys.stdin)["data"];print(d.get("failMsg") or d.get("failCode"))')" >&2; return 1
    fi
    sleep 4
  done
  echo "TIMEOUT $id" >&2; return 1
}

case "${1:-}" in
  img)
    prompt="$2"; aspect="${3:-9:16}"; reso="${4:-2K}"
    body=$(python3 -c 'import json,sys;print(json.dumps({"model":"nano-banana-2","input":{"prompt":sys.argv[1],"aspect_ratio":sys.argv[2],"resolution":sys.argv[3],"output_format":"png"}}))' "$prompt" "$aspect" "$reso")
    tid=$(create "$body"); echo "img taskId=$tid" >&2; poll "$tid" ;;
  vid)
    frame="$2"; prompt="$3"; aspect="${4:-9:16}"; dur="${5:-5}"
    body=$(python3 -c 'import json,sys;print(json.dumps({"model":"bytedance/seedance-2","input":{"prompt":sys.argv[1],"first_frame_url":sys.argv[2],"resolution":"720p","aspect_ratio":sys.argv[3],"duration":int(sys.argv[4]),"generate_audio":False,"nsfw_checker":False}}))' "$prompt" "$frame" "$aspect" "$dur")
    tid=$(create "$body"); echo "vid taskId=$tid" >&2; poll "$tid" ;;
  *) echo "usage: kie.sh img|vid ..." >&2; exit 2 ;;
esac
