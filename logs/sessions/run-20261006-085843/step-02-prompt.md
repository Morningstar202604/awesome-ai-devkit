# Step: 技术方案设计
**Description**: API / 数据模型 / 变更范围
## Context
- Task: example-feature
- Working directory: C:\Users\Administrator\.meituan-catpaw\3674654490\desk_default_workspace\awesome-ai-devkit
## Required Outputs
- `docs/design/<feature>.md`
## Reference Skills
## Skill: backend-architecture

---
name: backend-architecture
description: 后端架构：Feature-first分层、Controller→Service→Repository、依赖注入、CQRS
layer: 5-Skills
scenarios: [programming/fullstack]
tags: [backend, architecture, fastapi, layered, di, cqrs]
---

# 后端架构

## 触发条件
当需要设计后端项目结构、划分层级职责、或实现依赖注入时触发。

## 核心模式

### 1. Feature-First 目录结构

```
app/
├── main.py                    # FastAPI app factory
├── core/                      # 框架级基础设施
│   ├── config.py             # Settings (Pydantic BaseSettings)
│   ├── database.py           # DB session/engine
│   ├── security.py           # JWT, password hashing
│   └── middleware.py          # CORS, request ID, error handler
├── dependencies/              # FastAPI Depends() 提供者
│   ├── get_db.py
│   ├── get_current_user.py
│   └── get_services.py
├── features/                  # 按业务域组织
│   ├── auth/
│   │   ├── router.py         # API endpoints
│   │   ├── service.py        # Business logic
│   │   ├── repository.py     # Data access
│   │   ├── schemas.py        # Pydantic models
│   │   ├── models.py         # SQLAlchemy models
│   │   └── dependencies.py   # Feature-specific DI
│   ├── orders/
│   │   ├── router.py
│   │   ├── service.py
│   │   ├── repository.py
│   │   ├── schemas.py
│   │   └── models.py
│   └── products/
│       ├── router.py
│       ├── service.py
│       ├── repository.py
│       ├── schemas.py
│       └── models.py
└── shared/
    ├── exceptions.py          # Domain exceptions
    ├── pagination.py          # Pagination params
    └── types.py               # Shared type aliases
```

### 2. Controller → Service → Repository 分层

```python
# features/orders/router.py (Controller/Route Layer)
from fastapi import APIRouter, Depends
from app.features.orders.service import OrderService
from app.features.orders.schemas import OrderResponse, CreateOrderRequest

router = APIRouter(prefix="/api/orders", tags=["orders"])

@router.get("", response_model=PaginatedResponse[OrderResponse])
async def list_orders(
    pagination: PaginationParams = Depends(),
    service: OrderService = Depends(get_order_service),
):
    """Only parameter mapping and response formatting."""
    return await service.list_orders(page=pagination.page, size=pagination.size)

@router.post("", response_model=OrderResponse, status_code=201)
async def create_order(
    req: CreateOrderRequest,
    service: OrderService = Depends(get_order_service),
):
    return await service.create_order(req)
```

```python
# features/orders/service.py (Service Layer)
from app.features.orders.repository import OrderRepository
from app.features.inventory.service import InventoryService
from app.shared.exceptions import InsufficientStockError

class OrderService:
    def __init__(
        self,
        repo: OrderRepository,
        inventory: InventoryService,
        event_bus: EventBus,
    ):
        self.repo = repo
        self.inventory = inventory
        self.event_bus = event_bus

    async def create_order(self, req: CreateOrderRequest) -> Order:
        """Bu
... (truncated)
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
## Instructions
1. Read all reference skill(s) carefully
2. Produce all required output files
3. Self-verify against quality gate
4. If quality gate fails, fix and re-verify until passing
5. When done, reply with 'DONE' and a one-line summary
Begin.