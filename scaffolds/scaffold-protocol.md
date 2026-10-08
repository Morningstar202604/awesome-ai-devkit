# Scaffold Protocol v2.1

> Agent 接到开发任务时，按 scaffold.yaml 的描述执行。

---

## 核心理念

- scaffold.yaml 是 **agent 的行动指南**，不是给机器执行的脚本
- Agent 读 goal → 读对应 skill → 执行 → 按 quality_gate 自检
- 失败时 agent 自主重试，不需要预设 fallback
- 扁平 steps 列表，通过 `parallel: true` 标记可并行步骤

---

## Task 接收

1. 工作目录有 scaffold.yaml → 读取并执行
2. 没有 → 参考 `templates/project-scaffold/scaffold.yaml.template` 创建

---

## 开工前检查

1. scaffold.yaml 存在且 YAML 合法
2. context/project.yaml 存在
3. scaffold 中引用的 skill ID 在 skills/ 中存在
4. 执行: `bash hooks/scripts/pre-task.sh scaffold.yaml`

---

## 执行模型

```
步骤类型:
  - 默认: 串行 (按列表顺序逐个执行)
  - parallel: true: 并行 (连续多个标记为 parallel 的步骤同时执行)

执行顺序: 按 steps 列表顺序扫描，连续的 parallel 步骤合并为一个并行组

预定义 segments: 无 — step 自己通过 needs 声明依赖关系。
  Runner 默认遵循以下串行流程:
    1. pre-scaffold: 处理 baseTemplate 并应用 overrides
    2. scaffold: 处理主 development flow
    3. post-scaffold: 运行 extensionHooks

预置步骤位置: 通过 override 注入，不硬编码在协议中。
  默认 baseTemplate 注入位置: 通过 overrides 配置确定
  (protocol 不强制固定步骤位置)
```

---

## scaffold.yaml 字段定义

```yaml
version: "2.0"

task:
  name: "task-id"
  description: "任务目标"
  type: feature   # feature | bugfix | refactor | incident | deploy

memory:           # 开工前 agent 读取的文件/命令输出
  - context/project.yaml
  - git log --oneline -20

# ── 核心: 扁平步骤列表 ──────────────────────────────────
steps:

  # 串行步骤 (按列表顺序执行)
  - goal: "步骤目标"
    description: "一句话说明"
    skills: [skill-a, skill-b]    # 最多 3 个核心 skill
    outputs:
      - path/to/file.ext:
          contains: [关键字]      # agent 自我校验
    quality_gate: "质量标准描述"   # agent 自行决定如何验证

  # 并行步骤 (连续多个 parallel: true 的步骤会同时执行)
  - goal: "独立子任务 A"
    parallel: true
    skills: [skill-c]
    outputs:
      - path/to/output-a.ext

  - goal: "独立子任务 B"
    parallel: true
    skills: [skill-d]
    outputs:
      - path/to/output-b.ext

  # 后续串行步骤 (在所有 parallel 步骤完成后执行)
  - goal: "依赖前两步的任务"
    needs: [独立子任务 A, 独立子任务 B]  # 可选: 显式声明依赖
    skills: [skill-e]

# ── 完工验收 ──────────────────────────────────────────────
post_task:
  quality_gates:
    - "验收标准 1"
    - "验收标准 2"
```

---

## quality_gate 写法

| 不要 ❌ | 要 ✅ |
|---------|-------|
| `run: "pytest …"` | `"全量测试通过，无 skip"` |
| `run: "ruff check src/"` | `"代码无 lint 错误 (ruff)"` |
| `run: "grep -r password src/"` | `"无硬编码密钥泄露"` |

Agent 知道怎么跑测试、怎么 grep。只需要告诉它**质量标准是什么**。

---

## 并行步骤规则

连续的 `parallel: true` 步骤会被 runner 识别为一个并行组。**不连续的**并行步骤会分成独立的并行组。

