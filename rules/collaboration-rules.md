---
name: 协作规范
description: AI 代理与人类团队协作约定——Commit/PR/Review/沟通规范
layer: 1-Rules
scenarios: [programming/fullstack]
---

# 协作规范

## Commit 规范（Conventional Commits）

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

| type | 含义 |
|------|------|
| feat | 新功能 |
| fix | 修复 bug |
| docs | 文档变更 |
| refactor | 重构（无功能变更） |
| test | 测试增改 |
| chore | 构建/工具变更 |
| perf | 性能优化 |
| security | 安全修复 |

```
feat(auth): add OAuth2 PKCE flow for SPA clients
fix(api): correct pagination offset when page=0
perf(db): add composite index for user_orders query
```

## Pull Request 规范

- 标题格式同 commit
- 描述包含：变更原因、影响范围、测试方式
- 关联 issue：`Closes #123`
- 超过 500 行变更必须拆分
- CI 全部通过才可合并
- 至少 1 人 approve

## Code Review 检查维度

1. **正确性** — 逻辑是否正确处理边界条件
2. **安全性** — 注入、XSS、CSRF、权限绕过
3. **性能** — N+1 查询、内存泄漏、阻塞 I/O
4. **可维护性** — 命名、注释、单一职责
5. **测试覆盖** — 新增代码是否有对应测试

## AI 代理协作约定

| 场景 | AI 行为 |
|------|--------|
| 不确定需求 | 先列出假设并标注 `⚠️ inferred`，再实现 |
| 发现安全漏洞 | 立即暂停，提示风险，不静默修复 |
| 遇到 blocker | 报告阻塞原因，不跳过继续 |
| 大规模重构 | 先提交重构计划，分步执行 |
| 测试失败 | 分析根因而非仅修复断言 |
