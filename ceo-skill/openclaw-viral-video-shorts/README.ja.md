<!-- LANGS -->
[English](README.md) · [简体中文](README.zh-CN.md) · **日本語** · [Español](README.es.md)

# OpenClaw バイラル動画ショート生成

**サプライヤー / 商品ページ**を **30秒の縦型（9:16）バイラルショート**に変える OpenClaw スキル + エンドツーエンドのパイプライン：

1. **発見**：Instagram / TikTok / Shorts で実際に伸びているリファレンス動画を探す
2. **抽出**：再利用できるバイラル*構造*（フック → 課題 → デモ → ペイオフ → CTA）をオリジナル台本に落とし込む
3. **生成**：実物素材から動画を作る —— AI 画像→動画クリップ + 実写映像 + AI ナレーション + ロイヤリティフリー BGM を `ffmpeg` で合成

> 基本原則：**構造を学び、アイデンティティ/内容は決してコピーしない。** 移すのはテンポ・フック機構・感情・シーンの論理だけ —— 台本・映像・声はすべてオリジナル。

本書は **発見 → 台本 → 生成** の全工程を、実際に最後まで走らせた記録です（ケース：ZekSmart LED ミラーのショート）。`SKILL.md` はエージェント向けワークフロー、本ファイルは人/オペレーター向けの実行手順書です。

---

## パイプライン全体像

```
[1] リファレンス発見    Exa + Tavily  → IG/TikTok リール
        ↓
[2] 構造を抽出          フック/課題/デモ/ペイオフ/CTA → 台本 + 字幕
        ↓
[3] 商品素材を収集      Alibaba 商品画像  /  アップロード映像(zip)
        ↓
[4] クリップ生成        火山方舟 "Seedance 2.0" 画像→動画（9:16, 720p, 各5秒）
        ↓
[5] ナレーション        ElevenLabs TTS（1行ずつ、5秒スロットに同期）
        ↓
[6] BGM                 Pixabay ロイヤリティフリー（CDN 直リンク mp3）
        ↓
[7] 合成                ffmpeg：正規化 → 字幕(PNG重畳) → 連結 → サイドチェイン ducking ミックス → 多重化
        ↓
[8] (任意) 納品         最終 mp4 をアップロード / 送信
```

---

## 前提条件

**CLI ツール**

