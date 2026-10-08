# 全栈开发工作流索引

> Awesome AI DevKit — 全栈场景下的端到端工作流定义。

## 工作流目录

| 文件 | 说明 | 涉及角色 |
|------|------|---------|
| `sdlc/feature-development.md` | 端到端功能开发：需求 → 设计 → 实现 → 测试 → 部署 | PM, TechLead, FE, BE, QA, DevOps |
| `sdlc/bug-fix.md` | Bug 修复：复现 → 定位 → 修复 → 验证 → 回归 | Dev, QA |
| `sdlc/refactoring.md` | 重构：识别 → 计划 → 增量重构 → 验证 | Senior Dev, Code Reviewer |
| `release/release-checklist.md` | 发布前检查：安全、性能、测试、文档、变更日志 | QA, DevOps, TechLead, TW |
| `incident/incident-response.md` | 故障响应：检测 → 分级 → 缓解 → 解决 → 复盘 | SRE, DevOps, TechLead |
| `onboarding/new-developer.md` | 新成员入职：环境 → 代码 → 流程 → 首提交 | TechLead, PM |

---

## 工作流结构

每个工作流定义包含：

```yaml
name: 工作流名称
description: 用途说明
stages:
  - name: 阶段名称
    agents: [参与角色]
    inputs: [输入]
    outputs: [产出]
    hooks: [触发的 hooks]
    next: [下一阶段条件]
```

---

## 触发方式

| 触发点 | 命令 |
|--------|------|
| 功能开发 | `awesome-devkit workflow run feature-development --requirement "..." ` |
| Bug 修复 | `awesome-devkit workflow run bug-fix --issue-id PROJ-123` |
| 重构 | `awesome-devkit workflow run refactoring --scope "module-name"` |
| 发布检查 | `awesome-devkit workflow run release-checklist --version 1.2.0` |
| 故障响应 | `awesome-devkit workflow run incident-response --severity P1` |
| 入职流程 | `awesome-devkit workflow run new-developer --name "张三" --role frontend` |
