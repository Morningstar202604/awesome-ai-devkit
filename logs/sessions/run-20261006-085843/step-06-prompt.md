# Step: 代码自审 + 发布
## Context
- Task: example-feature
- Working directory: C:\Users\Administrator\.meituan-catpaw\3674654490\desk_default_workspace\awesome-ai-devkit
## Required Outputs
(no specific outputs)
## Quality Gate
After completing this step, verify: **无安全高危漏洞；CHANGELOG 已更新**
## Reference Skills
## Skill: security

---
name: security
description: Web应用安全：OWASP Top 10防护、XSS/CSRF/SQLi防御、CSP、密钥令牌轮换
layer: 5-Skills
scenarios: [programming/fullstack]
tags: [security, owasp, xss, csrf, sqli, csp, auth]
---

# Web 应用安全

## 触发条件
当需要进行安全审查、实现防护措施、或修复安全漏洞时触发。

## OWASP Top 10 核心防护

### 1. 注入攻击（SQLi / NoSQLi）

```python
# BAD: String interpolation → SQL Injection
query = f"SELECT * FROM users WHERE name = '{user_input}'"

# GOOD: Parameterized queries (SQLAlchemy)
from sqlalchemy import text
stmt = text("SELECT * FROM users WHERE name = :name")
result = await db.execute(stmt, {"name": user_input})

# GOOD: ORM 查询（自动转义）
user = await db.query(User).filter(User.name == user_input).first()

# MongoDB injection prevention
# BAD: Direct user input in MongoDB query
collection.find({"username": user_input})  # If user_input = {"$ne": null} → bypass

# GOOD: Type-check and sanitize
from pymongo import MongoClient
if not isinstance(user_input, str):
    raise ValidationError("Invalid input type")
collection.find({"username": {"$eq": user_input}})
```

### 2. XSS 防护

```typescript
// React 默认 esc JSX expression（安全）
// BAD: dangerouslySetInnerHTML
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// BETTER: Sanitize with DOMPurify
import DOMPurify from "dompurify";

function SafeHTML({ content }: { content: string }) {
  const sanitized = DOMPurify.sanitize(content, {
    ALLOWED_TAGS: ["b", "i", "em", "strong", "a", "p", "br"],
    ALLOWED_ATTR: ["href", "target"],
  });
  return <div dangerouslySetInnerHTML={{ __html: sanitized }} />;
}

// Reflected XSS: 不要将 URL params 直接渲染
// BAD: const search = new URLSearchParams(location.search).get("q"); → <div>{search}</div>
// GOOD: React 自动 escape，除非 dangerouslySetInnerHTML
```

```python
# FastAPI input validation (prevents many injection types)
from pydantic import BaseModel, field_validator
import re

class CreatePostRequest(BaseModel):
    title: str
    content: str

    @field_validator("title")
    @classmethod
    def validate_title(cls, v: str) -> str:
        if len(v) > 200:
            raise ValueError("Title too long")
        # Remove potential script tags
        if re.search(r"<script", v, re.IGNORECASE):
            raise ValueError("Invalid content")
        return v.strip()
```

### 3. CSRF 防护

```python
# FastAPI CSRF middleware
from starlette.middleware.base import BaseHTTPMiddleware

class CSRFMiddleware(BaseHTTPMiddleware):
    SAFE_METHODS = {"GET", "HEAD", "OPTIONS"}

    async def dispatch(self, request, call_next):
        if request.method not in self.SAFE_METHODS:
            # Check Origin/Referer header
            origin = request.headers.get("origin", "")
            if origin not in settings.ALLOWED_ORIGINS:
                return JSONResponse({"error": "CSRF: Invalid origin"}, status=403)

            # Or check CSRF token
            token = request.headers.get("X-CSRF-Token")
            session_token = request.cookies.get("csrf_token")
            if not token or token != session_token:
  
... (truncated)
## Instructions
1. Read all reference skill(s) carefully
2. Produce all required output files
3. Self-verify against quality gate
4. If quality gate fails, fix and re-verify until passing
5. When done, reply with 'DONE' and a one-line summary
Begin.