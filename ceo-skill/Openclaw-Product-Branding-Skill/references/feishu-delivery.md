# Feishu (Lark) delivery

Uses `lark-cli`. Two ways to hand off the finished `final.mp4`.

## A. Post as a playable video message (recommended, no extra scopes)
Bots can upload+send media. Video messages need a cover image.
```bash
ffmpeg -v error -ss 24 -i final.mp4 -frames:v 1 assets/cover.png     # any strong frame
lark-cli im +messages-send --as bot --chat-id oc_xxxxx \
  --video final.mp4 --video-cover assets/cover.png
```
Paths must be cwd-relative (absolute / `..` are rejected). Plays inline, forwardable.

## B. Drive share link
`lark-cli drive +upload` needs the **user** identity with scopes `drive:file:upload drive:drive.metadata:readonly`. If missing you'll get `missing_scope`. Re-auth (`lark-cli auth login --scope ...`) is a device-code OAuth flow — **only do it in a p2p (private) chat**, never in a group, or the verification URL leaks to whoever clicks first and binds the token to the wrong identity. After upload, set link-share to "anyone with link" and post the URL.

## Pitfalls
- **Don't pipe the send command through a JSON parser that reads to EOF** — `lark-cli` prints `uploading video…` progress before the JSON, and if your parser errors it can still have completed the send. Result: an accidental duplicate. Capture raw output, or check `ok` after. If you double-sent, recall one with:
  `lark-cli im messages delete --as bot --message-id <om_...> --yes` (high-risk-write needs `--yes`).
- Bots generally **cannot list chat messages** (`user_unauthorized`), so you can't always verify dupes via API — send carefully the first time.
