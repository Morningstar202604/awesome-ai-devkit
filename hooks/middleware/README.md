# Middleware Examples

中间件是可执行的 Python 脚本或模块，实现以下接口：

```python
# Base interface
class Middleware:
    def process_prompt(self, prompt: str, context: dict) -> str: ...
    def process_response(self, response: str, context: dict) -> str: ...
    def process_tool_call(self, tool_name: str, args: dict) -> dict: ...
```

## 内置中间件

### 1. `hooks/middleware/examples/logger.py`
全量记录 prompt → response，用于审计和调试。

### 2. `hooks/middleware/examples/cache.py`
基于 prompt hash 的 LLM 响应缓存，节省重复 token 开销。

### 3. `hooks/middleware/examples/rate_limiter.py`
令牌桶实现，控制 RPM/TPM。

### 4. `hooks/middleware/examples/secret_guard.py`
在 prompt 发送到 LLM 前扫描并脱敏敏感信息（API Key、密码等）。

### 5. `hooks/middleware/examples/context_injector.py`
从 `context/project.yaml` 动态注入当前项目上下文到 prompt。

## 优先级

中间件按 priority 升序执行（数值越小越先执行）。

```
10 → auth-check      # 先鉴权
20 → rate-limiter    # 再限流
30 → cache-lookup    # 查缓存
40 → context-inject  # 注入上下文
   ... → LLM ...
40 → cache-write     # 写缓存
50 → log-writer      # 记日志
```

## 编写自定义中间件

1. 在 `hooks/middleware/` 下创建 `<name>.py`
2. 实现 `Middleware` 类
3. 在 `hooks/config.yaml` 注册
4. 设置 `enabled: true` 激活
