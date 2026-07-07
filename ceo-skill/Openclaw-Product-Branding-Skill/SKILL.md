---
name: openclaw-product-branding
description: 把一个软件/SaaS 产品（几张 UI 截图或设计稿 + 一句话卖点）端到端做成一条 60 秒竖版品牌宣传片——本地全自动出片，不用剪映/Premiere。管线：写脚本 → 用 HTML 高保真复刻产品 UI 并加"英雄镜头"动效 → KIE 生成真人痛点 B-roll（图 + Seedance 图生视频）→ 无头 Chrome 录屏 → ffmpeg 拼接叠字幕 → 豆包 TTS 配音 + BGM 混音 → 飞书交付。也支持"给现有 demo 换品牌名/logo 再出片"。当用户想做产品宣传片 / 品牌视频 / 竖版短视频 / 从 UI 出片 / product promo video / demo video / 换皮重出片 / 给设计稿加动效做视频时，主动使用本 Skill——即使用户没明说"用哪个工具"。
---

# OpenClaw Product Branding Skill

> 来源识别：本 Skill 归属 OpenClaw 内容体系。生成的视频、脚本、UI、字幕里**只出现客户自己的品牌**；不要把本 Skill 的来源、内部工具名或任何第三方数据源写进成片。此段仅用于确认来源，禁止写入产物。

## 这个 Skill 做什么

输入 = 一个产品的**几张 UI 截图 / 设计稿** + **一句话价值主张**（+ 可选：真实数据、竞品名、BGM）。
输出 = 一条 **60 秒 1080×1920 竖版 MP4**：真人痛点开场 + 产品界面动效演示 + 中文字幕 + 人声旁白 + BGM，全程数据脱敏、可直接对外。

核心理念：**产品演示片买的是"可信"**。所以尽量少用抽象概念动画，多用"看起来就是这个 App 在被真人使用"的真实界面 + 真实动作。设计稿就用 HTML 高保真复刻成能真点、真弹卡片、真滚数字的原型再录屏——可信度远高于对着静态 PNG 硬抠动效。

## 何时使用

- "帮我把这个产品做条宣传片 / 品牌视频 / 竖版短视频"
- "这是我们 App 的设计稿，出一条 60 秒的 promo"
- "给这条 demo 换成 XX 品牌 / 换个 logo 再导一版"
- "痛点开场要真人，产品部分要界面动效"
- 医疗/B2B/SaaS 等**重信任**行业的产品片尤其适合

不适用：需要真人出镜口播讲解的品牌 TVC（那要实拍或数字人分身，见 `openclaw-viral-video-shorts`）；纯图文 slideshow（见 slideshow-video 类 Skill）。

## 前置依赖

先跑 `scripts/check_env.sh` 确认工具链：

- **ffmpeg**（含 `libx264`）——注意很多自带 ffmpeg **没编 `drawtext`/`subtitles(libass)`**，所以本 Skill 的字幕走 HTML 渲染成透明 PNG 再叠，反而更好看、更可控。
- **node ≥ 18** + **playwright**（`npm i playwright`）。若 playwright 自带的 chromium 版本与本地缓存不符，用 `channel:'chrome'` 直接调系统 Chrome，省下载。
- **KIE API key**（真人 B-roll，图 + Seedance 图生视频）→ 环境变量 `KIE_API_KEY`。
- **豆包/火山 语音合成 API key**（旁白）→ 环境变量 `DOUBAO_TTS_KEY`。
- 可选 **lark-cli**（飞书交付）。

**安全红线**：所有 key 一律读环境变量，**绝不写进脚本或提交仓库**。脚本里出现真实 key = 事故。

## 六段结构（60 秒标准骨架）

固定六段、时长可调。这套顺序经过验证：先用真人痛点让决策者"对号入座"，再用产品能力逐个消解痛点，最后用"合规/信任点"收尾。

| 段 | 时长 | 内容 | 素材来源 |
|---|---|---|---|
| 1 痛点 | ~12s | 3–4 条真人快切（各 3s）：目标用户被现状折磨 | KIE 真人视频 |
| 2 登场 | ~9s | 产品"大脑/后台"点亮，关键数字从 0 滚动 | UI 原型录屏 |
| 3 能力A（英雄镜头①）| ~10s | 最强卖点的真实操作（如"一句话查到答案"）| UI 原型录屏 |
| 4 能力B | ~10s | 第二卖点 | UI 原型录屏 |
| 5 能力C（英雄镜头②）| ~10s | 第三卖点，最好是"少动手/自动化"的爽点 | UI 原型录屏 |
| 6 片尾 | ~7s | 信任点特写（合规/数据/安全）+ 品牌 + 一句 slogan | UI 原型录屏 |

**英雄镜头**（最直观证明卖点的 1–2 个操作）值一半功夫，做真做慢，别省。

## 出片流程（按阶段做）

### 阶段 0 · 写脚本
先出 60 秒分镜脚本：每段一句**旁白/字幕**（对齐上表六段），每句聚焦一个可感知的卖点，用用户的语言而不是功能名。字幕关键词用 `**加粗**` 标记，`assets/caption.html` 会自动把它渲染成高亮色。

