---
name: 安全检查清单
description: AI 辅助开发安全检查清单——OWASP Top 10 + API + 数据安全
layer: 1-Rules
scenarios: [programming/fullstack]
---

# 安全检查清单

> AI 在编写或审查代码时必须逐条核查。发现高风险项应中止并提示。

## OWASP Top 10 对应

| 风险 | 检查点 | 阻断条件 |
|------|-------|---------|
| A01 访问控制 | 每个 endpoint 校验权限 | 无 @requireAuth 装饰器 |
| A02 密码学 | 密钥长度≥256bit、bcrypt≥12轮 | MD5/sha1、硬编码密钥 |
| A03 注入 | 参数化查询、无字符串拼接 SQL | 手动拼接 SQL/命令 |
| A04 不安全设计 | 限流、熔断、超时全配置 | 无 429/503 处理 |
| A05 安全配置 | helmet/cors/secure headers | cors: origin='*' 上线 |
| A06 脆弱组件 | npm/pip audit 无高危 | critical CVE 未修 |
| A07 认证错误 | JWT 正确校验、refresh轮换 | token 无过期/无签名验证 |
| A08 数据完整性 | 签名校验、防重放 nonce | 无签名、无幂等 |
| A09 日志不足 | 安全事件全部记录 | 登录失败/SQL错误无日志 |
| A10 SSRF | URL 校验、白名单 | 用户输入直传内部服务 |

## API 安全规则

```
✅ 所有 API 默认鉴权，公开 API 显式标注 @public
✅ 请求/响应禁止返回 password/hash/secret 字段
✅ PATCH 操作必须校验所有权: resource.userId === currentUser.id
✅ 批量接口限制 max pageSize = 100
✅ WebSocket 连接必须带 token，30s 内未认证断开

❌ 禁止 GET 请求改状态（幂等性原则）
❌ 禁止 response 中暴露 stack trace（生产环境）
❌ 禁止依赖客户端计算价格/权限
```

## 数据安全

| 数据类型 | 要求 |
|---------|------|
| 密码 | bcrypt/argon2id + salt，禁止日志 |
| PII（姓名/邮箱/手机） | AES-256 加密存储、脱敏展示 |
| API Key | HMAC-SHA256 哈希存储、前缀可见 |
| Token | httpOnly + secure + sameSite=strict |
| 文件上传 | 类型白名单、大小限制、magic bytes 校验 |

## AI 自检提示

当 AI 生成以下代码时，自动追加安全检查：
- SQL 查询 → 确认参数化
- 用户输入渲染 → 确认 XSS 转义
- 文件操作 → 确认路径遍历防护
- API 端点 → 确认鉴权中间件
