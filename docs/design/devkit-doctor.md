# devkit-doctor — 技术方案设计

> 生成时间: 2026-10-06
> 关联需求: docs/requirements/devkit-doctor.md

## 架构概览

devkit-doctor 是一个单文件 CLI 工具，采用**插件式检查器架构**：

```
devkit-doctor.py
├── CheckRunner          # 调度器，加载并执行所有注册检查器
├── BaseCheck (ABC)      # 检查器抽象基类
│   ├── SkillIntegrityCheck    # 52 个 SKILL.md 完整性
│   ├── ScaffoldValidityCheck  # scaffold yaml 合法性 + 引用
│   ├── MCPConfigCheck         # mcp-config.yaml 一致性
│   ├── HooksCheck             # hooks scripts 存在性 + 可执行性
│   └── EnvDependencyCheck     # git/node/python 最低版本
└── CheckResult          # 单个检查结果 enum(PASS/FAIL/WARN)
```

## 数据模型

```python
class CheckResult(Enum):
    PASS = "pass"
    FAIL = "fail"
    WARN = "warn"

@dataclass
class Finding:
    check: str           # 检查器名称
    result: CheckResult
    message: str         # 人类可读描述
    fix_hint: str = ""   # 修复建议
```

## CLI 接口

```
usage: devkit-doctor.py [--format {text,json}] [--check {skills,scaffolds,mcp,hooks,env,all}]

Options:
  --format {text,json}   输出格式 (默认 text)
  --check NAME           只运行某类检查 (默认 all)
  --root PATH            项目根目录 (默认自动检测)
  -v, --verbose          详细输出
```

## 输出格式

**text (默认)**:
```
[Awesome AI DevKit Doctor]
  ✓ skills      PASS  (52/52 SKILL.md present)
  ✓ scaffolds   PASS  (3 scaffolds valid)
  ✓ mcp         PASS  (mcp-config.yaml valid, 6 servers enabled)
  ✓ hooks       PASS  (all referenced scripts exist)
  ✓ env         PASS  (git 2.52, node 24.18, python 3.14)

Result: ALL PASS (5/5)
```

**JSON**:
```json
{
  "checks": [
    {"name": "skills", "result": "pass", "detail": "52/52 SKILL.md present"},
    ...
  ],
  "summary": {"pass": 5, "fail": 0, "warn": 0},
  "exit_code": 0
}
```

## 关键设计决策

1. **单文件**: 确保 `import yaml` 是项目已依赖的（scaffold-runner.py 也需要），无新增依赖
2. **根目录自动检测**: 先检查当前目录，再向上直到找到 scaffold.yaml 或 scaffolds/ 目录
3. **错误容忍**: 单个检查器异常不阻断整体，标记为该分类 FAIL

## 实施计划

| 阶段 | 内容 | 优先级 |
|------|------|--------|
| 1 | BaseCheck 抽象 + CheckRunner 框架 | P0 |
| 2 | SkillIntegrityCheck | P0 |
| 3 | ScaffoldValidityCheck | P0 |
| 4 | MCPConfigCheck + HooksCheck + EnvDependencyCheck | P1 |
| 5 | --format json 输出 | P1 |
| 6 | 自我测试（用 devkit 自身做 dogfood） | P1 |
