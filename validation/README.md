# Validation Layer (Layer 11)

> 确保框架中的所有组件符合规范——plugin schema、agent schema、skill schema 均有校验规则。

## 校验时机

| 时机 | 校验内容 |
|------|---------|
| Plugin 安装 | plugin.json schema、文件完整性 |
| Agent 加载 | system prompt 语法、tools 引用存在性 |
| Skill 执行 | 前置条件、依赖是否满足 |
| Workflow 编排 | agent 角色组合合法性、输入/输出兼容 |
| 推送前 | 全量交叉引用检查 |

## Schema 定义

### Plugin Schema (`validation/schemas/plugin.json`)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["name", "version", "type", "maintainers"],
  "properties": {
    "name": { "type": "string", "pattern": "^[a-z][a-z0-9-]*$" },
    "version": { "type": "string" },
    "type": { "enum": ["expert", "skill-pack", "tool", "mcp-server"] },
    "maintainers": { "type": "array", "minItems": 1 },
    "skills": { "type": "array" },
    "agents": { "type": "array" },
    "hooks": { "type": "array" }
  }
}
```

### Agent Schema (`validation/schemas/agent.json`)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "required": ["name", "role", "capabilities"],
  "properties": {
    "name": { "type": "string" },
    "role": { "type": "string" },
    "goal": { "type": "string" },
    "capabilities": { "type": "array", "minItems": 1 },
    "tools": { "type": "array" },
    "system_prompt_file": { "type": "string" },
    "constraints": { "type": "object" }
  }
}
```

### Workflow Schema (`validation/schemas/workflow.json`)
校验 stages 流转、agents 引用、inputs/outputs 兼容性。

## 校验策略

1. **本地校验 (pre-commit)**：快速 schema check
2. **CI 校验 (push)**：全量交叉引用 + 依赖图检查
3. **部署校验 (install)**：运行时能力 probe（tools 实际可用吗）

## 与 Hooks 集成

- `before_tool_call` 中可注入 validation 中间件
- `on_agent_start` 时校验 agent schema
- 校验失败 → 记录并降级/拒绝执行
