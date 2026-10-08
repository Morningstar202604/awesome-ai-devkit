# Step: 后端实现
## Context
- Task: example-feature
- Working directory: C:\Users\Administrator\.meituan-catpaw\3674654490\desk_default_workspace\awesome-ai-devkit
## Required Outputs
- `src/api/<feature>/<controller>.py`
## Quality Gate
After completing this step, verify: **后端单元测试全部通过**
## Reference Skills
## Skill: api-design

---
name: api-design
description: |
  RESTful 与 GraphQL API 设计完整规范，涵盖命名约定、HTTP 方法语义、状态码选择、分页策略（cursor/offset）、版本管理方案、统一错误响应格式、OpenAPI 文档模板，提供 TypeScript + Python 双语代码示例
layer: 5-Skills
scenarios: [programming/fullstack]
tags: [api, rest, graphql, openapi, backend, swagger, fastify, fastapi]
---

# API 设计规范与契约管理

## 触发条件

当遇到以下任一场景时，务必使用本 Skill：

- 设计新的 RESTful 或 GraphQL 端点
- 重构存在一致性问题的现有 API
- 定义前后端交互契约（OpenAPI Schema / GraphQL SDL）
- 引入 API 版本管理策略
- 统一多服务的错误响应格式
- 为 API 添加分页、过滤、排序能力
- 安全审查中的 API 认证/授权策略评估
- 生成 API 文档供前端团队或第三方开发者参考

---

## 核心模式

### 1. RESTful 资源命名规范

**原则**：使用名词复数表示资源集合，避免动词在路径中。

```
GET    /api/v1/users              # 列出用户
GET    /api/v1/users/{id}         # 获取单个用户
POST   /api/v1/users              # 创建用户
PUT    /api/v1/users/{id}         # 全量更新用户
PATCH  /api/v1/users/{id}         # 部分更新用户
DELETE /api/v1/users/{id}         # 删除用户
GET    /api/v1/users/{id}/orders  # 嵌套资源：用户的所有订单
```

**TypeScript (Fastify 路由定义示例):**

```typescript
import Fastify, { FastifyInstance } from 'fastify';
import { z } from 'zod';

const app: FastifyInstance = Fastify({ logger: true });

// 统一的错误响应 schema
const ErrorResponse = z.object({
  code: z.string(),
  message: z.string(),
  details: z.array(z.object({
    field: z.string(),
    issue: z.string(),
  })).optional(),
  requestId: z.string().uuid(),
});

// 查询参数 schema
const ListUsersQuery = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  sort: z.enum(['created_at', 'name', 'email']).default('created_at'),
  order: z.enum(['asc', 'desc']).default('desc'),
  search: z.string().optional(),
});

// GET /api/v1/users — cursor-based 分页
app.get('/api/v1/users', {
  schema: {
    querystring: ListUsersQuery,
    response: {
      200: z.object({
        data: z.array(z.object({
          id: z.string().uuid(),
          name: z.string(),
          email: z.string().email(),
          created_at: z.string().datetime(),
        })),
        pagination: z.object({
          next_cursor: z.string().nullable(),
          has_more: z.boolean(),
        }),
      }),
      400: ErrorResponse,
    },
  },
}, async (request, reply) => {
  const { page, limit, sort, order } = request.query;
  const users = await userRepository.findMany({ page, limit, sort, order });
  return reply.send({
    data: users.items,
    pagination: {
      next_cursor: users.nextCursor,
      has_more: users.hasMore,
    },
  });
});

// POST 统一错误处理
app.setErrorHandler((error, request, reply) => {
  const requestId = request.headers['x-request-id'] as string || crypto.randomUUID();
  if (error.validation) {
    reply.status(422).send({
      code: 'VALIDATION_ERROR',
      message: 'Request validation failed',
      details: error.validation.map(v => ({
        field: v.instancePath.replace('/', ''),
        issue: v.message,
      })),
      requestId,
    });
    return;
  }
  reply.status(error.statusCode || 500).send({
    code: error.code || 'INTERNAL
... (truncated)
## Skill: auth-implementation

---
name: auth-implementation
description: |
  用户认证与授权完整实现指南，涵盖 JWT + Refresh Token 双令牌机制、Session-based 认证、OAuth2/OIDC 第三方登录（GitHub/Google）、RBAC 基于角色权限控制、API Key 管理，提供 TypeScript + Python 前后端完整代码示例
layer: 5-Skills
scenarios: [programming/fullstack]
tags: [auth, jwt, oauth, session, security, rbac, oidc, refresh-token]
---

# 认证与授权实现完整指南

## 触发条件

当遇到以下任一场景时，务必使用本 Skill：

- 为新项目搭建用户注册、登录、登出功能
- 实现 Token 刷新机制（Access Token 过期后自动续期）
- 集成第三方登录（GitHub、Google、微信 OAuth2）
- 设计角色与权限系统（RBAC / ABAC）
- 实现 API Key 或 Service Token 管理（服务间通信）
- 审计现有认证机制的安全漏洞
- 管理 Session 生命周期（过期、撤销、并发控制）
- 实现多因素认证（MFA / TOTP）

---

## 核心模式

### 1. JWT + Refresh Token 双令牌机制

**架构流程：**

```
Client                    Server                    Redis
  |                         |                         |
  |--- POST /auth/login --->|                         |
  |                         |--- verify password ---->|
  |                         |<-- user valid ----------|
  |                         |--- store refresh token->|
  |<-- access_token(15m) --|                         |
  |    refresh_token(7d)    |                         |
  |                         |                         |
  |--- GET /api/resource --X---> (token expired)     |
  |<-- 401 Unauthorized ---|                         |
  |                         |                         |
  |--- POST /auth/refresh >|                         |
  |    (refresh_token)      |--- validate in Redis -->|
  |                         |<-- valid, rotate ------|
  |--- store new refresh ->|                         |
  |<-- new access+refresh -|                         |
```

**TypeScript (Node.js + Fastify + Redis):**

```typescript
import jwt from 'jsonwebtoken';
import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';
import { FastifyInstance } from 'fastify';

// Token 配置
const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL_DAYS = 7;
const REFRESH_TOKEN_BYTES = 48;

interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

interface AccessPayload {
  sub: string;       // user ID
  email: string;
  roles: string[];
  type: 'access';
}

interface RefreshPayload {
  sub: string;
  type: 'refresh';
  jti: string;       // token unique ID for revocation
}

// 生成 Token 对
export async function generateTokenPair(
  userId: string,
  email: string,
  roles: string[],
  redis: RedisClient,
): Promise<TokenPair> {
  // Access Token
  const accessToken = jwt.sign(
    { sub: userId, email, roles, type: 'access' } satisfies AccessPayload,
    process.env.JWT_ACCESS_SECRET!,
    { algorithm: 'RS256', expiresIn: ACCESS_TOKEN_TTL },
  );

  // Refresh Token — 随机字符串，仅存储 hash 在服务端
  const refreshToken = randomBytes(REFRESH_TOKEN_BYTES).toString('base64url');
  const refreshTokenHash = createHash('sha256').update(refreshToken).digest('hex');

  const payload: RefreshPayload = {
    sub: userId,
    type: 'refresh',
    jti: refreshTokenHash.slice(0, 16),
  };

  // Store in Redis with TTL
  await redis.setex(
    `r
... (truncated)
## Instructions
1. Read all reference skill(s) carefully
2. Produce all required output files
3. Self-verify against quality gate
4. If quality gate fails, fix and re-verify until passing
5. When done, reply with 'DONE' and a one-line summary
Begin.