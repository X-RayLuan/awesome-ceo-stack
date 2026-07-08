<p align="center"><img src="assets/banner.png" alt="Enterprise Knowledge Base — an awesome-ceo-stack agent skill" width="820"></p>

<div align="center">

# OpenClaw Enterprise Knowledge Base Skill

### Enterprise Knowledge Base Skill · 企业级知识库技能包 · 企業ナレッジベーススキル · 엔터프라이즈 지식 베이스 스킬 · Habilidad de Base de Conocimiento Empresarial

[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill_Compatible-orange)](https://github.com/openclaw)
[![Languages](https://img.shields.io/badge/Languages-中文%20%2F%20EN%20%2F%20JP%20%2F%20KR%20%2F%20ES-red)](#-多语言介绍--multilingual--多言語--다국어--multilingüe)
[![Agentify AI](https://img.shields.io/badge/Base_product_of-Agentify_AI-2E6BFF)](https://aiagentify.ai/)

[**📖 What it is / 这是什么 / 何ですか / 무엇인가요 / Qué es**](#-what-it-is--这是什么) ·
[**🏗️ Repository layout / 仓库结构 / リポジトリ構成 / 리포지토리 구조 / Estructura del repositorio**](#-repository-layout--仓库结构) ·
[**🚀 Quick Start / 60 秒启动 / 60秒起動 / 60초 시작 / Inicio rápido**](#-quick-start--快速上手) ·
[**🧠 Governance / 治理规则 / ガバナンス / 거버넌스 / Gobernanza**](#-governance--治理规则) ·
[**✅ Validation / 验证 / 検証 / 검증 / Validación**](#-validation--验证) ·
[**📘 Ontology / 术语体系 / オントロジー / 온톨로지 / Ontología**](#-ontology--术语体系)

</div>

> **🏢 The Enterprise Knowledge Base is the base product of [Agentify AI](https://aiagentify.ai/).**
> 企业知识库是 [Agentify AI](https://aiagentify.ai/) 的基座产品 —— 让公司知识被智能体理解、治理和调用。
> Learn more at **[aiagentify.ai](https://aiagentify.ai/)**.

---

## 🌐 Multilingual Introduction / 多语言介绍 / 多言語 / 다국어 / Multilingüe

### 🇨🇳 中文

这是一个将企业级 Markdown / Obsidian 仓库改造成可被 OpenClaw 直接消费的 **企业知识库技能包**。

核心目标：让公司知识被智能体理解和调用，但不变成“失控的笔记堆”。

每一个业务页面都应具备：

- 明确的元数据（status / visibility / owner / source / last_reviewed）
- 清晰的关系（对象与对象之间的链接）
- 明确的动作权限边界（哪些内容可触发行动、哪些仅供参考）
- 一份“启动热缓存”`hot.md`，让新会话知道先读什么


### 🇬🇧 English

This is a reusable **Enterprise Knowledge Base skill pack** that turns a Markdown/Obsidian vault into a structure that OpenClaw can consume safely and predictably.

The goal is to make company knowledge easily operable by agents without turning your KB into an unsafe dump of notes.

Each business page should include:

- Explicit metadata (`status`, `visibility`, `owner`, `source`, `last_reviewed`)
- Clear object relationships
- Explicit action permissions (what content can trigger actions and what is reference-only)
- A startup hotspot cache `hot.md` so a fresh agent knows where to begin


### 🇯🇵 日本語

これは、Markdown / Obsidian のナレッジを OpenClaw が直接参照できるように整える
**企業向け知識ベース Skill**です。

目的は、社内知識を「制御できないノート置き場」にしないことです。

各業務ページには以下を備える想定です。

- 明確なメタデータ（`status` / `visibility` / `owner` / `source` / `last_reviewed`）
- オブジェクト間の明示的な関連
- 実行可能なアクションの権限境界
- 新規セッション向けの起動キャッシュ `hot.md`

### 🇰🇷 한국어

이 저장소는 Markdown/Obsidian 기반의 기업 지식 저장소를 OpenClaw가 직접 사용할 수 있도록 정리하는
**엔터프라이즈 지식베이스 스킬팩**입니다.

핵심 목표는 기업 지식을 “제어되지 않은 노트 더미”가 아니라,
실무에서 안전하게 호출 가능한 지식 자산으로 구성하는 것입니다.

각 비즈니스 문서는 다음 요소를 가져야 합니다.

- 명시적 메타데이터 (`status`, `visibility`, `owner`, `source`, `last_reviewed`)
- 객체 간 관계 정의
- 액션 권한 경계(무엇이 조치 가능하고 무엇이 참조 전용인지)
- 신규 세션이 시작 지점을 바로 알 수 있는 `hot.md`

### 🇪🇸 Español

Este es un **skill pack de base de conocimiento empresarial** para convertir un repositorio Markdown/Obsidian en algo que OpenClaw pueda consumir de forma operativa.

El objetivo es que el conocimiento de la empresa sea útil para agentes, sin degradarse en una “montaña de notas sin control”.

Cada página de negocio debe incluir:

- Metadatos explícitos (`status`, `visibility`, `owner`, `source`, `last_reviewed`)
- Relaciones claras entre objetos
- Límites explícitos de permisos de acción
- Un caché de arranque `hot.md` que indique por dónde comenzar

---

## What it is / 这是什么 / これは何ですか / 이것은 무엇인가요 / Qué es

### 🇨🇳 中文

这个技能包包含一个企业知识库的落地实现模式：

- 企业知识库的本体论（ontology）模板
- 页面必需元数据标准
- 根路径启动策略（优先读取哪些文件）
- 高风险回答与动作治理规则
- 简单的校验器：校验 frontmatter、重复 ID、`hot.md` 长度
- Agentic RAG 路由与上下文充分性校验提示（跨语料路由）

### 🇬🇧 English

The package provides a practical enterprise KB pattern:

- Ontology conventions for enterprise pages
- Required frontmatter requirements
- OpenClaw bootstrap reading order
- Governance rules for customer-facing outputs and high-risk actions
- A lightweight validator for frontmatter, duplicate IDs, and startup cache length
- Agentic RAG guidance for routing across corpora and checking context sufficiency

### 🇯🇵 日本語

このスキルセットは以下を提供します。

- 企業データのオントロジー設計
- 必須のフロントマター定義
- OpenClaw起動時の読み込み優先順
- 顧客向け回答・高リスクアクションのガバナンス
- Frontmatter/重複`object_id`/`hot.md`長さの簡易バリデーション
- エージェントRAGのルーティングと十分な文脈チェック

### 🇰🇷 한국어

이 스킬은 실무에서 바로 적용 가능한 KB 패턴을 제공합니다.

- 엔터프라이즈 온톨로지 템플릿
- 필수 frontmatter 규칙
- OpenClaw 시작 시 읽는 우선순위
- 고객 응답과 고위험 액션을 위한 거버넌스 규칙
- frontmatter, 중복 `object_id`, `hot.md` 길이를 검사하는 경량 검증기
- Agentic RAG 라우팅 및 충분한 맥락 확인 지침

### 🇪🇸 Español

Incluye:

- Patrón de ontología para el conocimiento empresarial
- Reglas obligatorias de frontmatter
- Orden de lectura recomendado para el arranque de OpenClaw
- Reglas de gobernanza para respuestas al cliente y acciones de alto riesgo
- Un validador ligero para frontmatter, IDs duplicados y longitud de `hot.md`
- Guías de Agentic RAG para enrutar entre corpus y verificar suficiencia de contexto

---

## Repository Layout / 仓库结构 / リポジトリ構成 / 리포지토리 구조 / Estructura del repositorio

```text
.
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
│   ├── agent-sync.md
│   ├── agentic-rag.md
│   ├── hot-cache.md
│   ├── ontology-schema.md
│   ├── ontology-vocabulary.md
│   └── vault-structure.md
├── scripts/
│   └── validate-vault.mjs
└── tests/
    └── validate-vault.test.mjs
```

---

## Quick Start / 快速上手 / クイックスタート / 빠른 시작 / Inicio rápido

### 1) 准备企业仓库结构 / Prepare your vault structure / 倉庫構造を準備 / 저장소 구조 준비 / Preparar estructura de vault

```text
Enterprise-Vault/
├── hot.md
├── Home.md
├── 00-Dashboard/
├── actions/
├── evidence/
├── openclaw/
│   ├── README.md
│   ├── manifest.json
│   ├── Corpus-Descriptions.md
│   └── Agentic-RAG-Workflow.md
├── products/
├── sales/
└── service/
```

### 2) 每个对象页补齐元数据 / Fill required metadata / 必要メタデータを追加 / 필수 메타데이터 추가 / Completar metadatos obligatorios

```yaml
---
type:
object_id:
status: needs_review
visibility: internal
owner:
source:
last_reviewed:
---
```

### 3) OpenClaw 阅读顺序 / Read order / 読み取り順序 / 읽기 순서 / Orden de lectura

```text
openclaw/manifest.json -> openclaw/Corpus-Descriptions.md -> openclaw/Agentic-RAG-Workflow.md -> hot.md -> Home.md
```

`hot.md` 不是事实来源，仅是“启动上下文”。保持简洁（中文建议 <= 500 字，英文建议 < 900 词左右）。

---

## Governance / 治理规则 / ガバナンス / 거버넌스 / Gobernanza

### 关键原则（中文）

- 客户问题回答前必须有上下文来源与充分性检查。
- 公共可见内容需经过审核（`status` 与 `visibility` 一致）。
- 高风险动作（下单、报价、变更权限、导出敏感内容）需要显式动作约束。
- `object_id` 必须唯一，跨页面引用建议显式并可追溯。

### Key governance points (EN)

- Before customer-facing answers, require source and sufficiency checks.
- Public-facing pages should pass review gates (`status` and `visibility` must align).
- High-risk actions (quoting, mutating workflows, exposing sensitive content) require explicit action constraints.
- `object_id` must be unique, and cross-links should be explicit and traceable.

### 主要补充（JP / KR / ES）

- **JP:** レビュー状態と公開可否が不整合だと、回答・提案は生成しない。
- **KR:** 검증되지 않은 공개용 항목은 고객 대면 응답의 1차 소스로 사용하지 않습니다.
- **ES:** No se debe responder a clientes sin verificar estado/revisión y calidad de contexto.

---

## Validation / 验证 / 検証 / 검증 / Validación

```bash
node scripts/validate-vault.mjs --vault /path/to/Enterprise-Vault
```

Validator checks / 校验项 / 検証項目 / 검증 항목 / Validaciones:

- Markdown files with YAML frontmatter
- Missing required object fields
- Duplicate `object_id`
- Missing `action_id` on action pages
- Unverified public pages
- `hot.md` body length

---

## Ontology / 术语体系 / オントロジー / 온톨로지 / Ontología

该技能内置一组可复用的企业术语：

- 对象类型：`company`, `product`, `certification`, `sales_scenario`, `quote_template`, `service_rule`, `action`, `evidence`
- 关系谓词：`has_certification`, `suitable_for`, `quoted_by`, `derived_from`, `requires_approval_from`, `supersedes`
- 行动家族：销售、支持、知识维护、升级响应
- 治理规则：`status`, `visibility`, 审批门槛, 错误更正

Detailed ontology vocab and schema docs are in `references/ontology-vocabulary.md` and `references/ontology-schema.md`.

---

## Agentic RAG / Agentic RAG / エージェントRAG / 에이전틱 RAG / RAG Agéntico

For multi-corpus enterprise answers, add a routing map and a sufficiency-check workflow:

- `openclaw/Corpus-Descriptions.md`: route which corpus to search for each workflow.
- `openclaw/Agentic-RAG-Workflow.md`: check whether enough context exists before giving answers.
- See `references/agentic-rag.md` for templates and tool contracts (`route_corpus`, `sufficient_context_check`).

---

## Publishing Notes / 发布说明 / 公開ノート / 공개 메모 / Notas de publicación

- Keep company-specific facts, client data, pricing tables, internal disputes, and sensitive docs out of the public repository.
- This repo should stay a reusable skill template.
- Store operational data in your own private vault / deployment environment.
