---
name: incident-response
description: 故障响应工作流：从检测到恢复再到复盘
version: "1.0"
agents_involved:
  - sre-engineer
  - devops-engineer
  - tech-lead
  - frontend-developer
  - backend-developer
  - product-manager
incident_severities: [SEV1, SEV2, SEV3, SEV4]
---

# 故障响应工作流

> 标准化故障处理流程。核心原则：先止损，再定位，最后修复。

---

## 流程总览

```
detect → triage → mitigate → resolve → verify → postmortem → followup
```

---

## Stage 1: 检测与告警

**触发来源**:
- 监控告警（错误率飙升、响应时间异常、服务不可达）
- 用户反馈（客服工单骤增）
- 现场发现（开发者或 QA 主动发现）

**产出**:
- Incident Ticket 自动创建（PagerDuty / 飞书 / Slack）
- 初步影响评估（服务、用户范围）

**严重等级**:
| 等级 | 标准 | 响应时间 |
|------|------|---------|
| SEV1 | 全部用户受影响 / 核心服务完全不可用 | 5 分钟 |
| SEV2 | 大量用户受影响 / 主要功能严重受损 | 15 分钟 |
| SEV3 | 部分用户受影响 / 次要功能受损 | 1 小时 |
| SEV4 | 极少数用户受影响 / 体验问题 | 工作时间 |

**Hooks 触发**:
- `on_incident_detected` → 自动召集 on-call 人员（SEV1/SEV2）
- `on_alert_fired` → 发送告警通知到值班群

---

## Stage 2: 分级与响应

**角色**: `sre-engineer`（指挥）、`tech-lead`（决策）

**输入**:
- Incident 告警信息
- 监控仪表板截图

**产出**:
- 确认的严重等级和范围
- Incident Commander（IC）指定
- 沟通计划（内部通知、用户公告、管理层汇报）

**IC（Incident Commander）职责**:
1. 协调各方资源
2. 做决策（回滚/降级/继续追因）
3. 定时同步状态（每 15 分钟）
4. 授权变更（紧急修复可跳过常规 CR）

**角色分工**:
- **IC（SRE）**：指挥全局
- **Communicator**：负责内外部沟通（可由 PM 兼任）
- **Scribe**：记录时间线和决策（可以是工具人角色）
- **Operators**：执行具体修复操作的开发者

**Hooks 触发**:
- `on_incident_assigned` → 创建战时沟通频道（Slack/飞书）
- `on_sev1_escalation` → 通知技术负责人和业务负责人

---

## Stage 3: 止损（缓解）

**角色**: `devops-engineer`、`backend-developer`

**目标**：尽快恢复服务，哪怕只是部分恢复。不要求定位根因。

**策略优先级**（从快到慢）:
1. **回滚（Rollback）**：如果故障由新发布引起 → 立即回滚到上一版本
2. **降级（Degradation）**：关闭非核心功能（通过 feature flag）
3. **扩容（Scale up）**：如果是资源瓶颈 → 临时增加实例
4. **限流（Rate limit）**：减少后端压力，保护核心链路
5. **切换到备用（Failover）**：如使用多 AZ/多 Region

**决策树**:
```
是否由最近发布引起？
├── 是 → 立即回滚
└── 否 → 是否有明显资源瓶颈？
    ├── 是 → 扩容
    └── 否 → 是否可以降级？
        ├── 是 → 关功能、限流
        └── 否 → 进入定位阶段
```

**Hooks 触发**:
- `before_rollback` → 确认无数据不可逆风险
- `after_rollback` → 确认服务恢复
- `on_mitigation_applied` → 更新 incident timeline

**验收条件**:
- [ ] 核心服务可用性恢复（可达 > 95%）
- [ ] 错误率降至正常水平（< 1%）
- [ ] 用户反馈证实问题已缓解

---

## Stage 4: 根因定位

**角色**: 被分配的`backend-developer`/`frontend-developer`

**输入**:
- Incident 时间线
- 监控数据（ Metrics + Logs + Traces）
- 变更历史（最近发布、配置变更、基础设施变更）

**产出**:
- 根因描述（在什么条件下、因为什么代码/配置、导致了什么故障）
- 数据流异常链路图

