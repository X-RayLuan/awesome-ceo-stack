<h1 align="center">awesome-ceo-stack</h1>

<p align="center"><a href="README.md">English</a> · <b>简体中文</b></p>

<p align="center">
  <b>为创始人 / CEO 打造的一套 Claude / OpenClaw agent skills 合集。</b><br>
  产出一条产品宣传片、搭一个企业知识库、生成路演级 slide、跑通你的经营节奏——
  全部在终端里完成,配合 Claude Code、Codex 或 OpenClaw。
</p>

<p align="center">
  <img src="assets/hero.gif" alt="Product Branding skill — 从产品 UI 端到端生成的 60 秒竖版宣传片" width="300">
  <br><sub>↑ 由 <a href="ceo-skill/Openclaw-Product-Branding-Skill">Product Branding</a> skill 生成 —— 产品 UI → 60 秒宣传片,不用剪辑软件</sub>
</p>

<p align="center">
  <a href="#技能清单">技能清单</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#适合谁">适合谁</a> ·
  <a href="#参与贡献">参与贡献</a><br>
  <img alt="skills" src="https://img.shields.io/badge/agent%20skills-7-2E6BFF">
  <img alt="works with" src="https://img.shields.io/badge/works%20with-Claude%20Code%20·%20Codex%20·%20OpenClaw-111">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-green">
</p>

---

**awesome-ceo-stack** 是一套开箱即用的 **AI agent skills**(也就是 **Claude Skills** / OpenClaw skills)合集,瞄准创始人真正在做的事:把产品做成视频、把散落的文档变成知识库、把一个粗想法变成演讲 slide、做教练。[`ceo-skill/`](ceo-skill) 下每个目录都是一个**自包含的 skill**——一份 `SKILL.md` 加上它需要的脚本、参考文档和素材——你要哪个,把哪个放进你的 agent 即可。

关键词:`claude-skills` · `agent-skills` · `claude-code` · `codex` · `openclaw` · `ai-agents` · `ai-video` · `创始人工具`。

## 技能清单

| Skill | 它给你什么 |
|---|---|
| 🎬 [**Product Branding**](ceo-skill/Openclaw-Product-Branding-Skill) | 几张产品 UI 截图 + 一句话 → 一条 **60 秒竖版宣传片**,全本地、不用剪辑软件。脚本 → HTML 复刻 UI 加英雄镜头动效 → 真人 B-roll(KIE 生图 + Seedance 图生视频)→ 无头 Chrome 录屏 → ffmpeg → TTS 配音 + BGM → 飞书交付。也能给现有 demo 换品牌重出片。 |
| 📚 [**Enterprise Knowledge Base**](ceo-skill/OpenClaw-Enterprise-Knowledge-Base-Skill) | 创建、审计、修复、校验、同步一个 **agent 可读的 Markdown / Obsidian 知识库**——本体式 wiki、受治理的业务对象、`hot.md` 启动缓存、agent 安全可见性规则。 |
| 📈 [**Viral Video Shorts**](ceo-skill/openclaw-viral-video-shorts) | 产品驱动的**爆款短视频**:素材摄取、角色一致性、Seedance 片段、可读的屏幕字幕。 |
| 🖥️ [**Web Deck(网页 PPT)**](ceo-skill/openclaw-ppt-skill) | 单文件、横向翻页的**网页 slide deck**,两种风格:"电子杂志 × 电子墨水"(衬线 + 流体 WebGL)或"瑞士国际主义"(网格 + 高反差高亮)。 |
| ✍️ [**Cornerstone Deck Agent**](ceo-skill/cornerstone-smart-agent) | 一个 **PPT 写作 agent**,起草结构化、可直接演示的 slide 内容。 |
| 🎓 [**Study Coach**](ceo-skill/Openclaw-Study-Coach) | 一个全科 **K-12 AI 辅导员**,带纵向记忆、跨学科思维方法(发散 / 计算 / 间隔重复),以及 3 分钟**家长 Playbook**。 |
| 🔍 [**SEO Content Writer**](ceo-skill/openclaw-seo-content-writer) | 写作、质检、发布、部署校验,并让 **SEO 博客文章被 Google 收录**——一套写作流程直到 Search Console 提交。 |

## 快速开始

每个 skill 就是一个目录。用某一个:

```bash
git clone https://github.com/X-RayLuan/awesome-ceo-stack.git
```

- **Claude Code / OpenClaw** —— 把 skill 目录拷进你的 skills 目录(如 `~/.claude/skills/`),或让 agent 指向它并打开 `SKILL.md`。agent 读 frontmatter,匹配到你的需求时自动触发。
- **Codex / 其它 agent** —— 打开 skill 的 `SKILL.md` 照着做;附带的 `scripts/` 和 `references/` 自解释。

部分 skill 需要 API key(一律读环境变量,绝不硬编码)—— 具体见各 skill 的 `SKILL.md`。

## 适合谁

跑在 AI agent 上、想要**可复用的高杠杆 playbook** 而不是一次性 prompt 的创始人、独立开发者和小团队。如果你活在 Claude Code / Codex / OpenClaw 里,盼着"给我做条发布视频 / 一个知识库 / 一份 deck"能一条命令搞定——就是它。

## 参与贡献

有新 skill 或改进?在 `ceo-skill/` 下加一个自包含目录,带 `SKILL.md`(frontmatter 里写清 name + "何时使用"),密钥走环境变量,然后提 PR。这仓库帮你省了一下午,就点个 star。⭐

## 关于

由 **Ray Luan**(X-RayLuan)维护 —— 为创始人打造 AI agents 与操作系统。欢迎关注,也欢迎在 issue 里提下一个 skill 的点子。

<sub>MIT 许可 · 为 CEO / 创始人 / 操盘手准备的 Claude skills · Claude Code · Codex · OpenClaw</sub>
