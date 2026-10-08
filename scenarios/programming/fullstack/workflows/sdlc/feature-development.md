---
name: feature-development
description: 端到端功能开发工作流：从需求到部署的完整链路
version: "1.0"
agents_involved:
  - product-manager
  - tech-lead
  - frontend-developer
  - backend-developer
  - qa-engineer
  - devops-engineer
  - code-reviewer
estimated_duration: 根据复杂度（1 天 ~ 2 周）
---

# 功能开发工作流

> 从需求输入到功能上端的完整端到端流程。每个阶段明确定义了输入输出、参与角色和触发 hooks。

---

## 流程总览

```
requirements → design → schema-change → api-impl → ui-impl
    → integration → test → code-review → staging → deploy
```

---

## Stage 1: 需求分析与验收标准

**角色**: `product-manager`（主导）、`tech-lead`（评审）

**输入**:
- 需求描述（PRD）或用户故事
- 优先级标签（P0-P3）
- 相关业务上下文（现有功能截图、流程说明）

**产出**:
- 结构化的验收标准清单（Gherkin 格式）
- 确认的设计稿（Figma 链接或截图）
- 范围确认文档（含不做的事项）

**Hooks 触发**:
- `on_requirement_created` → 通知相关角色
- `before_requirement_review` → Tech Lead 自动检查技术可行性

**验收条件**:
- [ ] 所有功能点有明确的 Given/When/Then 描述
- [ ] 边界条件和异常场景已定义
- [ ] UI/UX 设计稿已确认（如适用）
- [ ] 数据模型变更已有初步方案

**进入下一阶段条件**: PM 与 Tech Lead 双方确认需求无歧义

---

## Stage 2: 技术设计与方案评审

**角色**: `tech-lead`（主导）、`backend-developer`、`frontend-developer`

**输入**:
- Stage 1 产出的需求和验收标准
- 现有系统架构文档
- 相关数据库 Schema

**产出**:
- 技术设计文档（`docs/design/feat-xxx.md`）
  - API 接口定义（OpenAPI snippet）
  - 数据模型变更（migration 草稿）
  - 前端组件结构设计
  - 错误码和异常处理策略
  - 性能目标（如响应时间 < 200ms）
- 任务拆解（Ticket 列表）
- 风险评估（如：是否需要灰度发布？）

**Hooks 触发**:
- `before_design_review` → 自动创建 design review 检查清单
- `after_design_review` → 归档评审结论和 TODO

**验收条件**:
- [ ] 所有 API 端点有明确的路径、方法、请求/响应格式
- [ ] 数据库 migration 方案已确认可回滚
- [ ] 前后端协作接口已对齐（mock data）
- [ ] 安全风险已评估（OWASP Top 10 检查）

---

## Stage 3: Schema / 数据模型变更

**角色**: `backend-developer`（主导）、`database-architect`（评审）

**输入**:
- Stage 2 设计文档中的数据模型章节
- 当前数据库 Schema

**产出**:
- 迁移文件（migration SQL 或 Prisma migration）
- 种子数据更新（如新增枚举值）
- 回滚脚本
- Schema 文档更新

**执行流程**:
1. 编写 migration 文件
2. 本地验证（`prisma migrate dev` 或手动 SQL）
3. 在开发环境执行并验证
4. 确认回滚可逆

**Hooks 触发**:
- `before_migration` → 自动备份开发数据库
- `after_migration` → 生成 Schema diff 报告
- `git.pre_commit` → 检查 migration 文件命名规范

**验收条件**:
- [ ] Migration 文件可正常执行
- [ ] 回滚测试通过
- [ ] 不影响现有数据完整性
- [ ] Schema 文档已更新

---

## Stage 4: API / 后端实现

**角色**: `backend-developer`

**输入**:
- Stage 2 的 API 设计
- Stage 3 的数据库 Schema

**产出**:
- API 实现代码（控制器/路由 → 服务层 → 数据层）
- 单元测试（覆盖率 ≥ 80%）
- API 文档片段（OpenAPI 注释）
- 错误日志埋点

**实现顺序**:
1. 数据仓库层（Repository / Prisma Client）
2. 业务服务层（Service / Use Case）
3. 路由控制器（Controller / Handler）
4. 中间件（认证、验证、日志）
5. 单元测试编写

**Hooks 触发**:
- `before_tool_call` → `[auth-check, sql-injection-guard]`
- `after_tool_call` → `[log-writer]`
- `git.pre_commit` → `[lint, format, type-check, migration-check]`

**验收条件**:
- [ ] 所有 API 端点通过手动测试（curl/Postman）
- [ ] 单元测试全部通过
- [ ] `type-check` 零错误
- [ ] 错误处理覆盖所有异常分支
- [ ] 新增端点有完整 OpenAPI 注释

---

