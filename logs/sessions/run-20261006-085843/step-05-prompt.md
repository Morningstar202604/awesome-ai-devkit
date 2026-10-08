# Step: 集成测试
## Context
- Task: example-feature
- Working directory: C:\Users\Administrator\.meituan-catpaw\3674654490\desk_default_workspace\awesome-ai-devkit
## Required Outputs
(no specific outputs)
## Quality Gate
After completing this step, verify: **集成测试全部通过，核心 E2E 通过**
## Reference Skills
## Skill: test-strategy

---
name: test-strategy
description: |
  测试策略完整制定与自动化实现指南，涵盖测试金字塔与菱形模型选择、单元/集成/E2E/性能测试分类与职责边界、覆盖率目标设定与管理、测试数据工厂（Factory/Fixture）策略、CI/CD 集成最佳实践，提供 TypeScript + Python 双语代码示例与可执行测试模板
layer: 5-Skills
scenarios: [programming/fullstack]
tags: [testing, unit, integration, e2e, tdd, coverage, test-strategy]
---

# 测试策略完整制定与自动化实现指南

## 触发条件

当遇到以下任一场景时，务必使用本 Skill：

- 新项目启动需要从零制定端到端测试策略
- 现有项目测试覆盖率低或测试用例难以维护
- 引入 TDD（测试驱动开发）工作流
- 区分哪些功能应由单元测试 vs 集成测试 vs E2E 覆盖
- 测试运行时间过长，需拆分或优化
- 排查 flaky test（间歇性失败）的根因与修复方案
- 建立或重构测试数据管理体系
- 配置 CI 流水线中的测试门禁（quality gate）
- 从 Write-after 测试向 Contract / Snapshot 测试迁移

---

## 核心模式

### 1. 测试模型选择

**经典金字塔（适用于纯业务逻辑/后端为主的项目）：**

```
        /  E5  \          ← 少量，核心用户旅程（登录→购买）
       /--------\           慢但高信心
      / 集成测试  \        ← 中等量，模块协作（API + DB）
    /--------------\        中速，边界覆盖
   /   单 元 测 试   \     ← 大量，全分支边界
/______________________\    快速，逻辑正确性
```

**菱形模型（适用于前端为主/重交互的项目）：**

```
      /    E2E   \        ← 少量但关键路径
     /  集成/E2E   \      ← 中等，组件组合
    / 集成测试（API） \   ← 主要着力点
   /  单元（业务核心）  \  ← 不可忽视
  /______________________\
```

**选型原则：**

| 项目特征 | 推荐模型 | 核心投入层 |
|---------|---------|-----------|
| 后端 API 主导 | 金字塔 | 单元 + 集成 |
| 前端 SPA 主导 | 菱形 | 集成 + 组件 |
| CRUD + 复杂逻辑混合 | 金字塔 | 单元（逻辑层） |
| 微服务架构 | 菱形 | 集成（契约测试） |
| 数据驱动（ETL） | 金字塔 | 单元（转换函数） |

### 2. 测试分类与职责边界

**单元测试：测什么？**
- 纯函数（无副作用、无 I/O）
- 边界条件与异常分支
- 业务规则（价格计算、状态转换、权限判断）
- **不在单元测试中测：调用网络、读写文件系统、操作数据库**

**集成测试：测什么？**
- API 路由与授权中间件的整条链路
- ORM 与数据库的查询正确性
- 第三方服务 Adapter（带 Mock 或 Testcontainers）
- 消息队列的生产/消费流程

**E2E 测试：测什么？**
- 完整的关键用户旅程（注册 → 登录 → 核心操作）
- 支付/订阅等涉及多个系统的流程
- 视觉/渲染对比（关键页面截图）

### 3. TypeScript 测试实现

```typescript
// ── 单元测试（Vitest）──
// src/services/pricing.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { calculateTotal } from './pricing';
import { DiscountError } from './errors';

describe('calculateTotal', () => {
  // 工厂函数：生成测试数据
  const createOrder = (overrides = {}) => ({
    items: [
      { productId: 'p1', price: 100, quantity: 2 },
      { productId: 'p2', price: 50, quantity: 1 },
    ],
    couponCode: null,
    customerTier: 'standard' as const,
    ...overrides,
  });

  describe('normal calculation', () => {
    it('should sum item prices multiplied by quantity', () => {
      const order = createOrder();
      const result = calculateTotal(order);
      expect(result.subtotal).toBe(250); // 100*2 + 50*1
    });

    it('should apply standard discount for orders over 200', () => {
      const order = createOrder();
      const result = calculateTotal(order);
      expect(result.discount).toBe(25); // 10% of 250
      expect(result.total).toBe(225);
    });

    it('should not apply discount for orders under 200', () => {
      const order = createOrder({ items: [{ productId: 'p1', price: 100, quantity: 1 }] });
      const result = calculateTotal(order);
      expect(result.discount).toBe(0);
      expect(result.total).toBe(100);
    });
  });

  describe('tier-based pricing', () => {
    i
... (truncated)
## Instructions
1. Read all reference skill(s) carefully
2. Produce all required output files
3. Self-verify against quality gate
4. If quality gate fails, fix and re-verify until passing
5. When done, reply with 'DONE' and a one-line summary
Begin.