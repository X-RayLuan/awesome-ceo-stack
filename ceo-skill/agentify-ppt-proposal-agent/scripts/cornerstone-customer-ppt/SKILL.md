---
name: cornerstone-customer-ppt
description: "收到客户信息后，搜索 Cornerstone Wiki 知识库，生成差异化 PPT 大纲，经用户确认后生成 PPTX。"
metadata:
  allowed-tools: [read, exec, write, sessions_spawn, message]
  user-invocable: true
---

# Cornerstone Customer PPT

收到客户需求信息后，在 Cornerstone Wiki 知识库中搜索相关背景，结合已有资料生成有差异化的 PPT 大纲，经用户确认后生成 PPTX 文件。

## 工作流程

### 第一步：收集与分析客户信息

收到用户发来的客户信息（包括公司背景、行业、项目需求、目标学员等），立即做信息结构化提取：

- 客户名称 / 行业
- 项目类型（课程 / 训练营 / 咨询 / 行动学习）
- 目标学员层级
- 核心痛点 / 需求关键词
- 其他已知背景（规模、已有培训体系等）

### 第二步：搜索知识库，深度检索

在以下路径中检索相关内容（关键词：公司名、行业、需求类型、方法论关键词）：

```
~/Desktop/Cornerstone Wiki/knowledge-base/
~/Desktop/Cornerstone Wiki/
```

检索内容优先级：

1. `knowledge-base/` 中相关 Wiki 页面（`00-导航` 开始的结构化知识）
2. 同一客户或同行业已有 PPT proposal
3. 相关课程 / 解决方案 / 方法论文档
4. 讲师与专家库中的对口顾问

检索完成后，整理出可用资产清单（可复用的课程模块、方法论、客户案例、讲师资源）。

### 第三步：生成差异化 PPT 大纲

基于检索到的知识库内容，生成**差异化大纲**，每页内容包括：

- 页码 & 页面标题
- 内容要点（3～5 条）
- 设计说明（用哪类知识库资产支撑）
- 假设说明（如客户信息不足，需注明假设前提）

大纲用 Markdown 表格或分点形式呈现。

### 第四步：等待用户确认大纲

将大纲发送给用户，等待确认或修改意见。用户确认后再进入下一步。

### 第五步：生成 deck.html

按照确认后的大纲，参考以下模板的视觉和格式生成 `deck.html`：

```
~/Desktop/Cornerstone Wiki/柯纳仕咨询与培训 Intro_CN 咨询版 V1.2.pptx
```

HTML 结构规范：

- 每页用 `<section class="slide">` 包裹
- 页内标题用 `<h1>` 或 `<h2>`
- 内容使用 `<ul>` / `<ol>` / `<table>` / `<p>`
- 不使用内联样式，全部依赖外联 CSS 或母版定义
- 字体、配色、版式尽量贴近母版风格

deck.html 保存路径：`~/Desktop/Cornerstone Wiki/deck.html`

### 第六步：转换为 PPTX

调用脚本生成 PPTX：

```bash
~/.openclaw/workspace-smart/build_ppt_from_html.sh deck.html <客户名>_<项目主题>_<柯纳仕方案>_$(date +%Y%m%d).pptx
```

脚本使用 `html_to_pptx.py` + 母版 `柯纳仕咨询与培训 Intro_CN 咨询版 V1.2.pptx` 进行转换。

输出文件保存到：`~/Desktop/Cornerstone Wiki/`

## 文件命名规范

```
<客户名>_<项目主题>_<柯纳仕方案>_YYYYMMDD.pptx
```

示例：`百威商学院_领导力发展_柯纳仕方案_20260526.pptx`

## 关键约束

- 未经用户确认大纲，不得擅自生成 PPT
- 客户背景信息不足时，大纲中需明确标注"假设"或"待确认"
- 不捏造客户事实，不用夸大词汇
- 输出文件不覆盖已有同名文件（需重命名或告知用户）