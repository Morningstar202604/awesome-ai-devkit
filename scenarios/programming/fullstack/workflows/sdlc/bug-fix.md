---
name: bug-fix
description: Bug 修复工作流：从问题报告到修复验证的完整流程
version: "1.0"
agents_involved:
  - qa-engineer
  - frontend-developer
  - backend-developer
  - tech-lead
estimated_duration: 1 小时 ~ 3 天（视严重程度）
severity_levels: [P0, P1, P2, P3]
---

# Bug 修复工作流

> 标准化 bug 修复流程，确保每个问题都有完整闭环：复现 → 定位 → 修复 → 验证 → 回归。

---

## 流程总览

```
report → triage → reproduce → isolate → fix → test → verify → close
```

---

## Stage 1: Bug 报告与录入

**角色**: 任何人（QA、用户、监控告警）

**输入**:
- Bug 标题和描述
- 复现步骤
- 预期行为 vs 实际行为
- 环境信息（浏览器/OS/版本）
- 截图/录屏/错误日志

**产出**:
- 标准化的 Bug Ticket（Project Issue Tracker）
- 自动分配严重等级

**严重等级定义**:
| 等级 | 说明 | 响应时间 |
|------|------|---------|
| P0 | 核心功能不可用、数据丢失、安全漏洞 | 立即 |
| P1 | 主要功能受损，无可用 workaround | 4 小时内 |
| P2 | 功能受影响，存在 workaround | 24 小时内 |
| P3 | 体验问题、UI 瑕疵、非关键功能异常 | 本周内 |

**Hooks 触发**:
- `on_bug_reported` → 自动分配给相关模块 owner
- `on_bug_p0` → 立即通知 on-call 人员

---

## Stage 2: 分级与优先级

**角色**: `tech-lead`（主导）、`product-manager`（业务影响评估）

**输入**:
- Stage 1 的 Bug Ticket

**产出**:
- 确认的严重等级和优先级
- 修复 SLA（Service Level Agreement）
- 分配的开发人员
- 是否需要热修复（hotfix）的判断

**决策树**:
```
是否影响生产环境？
├── 是 → 是否影响用户核心流程？
│   ├── 是 → P0，立即 hotfix
│   └── 否 → P1，4h 内修复
└── 否 → 是否影响交付？
    ├── 是 → P2，当前 sprint 内修复
    └── 否 → P3，排入 backlog
```

**进入下一阶段条件**: Tech Lead 确认严重等级并指派开发者

---

## Stage 3: 复现

**角色**: `qa-engineer`（主导），被指派的开发者协助

**输入**:
- Bug 报告中的复现步骤
- 相关的测试环境

**产出**:
- 可稳定复现的最小步骤（Minimal Reproduction）
- 复现视频或截图
- 环境配置快照

**复现策略**:
1. 按报告步骤尝试复现
2. 如无法确认，检查版本差异（是否在最新版本仍然存在）
3. 尝试简化条件（去除不必要的步骤）
4. 如涉及数据，创建最小复现数据集

**Hooks 触发**:
- `on_bug_reproduced` → 更新 Ticket 状态为 "In Progress"
- `on_bug_not_reproduced` → 标记为 "Need Info"，通知报告者

**验收条件**:
- [ ] Bug 可在测试环境中稳定复现
- [ ] 最小复现步骤已记录（3 步以内为佳）
- [ ] 确定的触发条件和边界

---

## Stage 4: 定位根因

**角色**: 被分配的`backend-developer`或`frontend-developer`

**输入**:
- Stage 3 的复现代码和复现步骤
- 相关源代码

**产出**:
- 根因分析报告
- 定位到的具体代码位置（文件 + 行号）
- 修复方案设计

**定位方法**:
1. **日志分析** — 检查应用日志、浏览器控制台
2. **断点调试** — 在关键路径加断点追踪数据流
3. **二分排查** — 通过 git bisect 定位引入 bug 的 commit
4. **数据检查** — 验证数据库状态是否符合预期
5. **依赖检查** — 检查第三方服务是否正常