| ツール | 用途 | 備考 |
|--------|------|------|
| `ffmpeg` / `ffprobe` | 音声・映像処理すべて | **`drawtext` が無い場合あり**（libfreetype 欠如）→ 字幕は PNG 重畳で対応、[落とし穴](#落とし穴と教訓)参照 |
| `python3` + `Pillow` | 字幕 PNG、API 呼び出し | `pip install --break-system-packages Pillow` |
| Playwright（ブラウザ） | Pixabay 音源 URL 抽出 | BGM ステップのみ必要 |
| `yt-dlp`（任意） | リファレンスをローカル mp4 化 | 任意。検索スニペットからでも構造抽出可 |

**API キー（環境変数で。リポジトリには絶対にコミットしない）**

```bash
export EXA_API_KEY=...          # バイラル参考の発見
export TAVILY_API_KEY=...       # 検索 + ページ抽出（Alibaba, Pixabay 代替）
export ARK_API_KEY=...          # 火山方舟 / Seedance 2.0 動画生成
export ELEVENLABS_API_KEY=...   # ナレーション TTS
export KIE_API_KEY=...          # 任意：GPT-Image アバター生成（スキル既定経路）
```

---

## [1] リファレンス発見

ニッチで実際にデータの出ているショートを探す。**両エンジン**を使う（カバレッジが異なる）。

```bash
# Exa —— 意味検索（注意：Exa は instagram.com ドメイン非対応。
# tiktok/youtube を指定し、instagram は Tavily に任せる）
curl -s -X POST https://api.exa.ai/search -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"viral LED mirror smart mirror short video reel",
       "numResults":8,
       "includeDomains":["tiktok.com","youtube.com"]}'

# Tavily —— instagram.com に対応 + スニペット本文を返す
curl -s -X POST https://api.tavily.com/search -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",
       \"query\":\"viral LED mirror tiktok instagram reel hook\",
       \"search_depth\":\"advanced\",\"max_results\":6,
       \"include_domains\":[\"tiktok.com\",\"instagram.com\"]}"
```

任意：1本をローカル mp4 に取り込み、フレーム単位で分析（`yt-dlp` 必要）：

```bash
node scripts/ingest-source-video.mjs --url "<reel-url>" --out source
```

---

## [2] バイラル構造を抽出 → 台本

参考を再利用可能な構造に蒸留し、その上に**オリジナル**の商品台本を書く。

```json
{
  "viral_pattern": "退屈-vs-感動 → デモ → 裏付け → CTA",
  "emotional_driver": "憧れ + 満足感",
  "structure": ["0-5 フック", "5-15 デモ", "15-25 裏付け", "25-30 CTA"]
}
```

安定する 30秒構成（6 × 5秒シーン）。各シーンに短い字幕/ナレーション1行：

| 時間 | シーン | 字幕 / ナレーション |
|------|--------|---------------------|
| 0–5 | フック（最もスクロールを止める画） | "Your bathroom mirror? So boring." |
| 5–10 | 機能デモ | "Touch to dim. Three light colors." |
| 10–15 | 種類 / 規模 | "Round, oval, any shape, any size." |
| 15–20 | **実写の裏付け**（工場 / 検品） | "Made in our own factory." |
| 20–25 | 信頼の機能 | "Anti-fog, bluetooth, memory function." |
| 25–30 | CTA | "OEM/ODM — DM us for wholesale pricing!" |

---

## [3] 商品素材を収集

実用的な2系統：

**A. Alibaba / 1688 ストアの商品画像**（CDN のサイズ接尾辞を除去して原寸を取得）：

```bash
curl -s -X POST https://api.tavily.com/extract -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",\"urls\":[\"<ストア一覧url>\"],\"extract_depth\":\"advanced\"}" \
  | python3 -c "import sys,json,re; t=json.load(sys.stdin)['results'][0]['raw_content']; \
[print(re.sub(r'_\d+x\d+\.jpg$','.jpg',u)) for u in set(re.findall(r'https://s\.alicdn\.com/@sc04/kf/[^\"\s]+?\.jpg', t))]"
# ブラウザ UA + referer を付けないと CDN が 403 になることがある
curl -sL -A "Mozilla/5.0" -e "https://example.en.alibaba.com/" "<画像url>" -o img01.jpg
```

**B. クライアントがアップした実写**（例：工場検品の `.zip`）。中文 Windows の zip は **GBK** 名で、macOS `unzip` が失敗する → Python で再エンコードして展開：

```python
import zipfile, os
z = zipfile.ZipFile("footage.zip"); os.makedirs("ex", exist_ok=True); i = 0
for info in z.infolist():
    if info.is_dir(): continue
    try: name = info.filename.encode('cp437').decode('gbk')   # GBK 名を修復
    except Exception: name = info.filename
    if os.path.splitext(name)[1].lower() in ('.mp4', '.mov'):
        i += 1
        open(f"ex/clip{i:02d}.mp4", "wb").write(z.open(info).read())
```

---

## [4] クリップ生成 —— 火山方舟 "Seedance 2.0"（画像→動画）

各商品画像を先頭フレームとして入力し、Seedance が動かす（点灯、寄り、曇り取れ、色変化…）。

```bash
# タスク作成 —— 画像→動画。image_url は公開 URL か data:base64。
# 生成パラメータはプロンプト末尾にテキストフラグで付与。
curl -s -X POST "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks" \
  -H "Authorization: Bearer $ARK_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"doubao-seedance-2-0-fast-260128",
       "content":[
         {"type":"text","text":"LED mirror lights turn on, slow cinematic push-in, premium reveal --resolution 720p --ratio 9:16 --duration 5 --camerafixed false"},
         {"type":"image_url","image_url":{"url":"<公開画像url>"}}
       ]}'
# → {"id":"cgt-..."}

# status == "succeeded" までポーリングし、content.video_url を読む
curl -s "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks/<id>" \
  -H "Authorization: Bearer $ARK_API_KEY"
```

- モデル：`doubao-seedance-2-0-260128`（高品質）/ `doubao-seedance-2-0-fast-260128`（高速・低コスト）。
- **全シーンのタスクを並列投入**してまとめてポーリング —— 生成（各約3〜6分）がボトルネック。
- 各クリップは 9:16 720p 約5秒。

---

## [5] ナレーション —— ElevenLabs

シーンごとに短い1行を生成し、各5秒地点へ配置。

```bash
# 若い女性声、例：「Jessica」（陽気・明るい・温かい）
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/cgSgspJ2msm6clMCkdW9?output_format=mp3_44100_128" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
  -d '{"text":"Your bathroom mirror? So boring.",
       "model_id":"eleven_multilingual_v2",
       "voice_settings":{"stability":0.4,"similarity_boost":0.8,"style":0.45,"use_speaker_boost":true}}' \
  -o vo1.mp3
```

`eleven_multilingual_v2` は中国語/日本語/スペイン語にも対応（ローカライズ可）。（キー無しの代替：macOS `say -v Samantha`。）

`adelay` で 0.3秒・5.3秒・10.3秒 … に配置し `amix` で30秒の音声トラックに。

---

## [6] BGM —— Pixabay（ロイヤリティフリー）

Pixabay の**公開 API は画像・動画のみで、音楽は API に無い**。検索ページは JS で音源 URL を読み込むため、ヘッドレスブラウザで CDN 直リンク mp3 を読み取り、ダウンロードする（CDN ファイル自体はキー不要）：

```js
// https://pixabay.com/music/search/upbeat/ に遷移後
() => {
  const found = new Set();
  document.querySelectorAll('script').forEach(s => {
    const m = (s.textContent||'').match(/https:\/\/cdn\.pixabay\.com\/audio\/[^"' ]+?\.mp3/g);
    if (m) m.forEach(u => found.add(u));
  });
  const btn = document.querySelector('button[aria-label*="Play" i]'); if (btn) btn.click();
  document.querySelectorAll('audio,source').forEach(a => a.src && found.add(a.src));
  return [...found];
}
```

```bash
curl -sL -A "Mozilla/5.0" -e "https://pixabay.com/" "<cdn音源url>" -o bgm.mp3
```

---

## [7] ffmpeg で合成

**各クリップを 720×1280、30fps に正規化。** 縦の AI クリップは切り抜きで埋め、横の実写はぼかし背景でフィット：

```bash
# 縦の AI クリップ
ffmpeg -y -i scene.mp4 -t 5 -vf "scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,fps=30" -an seg.mp4
# 横の実写 → ぼかし背景 9:16
ffmpeg -y -ss 30 -t 5 -i factory.mp4 -filter_complex \
  "[0:v]scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,boxblur=24:6[bg];\
   [0:v]scale=720:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2,fps=30" -an seg4.mp4
```

**字幕は PNG 重畳**（この ffmpeg に `drawtext` が無い）。Pillow で透明な字幕帯を描き、`overlay`：

```python
from PIL import Image, ImageDraw, ImageFont
f = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 46)
img = Image.new("RGBA", (720, 160), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
d.rounded_rectangle([60, 10, 660, 150], radius=24, fill=(0, 0, 0, 150))
d.text((360, 80), "Touch to dim", font=f, fill="white", anchor="mm")
img.save("cap.png")
```
```bash
ffmpeg -y -i seg.mp4 -i cap.png -filter_complex "[0:v][1:v]overlay=x=(W-w)/2:y=H-360" -an final_seg.mp4
ffmpeg -y -f concat -safe 0 -i concat.txt -c:v libx264 -pix_fmt yuv420p -r 30 video.mp4   # 全連結
```

**音声：サイドチェイン ducking** で BGM をナレーション下に潜らせ、無音区間で持ち上げる：

```bash
ffmpeg -y -i voice30.wav -i bgm_seg.wav -filter_complex \
 "[1]volume=0.55[bg];[bg][0]sidechaincompress=threshold=0.03:ratio=8:attack=15:release=350[duck];\
  [0][duck]amix=inputs=2:normalize=0,alimiter=limit=0.95[m]" -map "[m]" mixed.wav
# 無音動画に多重化
ffmpeg -y -i video.mp4 -i mixed.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -t 30 final.mp4
```

`volumedetect` で確認：全体ミックス平均 ≈ −15 dB、ナレーション無音区間で BGM が聞こえる（≈ −22 dB）こと。

---

## [8] 納品（任意）

`final.mp4`（720×1280、約30秒）を書き出す。投稿前に CapCut / 剪映 で**流行りのアプリ内サウンド**を当てる —— プラットフォームはネイティブのトレンド音源を優遇する。

---

## 落とし穴と教訓

実際にこのパイプラインで踏んだ問題 —— あなたも必ず踏む：

- **`drawtext` 無し ffmpeg** → `drawtext` で焼かず、**PNG 重畳**（Pillow）+ `overlay`。
- **`zsh` 配列は 1 始まり**（bash の 0 始まりと違う）→ `${arr[1]}` が先頭。ずれると静かに行が抜け/重複。
- **Exa は `instagram.com` を拒否**（`SOURCE_NOT_AVAILABLE`）→ Instagram は Tavily で。
- **Alibaba CDN 画像**はブラウザ `User-Agent` + `Referer` 無しで 403。`_480x480.jpg` 接尾辞を外すと原寸。
- **中文 Windows の GBK zip 名**で macOS `unzip` が失敗 → Python の `cp437→gbk` 再エンコードで展開。
- **Pixabay 音楽は公開 API に無い** → ヘッドレスブラウザでページを描画し、JS / `<audio>` から CDN mp3 を読む。
- **ミックス後に BGM が聞こえない** → *レベル*の問題。音楽を既知のラウドネスに正規化（例 `loudnorm I=-22`）し、無音区間を `volumedetect` で確認。裸の `volume=0.18` を信じない。
- **Seedance のレイテンシ** → 全クリップを並列投入してまとめてポーリング。直列ループは数分を無駄にする。

---

## 出力ディレクトリ構成

```
viral-shorts/<campaign>/<YYYY-MM-DD>/
  source-images/      # 商品静止画
  real-footage/ex/    # クライアント素材（正規化名）
  clips/              # 生成 Seedance クリップ
  audio/              # ナレーション、BGM、ミックス
  caps/               # 字幕 PNG
  final.mp4           # 納品物
  receipts.json       # モデル、タスク id、ファイルパス、メモ
```

---

## リポジトリ内容

- `SKILL.md` —— エージェント向けワークフロー
- `scripts/ingest-source-video.mjs` —— ソース URL → ローカル mp4 取り込み
- `scripts/apply-overlays.mjs` —— 字幕 / UI 重畳レンダラー

## 安全とコンプライアンス

- **構造を学び、アイデンティティは学ばない** —— 文言・シーン・声・肖像を決して複製しない。
- ロイヤリティフリー / ライセンス済みの音楽のみ使用。著作権のあるトレンド音源を同梱しない。
- 商品ページにない機能を主張しない。
- 生成動画・スクショ・receipts・API キー・ローカル `.env` は**コミットしない**。
