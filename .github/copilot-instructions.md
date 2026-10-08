# GitHub Copilot 工程指令 — 2026 标准

> 适用：GitHub Copilot Chat / Copilot Agent Mode / Copilot CLI
> 采纳率：企业覆盖率 90% / IDE 市占率约 21%（Claude Code 39% 上升中）
> 最后更新：2026-10

---

## 🏗 项目通用约定

- **默认语言**：与项目一致，回复用中文
- **默认框架**：根据 package.json / pyproject.toml / Cargo.toml 自动识别
- **不要生成冗余 import**，不修改无关文件，不添加未请求的功能

---

## 代码风格与规范

### Python
- Python 3.12+，优先用 type hint、dataclass、match/case
- 遵循 PEP 8 + Black 风格，docstring 用 Google 风格
- 异步代码用 async/await，不用回调
- 优先用标准库，第三方包需验证维护状态（PyPI stars > 500，最近提交 < 6 个月）

### TypeScript / JavaScript
- ES2022+，strict mode 启用
- 优先用 `interface` 描述对象形状，`type` 用于联合/映射
- 函数式风格优先（map/filter/reduce），避免 for 循环
- 错误处理：用 Result 模式或 try-catch，禁止吞异常

### Java
- Java 21+，优先用 record、sealed class、pattern matching
- Spring Boot 3.x，JPA/Hibernate 6
- 遵循 Google Java Style，Javadoc 公共 API

### Go
- Go 1.22+，遵循 Effective Go + 官方 review 规范
- idiom：err != nil 处理，不 panic，context.Context 传递
- 包名小写单文件，接口定义在调用方

### Rust
- Edition 2024，遵循 rustfmt + clippy 严格模式
- 优先用 `Result<T, E>`，自定义 error 用 thiserror
- 所有权清晰，避免不必要的 clone

---

## 安全红线（OWASP Top 10 2024）

| 类别 | 规则 |
|------|------|
| 注入 | 参数化查询 / ORM，禁止拼接 SQL / 命令 |
| 认证 | bcrypt/argon2 哈希，JWT 验签 + 过期，禁止明文存储密钥 |
| 敏感数据 | 环境变量进秘密管理器，不硬编码 .env，日志脱敏 |
| 访问控制 | 默认拒绝，显式白名单，路径遍历校验 XXE |
| XML | 禁用外部实体，禁用 DTD |
| 反序列化 | 白名单类白名单，禁止 ObjectInputStream 直接读 |
| 日志 | 不记录密码/Token/个人明文信息 |

---

## API 设计规范

- REST：资源名词复数，版本在 URL（/api/v1/），标准化错误体
- GraphQL：schema 优先，N+1 用 DataLoader，复杂度限制
- gRPC：proto3 定义，向后兼容字段保留
- 响应格式：`{ "code": "SUCCESS", "data": {...}, "message": "..." }`
- 错误格式：`{ "code": "ERR_XXX", "message": "...", "details": [...] }`

---

## 测试规范

- 单元测试：覆盖率 ≥ 80%，AAA 结构，Mock 外部依赖
- 集成测试：测试容器（Testcontainers），真实数据库交互
- E2E 测试：Playwright/Cypress，关键用户路径覆盖
- TDD 场景：先写失败测试 → 实现 → 重构

---

## Git / 提交规范

- Conventional Commits：`feat:` / `fix:` / `refactor:` / `docs:` / `test:` / `chore:`
- 分支：main（受保护）→ develop → feature/xxx / fix/xxx
- PR：关联 issue，CI 全绿，至少一人 review
- commit 粒度：单一职责，禁止"修复和重构一起提交"

---

## 数据库规则

- 用 ORM 或查询构造器，禁止字符串拼接 SQL
- 迁移文件幂等，可回滚，带 down 方法
- 敏感字段加密存储（AES-256-GCM），关联字段合理索引
- 大表变更：gh-ost / pt-online-schema-change 无锁变更

---

## 性能准则

- 数据库查询：N+1 用 JOIN/batch，分页用游标分页
- 缓存：Redis/Memcached，合理 TTL，缓存穿透/雪崩防护
- 异步CPU密集：线程池/协程，不阻塞 I/O 线程
- 监控：关键路径埋点（耗时/QPS/错误率）

---

## 协作约定

- 对话语言：中文（除非讨论英文文档或 API）
- 代码不解释不写，解释不代码不做
- 重构请求：先确认范围，不扩散修改
- 新增依赖：提供理由 + 替代方案比较

---

> 💡 **2026 趋势**：GitHub Copilot 已转向 Agent 模式，支持多文件编辑与 notebooks 增强。
> 企业版支持私有代码库微调与合规审查。若需本地模型或更深度管控，请配合 Azure AI。
