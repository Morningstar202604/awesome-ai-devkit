# Hooks System (Layer 9)

钩子系统允许在 agent 生命周期的任意阶段注入自定义逻辑，从而在不修改核心框架的前提下扩展行为。

## 钩子类型

### 1. Agent Lifecycle Hooks（`hooks/agent-lifecycle/`）

在 agent 启动、运行、结束时触发。

| 钩子 | 触发时机 | 典型用途 |
|------|---------|---------|
| `on_agent_start` | agent 开始处理前 | 加载上下文、注入环境变量 |
| `on_agent_end` | agent 完成后 | 清理临时文件、记录 metrics |
| `on_agent_error` | agent 出错时 | 发送告警、回滚状态 |
| `on_agent_timeout` | agent 超时时 | 优雅降级、保存 checkpoint |

### 2. Action Hooks（`hooks/middleware/`，通过中间件实现）

在 agent 的每个 action（工具调用）前后触发，当前通过中间件（`hooks/middleware/`）统一实现。

| 钩子 | 触发时机 | 典型用途 |
|------|---------|---------|
| `before_tool_call` | 工具调用前 | 权限校验、参数校验 |
| `after_tool_call` | 工具调用后 | 日志记录、结果脱敏 |
| `before_prompt_send` | 发送 prompt 前 | 注入动态上下文、token 裁剪 |
| `after_response_recv` | 接收响应后 | 格式校验、重试判断 |

### 3. Git Hooks（`hooks/git/`）

与本机 git 钩子协同，agent 操作仓库时触发。

| 钩子 | 触发时机 | 典型用途 |
|------|---------|---------|
| `pre_commit` | commit 前 | lint、格式化检查 |
| `post_merge` | merge 后 | 依赖检查、冲突标记 |
| `pre_push` | push 前 | 安全扫描、测试运行 |

### 4. Middleware Pipeline（`hooks/middleware/`）

中间件按顺序组成处理链，可以拦截和修改 prompt/response。

```
Client → mw[0] → mw[1] → ... → mw[n] → LLM → mw[n] → ... → mw[0] → Response
```

中间件可用于：
- **缓存层**：相同 prompt 命中缓存直接返回，节省 token
- **限流层**：控制并发和 RPM/TPM
- **审计层**：记录全量 prompt/response 到日志
- **安全层**：拦截敏感信息泄露、注入攻击

## 配置示例

```yaml
# hooks/config.yaml
hooks:
  agent_lifecycle:
    on_agent_start:
      - script: "hooks/agent-loader.sh"
        env: ["API_KEY", "WORKSPACE_ROOT"]
    on_agent_error:
      - script: "hooks/error-alert.sh"
        channels: ["slack", "log"]

  before_action:
    - middleware: "hooks/middleware/auth-check.py"
      priority: 10
    - middleware: "hooks/middleware/cache-lookup.py"
      priority: 5

  after_action:
    - middleware: "hooks/middleware/log-writer.py"
      priority: 1
    - middleware: "hooks/middleware/cache-write.py"
      priority: 2
```

## 中间件签名

每个中间件是一个可执行文件或 Python 模块：

```python
# middleware interface
class Middleware:
    def process_prompt(self, prompt: str, context: dict) -> str:
        """接收 prompt，返回修改后的 prompt"""
        ...

    def process_response(self, response: str, context: dict) -> str:
        """接收 response，返回修改后的 response"""
        ...

    def process_tool_call(self, tool_name: str, args: dict) -> dict:
        """拦截工具调用，可修改参数或拒绝"""
        ...
```