**Hooks 触发**:
- `after_isolation` → 自动记录根因到 Ticket

**验收条件**:
- [ ] 已明确问题根因（不是表象）
- [ ] 确定了影响范围（是否还有其他地方有相同问题）
- [ ] 修复方案与团队对齐

---

## Stage 5: 修复实现

**角色**: 被分配的开发者

**输入**:
- Stage 4 的根因分析和修复方案
- 相关代码库

**产出**:
- 修复代码（commit/PR）
- 对应的回归测试（确保 bug 不会再次出现）
- 更新相关文档（如发现文档与实际不符）

**修复原则**:
1. **最小改动**：只修改问题代码，不顺手重构
2. **添加回归测试**：修复前先写一个验证 bug 的测试，确认失败后再修复
3. **保持兼容**：不引入破坏性变更
4. **修复根因**：不修症状

**Hooks 触发**:
- `before_tool_call` → `[auth-check, rate-limit]`
- `git.pre_commit` → `[lint, format, type-check, test-related]`

**验收条件**:
- [ ] 回归测试通过
- [ ] 原有测试不受影响
- [ ] 代码通过 self-review checklist
- [ ] 修复符合编码规范

---

## Stage 6: 测试验证

**角色**: `qa-engineer`（主导）、开发者协助

**输入**:
- Stage 5 的修复代码
- Stage 3 的复现步骤

**产出**:
- 验证通过/失败结论
- 回归测试结果
- 影响范围测试报告

**验证流程**:
1. **Bug 验证**：按复现步骤验证问题已修复
2. **回归测试**：运行涉及模块的全部测试套件
3. **影响范围检查**：检查修改是否影响关联功能
4. **边界测试**：验证修复未引入新的边界问题

**Hooks 触发**:
- `on_bug_fix_verified` → 自动更新 Ticket 状态
- `on_regression_found` → 创建新的关联 Bug Ticket

**验收条件**:
- [ ] Bug 按照复现步骤验证已修复
- [ ] 模块回归测试全部通过
- [ ] 影响范围内功能正常
- [ ] 无新引入的 console 错误/warnings

---

## Stage 7: 审查与合并

**角色**: `code-reviewer`、`tech-lead`

**输入**:
- Stage 5 的修复代码
- Stage 6 的测试结果

**审查重点**:
- 修复是否针对根因
- 测试是否足够（能否防止同类 bug 复发）
- 是否存在更优方案
- 是否需要同时修复环境/数据问题

**快速通道**（仅限 P0/P1 hotfix）:
- 简化审查流程，但至少 1 人 approve
- 合并后补全回归测试

**Hooks 触发**:
- `github.pre_merge` → `[test-smoke, lint-diff]`
- `after_merge` → `[notify-qa-staging]`

**验收条件**:
- [ ] 至少 1 人 approve
- [ ] CI 全部通过
- [ ] Hotfix 场景下应立即部署到生产

---

## Stage 8: 关闭与总结

**角色**: `qa-engineer`

**输入**:
- 所有阶段完成

**产出**:
- 更新 Ticket 状态为 Closed
- 根因标签（如 `regression`、`missing-validation`、`race-condition`）
- 是否需要流程改进的标记
- 月度 Bug 统计汇总数据

**关闭检查**:
- [ ] Bug 在生产环境验证修复
- [ ] 回归测试已提交
- [ ] 相关文档已更新
- [ ] 如需要，已在团队分享复盘中总结教训

---

## 异常流程

| 场景 | 处理 |
|------|------|
| 无法复现 | 与报告者确认环境差异；关闭并标记 "Cannot Reproduce" |
| 修复引入新 Bug | 回滚，创建新 Ticket，重新走本流程 |
| Hotfix 紧急发布 | 跳过常规审查，但 24h 内补全审查和技术债务记录 |
| 第三方服务问题 | 添加监控 + 降级方案，但不改变外部依赖 |
