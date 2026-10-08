# 全栈开发 — 项目上下文共享层

> Awesome AI DevKit Layer 10 (Context) 的实现。

## 什么是「上下文层」

全栈开发是多 Agent 协作场景。前端 Agent、后端 Agent、QA Agent、DevOps Agent
同时工作但又处于不同阶段。**上下文层解决的问题是**：让所有 Agent 对「我们在做什么、
用什么技术栈、当前文件变更状态」有一致且低成本的共识。

```
┌────────────┐    ┌───────────────┐    ┌────────────┐
│  Frontend  │───▶│  context/     │───▶│  Backend   │
│  Agent     │◀───│  (共享层)     │◀───│  Agent     │
└────────────┘    └───────┬───────┘    └────────────┘
                          │
                  ┌───────┤───────┐
                  ▼       ▼       ▼
                ADR     Session  Project
                (.md)   (.jsonl) (.yaml)
```

## 文件清单

| 文件 | 作用 | 何时读写 |
|------|------|---------|
| `project.yaml` | 项目级元数据（技术栈、授权 Agent、路径约束） | Agent 启动时加载，运行中只读 |
| `architecture.md` | 所有 ADR（Architecture Decision Record） | Agent 按 topic 检索 |
| `logs/sessions/*.jsonl` | 每个会话的结构化运行日志 | Agent 结束时写入 |
| `session.template.json` | 会话状态的 JSON 模板 | 供框架初始化新会话 |

## 使用方式

### 1. 初始化

```bash
cp context/project.template.yaml context/project.yaml
# 编辑 project.yaml，填写项目名、技术栈、Agent 列表
```

### 2. Agent 运行时

- **Start**: `hooks/scripts/load-project-context.sh` 自动注入，输出 JSON summary。
- **During**: Agent 可通过 `read_file context/project.yaml` 检查 `features` / `allowed_paths`。
- **End**: `hooks/scripts/save-session-log.sh` 追加写入 `logs/sessions/<id>.jsonl`。

### 3. 跨 Agent 协作

当一个 Agent 发现新的架构决策（如选用 Meilisearch 替代 Elasticsearch），
应通过以下流程更新共享上下文：

```
1.  Agent 完成决策 → 以 ADR 格式补写至 context/architecture.md
2.  commit 前先过 hooks (ruff / prettier / mypy)
3.  其他 Agent 通过 git diff 或 ADR 编号感知最新决策
```

## 与 11 层框架的关系

```
Layer 9  Hooks   └── 读取/写入本层日志 & 配置
Layer 10 Context  ←── 本目录 — 项目级共享状态
Layer 11 Validation ── 校验本层文件格式和内容
```

## 安全约束

| 类别 | 规则 |
|------|------|
| 写入 | 仅通过 git 提交写入；运行时只读 |
| 密钥 | 绝对不允许放入 context/；使用外部 vault 或环境变量 |
| 日志 | sessions/*.jsonl 保留 50 个，旧文件自动轮转 |
| 范围 | denied_paths 列出的目录，Agent 工具层会拒绝操作 |
