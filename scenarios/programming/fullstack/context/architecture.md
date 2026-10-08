# Architecture Decision Records (全栈场景)

> Awesome AI DevKit — ADR 模板。每项决策一个 `## adr-NNN` 段落。

---

## adr-001 — [示例] 前端框架选择

- **Status**: accepted
- **Date**: 2025-01-10
- **Deciders**: tech-lead, frontend-developer

### Context

项目需要一个支持 SSR、TypeScript 第一公民的 React 框架。备选项：
Next.js 15、Remix、Astro。

### Decision

采用 **Next.js 15 (App Router)**。

### Consequences

- 正面：RSC 带来首屏性能提升；官方支持充足；生态最大。
- 负面：版本更新频繁，团队需跟进 breaking changes；构建打包时间相对较长。

### References

- RFC: `requirements/frontend-rfc-2025-01.md`

---

## adr-002 — [示例] API 协议选择

- **Status**: accepted
- **Date**: 2025-01-12
- **Deciders**: tech-lead, backend-developer

### Context

前端与后端通信协议：REST (OpenAPI) 或 GraphQL。考虑因素：团队熟悉度、
接口文档化、移动端复用需求。

### Decision

采用 **REST + OpenAPI 3.1 规范**。暂不使用 GraphQL。

### Consequences

- 正面：学习成本低，工具链成熟（Swagger UI, codegen 完备）。
- 负面：过度获取/欠获取问题需靠良好的资源建模解决。

---

## adr-003 — [示例] 数据库选型

- **Status**: accepted
- **Date**: 2025-01-15
- **Deciders**: tech-lead, backend-developer, database-architect

### Context

主要数据存储需求：关系型实体 + 全文检索 + 会话缓存。

### Decision

- **OLTP**: PostgreSQL 16 (主数据库)
- **Cache**: Redis 7 (会话 + 查询缓存)
- **Search**: Meilisearch (若全文检索需求不强，备用 PostgreSQL FTS)

### Consequences

- 正面：Postgres 生态极强；Redis 通用且成熟。
- 负面：若后续全文检索量增大，Meilisearch 扩展能力需评估。

---

## adr-004 — [模板 — 请按需增删]

- **Status**: proposed | accepted | deprecated | superseded
- **Date**: YYYY-MM-DD
- **Deciders**: list of roles

### Context

[需要做出决策的背景描述]

### Decision

[最终选择的方案]

### Consequences

- 正面：[优点]
- 负面：[缺点 / 风险]

### References

- 相关 RFC / 讨论链接

---

<!-- 💡 添加新 ADR 时，请复制 adr-004 模板，递增编号 -->
