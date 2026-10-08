# 架构决策记录 (ADR)

---

## ADR-001: devkit-doctor 诊断工具

- **日期**: 2026-10-06
- **状态**: Accepted
- **决策**: 开发一个 Python 单文件 CLI 工具 `devkit-doctor.py`，用于检查 Awesome AI DevKit 安装健康状态

### 背景

随着 Awesome AI DevKit 规模增长（52 个 skill、3 个 scaffold、12 个 MCP server），
开发者在配置和环境验证上缺乏快速诊断手段。常见问题包括：skill 文件缺失、
scaffold 引用断裂、hook 脚本丢失、环境版本不足。

### 方案选择

| 方案 | 优点 | 缺点 |
|------|------|------|
| A. 单文件 Python CLI | 无新依赖、跨平台、易维护 | 功能受限于 stdlib+yaml |
| B. Node.js CLI | 与 MCP 生态一致 | 增加 JS 依赖，Python 用户不便 |
| C. Shell 脚本 | 零依赖 | 跨平台性差，复杂逻辑难写 |

### 决策依据

- 选 A: 项目已有 Python 依赖（scaffold-runner.py, scaffold-validate.py），PyYAML 已可用
- 单文件简化分发——一个文件搞定所有检查
- 仅依赖 stdlib + yaml，无额外 `pip install`

### 后果

- 必须保持单文件（不拆模块），直到复杂度确需拆分
- 检查器采用插件式注册，新增检查器只需继承 BaseCheck

---

