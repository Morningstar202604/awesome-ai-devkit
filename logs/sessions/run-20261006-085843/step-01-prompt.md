# Step: 需求分析与验收标准
**Description**: 将模糊需求转化为可测试的验收标准
## Context
- Task: example-feature
- Working directory: C:\Users\Administrator\.meituan-catpaw\3674654490\desk_default_workspace\awesome-ai-devkit
## Required Outputs
- `docs/requirements/<feature>.md`
## Reference Skills
## Skill: project-management

---
name: project-management
description: 项目管理：Sprint规划、估算(故事点/T恤尺码)、回顾会议、燃尽图
layer: 5-Skills
scenarios: [programming/fullstack]
tags: [project-management, sprint, scrum, estimation, retrospective]
---

# 项目管理

## 触发条件
当需要规划迭代、组织团队协作、或跟踪项目进度时触发。

## 核心模式

### 1. Sprint 规划

```
Sprint 结构（2 周迭代）:
────────────────────────────────────────────────
Day 1      Sprint Planning (2-4h)
           ├─ 选出 P0 任务（must-have）
           ├─ 拆分为 < 8h 的子任务
           └─ 团队承诺 Sprint Goal

Day 2-9    开发 (Daily Standups 15min)
           ├─ 昨天完成了什么
           ├─ 今天要做什么
           └─ 有什么阻塞

Day 10     Sprint Review (1h) + Retrospective (1h)

Sprint Goal 评估:
  完成率 = completed / committed
  健康区间: 70-90% (太低 = 估算差, 太高 = 没挑战)
```

### 2. 故事点估算（Story Points）

```
T恤尺码法（快速估算）:
────────────────────────────────────────────────
XS  = 1 SP    半天内完成的小改动
S   = 2 SP    1 天，明确且简单
M   = 3 SP    1-2 天，有中等不确定性
L   = 5 SP    3-5 天，需要拆分审视
XL  = 8 SP    必须拆分后再估算

Fibonacci 法（精确估算）:
────────────────────────────────────────────────
1, 2, 3, 5, 8, 13, 21

规则:
  - 13+ 表示需要拆分（太大无法准确估算）
  - 团队达成共识（不是 PO 指定）
  - 参考已有完成的 story 做校准

Planning Poker 流程:
  1. PO 描述 story（5min）
  2. 团队提问澄清（10min）
  3. 每张牌同时翻出
  4. 最高分和最低分讨论差异原因
  5. 重新投票直到共识（最多 3 轮）

团队速率（Velocity）:
  Sprint 1: 完成 25 SP
  Sprint 2: 完成 32 SP
  Sprint 3: 完成 28 SP
  速率 = avg(25, 32, 28) ≈ 28 SP/Sprint
  → 下个 Sprint 不要承诺超过 30 SP
```

```typescript
// Story structure for issue tracking
interface Story {
  id: string;
  title: string;
  description: string;
  acceptanceCriteria: string[];
  storyPoints: number;
  priority: "P0" | "P1" | "P2" | "P3";
  type: "feature" | "bug" | "tech-debt" | "spike";
  assignee?: string;
  epic?: string;
  labels: string[];
}

// Template for a well-defined story
const newStory: Story = {
  id: "FE-142",
  title: "User can filter products by price range",
  description: `As a shopper, I want to filter products by price
    so that I can find items within my budget.`,
  acceptanceCriteria: [
    "Price slider appears on product listing page",
    "Min $0, Max $1000 with step $10",
    "Filter updates results in real-time (< 300ms)",
    "URL reflects filter state (shareable)",
    "No results state shown when filter is too narrow",
    "Works together with existing category filter",
  ],
  storyPoints: 3,
  priority: "P1",
  type: "feature",
  assignee: "alice",
  epic: "product-discovery",
  labels: ["frontend", "ux"],
};
```

### 3. Daily Standup 与进度跟踪

```
Daily Standup 模板（15min，站姿）:
────────────────────────────────────────────────
每人回答 3 个问题:
  1. 昨天我完成了什么？
  2. 今天我计划做什么？
  3. 有什么阻塞我？

规则:
  ✓ 每人 ≤ 2min
  ✓ 阻塞讨论在会后（不超过会议时间）
  ✓ 阻塞立即升级给 Scrum Master/TL

常见反模式:
  ✗ 向 manager 汇报状态（应该向团队同步）
  ✗ standup 开成讨论会（问题会后跟进）
  ✗ 只有开发参与（缺少设计/PM 视角）
```

### 4. Sprint 回顾（Retrospective）

```
回顾会议框架 (60min):
────────────────────────────────────────────────

1. Set the Stage (5min)
   - 今天的 mood vote (1-5)

2. Gather Data (15min) — 3 列法
   ┌──────────────┬──────────────┬──────────────┐
   │   What Went  │  What Could  │  Wh
... (truncated)
## Instructions
1. Read all reference skill(s) carefully
2. Produce all required output files
3. Self-verify against quality gate
4. If quality gate fails, fix and re-verify until passing
5. When done, reply with 'DONE' and a one-line summary
Begin.