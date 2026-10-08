# Context / Memory Layer (Layer 10)

> 跨 agent 共享状态和记忆，解决"agent 间不知道对方做了什么"的问题。

## 设计理念

Agent 系统常见问题：
1. 前后端 agent 各自实现对齐的 API 契约
2. 同一个 bug 被多个 agent 分别分析
3. 项目约定反复描述，浪费 token

Context 层通过共享的知识库 + 状态文件解决这些问题。

## 层次

### 1. 项目上下文（`context/project/`）

```yaml
# context/project.yaml
project:
  name: "Heyo"
  stack:
    frontend: "Next.js 15 + React 19 + Tailwind"
    backend: "FastAPI + LangGraph"
    database: "PostgreSQL + Redis + Qdrant"
  conventions:
    commit_style: "angular"
    api_style: "rest"
    test_threshold: 0.8
  decisions:  # ADR — Architecture Decision Records
    - id: "ADR-001"
      title: "选择 LangGraph 而非自研编排"
      date: "2026-10-05"
      status: "accepted"
```

### 2. 会话记忆（`context/session/`）

```json
// context/session/<session-id>.json
{
  "current_task": "实现用户登录流程",
  "completed_steps": ["设计数据模型", "实现后端 API"],
  "pending_steps": ["前端表单", "E2E 测试"],
  "shared_variables": {
    "api_endpoint": "https://api.example.com/v1",
    "db_schema_version": "2.3"
  }
}
```

### 3. 长期记忆（`context/long-term/`）

```
context/long-term/
├── patterns/       # 跨项目复用的设计模式
├── gotchas/        # 踩坑记录
├── insights/       # 技术洞察
└── preferences/    # 用户偏好（命名风格、工具选择等）
```

### 4. 知识图谱（`context/graph/`）

```
context/graph/
├── entities/       # 项目中的核心实体及其关系
├── dependencies/   # 模块依赖图
└── impact/         # 变更影响分析
```

## 使用方式

Agent 在启动时加载相关 context：
1. 匹配当前项目 → 加载 `context/project.yaml`
2. 查找活跃的会话 → 加载 `context/session/`
3. 匹配任务类型 → 加载 `context/long-term/patterns/` 中的相关知识
4. 在 Session 结束时写回状态

## 与 Hooks 的集成

- `on_agent_start` → 加载 context
- `on_agent_end` → 保存 session 状态
- `before_tool_call` → 注入 context 变量到 prompt
- `after_tool_call` → 更新 shared_variables
