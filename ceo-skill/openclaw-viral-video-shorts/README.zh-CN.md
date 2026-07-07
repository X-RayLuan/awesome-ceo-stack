<!-- LANGS -->
[English](README.md) · **简体中文** · [日本語](README.ja.md) · [Español](README.es.md)

# OpenClaw 爆款短视频生成

一个 OpenClaw skill + 端到端流程，把一个**供应商 / 产品页面**变成一条 **30 秒竖屏(9:16)爆款短视频**：

1. **检索**：在 Instagram / TikTok / Shorts 上找到真实的爆款参考
2. **拆解**：提取它们可复用的爆款*结构*（钩子 → 痛点 → 演示 → 爽点 → CTA），写成一份原创脚本
3. **生成**：用真实产品素材生成视频 —— AI 图生视频片段 + 真实镜头 + AI 配音 + 免版权 BGM，再用 `ffmpeg` 合成

> 核心原则：**学结构，绝不抄身份/内容。** 迁移的是节奏、钩子机制、情绪和分镜逻辑 —— 脚本、画面、声音全部原创。

本文档记录完整的 **检索 → 脚本 → 生成** 流程（案例：一条 ZekSmart LED 镜短视频）。`SKILL.md` 是给 agent 看的工作流；本文件是给人/操作者的实操手册。

---

## 流程总览

```
[1] 检索爆款参考      Exa + Tavily  → IG/TikTok reels
        ↓
[2] 拆解结构          钩子/痛点/演示/爽点/CTA → 脚本 + 字幕
        ↓
[3] 收集产品素材      阿里产品图  /  客户上传镜头(zip)
        ↓
[4] 生成片段          火山方舟 "Seedance 2.0" 图生视频（9:16, 720p, 每段 5s）
        ↓
[5] 配音              ElevenLabs TTS（逐句配音，对齐到 5s 卡点）
        ↓
[6] 背景音乐          Pixabay 免版权（CDN 直链 mp3）
        ↓
[7] 合成              ffmpeg：归一化 → 字幕(PNG 叠加) → 拼接 → 侧链 ducking 混音 → 合轨
        ↓
[8] (可选) 交付       上传 / 发送最终 mp4
```

---

## 前置条件

**命令行工具**

