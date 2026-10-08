# Agent Lifecycle Hooks

在 agent 生命周期的关键节点执行自定义逻辑。

## 钩子列表

### on_agent_start
```yaml
# 加载项目特定上下文
script: "hooks/agent-lifecycle/load-context.sh"
env: ["PROJECT_ROOT"]
timeout: 5  # 秒
```

### on_agent_end
```yaml
# 运行完成：保存 session、更新 metrics
script: "hooks/agent-lifecycle/save-session.sh"
```

### on_agent_error
```yaml
# 出错：告警 + 保存崩溃上下文
script: "hooks/agent-lifecycle/error-alert.sh"
channels: ["log", "slack", "email"]
```

### on_agent_timeout
```yaml
# 超时：保存 checkpoint、释放资源
script: "hooks/agent-lifecycle/graceful-stop.sh"
```

## 脚本约定

1. 脚本通过环境变量接收上下文
2. 退出码 0 = 成功，非 0 = 失败（阻止继续执行）
3. stdout/stderr 被记录到 agent 日志
4. 超时（秒）到达后被 kill

## 环境变量

| 变量 | 说明 |
|------|------|
| `AGENT_NAME` | 当前 agent 名称 |
| `AGENT_ROLE` | 角色 |
| `SESSION_ID` | 会话 ID |
| `WORKSPACE_ROOT` | 工作区根目录 |
| `CURRENT_TASK` | 当前任务描述 |
| `TOOL_NAME`（仅 action hooks）| 工具名称 |