## Stage 5: UI / 前端实现

**角色**: `frontend-developer`（主导）、`ui-designer`（评审）

**输入**:
- Stage 2 的设计稿与组件结构
- Stage 4 的 API 文档（后端应已完成或提供 mock）

**产出**:
- 页面/组件代码
- Storybook 组件文档（如适用）
- 前端单元测试 + 组件测试
- 端到端的 mock 数据（用于独立开发）

**实现顺序**:
1. 静态 UI → 还原设计稿，不接 API
2. 数据绑定 → 连接 API（真实或 mock）
3. 交互逻辑 → 表单验证、加载/错误态
4. 响应式与无障碍（a11y）检查
5. 单元测试

**Hooks 触发**:
- `git.pre_commit` → `[lint, format, type-check, a11y-check]`
- `after_component_create` → 自动更新 Storybook

**验收条件**:
- [ ] UI 还原度 ≥ 95%（对比设计稿）
- [ ] 所有交互状态可正常展示（加载/空/错误）
- [ ] 组件测试覆盖关键路径
- [ ] Lighthouse 无障碍评分 ≥ 90

---

## Stage 6: 集成测试

**角色**: `qa-engineer`（主导）、`backend-developer`、`frontend-developer`

**输入**:
- Stage 4 和 Stage 5 的实现代码
- 部署到集成/测试环境后的完整应用

**产出**:
- 集成测试用例与结果报告
- E2E 测试用例（Playwright）
- 缺陷报告（Bug 列表）
- 环境配置文档更新

**Hooks 触发**:
- `before_integration_test` → 自动部署到测试环境
- `after_test_run` → 生成测试覆盖率报告

**验收条件**:
- [ ] 所有验收标准（Gherkin scenarios）通过
- [ ] E2E 测试覆盖关键用户路径
- [ ] 无 P0/P1 缺陷
- [ ] API 契约测试通过（Pact 或类似工具）

---

## Stage 7: 代码审查

**角色**: `code-reviewer`、`tech-lead`

**输入**:
- Stage 4 和 Stage 5 的代码变更
- 相关测试报告和 CI 结果

**产出**:
- Review 评论与 Approved / Request Changes
- 合并后的主分支
- CR 决策记录

**审查清单**:
- [ ] 实现是否符合设计文档
- [ ] 边界条件和错误处理是否完善
- [ ] 是否有不必要的复杂度
- [ ] 测试是否覆盖了修改的所有路径
- [ ] 性能是否有隐患（N+1 查询、无界列表等）

**Hooks 触发**:
- `github.pre_merge` → `[test-smoke, security-scan, lint-diff]`
- `after_review_approved` → 自动准备 squash merge

**验收条件**:
- [ ] 至少一人 Approved
- [ ] 所有 Review Comments 已处理
- [ ] CI 全部绿色
- [ ] 无合并冲突

---

## Stage 8: 预发布验证

**角色**: `devops-engineer`、`qa-engineer`

**输入**:
- 合并到主分支的代码
- Staging 环境

**产出**:
- Staging 环境部署成功
- 冒烟测试通过记录
- 性能基线报告

**检查项**:
- [ ] 配置项（环境变量、密钥）已就位
- [ ] 数据库 migration 在 staging 执行成功
- [ ] 关键用户流程在 staging 验证通过
- [ ] 负载测试（如适用）通过

---

## Stage 9: 生产发布

**角色**: `devops-engineer`（主导）、`product-manager`（验收）

**输入**:
- 通过 staging 验证的代码版本
- Release 检查清单

**产出**:
- 生产环境部署成功
- Release 文档（CHANGELOG）
- 监控仪表板更新

**发布策略**（由 Tech Lead 决定）:
- **滚动更新**：逐步替换实例，零停机
- **蓝绿部署**：并行运行新旧版本，一键切换
- **灰度发布**：先开放 5% 流量 → 25% → 50% → 100%

**Hooks 触发**:
- `before_deploy` → `[security-scan, dependency-audit]`
- `after_deploy` → `[smoke-test, monitoring-check, notify-slack]`
- `on_rollback` → `[alert-dispatcher, incident-create]`

**验收条件**:
- [ ] 生产环境部署成功，所有实例健康
- [ ] Smoke 测试通过
- [ ] 监控无异常告警
- [ ] PM 验收确认功能符合需求

---

## 异常流程

| 异常场景 | 处理方式 |
|---------|---------|
| 需求不清晰 | 返回 Stage 1，PM 补充信息 |
| 设计评审不通过 | 返回 Stage 2，Tech Lead 重新设计 |
| 测试发现严重 Bug | 返回 Stage 4/5 修复，重新走集成测试 |
| Review 提出重大修改 | 开发者修改后重新提交审查 |
| 生产发布失败 | 执行回滚，触发 incident-response 工作流 |
