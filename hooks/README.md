# Hooks 系统

> Awesome AI DevKit — Agent 任务生命周期钩子

## 快速开始

```
pre-task.sh  ──►  Agent 按 scaffold.yaml 执行  ──►  post-task.sh
  (开工检查)                                        (完工验收)
```

详见 → [scaffolds/scaffold-protocol.md](../../scaffolds/scaffold-protocol.md)

## 钩子脚本

| 脚本 | 触发时机 | 作用 |
|------|---------|------|
| `scripts/pre-task.sh` | scaffold start | scaffold.yaml 合法性 + skill 引用检查 |
| `scripts/post-task.sh` | scaffold end | 验收 + summary |
| `scaffold-validate.py` | validation | 执行 scaffold post_task quality_gates |

## 场景层钩子

全栈场景的额外钩子（agent 生命周期）：

| 脚本 | 触发时机 | 作用 |
|------|---------|------|
| `scenarios/.../hooks/scripts/load-project-context.sh` | agent start | 加载项目上下文 |
| `scenarios/.../hooks/scripts/save-session-log.sh` | agent end | 保存会话日志 |
| `scenarios/.../hooks/scripts/error-alert.sh` | on_error | 错误告警 |
| `scenarios/.../hooks/middleware/auth_check.py` | tool call | 工具调用权限检查 |

## 编辑配置

顶层配置：[hooks/config.yaml](config.yaml)
场景配置：[scenarios/programming/fullstack/hooks/config.yaml](../../scenarios/programming/fullstack/hooks/config.yaml)
