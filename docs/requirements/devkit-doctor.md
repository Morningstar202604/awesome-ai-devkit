# devkit-doctor — 需求分析与验收标准

> 生成时间: 2026-10-06
> 状态: Draft
> 优先级: P1

## 背景

Awesome AI DevKit 是一个大型配置生态，包含 52 个 skill、3 个 scaffold 工作流、12
个 MCP server 配置、hooks 脚本等。开发者在安装/配置后缺乏一个 "健康检查" 工具来
验证各项配置是否齐全、版本是否匹配、引用是否断裂。

## 目标

提供 `devkit-doctor` 命令行诊断工具，扫描当前项目并报告：

1. **Skill 完整性**: 52 个 SKILL.md 是否都存在且 frontmatter 合法
2. **Scaffold 有效性**: scaffold yaml 是否格式正确、引用的 skill 是否存在
3. **MCP 配置**: mcp-config.yaml 是否合法、enabled servers 是否在 awesome-servers.json 中注册
4. **Hooks 脚本**: 是否可执行、config.yaml 引用的脚本是否存在
5. **环境依赖**: git/node/python 版本是否满足最低要求

## 验收标准 (Gherkin)

```gherkin
Feature: devkit-doctor 健康检查

  Scenario: 完整安装的健康检查
    Given awesome-ai-devkit 仓库已完整克隆
    When 运行 "python3 devkit-doctor.py"
    Then 输出应包含 5 个检查分类
    And 所有分类应显示 PASS
    And 退出码应为 0

  Scenario: 检测到缺失 skill
    Given 删除 skills/security/SKILL.md
    When 运行 "python3 devkit-doctor.py"
    Then skill 完整性检查应显示 FAIL
    And 报告应指出 "skills/security/SKILL.md missing"
    And 退出码应为 1

  Scenario: scaffold 引用断裂
    Given scaffold.yaml 中引用了不存在的 skill "nonexistent-skill"
    When 运行 "python3 devkit-doctor.py --check-scaffolds"
    Then scaffold 有效性检查应显示 FAIL
    And 报告应指出 "nonexistent-skill not found"

  Scenario: 环境版本不满足
    Given node 版本低于 v18
    When 运行 "python3 devkit-doctor.py --check-env"
    Then 环境检查应显示 WARN

  Scenario: JSON 模式输出
    When 运行 "python3 devkit-doctor.py --format json"
    Then 输出应为合法 JSON
    And 应包含 checks / summary / exit_code 字段
```

## 用户故事

| ID | 故事 | 优先级 |
|----|------|--------|
| U1 | 作为开发者，我想一键检查安装是否完整，以便快速定位配置问题 | P0 |
| U2 | 作为 CI/CD pipeline，我想以 JSON 格式获取检查结果，以便自动化判断 | P1 |
| U3 | 作为初学者，我想看到清晰的 PASS/FAIL/WARN 输出，以便理解哪步出了问题 | P1 |
| U4 | 作为维护者，我想单独运行某个检查分类，以便快速验证单项修复 | P2 |

## 技术约束

- Python 3.10+，无额外依赖（仅 stdlib + yaml）
- 跨平台: Windows / macOS / Linux
- 输出格式: text (默认) / JSON (可选)
- 退出码: 0 = 全通过, 1 = 有 FAIL, 2 = 有 WARN
