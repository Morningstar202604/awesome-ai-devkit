# 全栈开发场景 — Hooks 体系

> Awesome AI DevKit 全栈开发场景的钩子配置

## 快速开始

```
Agent 启动 → load-project-context.sh（加载上下文）
    ↓
Agent 执行任务（使用 52 个 skill + MCP tools）
    ↓
Task 完成 → save-session-log.sh（保存日志）
       或 error-alert.sh（错误告警）
```

配置: [hooks/config.yaml](config.yaml)

---

## 文件清单

| 路径 | 类型 | 说明 |
|------|------|------|
| `config.yaml` | 配置 | 钩子定义与参数 |
| `middleware/auth_check.py` | 中间件 | 工具调用权限检查（需 admin/read/write 级别） |
| `scripts/load-project-context.sh` | 脚本 | 加载项目上下文到 agent |
| `scripts/save-session-log.sh` | 脚本 | 持久化会话日志 |
| `scripts/error-alert.sh` | 脚本 | 错误分级告警（ERROR → 日志，CRITICAL → Slack） |

---

## Agent 生命周期钩子

| 时机 | 脚本 | 超时 | 说明 |
|------|------|------|------|
| on_agent_start | `scripts/load-project-context.sh` | 5s | 加载 context/project.yaml + ADR |
| on_agent_end | `scripts/save-session-log.sh` | 10s | 保存 session jsonl |
| on_agent_error | `scripts/error-alert.sh` | 15s | 分级告警 |

---

## Before Action 中间件

| 中间件 | 说明 |
|--------|------|
| auth_check.py | 验证工具调用所需权限（read/write/admin） |

---

## 环境变量

| 变量 | 说明 |
|------|------|
| `SLACK_WEBHOOK_URL` | Slack webhook（可选，错误告警用） |
| `PROJECT_ROOT` | 项目根目录（默认自动检测） |
