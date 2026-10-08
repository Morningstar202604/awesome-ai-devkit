---
name: fullstack-roles
description: 全栈开发场景下的全部角色映射（11 层框架）
scenarios: [programming/fullstack]
---

# 全栈开发 — 角色映射

> 本场景使用 Awesome AI DevKit 框架的全部角色层。以下为推荐组合，数量按需增减。
>
> 通用角色定义参见 [`roles/expanded/PROGRAMMING_ROLES.md`](../../roles/expanded/PROGRAMMING_ROLES.md)（平台无关描述，含 20+ 角色的职责说明）。

---

## 极小项目 (1-3 人，推荐)

适用于 MVP、原型验证、个人项目。

| 角色 | 兼任职责 | 层 |
|------|---------|---|
| `tech-lead` | 架构 + DevOps + 代码审查 | Layer B + E |
| `senior-developer` | 前后端 + 数据库 + 测试 | Layer C |
| `qa-engineer` | 安全 + 测试 + 发布 | Layer D |

**技能重点**：`api-design`、`database-design`、`frontend-architecture`、`backend-architecture`、`test-strategy`

---

## 中小项目 (4-8 人)

适用于初创团队、业务型应用。

| 角色 | 核心职责 | 层 |
|------|---------|---|
| `product-manager` | PRD、需求优先级、验收 | Layer A |
| `tech-lead` | 系统架构、技术决策、代码审查 | Layer B |
| `frontend-developer` | React / Next.js / Vue 实现 | Layer C |
| `backend-developer` | API、服务、中间件 | Layer C |
| `qa-engineer` | 测试策略、自动化、质量保障 | Layer D |
| `devops-engineer` | CI/CD、容器化、部署 | Layer E |
| `ui-designer` | 交互设计、设计系统 | Layer B |
| `security-engineer` | 威胁建模、安全审计 | Layer D |

**技能重点**：增加 `cicd-pipeline`、`design-system`、`security`、`monitoring`

---

## 大项目 (9-15 人)

适用于中大型系统、多模块应用。

在中小项目基础上增加：

| 角色 | 核心职责 | 层 |
|------|---------|---|
| `ai-engineer` | LLM 集成、Agent 构建、RAG | Layer C |
| `data-engineer` | ETL、数据管道、数仓 | Layer C |
| `ml-engineer` | 模型训练、推理优化、MLOps | Layer C |
| `database-architect` | 数据建模、分库分表、索引策略 | Layer B |
| `sre-engineer` | SLO/SLA、故障响应、容量规划 | Layer E |
| `technical-writer` | API 文档、架构决策文档 | Layer F |
| `scrum-master` | Sprint 规划、站会、障碍移除 | Layer A |
| `ux-researcher` | 用户访谈、可用性测试 | Layer B |
| `mobile-developer` | iOS / Android / 跨平台 | Layer C |
| `code-reviewer` | 代码审查、规范执行 | Layer D |
| `penetration-tester` | 渗透测试、红队评估 | Layer D |

---

## 完整项目 (16+ 人)

全部 20+ 角色全覆盖，额外包括：

- `agile-coach` — 流程改进、度量、回顾
- `release-manager` — 版本发布、变更审批
- `cloud-architect` — 云原生架构、成本优化
- `platform-engineer` — 内部开发者平台
- `blockchain-developer` — 智能合约（如适用）
- `cli-tool-engineer` — 命令行工具
- `ai-ethics-reviewer` — AI 偏见审查

---

## 11 层框架总览

```
Layer A 产品/规划     product-manager, scrum-master, release-manager
Layer B 架构/设计     tech-lead, database-architect, ui-designer, ux-researcher
Layer C 开发/实现     frontend-developer, backend-developer, mobile-developer,
                     ai-engineer, data-engineer, ml-engineer
Layer D 质量/安全     qa-engineer, code-reviewer, security-engineer, penetration-tester
Layer E 运维/平台     devops-engineer, sre-engineer, platform-engineer
Layer F 辅助/沟通     technical-writer, translator, evangelist
```

---

## 全栈特有组合规则

1. **前后端比例**：前端 : 后端 通常为 1:1 到 2:1，根据 UI 复杂度调整
2. **DevOps 人员**：团队 ≤ 5 人时可由 tech-lead 兼任；> 5 人建议独立
3. **QA 介入时机**：从第一天开始，不是开发完成后再补
4. **安全左移**：security-engineer 在架构设计阶段介入，而非上线前审查
5. **AI/ML 按需**：仅在需要 AI 功能时引入 ai-engineer / ml-engineer
