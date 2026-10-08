# 编程开发场景 - 角色全景

> 本目录定义编程开发（场景）下的全部角色。
>
> ⚠️ **灵活原则**：角色数量不固定，以下分层仅为全景参考。每个项目按需选择，可用 3 个角色完成小项目，也可用 20+ 角色铺满大团队。**角色数量随需增减，框架本身不限制。**
>
> 每个角色 = 平台无关描述 + 可选的框架实现（如 `_catpaw.md`、`_cursor.md`）。

## 角色分层总览

### 🎯 Layer A：产品 / 规划

| 角色 | 核心职责 | 何时用 |
|------|---------|-------|
| Product Manager | PRD、用户故事、优先级排序 | 从0→1、需求变更 |
| Scrum Master | Sprint 规划、站会、障碍移除 | 团队 ≥ 3 人、需要节奏 |
| Agile Coach | 流程改进、度量、回顾 | 团队磨合期、流程优化 |
| Release Manager | 版本发布、变更审批、回滚 | 多版本并行、灰度发布 |

### 🏗️ Layer B：架构 / 设计

| 角色 | 核心职责 | 何时用 |
|------|---------|-------|
| Tech Lead / Architect | 系统架构、技术决策、代码审查 | 几乎所有项目 |
| Solution Architect | 跨系统集成、技术选型、非功能需求 | 中大型系统、微服务 |
| Database Architect | 数据建模、索引策略、分库分表 | 数据密集型应用 |
| Cloud Architect | 云原生架构、成本优化 | K8s / Serverless 部署 |
| UI / UX Designer | 交互设计、设计系统、可用性 | 前端为主的项目 |
| UX Researcher | 用户访谈、可用性测试、度量 | 产品探索阶段 |

### 👨‍💻 Layer C：开发 / 实现

| 角色 | 核心职责 | 何时用 |
|------|---------|-------|
| Senior Full-Stack Dev | 通用开发、全栈实现 | 小型团队、MVP |
| Frontend Developer | React / Next.js / Vue 开发 | 前端为主的场景 |
| Backend Developer | API / 服务 / 中间件开发 | 后端为主的场景 |
| Mobile Developer | iOS / Android / 跨平台 | App 项目 |
| ML Engineer | 模型训练、推理优化、pipeline | AI 原生应用 |
| Data Engineer | ETL / 数据管道 / 湖仓 | 数据平台项目 |
| AI Engineer | LLM 集成、Agent 构建、RAG | AI 功能集成 |
| Blockchain Developer | 智能合约、链上交互 | Web3 项目 |
| CLI Tool Engineer | 命令行工具、DevTool | 工具/SDK 类项目 |
| Library / SDK Engineer | 开源库、API 客户端 | 基础设施类项目 |

### 🛡️ Layer D：质量 / 安全

| 角色 | 核心职责 | 何时用 |
|------|---------|-------|
| QA Engineer | 测试策略、自动化测试 | 几乎所有项目 |
| Code Reviewer | 代码审查、规范执行 | 团队协作 |
| Security Engineer | 威胁建模、安全审计 | 安全敏感项目 |
| Penetration Tester | 渗透测试、红队评估 | 金融/政务项目 |
| AI Ethics Reviewer | AI 偏见审查、可解释性 | AI 产品发布前 |

### 🚀 Layer E：运维 / 平台

| 角色 | 核心职责 | 何时用 |
|------|---------|-------|
| DevOps Engineer | CI/CD、容器化、部署 | 需要交付的项目 |
| SRE（Site Reliability Engineer）| SLO/SLA、故障响应、容量规划 | 线上服务 |
| Platform Engineer | 内部开发者平台、自助服务 | 多团队组织 |
| Database Administrator | 备份、恢复、性能调优 | 数据密集型 |

### 📚 Layer F：辅助 / 沟通

| 角色 | 核心职责 | 何时用 |
|------|---------|-------|
| Technical Writer | API 文档、架构决策文档 | 公开 API / 开源项目 |
| Translator / i18n | 国际化、文档翻译 | 多语言产品 |
| Technical Evangelist | 对外技术内容、社区运营 | 开源 / 平台型产品 |

## 全栈项目推荐角色组合（灵活模板）

> 以下为参考组合，实际按项目规模裁剪。

### 最小可行组合（1-2 人）
```
Tech Lead (兼架构)
Senior Full-Stack Dev (兼前后端)
QA Engineer (兼安全)
```

### 中小团队（3-7 人）
```
Product Manager
Tech Lead / Architect
Frontend Developer
Backend Developer
QA Engineer
DevOps Engineer
```

### 完整团队（8+ 人）
```
Product Manager + Scrum Master
Tech Lead + Solution Architect + Database Architect
Frontend + Backend + Mobile + AI Engineer
QA + Code Reviewer + Security Engineer
DevOps + SRE + Platform Engineer
Technical Writer + UX Designer
```

## 角色文件命名规范

```
roles/
├── expanded/                    # 平台无关描述
│   ├── PROGRAMMING_ROLES.md    # 本文件：总览
│   ├── product-manager.md
│   ├── tech-lead.md
│   ├── frontend-developer.md
│   └── ...
├── catpaw/                      # CatPaw 平台实现
│   ├── product-manager.md
│   └── ...
├── cursor/                      # Cursor 平台实现
│   └── ...
└── _index.md                    # 角色注册表
```
