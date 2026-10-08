---
name: release-checklist
description: 发布前检查清单：安全、性能、测试、文档、变更日志
version: "1.0"
agents_involved:
  - qa-engineer
  - devops-engineer
  - tech-lead
  - technical-writer
  - security-engineer
estimated_duration: 2 小时 ~ 1 天
release_types: [major, minor, patch, hotfix]
---

# 发布前检查清单

> 每次发布到生产环境前，必须通过本清单的所有检查项。发布是团队协作的最终验收点。

---

## 流程总览

```
pre-check → security-scan → perf-baseline → test-full → docs-review
  → changelog → approval → deploy-window → deploy
```

---

## Stage 1: 发布准备确认

**角色**: `devops-engineer`（主导）、`tech-lead`

**输入**:
- 发布版本号（遵循语义化版本）
- 发布范围（本次包含的功能/Bug 修复）
- 目标发布时间窗口

**产出**:
- 发布计划文档（`docs/releases/vX.Y.Z.md`）
- 发布窗口确认（避免高峰时段、节假日）
- 回滚计划

**检查项**:
- [ ] 所有目标功能已通过 QA 验收
- [ ] 所有 P0/P1 Bug 已修复
- [ ] 发布分支已从 main 切出并冻结
- [ ] 发布窗口已通知所有利益相关者

**Hooks 触发**:
- `on_release_branch_created` → 自动冻结分支（需审批才能合并）
- `before_release` → 自动生成发布检查进度仪表板

---

## Stage 2: 安全扫描

**角色**: `security-engineer`（主导）、`devops-engineer`

**扫描类型**:
1. **依赖漏洞扫描**（sca）— Snyk / npm audit / pip-audit
2. **静态代码分析**（SAST）— Semgrep / CodeQL
3. **密钥泄露检测** — GitLeaks / truffleHog
4. **容器镜像扫描** — Trivy / Docker Scout（如有 Docker）
5. **基础设施配置审计** — Checkov / tfsec（如涉及 IaC）

**阻塞条件**:
- 发现 critical 或 high 级别漏洞 → **必须修复后才能发布**
- 发现 medium 级别漏洞 → Tech Lead 评估风险后可先发布但需排期修复
- 发现 low 级别漏洞 → 记录并排入下一版本

**Hooks 触发**:
- `before_release` → 自动运行全套安全扫描流水线
- `on_security_issue_found` → 自动创建安全工单

**产出**:
- 安全扫描报告
- 风险接受记录（Tech Lead 签字）

---

## Stage 3: 性能基准测试

**角色**: `qa-engineer`（主导）、`backend-developer`

**输入**:
- Staging 环境
- 性能基准数据（上次发布的数据）

**产出**:
- 性能对比报告
- 性能是否可接受的判定

**测试维度**:
| 维度 | 工具 | 通过标准 |
|------|------|---------|
| API 响应时间 | k6 / Locust | P95 ≤ 基线的 110% |
| 并发处理能力 | k6 | 错误率 < 0.1% |
| 前端加载速度 | Lighthouse | 性能分数 ≥ 85 |
| 数据库慢查询 | pg_stat_statements | 无新增 > 1s 的查询 |
| 内存消耗 | 监控面板 | 无内存泄漏趋势 |

**对比基线**: 与上一版本在相同测试条件下对比。

**Hooks 触发**:
- `on_perf_regression` → 自动标记为阻塞项
- `on_perf_pass` → 归档性能报告

---

## Stage 4: 全量测试

**角色**: `qa-enginever`（主导）

**输入**:
- 发布候选版本
- Staging 环境

**覆盖范围**:
1. **单元测试** — 全部通过
2. **集成测试** — 全部通过
3. **端到端测试（E2E）** — 核心流程全部通过
4. **冒烟测试** — 手动在 staging 走一遍核心用户路径
5. 跨浏览器测试（前端）— Chrome / Safari / Firefox
6. 真机真网测试（移动端，如适用）

**覆盖率门槛**:
- 行覆盖率 ≥ 80%（核心模块 ≥ 90%）
- 所有新增代码有对应测试

