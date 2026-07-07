# 豆包 / 火山引擎 语音合成大模型 (TTS) — voiceover

New-console single-header auth. Get the key from 火山控制台 > API Key 管理 → env `DOUBAO_TTS_KEY`.
Docs: https://www.volcengine.com/docs/6561/2528925 (单向流式 HTTP) · 音色列表 /docs/6561/1257544

## Endpoint (streaming HTTP, non-WebSocket, easiest)
`POST https://openspeech.bytedance.com/api/v3/tts/unidirectional`
Headers:
```
X-Api-Key: $DOUBAO_TTS_KEY
X-Api-Resource-Id: seed-tts-2.0
Content-Type: application/json
```
Body:
```json
{ "req_params": {
    "text": "要合成的文本",
    "speaker": "zh_male_cixingjieshuonan_uranus_bigtts",
    "audio_params": { "format": "mp3", "sample_rate": 44100 }
} }
```

## Response = HTTP-chunked JSON stream
Multiple JSON objects stream back; each has a base64 audio fragment in `"data"`. Concatenate **all** `data` fragments in order and base64-decode → the full mp3. (`scripts/tts.sh` greps `"data":"..."`, joins, decodes.) Final line carries a success code (`0` / `20000000`).

## Auth / resource errors
- `[resource_id=volc.service_type.10074] requested resource not granted` = the **seed-audio** (`/api/v3/tts/create`) model isn't enabled for this key. Use **this** endpoint (`/unidirectional`, resource `seed-tts-2.0`) instead — that's the standard 语音合成大模型 most accounts have.
- `X-Api-Key` is the new-console single header. Old console used `X-Api-App-Id` + `X-Api-Access-Key`.

## Voices for a business promo (male, all `..._uranus_bigtts`)
- `zh_male_cixingjieshuonan` — 磁性解说男 (default: confident, restrained, ideal for B2B)
- `zh_male_gaolengchenwen` — 高冷沉稳
- `zh_male_shenyeboke` — 深夜播客 (warm/calm)
- `zh_male_jieshuoxiaoming` — 解说男
Full list + audition: docs 6561/1257544. Female example: `zh_female_vv_uranus_bigtts`.

## Tuning
`audio_params` also takes `speech_rate` [-50,100] and `loudness_rate`, `pitch_rate`. Keep default rate for narration. Generate one clip per script line, then align with `adelay` in `gen_vo.sh`.