**定位方法**:
1. **日志分析**：ELK/CloudWatch，搜索 ERROR/WARN
2. **链路追踪**：Jaeger/SkyWalking，定位慢/异常的 span
3. **指标关联**：将异常时间与发布/配置时间对齐
4. **Diff 分析**：对比正常运行时的系统状态
5. **脑爆会议**：紧急情况下多人并行排查

**不要做的事**:
- 不要在压力下做复杂的代码修改
- 不要在追因期间清理现场（保留日志、payload、监控截图）
- 不要互相指责（blameless 文化）

**Hooks 触发**:
- `after_rootcause_found` → 更新 incident 根因标签
- `after_rca_timeout` → 如果 30 分钟未找到，自动升级给更多人

---

## Stage 5: 修复实施

**角色**: 被分配的开发者 + `code-reviewer`（简化审查）

**输入**:
- Stage 4 的根因分析
- 已经通过缓解措施降级的系统

**产出**:
- 修复 commit/PR
- 紧急修复的测试（可能不完整，在恢复后补）

**修复模式**：
1. **Hotfix 分支**：从 release 分支切出 → 修复 → 合并回 main + release
2. **Feature Flag 修复**：修复代码后通过 flag 灰度放开
3. **数据修复脚本**：如果故障导致了数据不一致，需要编写并执行修复脚本

**快速审查**：
- SEV1/SEV2 场景下，review 可以简化为 1 人快速 approve
- 修复必须在合并后立刻部署到生产

**Hooks 触发**:
- `before_hotfix_merge` → `[smoke-test, test-related-module]`
- `after_hotfix_deploy` → `[error-rate-check, latency-check]`

**验收条件**:
- [ ] 修复已部署到生产
- [ ] 监控显示系统恢复正常
- [ ] 至少 30 分钟无复发

---

## Stage 6: 恢复确认

**角色**: `sre-engineer`、`qa-engineer`

**输入**:
- Stage 5 的修复状态
- 监控仪表板

**产出**:
- Incident 关闭决策
- 残余风险记录

**恢复标准**:
- 核心接口可用性 > 99.5%（持续 30 分钟）
- 错误率 < 正常基线 + 0.5%
- 响应时间 P95 < 正常基线 * 1.2

**Hooks 触发**:
- `on_incident_resolved` → 通知所有关注者
- `after_recovery_confirm` → 归档 incident 记录

---

## Stage 7: 复盘（Postmortem）

**角色**: `tech-lead`（主持）、`sre-engineer`、所有参与修复者

**输入**:
- Incident 时间线（发生 → 检测 → 响应 → 恢复）
- 根因分析结果

**产出**:
- Blameless Postmortem 文档
  - 时间线（精确到分钟）
  - 根因 + 引发条件
  - 影响范围（用户数、请求损失、收入影响）
  - 什么做得好、什么做得不好
  - Action Items（修复同类问题的具体措施）

**复盘原则**（Blameless）:
- **不追责个人**，关注系统和流程缺陷
- 每个人都诚实描述当时做了什么决策
- 关注"怎么会这样"而非"谁的责任"

**Action Items 要求**:
- 每条有负责人和截止日期
- 优先级排序（针对根因 > 改进点 > 优化点）

**Hooks 触发**:
- `on_postmortem_scheduled` → 自动邀请参会人员
- `on_postmortem_published` → 通知全员、归档为知识库文档
- `on_action_item_created` → 自动创建 tracking ticket

**产出交付**:
- [ ] Postmortem 文档发布到团队知识库
- [ ] Action Items 已指派负责人
- [ ] 监控/告警改善项已提交

---

## Stage 8: 跟进与预防

**角色**: `tech-leer`（监督）、`qa-engineer`（补充测试）、`sre-engineer`（告警优化）

**检查清单**:
- [ ] Action Items 全部完成
- [ ] 针对根因的自动化测试已添加
- [ ] 监控和告警规则已优化（避免同类问题无法及时发现）
- [ ] Runbook 已更新或新建
- [ ] 经验教训分享会在团队周会中传达

---

## 异常情况

| 场景 | 处理 |
|------|------|
| 无法回滚（数据已变更） | 执行数据修复脚本，保持服务运行 |
| 定位时间过长（> 2h） | 升级至更高管理层，请求更多资源 |
| 修复引入新问题 | 再次评估回滚或快速修复 |
| 第三方服务故障 | 实施降级/熔断，持续跟进第三方恢复 |