```yaml
# 这两个并行 → 一个并行组 (同时执行)
- goal: "后端实现"
  parallel: true
- goal: "前端实现"
  parallel: true

# 这两个串行 → 等上面并行完成后再执行
- goal: "集成测试"
- goal: "代码审查"
```

---

## 记忆管理

`memory` 段告诉 agent 在开始干活之前先读什么:

```yaml
memory:
  - context/project.yaml                    # 项目名、技术栈
  - context/architecture.md                 # 架构决策 (ADR)
  - git log --oneline -20                   # 最近的代码变更
  - memory_query:                           # 按标签提取经验（可选）
      tags: [auth, security]                # 匹配 context/memory/entries/*.jsonl
      scope: project
      limit: 5
```

Agent 读这些材料后决定怎么做。`memory_query` 按 tags 交集从项目记忆文件中检索相关经验教训（参见 `memory-management` skill）。

### 记忆写入

每个任务完成时，agent 将本次经验写入 `context/memory/entries/<topic>.jsonl`：

```jsonl
{"ts":"2026-10-06T10:00:00Z","type":"lesson","tags":["auth","jwt"],"summary":"...","confidence":0.95}
```

| type | 触发时机 |
|------|---------|
| lesson | 踩坑后发现错误 |
| decision | ADR 写入后 |
| pattern | 发现可复用做法 |
| warning | 安全审查发现风险 |

---

## 安全门控

步骤可声明 `security` 约束，触发审批流程：

```yaml
steps:
  - goal: "修改生产数据库"
    security:
      approval_required: true
      reason: "不可逆操作，需要人工确认"
```

审批流程: agent 输出 `[APPROVAL_REQUIRED: reason]` → 等用户回复 OK/SKIP/MODIFY → 记录到 `logs/approvals/*.jsonl`。

---

## 模型路由

步骤可声明模型偏好（对齐 OpenCode 的多模型策略）：

```yaml
steps:
  - goal: "架构设计（需要深度推理）"
    model:
      preferred: claude-sonnet
      fallback: gpt-5.2
  - goal: "简单样式调整"
    model:
      preferred: gpt-4o-mini    # 低成本
```

参见 `model-routing` skill 获取路由策略详情。

---

## 失败回退

不预设 fallback。Agent 自主决策:
1. 重试 (换策略)
2. 仍失败 → 回退上一步重做
3. 模型 failover: primary 不可用 → 按 model.fallback 切换
4. 触发人类介入

---

## Scaffold Runner (可选)

仓库提供了一个 Python runner，可以驱动 `claude` / `cursor-agent` / 自定义 CLI agent 逐步执行 scaffold:

```bash
# 干跑 (只生成 prompt，不执行)
python3 scaffolds/scaffold-runner.py --dry-run

# 真实执行 (使用 Claude Code)
python3 scaffolds/scaffold-runner.py --provider claude

# 每步成功后自动 commit
python3 scaffolds/scaffold-runner.py --provider claude --auto-commit

# 使用 Cursor agent
python3 scaffolds/scaffold-runner.py --provider cursor-agent

# 指定 scaffold 文件
python3 scaffolds/scaffold-runner.py my-feature.yaml --dry-run

# 使用自定义 LLM CLI
DEVKIT_PROVIDER="my-llm-cli" python3 scaffolds/scaffold-runner.py
```

不做 runner 也可以 — 任何 AI coding agent (Cursor, Claude Code, Copilot) 都能直接读 scaffold.yaml 按步骤执行。Runner 只是让执行自动化。

---

## Post-task 完工验收

完成所有步骤后，agent 按 `post_task.quality_gates` 逐项自检，全部通过后:
- 生成 git commit
- 更新 ADR (如有架构决策变更)

---

## 版本兼容

| 版本 | 日期 | 变更 |
|------|------|------|
| 2.1 | 2026-10 | memory_query + 安全门控 + 模型路由 + 经验沉淀 |
| 2.0 | 2026-10 | 扁平 steps + parallel 标记；移除硬编码 gate 命令 |
| 1.0 | 2026-08 | 初始版本 |

新版本向后兼容 (runner 会提示但不阻断)。
