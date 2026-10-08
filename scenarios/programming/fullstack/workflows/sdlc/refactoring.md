---
name: refactoring
description: 重构工作流：从识别到验证的安全增量重构流程
version: "1.0"
agents_involved:
  - senior-developer
  - code-reviewer
  - qa-engineer
  - tech-lead
estimated_duration: 半天 ~ 1 周
---

# 重构工作流

> 安全、增量的代码重构流程。核心原则：**行为不变，结构改善**。

---

## 流程总览

```
identify → plan → baseline → incremental → verify → cleanup → review
```

---

## Stage 1: 识别与提案

**角色**: `senior-developer`（发起）、`tech-lead`（审批）

**输入**:
- Code smell 指标（复杂度、重复率、测试覆盖率低）
- 技术债务跟踪列表
- 业务变更需求（需要更灵活的代码结构）

**产出**:
- 重构提案文档，包含：
  - 重构目标（改什么，为什么）
  - 影响范围分析
  - 预估工作量和风险
  - 验收标准（行为不变的具体定义）

**触发场景**:
- 圈复杂度 > 10 的函数需要拆分
- 重复代码出现 3 次以上需抽象
- 模块依赖方向违反架构层
- 测试难以编写（说明接口设计有问题）

**Hooks 触发**:
- `on_refactor_proposed` → 创建 Tech Lead review 请求

**审批条件**:
- [ ] 提案明确说明"为什么现在要重构"（业务驱动 > 技术洁癖）
- [ ] 已有完整的测试基准（确保重构过程中行为不变）
- [ ] 不影响当前 sprint 交付计划

---

## Stage 2: 计划与范围界定

**角色**: `senior-developer`、`code-reviewer`

**输入**:
- Stage 1 的重构提案
- 依赖关系图（import graph）

**产出**:
- 重构计划，包含：
  - 分步实施计划（每步一个独立 commit）
  - 每步的影响单元（按文件或函数）
  - 回滚策略
  - testing 策略（如何确保每步行为不变）

**SMART 计划模板**:
```
目标：将 UserService 从单文件拆分为 Repository + Service + Validator 三层
步骤 1（独立 commit）：提取 Repository 层 → 新增文件，旧代码不变
步骤 2（独立 commit）：依赖注入切换 → 使用 Repository 替代 inline 查询
步骤 3（独立 commit）：提取 Validator → 纯函数抽离
步骤 4（独立 commit）：删除旧代码 → 全部切换到新结构
回滚：每个 commit 可独立 revert，不影响主分支
```

**Hooks 触发**:
- `on_refactor_planned` → 标记相关 code area 为 "refactoring-in-progress"

**验收条件**:
- [ ] 每步重构可独立验证（不依赖后续步骤）
- [ ] 每步的计划粒度 ≤ 1 天工作量
- [ ] 有完整的测试基准可用

---

## Stage 3: 建立测试基线

**角色**: `senior-developer`（主导）、`qa-engineer`（审查测试完整性）

**输入**:
- 待重构代码
- Stage 2 的重构计划

**产出**:
- 完整的测试覆盖（对现有行为的"保护网"）
- 行为基线文档（输入 → 预期输出）

**测试策略**:
1. **Characterization Tests**：为现有代码编写测试，记录当前行为（即使有 bug 也要先锁定）
2. **Integration Tests**：确保外部依赖和边界行为不变
3. **Performance Baseline**：记录重构前的响应时间/内存数据

**不要做的事**:
- 不要在重构前修改已有测试的期望值
- 不要在测试中 mock 过多（应测试行为而非实现）

**Hooks 触发**:
- `on_tests_added` → 自动运行全量测试确认 baseline 全绿

**验收条件**:
- [ ] 测试覆盖率 ≥ 重构涉及模块的 90%
- [ ] 基线测试全部通过
- [ ] Performance 基线数据已记录（Time、Memory、DB Query count）

---

## Stage 4: 增量重构执行

**角色**: `senior-developer`

**输入**:
- Stage 2 的分步计划
- Stage 3 的测试基线

**产出**:
- 每一小步的独立 commit
- 每一步后的全绿测试状态