**Hooks 触发**:
- `before_release` → 触发 CI 全量测试流水线
- `on_test_failure` → 阻塞发布，自动通知提交者

**产出**:
- 测试覆盖率报告
- 测试执行摘要（通过/失败/跳过数）

---

## Stage 5: 文档与变更日志

**角色**: `technical-writer`（主导）、各功能开发者协助

**产出**:
- **CHANGELOG.md** — 遵循 [Keep a Changelog](https://keepachangelog.com/) 格式
- **API 文档** — 如有 API 变更，确保文档同步
- **用户指南** — 新功能的使用说明
- **迁移指南** — 如有 breaking change，提供迁移步骤

**CHANGELOG 模板**:
```markdown
## [1.2.0] - 2025-01-15

### Added
- 用户登录支持 Google OAuth (#123)
- 新增导出 CSV 功能 (#145)

### Changed
- 优化列表页加载速度，提升 40% (#156)

### Fixed
- 修复分页在第二页数据为空时的显示 bug (#167)

### Security
- 升级 lodash 至 4.17.21 修复原代码注入漏洞

### Deprecated
- 标记 `/api/v1/legacy-endpoint` 为废弃（1.3.0 移除）
```

**检查项**:
- [ ] CHANGELOG 已更新，版本号正确
- [ ] API 文档如有变更已全部更新
- [ ] 用户可见功能的截图/说明已更新
- [ ] Migration guide 已提供（如有 breaking change）

---

## Stage 6: 发布审批

**角色**: `tech-lead`（最终审批）

**输入**:
- 所有上述阶段的检查报告
- 发布计划

**审批流程**:
1. QA 确认测试通过 → 签字
2. DevOps 确认部署就绪 → 签字
3. Tech Lead 最终确认 → 签字
4. 以上全部通过 → 进入发布窗口

**审批讨论点**:
- 未关闭的 P2/P3 Bug 是否可以延期
- 未修复的 medium 安全漏洞的风险接受
- 是否有 feature flag 需要准备（灰度控制）

**Hooks 触发**:
- `on_release_approved` → 解锁发布流水线
- `on_release_rejected` → 通知团队重新修复并申请新一轮检查

---

## Stage 7: 部署执行

**角色**: `devops-engineer`

**部署策略选择**:
- **标准发布**：滚动更新，无 downtime
- **热修复（hotfix）**：跳过部分验证，紧急上线
- **灰度发布**：5% → 25% → 50% → 100%，每步观察 15 分钟

**部署检查**:
- [ ] 数据库 migration 在应用启动前执行（或使用 expand-contract 模式）
- [ ] 环境变量和密钥已正确配置
- [ ] Feature flag 已初始化
- [ ] 回滚命令已就绪（记录在发布文档中）

**Hooks 触发**:
- `before_deploy` → `[smoke-test]`
- `after_deploy` → `[smoke-test, monitoring-check, notify-slack]`
- `on_deploy_failure` → 自动执行回滚

---

## Stage 8: 发布后验证

**角色**: `qa-engineer`、`devops-engineer`

**时间线**:
- **T+5min**：Smoke 测试，关键 API 可达
- **T+30min**：错误率、响应时间监控无异常
- **T+2h**：核心业务流程人工验证
- **T+24h**：监控大盘对比，确认无回退

**验证项**:
- [ ] 生产环境关键 API 响应正常
- [ ] 错误率未上升
- [ ] 无新增的 critical 告警
- [ ] 用户无集中反馈异常

**Hooks 触发**:
- `post_deploy_monitor` → 自动监控 30 分钟
- `on_regression_detected` → 触发回滚决策流程

---

## 异常情况

| 场景 | 处理 |
|------|------|
| 安全扫描发现 critical 漏洞 | 修补后重新走全量发布检查 |
| 性能回退 > 10% | Tech Lead 决定：优化后发布 or 先发布并排期修复 |
| 测试环境不稳定 | 暂停发布，先修复环境 |
| 部署后立即出现 P0 bug | 执行回滚 → 启动 incident-response 流程 |
