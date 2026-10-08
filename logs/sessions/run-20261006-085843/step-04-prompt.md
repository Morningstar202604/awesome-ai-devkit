# Step: 前端实现
## Context
- Task: example-feature
- Working directory: C:\Users\Administrator\.meituan-catpaw\3674654490\desk_default_workspace\awesome-ai-devkit
## Required Outputs
- `frontend/app/<feature>/page.tsx`
## Quality Gate
After completing this step, verify: **前端 build 无 error**
## Reference Skills
## Skill: design-system

---
name: design-system
description: 设计系统：设计令牌(CSS变量)、组件库(Radix/shadcn)、主题(暗色模式)、响应式设计
layer: 5-Skills
scenarios: [programming/fullstack]
tags: [design-system, css-variables, radix, theming, responsive]
---

# 设计系统

## 触发条件
当需要搭建前端组件库、统一视觉规范、或实现主题切换时触发。

## 核心模式

### 1. Design Tokens — CSS 变量

```css
/* styles/globals.css — 设计令牌（Design Tokens） */
@layer base {
  :root {
    /* Color Palette */
    --color-primary-50: 239 246 255;
    --color-primary-100: 219 234 254;
    --color-primary-200: 191 219 254;
    --color-primary-300: 147 197 253;
    --color-primary-400: 96 165 250;
    --color-primary-500: 59 130 246;    /* Main brand */
    --color-primary-600: 37 99 235;
    --color-primary-700: 29 78 216;
    --color-primary-800: 30 64 175;
    --color-primary-900: 30 58 138;

    --color-neutral-0: 255 255 255;
    --color-neutral-50: 250 250 250;
    --color-neutral-100: 245 245 245;
    --color-neutral-200: 229 229 229;
    --color-neutral-300: 212 212 212;
    --color-neutral-400: 163 163 163;
    --color-neutral-500: 115 115 115;
    --color-neutral-600: 82 82 82;
    --color-neutral-700: 64 64 64;
    --color-neutral-800: 38 38 38;
    --color-neutral-900: 23 23 23;
    --color-neutral-950: 10 10 10;

    /* Semantic Colors */
    --color-bg: var(--color-neutral-0);
    --color-fg: var(--color-neutral-900);
    --color-muted: var(--color-neutral-500);
    --color-border: var(--color-neutral-200);
    --color-accent: var(--color-primary-500);
    --color-success: 34 197 94;
    --color-warning: 234 179 8;
    --color-error: 239 68 68;

    /* Spacing Scale */
    --space-0: 0;
    --space-1: 0.25rem;   /* 4px */
    --space-2: 0.5rem;    /* 8px */
    --space-3: 0.75rem;   /* 12px */
    --space-4: 1rem;      /* 16px */
    --space-5: 1.25rem;   /* 20px */
    --space-6: 1.5rem;    /* 24px */
    --space-8: 2rem;      /* 32px */
    --space-10: 2.5rem;   /* 40px */
    --space-12: 3rem;     /* 48px */
    --space-16: 4rem;     /* 64px */

    /* Typography */
    --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
    --font-mono: "JetBrains Mono", ui-monospace, monospace;
    --text-xs: 0.75rem;
    --text-sm: 0.875rem;
    --text-base: 1rem;
    --text-lg: 1.125rem;
    --text-xl: 1.25rem;
    --text-2xl: 1.5rem;
    --text-3xl: 1.875rem;

    /* Radii */
    --radius-sm: 0.25rem;
    --radius-md: 0.5rem;
    --radius-lg: 0.75rem;
    --radius-full: 9999px;

    /* Shadows */
    --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
    --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
    --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);

    /* Motion */
    --ease-standard: cubic-bezier(0.2, 0, 0, 1);
    --ease-emphasized: cubic-bezier(0.3, 0, 0, 1);
    --duration-fast: 150ms;
    --duration-normal: 250ms;
    --duration-slow: 350ms;
  }

  .dark {
    --color-bg: var(--color-neutral-950);
    --color-fg: var(--color-neutral-50);
    --color-muted: var(--color-neutral-400);
    --color-border: var(--color-neutral-800);
  }
}
```

### 2. Tailwi
... (truncated)
## Skill: state-management

---
name: state-management
description: |
  前端状态管理 — Zustand/Jotai 选择、服务端状态 vs 客户端状态、乐观更新、同步与缓存策略
layer: 5-Skills
scenarios:
  - programming/fullstack
tags:
  - state-management
  - zustand
  - jotai
  - tanstack-query
  - optimistic-update
  - server-state
---

# 前端状态管理

## 触发条件

当需要在前端项目中引入状态管理库、区分服务端与客户端状态边界、实现乐观更新反馈、或解决复杂组件间状态共享时触发。

## 核心模式

### 1. 状态分类与分层策略

核心原则：**不是所有状态都需要全局管理**。

```
状态分类决策树：

                            这个状态是不是从服务器来的？
                           /                              \
                        是                                  否
                        ↓                                  ↓
              放在 TanStack Query                    这个状态是否跨组件共享？
              (服务端缓存层)                        /                      \
                                                 是                        否
                                                 ↓                         ↓
                                          全局状态库                  组件本地 state
                                       (Zustand / Jotai)             useState / useReducer
```

### 2. Zustand — 轻量全局状态

适合：用户认证信息、UI 主题、全局配置、共享表单草稿。

```typescript
// stores/user-store.ts
import { create } from 'zustand';
import { persist, devtools } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface UserState {
  id: string | null;
  email: string | null;
  role: 'admin' | 'editor' | 'viewer' | null;
  preferences: {
    theme: 'light' | 'dark' | 'system';
    language: string;
    notifications: boolean;
  };
  // actions
  setUser: (user: { id: string; email: string; role: string }) => void;
  clearUser: () => void;
  updatePreference: <K extends keyof UserState['preferences']>(
    key: K,
    value: UserState['preferences'][K],
  ) => void;
}

export const useUserStore = create<UserState>()(
  devtools(
    immer(
      persist(
        (set) => ({
          id: null,
          email: null,
          role: null,
          preferences: {
            theme: 'system',
            language: 'zh-CN',
            notifications: true,
          },
          setUser: (user) =>
            set((state) => {
              state.id = user.id;
              state.email = user.email;
              state.role = user.role as UserState['role'];
            }),
          clearUser: () =>
            set((state) => {
              state.id = null;
              state.email = null;
              state.role = null;
            }),
          updatePreference: (key, value) =>
            set((state) => {
              state.preferences[key] = value;
            }),
        }),
        {
          name: 'user-storage',
          // 仅持久化 preferences，不持久化敏感认证信息
          partialize: (state) => ({ preferences: state.preferences }),
        },
      ),
    ),
    { name: 'UserStore' },
  ),
);

// 选择器工厂 — 避免不必要的重渲染
import { shallow } from 'zustand/shallow';

// 组件中使用：精确订阅，只有变化的字段触发重渲染
const { theme, language } = useUserStore(
  (s) => ({ theme: s.preferenc
... (truncated)
## Instructions
1. Read all reference skill(s) carefully
2. Produce all required output files
3. Self-verify against quality gate
4. If quality gate fails, fix and re-verify until passing
5. When done, reply with 'DONE' and a one-line summary
Begin.