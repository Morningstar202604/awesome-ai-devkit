---
name: 编码规范
description: 全栈项目编码规范——TypeScript / Python / 通用最佳实践
layer: 1-Rules
scenarios: [programming/fullstack]
---

# 编码规范（全栈通用）

> 此规则适用所有 AI 代理和人类开发者。当 AI 编写或审查代码时必须遵循。

## TypeScript 规范

### 命名

```
变量/函数: camelCase          userService, fetchUserData
类/接口:   PascalCase         UserController, ApiResponse
常量:      SCREAMING_SNAKE    MAX_RETRY_COUNT, API_BASE_URL
文件:      kebab-case         user-service.ts, api-client.ts
私有成员:  # 前缀（原生私有）  #userRepo, #validate()
```

### 类型

| 规则 | 正确 | 错误 |
|------|------|------|
| 接口返回值 | `Promise<UserDTO>` | `Promise<any>` |
| 可选参数 | `name?: string` | `name: string \| undefined` |
| 联合类型 | `type Status = 'active' \| 'inactive'` | `type Status = string` |
| 异常 | `throw new NotFoundError('User', id)` | `throw new Error('not found')` |

### 异步

```typescript
// ✅ async/await，禁止裸 .then() 链
const user = await userRepo.findById(id);

// ✅ 并行请求用 Promise.all
const [user, orders] = await Promise.all([
  userRepo.findById(userId),
  orderRepo.findByUser(userId),
]);
```

## Python 规范

### 命名

```
变量/函数: snake_case         user_service, fetch_data
类:        PascalCase         UserController, OrderService
常量:      SCREAMING_SNAKE    MAX_RETRY_COUNT, DATABASE_URL
私有:      _ 前缀             _validate(), _internal_cache
```

### 类型注解

```python
# ✅ 所有公共函数必须有类型注解
async def get_user(user_id: int) -> UserDTO:
    user = await self.repo.find_by_id(user_id)
    if not user:
        raise NotFoundError("User", str(user_id))
    return UserDTO.model_validate(user)

# ✅ 可选值用 | None (Python 3.10+)
def find_by_email(email: str) -> User | None: ...
```

### Pydantic 模型

```python
class UserCreateRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    role: UserRole = UserRole.MEMBER

class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

## 通用原则

| # | 规则 | 原因 |
|---|------|-----|
| 1 | 禁止 secrets 硬编码 — 必须读 env | 安全审计 |
| 2 | 所有外部输入在 boundary 验证 | 防御注入 |
| 3 | 错误必须结构化 + 带 request_id | 可观测性 |
| 4 | 日志用 JSON 格式，禁止 console.log / print | 集中采集 |
| 5 | 数据库变更用 migration，禁止手动改 schema | 版本化 |
| 6 | API 必须版本化（URL 或 Header） | 向后兼容 |
| 7 | 每个 endpoint 必须有对应的测试 | 覆盖率 |
| 8 | commit message 用 Conventional Commits | 自动化 changelog |