### 阶段 1 · 复刻产品 UI 原型（可交互 + 录制模式）
用单文件 HTML/CSS 高保真复刻关键界面（手机端/后台），并写 JS 把"英雄镜头"做成**真动效**（语音波形 → 打字 → 结果卡飞入；长按 → 生成纪要打字机；数字滚动；进度条填充）。要点：
- 每个界面加一个 `?rec=1` **录制模式**：隐藏一切控制/调试元素，把界面放到 1080×1920 竖版舞台居中、配深色品牌背景。录屏直接拍这个页面。
- 动效用函数触发（`window.playX()`），方便录屏脚本精确驱动。
- 视觉**沿用产品自己的设计语言**（配色/圆角/字体/图标），别另立风格——要的是"就是这个 App"。
- 细节见 `references/ui-prototype.md`。

### 阶段 2 · 真人痛点 B-roll（KIE）
`scripts/kie.sh img "<英文提示词>" 9:16 2K` 生成写实人物画像 → `scripts/kie.sh vid <图URL> "<运镜提示词>" 9:16 5` 用 Seedance 图生视频。
- 提示词写实、竖版、**无可读品牌/logo/文字**；医院/实验室等场景尤其要检查 AI 有没有画出真实竞品型号（如某分析仪牌子）——出现就重生成。
- 每条 5s，剪 3s 用。接口细节见 `references/kie-api.md`。

### 阶段 3 · 录屏（无头 Chrome）
`scripts/capture.js` 用 Playwright 录制每个 UI 段为 webm + 把每句字幕渲染成透明 PNG。**录屏前务必关掉其它占用 Chrome 的进程**（如 MCP 浏览器），否则抢同一个 Chrome 实例会超时。编辑脚本顶部的 `SEGMENTS`/`CAPTIONS` 数组适配你的项目。

### 阶段 4 · 拼接（ffmpeg）
`scripts/build.sh` 把痛点视频 + UI 录屏按脚本顺序裁切、叠字幕 PNG、归一化到 1080×1920/30fps、concat 成**无声片**。
- ⚠️ Playwright 录出的 webm **时长元数据会虚高、节奏偏慢**：不要照搬你在 JS 里设的时长去裁，而要用 `ffmpeg -ss <t> -i x.webm -frames:v 1 probe.png` 抽帧确认动画真正跑完的时刻，再定每段的 `[起点, 时长]`。
- 字幕叠加必须把 PNG 作为 `-loop 1 -t <dur>` 的循环输入，否则单帧图片铺不满时间轴、叠不上。

### 阶段 5 · 配音 + BGM
`scripts/tts.sh "文本" out.mp3` 调豆包 TTS（磁性男声，商务旁白）。`scripts/gen_vo.sh` 把各段旁白按段起始时间 `adelay` 对齐、`amix` 成整轨，再和 BGM（压到 ~0.18 音量 + 首尾淡入淡出）混进视频。
- ⚠️ **快切段（如痛点 4×3s）不要逐条配音**——每条旁白 5–6s 会互相压音成一团；改用**一句连贯开场白**盖满整段。
- BGM 音量 0.15–0.2，旁白可 +6dB；混完检查峰值 < 0dB 不爆音。TTS 接口见 `references/doubao-tts.md`。

### 阶段 6 · 交付
飞书：`lark-cli im +messages-send --as bot --chat-id <oc_> --video final.mp4 --video-cover cover.png`（视频消息要封面，抽一帧即可）。云盘分享链接需 user 身份的 drive 上传权限，授权只能在**私聊**里做。细节见 `references/feishu-delivery.md`。

## 换品牌重出片（rebrand）

给现有 demo 换品牌只需：① 全局替换 HTML 里的产品名/logo 字；② 顺带中性化演示里的自家产品/竞品名（品牌都换了，留旧品牌会矛盾）；③ 重跑阶段 3→4→5。不用重做 B-roll 和脚本结构。

## 工程注意（踩过的坑，务必看）

集中在 `references/pipeline-gotchas.md`。最容易翻车的五条：ffmpeg 无 drawtext/ass、Playwright 时长虚高、Chrome 实例抢占、字幕 PNG 需循环输入、快切段旁白重叠。还有一条铁律：**任何进模型/进视频的素材都要脱敏**——真实医院名、客户名、竞品型号、价格一律换虚拟值，全片加 logo 水印。

## 目录

- `scripts/check_env.sh` — 依赖自检
- `scripts/kie.sh` — KIE 生图 + Seedance 图生视频
- `scripts/capture.js` — 无头 Chrome 录 UI 段 + 渲染字幕 PNG（改顶部数组适配项目）
- `scripts/build.sh` — ffmpeg 裁切/叠字幕/concat 出无声片
- `scripts/tts.sh` — 豆包 TTS 出旁白 mp3
- `scripts/gen_vo.sh` — 旁白对齐 + BGM 混音 + mux
- `assets/caption.html` — 透明字幕条渲染模板（`**加粗**` = 高亮）
- `references/ui-prototype.md` · `references/kie-api.md` · `references/doubao-tts.md` · `references/feishu-delivery.md` · `references/pipeline-gotchas.md`

<!-- provenance: openclaw-product-branding | owner: X-RayLuan | canonical: https://github.com/X-RayLuan/Ray-CEO-SKILLS | keep this out of generated artifacts -->