| 工具 | 用途 | 备注 |
|------|------|------|
| `ffmpeg` / `ffprobe` | 所有音视频处理 | **可能不带 `drawtext`**（缺 libfreetype）—— 字幕改用 PNG 叠加，见[踩坑](#踩坑与经验) |
| `python3` + `Pillow` | 字幕 PNG、调 API | `pip install --break-system-packages Pillow` |
| Playwright（浏览器） | 提取 Pixabay 音乐链接 | 仅 BGM 步骤需要 |
| `yt-dlp`（可选） | 把参考 reel 下成本地 mp4 | 可选；也能仅从搜索摘要里拆结构 |

**API key（用环境变量导出 —— 切勿提交进仓库）**

```bash
export EXA_API_KEY=...          # 爆款参考检索
export TAVILY_API_KEY=...       # 搜索 + 页面抽取（阿里、Pixabay 兜底）
export ARK_API_KEY=...          # 火山方舟 / Seedance 2.0 视频生成
export ELEVENLABS_API_KEY=...   # 配音 TTS
export KIE_API_KEY=...          # 可选：GPT-Image 头像生成（skill 默认路径）
```

---

## [1] 检索爆款参考

在细分品类里找到真实、当下有数据的短视频。**两个引擎都用** —— 覆盖面不同。

```bash
# Exa —— 语义检索（注意：Exa 不开放 instagram.com 域名；
# 用 tiktok/youtube，instagram 交给 Tavily）
curl -s -X POST https://api.exa.ai/search -H "x-api-key: $EXA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"viral LED mirror smart mirror short video reel",
       "numResults":8,
       "includeDomains":["tiktok.com","youtube.com"]}'

# Tavily —— 覆盖 instagram.com + 返回摘要文本
curl -s -X POST https://api.tavily.com/search -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",
       \"query\":\"viral LED mirror tiktok instagram reel hook\",
       \"search_depth\":\"advanced\",\"max_results\":6,
       \"include_domains\":[\"tiktok.com\",\"instagram.com\"]}"
```

可选：把一条参考下成本地 mp4 做逐帧分析（需 `yt-dlp`）：

```bash
node scripts/ingest-source-video.mjs --url "<reel-url>" --out source
```

---

## [2] 拆解爆款结构 → 脚本

把参考提炼成可复用结构，再在上面写一份**原创**产品脚本。

```json
{
  "viral_pattern": "无聊-vs-惊艳 → 演示 → 背书 → CTA",
  "emotional_driver": "向往 + 解压满足",
  "structure": ["0-5 钩子", "5-15 演示", "15-25 背书", "25-30 CTA"]
}
```

一套稳定的 30s 产品结构（6 × 5s 分镜），每镜配一句短字幕/口播：

| 时间 | 分镜 | 字幕 / 口播 |
|------|------|-------------|
| 0–5 | 钩子（最抓眼的一帧） | "Your bathroom mirror? So boring." |
| 5–10 | 功能演示 | "Touch to dim. Three light colors." |
| 10–15 | 多样/规模 | "Round, oval, any shape, any size." |
| 15–20 | **真实背书**（工厂/质检） | "Made in our own factory." |
| 20–25 | 信任卖点 | "Anti-fog, bluetooth, memory function." |
| 25–30 | CTA | "OEM/ODM — DM us for wholesale pricing!" |

---

## [3] 收集产品素材

两种真实来源都好用：

**A. 阿里 / 1688 店铺的产品图**（抽高清原图，去掉 CDN 尺寸后缀）：

```bash
curl -s -X POST https://api.tavily.com/extract -H "Content-Type: application/json" \
  -d "{\"api_key\":\"$TAVILY_API_KEY\",\"urls\":[\"<店铺列表页url>\"],\"extract_depth\":\"advanced\"}" \
  | python3 -c "import sys,json,re; t=json.load(sys.stdin)['results'][0]['raw_content']; \
[print(re.sub(r'_\d+x\d+\.jpg$','.jpg',u)) for u in set(re.findall(r'https://s\.alicdn\.com/@sc04/kf/[^\"\s]+?\.jpg', t))]"
# 下载时带浏览器 UA + referer，否则 CDN 可能 403
curl -sL -A "Mozilla/5.0" -e "https://example.en.alibaba.com/" "<图片url>" -o img01.jpg
```

**B. 客户上传的真实镜头**（如验厂 `.zip`）。中文 Windows 压缩包用的是 **GBK** 文件名，macOS `unzip` 会报错 —— 用 Python 提取并重编码：

```python
import zipfile, os
z = zipfile.ZipFile("footage.zip"); os.makedirs("ex", exist_ok=True); i = 0
for info in z.infolist():
    if info.is_dir(): continue
    try: name = info.filename.encode('cp437').decode('gbk')   # 修复 GBK 名
    except Exception: name = info.filename
    if os.path.splitext(name)[1].lower() in ('.mp4', '.mov'):
        i += 1
        open(f"ex/clip{i:02d}.mp4", "wb").write(z.open(info).read())
```

---

## [4] 生成片段 —— 火山方舟 "Seedance 2.0"（图生视频）

把每张产品图作为首帧喂进去，Seedance 让它动起来（亮灯、推镜、防雾消散、变色…）。

```bash
# 创建任务 —— 图生视频。image_url 可以是公开 URL 或 data:base64。
# 生成参数以文本 flag 形式追加在 prompt 后面。
curl -s -X POST "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks" \
  -H "Authorization: Bearer $ARK_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"doubao-seedance-2-0-fast-260128",
       "content":[
         {"type":"text","text":"LED mirror lights turn on, slow cinematic push-in, premium reveal --resolution 720p --ratio 9:16 --duration 5 --camerafixed false"},
         {"type":"image_url","image_url":{"url":"<公开图片url>"}}
       ]}'
# → {"id":"cgt-..."}

# 轮询直到 status == "succeeded"，再读 content.video_url
curl -s "https://ark.cn-beijing.volces.com/api/v3/contents/generations/tasks/<id>" \
  -H "Authorization: Bearer $ARK_API_KEY"
```

- 模型：`doubao-seedance-2-0-260128`（高质量）/ `doubao-seedance-2-0-fast-260128`（更快更省）。
- **所有分镜任务并行下单**再统一轮询 —— 生成（每段约 3–6 分钟）是瓶颈。
- 每段返回 9:16 720p 约 5s。

---

## [5] 配音 —— ElevenLabs

每镜生成一句短口播，再把每句放到对应的 5 秒卡点。

```bash
# 选一个年轻女声，例如 "Jessica"（活泼、明亮、温暖）
curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/cgSgspJ2msm6clMCkdW9?output_format=mp3_44100_128" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
  -d '{"text":"Your bathroom mirror? So boring.",
       "model_id":"eleven_multilingual_v2",
       "voice_settings":{"stability":0.4,"similarity_boost":0.8,"style":0.45,"use_speaker_boost":true}}' \
  -o vo1.mp3
```

`eleven_multilingual_v2` 也支持中文/日文/西班牙文，可做本地化配音。（无 key 兜底：macOS `say -v Samantha`。）

用 `adelay` 把各句放在 0.3s、5.3s、10.3s … 再 `amix` 成一条 30s 人声轨。

---

## [6] 背景音乐 —— Pixabay（免版权）

Pixabay **公开 API 只有图片和视频 —— 音乐不在 API 里**，且搜索页用 JS 动态加载音频链接。用无头浏览器读出 CDN 直链 mp3，再下载（CDN 文件本身不需要 key）：

```js
// 导航到 https://pixabay.com/music/search/upbeat/ 之后
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
curl -sL -A "Mozilla/5.0" -e "https://pixabay.com/" "<cdn音频url>" -o bgm.mp3
```

---

## [7] 用 ffmpeg 合成

**每段归一化到 720×1280、30fps。** 竖屏 AI 片段裁切填满；横屏镜头用模糊背景适配：

```bash
# 竖屏 AI 片段
ffmpeg -y -i scene.mp4 -t 5 -vf "scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,fps=30" -an seg.mp4
# 横屏镜头 → 模糊背景 9:16
ffmpeg -y -ss 30 -t 5 -i factory.mp4 -filter_complex \
  "[0:v]scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,boxblur=24:6[bg];\
   [0:v]scale=720:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2,fps=30" -an seg4.mp4
```

**字幕用 PNG 叠加**（本机 ffmpeg 没有 `drawtext`）。用 Pillow 渲染透明字幕条，再 `overlay`：

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
ffmpeg -y -f concat -safe 0 -i concat.txt -c:v libx264 -pix_fmt yuv420p -r 30 video.mp4   # 拼接全部
```

**音频：侧链 ducking**，让 BGM 在人声处压低、空隙处回升：

```bash
ffmpeg -y -i voice30.wav -i bgm_seg.wav -filter_complex \
 "[1]volume=0.55[bg];[bg][0]sidechaincompress=threshold=0.03:ratio=8:attack=15:release=350[duck];\
  [0][duck]amix=inputs=2:normalize=0,alimiter=limit=0.95[m]" -map "[m]" mixed.wav
# 合到无声视频上
ffmpeg -y -i video.mp4 -i mixed.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -t 30 final.mp4
```

用 `volumedetect` 校验：整体混音均值 ≈ −15 dB，并确认人声空隙处 BGM 可闻（≈ −22 dB）。

---

## [8] 交付（可选）

导出 `final.mp4`（720×1280，约 30s）。发布前在剪映/CapCut 里**套一个当下热门音轨** —— 平台算法更偏爱原生热门音乐。

---

## 踩坑与经验

跑这套流程时真实遇到的坑 —— 你大概率也会撞上：

- **ffmpeg 没有 `drawtext`** → 别用 `drawtext` 烧字幕；用 **PNG 叠加**（Pillow）+ `overlay`。
- **`zsh` 数组是 1-based**，不像 bash 的 0-based → `${arr[1]}` 才是第一个；错位会悄悄丢句/重复。
- **Exa 不支持 `instagram.com`**（`SOURCE_NOT_AVAILABLE`）→ Instagram 用 Tavily 覆盖。
- **阿里 CDN 图片不带浏览器 `User-Agent` + `Referer` 会 403**；去掉 `_480x480.jpg` 后缀拿高清原图。
- **中文 Windows 的 GBK 压缩包文件名**会让 macOS `unzip` 报错 → 用 Python `cp437→gbk` 重编码提取。
- **Pixabay 音乐不在公开 API 里** → 用无头浏览器渲染页面，从 JS / `<audio>` 读 CDN mp3 链接。
- **混完 BGM 听不见** → 是*电平*问题：把音乐归一化到已知响度（如 `loudnorm I=-22`），在人声空隙处用 `volumedetect` 验，别信裸 `volume=0.18`。
- **Seedance 延迟** → 所有片段任务并行下单、统一轮询；串行循环白白浪费几分钟。

---

## 产出目录结构

```
viral-shorts/<campaign>/<YYYY-MM-DD>/
  source-images/      # 产品图
  real-footage/ex/    # 客户素材（规范化命名）
  clips/              # 生成的 Seedance 片段
  audio/              # 配音、BGM、混音
  caps/               # 字幕 PNG
  final.mp4           # 交付物
  receipts.json       # 模型、任务 id、文件路径、备注
```

---

## 仓库内容

- `SKILL.md` —— 面向 agent 的工作流说明
- `scripts/ingest-source-video.mjs` —— 源 URL → 本地 mp4 下载助手
- `scripts/apply-overlays.mjs` —— 字幕 / UI 叠加渲染器

## 安全与合规

- **学结构、不抄身份** —— 绝不照搬创作者的文案、分镜、声音或形象。
- 只用免版权 / 已授权音乐；不要打包有版权的热门音轨。
- 不要宣称产品页不支持的功能。
- **切勿提交**生成的视频、截图、receipts、API key 或本地 `.env`。