**执行纪律**:
1. **每步一个 commit**：回滚时粒度精确
2. **每步后全量测试**：确保行为未变
3. **不混合重构与功能变更**：重构 PR 不引入新行为
4. **频繁 push**：避免长时间本地分支

**常用重构手法**:

| 手法 | 适用场景 | 风险 |
|------|---------|------|
| Extract Method | 长函数 | 低 |
| Extract Class | 上帝类 | 中 |
| Replace Conditional with Polymorphism | 复杂的 switch/if | 中 |
| Introduce Parameter Object | 参数列表过长 | 低 |
| Move Feature Between Object | 职责分散 | 中 |
| Replace Inheritance with Delegation | 继承滥用 | 中 |

**Hooks 触发**:
- `git.pre_commit` → `[lint, type-check, test-related-module]`
- `git.pre_push` → `[test-smoke, complexity-check]`

**验收条件**:
- [ ] 每一步 commit 的测试全部通过
- [ ] 无语义变化（仅结构变化）
- [ ] 代码复杂度指标改善（圈复杂度、认知复杂度）

---

## Stage 5: 行为验证

**角色**: `qa-engineer`、`senior-developer`

**输入**:
- 重构后的全部代码
- Stage 3 的测试基基线

**产出**:
- 行为一致性报告
- Performance 对比报告（重构前 vs 重构后）
- 已知差异清单（如重构中有意修正的小问题，需经 Tech Lead 审批）

**验证项目**:
1. **功能一致性**：重构前后对相同输入产生相同输出
2. **边界处理**：null、空集、超限值、并发
3. **性能对比**：确保不引入性能回退（响应时间 ≤ 基线的 110%）
4. **日志对比**：确认日志输出格式未改变（监控依赖日志格式）

**Hooks 触发**:
- `on_refactor_verified` → 对比报告输出到 PR 评论

**验收条件**:
- [ ] 功能测试 100% 通过
- [ ] 性能无回退（在可接受范围内）
- [ ] 边界场景处理一致
- [ ] 日志/错误码无变化

---

## Stage 6: 清理与文档化

**角色**: `senior-developer`

**输入**:
- Stage 4 的重构 commit 序列

**产出**:
- Squash 合并的 clean commit
- 更新的架构文档（如果结构变更较大）
- 更新的 README 或开发者指南

**清理内容**:
- 删除调试用的 console.log / print
- 删除临时的 @ts-ignore 注释
- 更新已过时的 inline 注释
- 清理未使用的 import
- 检查并删除因此变得无用的代码（"死代码"）

**Hooks 触发**:
- `before_merge` → `[dead-code-check, unused-import-check, doc-lint]`

**验收条件**:
- [ ] 无无用代码残留
- [ ] 注释与代码同步
- [ ] 架构文档（如有需要）已更新

---

## Stage 7: 最终审查

**角色**: `code-reviewer`、`tech-lead`

**输入**:
- 重构后的最终代码
- 行为验证和性能报告

**审查重点**（区别于常规 CR）:
- 结构变更是否提升可维护性（而非简单地"换一种写法"）
- 抽象层次是否合理（不过度设计）
- 新结构是否与项目其他部分风格一致
- 变更是否可以作为团队的最佳实践参考

**Hooks 触发**:
- `github.pre_merge` → `[test-full, lint-full, type-check, doc-check, complexity-report]`
- `after_merge` → 标记技术债务为 "resolved"

**验收条件**:
- [ ] 2 人以上 approve（重构需要更高审查标准）
- [ ] 全量测试通过
- [ ] 无明显的设计退步
- [ ] 复杂度指标改善有数据支撑

---

## 异常情况

| 场景 | 处理 |
|------|------|
| 重构过程中发现重大设计缺陷 | 暂停重构，升级至 Tech Lead，可能需要设计评审 |
| 重构导致测试失败 | 先确认是测试过时还是行为变更，如果是行为变更则停止重构 |
| 重构成本远超预期 | 缩小范围至最有价值的部分，其余记录为技术债务 |
| PR 争议较大 | 组织 design review 会议统一意见，不强行推进 |
