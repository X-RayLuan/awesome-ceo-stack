#!/usr/bin/env bash
# 豆包/火山 语音合成大模型 (单向流式 HTTP) -> mp3
# usage: ./tts.sh "文本" out.mp3 [speaker]
# Requires: DOUBAO_TTS_KEY in env (火山控制台 > API Key，新版单头鉴权).
# Docs: https://www.volcengine.com/docs/6561/2528925  (音色列表: /docs/6561/1257544)
set -euo pipefail
KEY="${DOUBAO_TTS_KEY:?set DOUBAO_TTS_KEY}"
TEXT="$1"; OUT="$2"; SPK="${3:-zh_male_cixingjieshuonan_uranus_bigtts}"  # 磁性解说男，适合商务旁白
RAW="$(mktemp)"
BODY=$(python3 -c 'import json,sys;print(json.dumps({"req_params":{"text":sys.argv[1],"speaker":sys.argv[2],"audio_params":{"format":"mp3","sample_rate":44100}}}))' "$TEXT" "$SPK")
curl -s -N --max-time 90 -X POST 'https://openspeech.bytedance.com/api/v3/tts/unidirectional' \
  -H "X-Api-Key: $KEY" -H 'X-Api-Resource-Id: seed-tts-2.0' -H 'Content-Type: application/json' \
  -d "$BODY" > "$RAW"
python3 - "$RAW" "$OUT" <<'PY'
import re,base64,sys
raw=open(sys.argv[1],'r',errors='ignore').read()
chunks=re.findall(r'"data":"([^"]*)"',raw)          # response = HTTP-chunked JSON, base64 audio in each "data"
if not chunks:
    print("TTS FAIL",set(re.findall(r'"code":\s*(\d+)',raw)),re.findall(r'"message":"([^"]*)"',raw)[:2]); sys.exit(1)
open(sys.argv[2],'wb').write(b''.join(base64.b64decode(c) for c in chunks if c))
print("ok",sys.argv[2])
PY
rm -f "$RAW"
