# Git Hooks

与本机 git hooks 协同，在 agent 操作仓库时执行质量/安全检查。

## 安装

```bash
# 手动安装 git hooks（将 scripts/ 复制到 .git/hooks/）
cp hooks/scripts/* .git/hooks/
chmod +x .git/hooks/*.sh
# 或通过工具自动部署：awesome-devkit hooks install
```

## 可用钩子

### pre-commit
- 调用 linter（ruff / eslint / prettier）
- 类型检查（mypy / tsc）
- 阻止包含 secret 的提交

### pre-push
- 运行冒烟测试
- 安全扫描（依赖 + 容器）
- 检查 CI 配置文件完整性

### commit-msg
- 校验 commit message 风格（angular / conventional commits）
- 检查关联 issue/PR 引用

### post-merge
- 检查依赖变更（package-lock / requirements）
- 提示是否需要迁移或重装

## 配置

```yaml
# hooks/config.yaml
git:
  enabled: true
  fail_fast: true  # 任一检查失败立即中断
  skip_for:       # 可跳过的分支
    - "dependabot/*"
    - "renovate/*"
```

## Hooks 与 Agent Hooks 的联动

Git hooks 触发时会调用对应的 agent hooks：
- `pre-commit` → `before_tool_call`（lint 中间件）
- `post-merge` → `on_agent_start`（重新加载 context）
