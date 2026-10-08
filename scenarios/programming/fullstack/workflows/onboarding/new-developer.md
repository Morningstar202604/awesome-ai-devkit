---
name: new-developer
description: 新开发者入职工作流：从入职到首次代码提交的完整引导
version: "1.0"
agents_involved:
  - tech-lead
  - senior-developer
  - product-manager
  - scrum-master
estimated_duration: 3 ~ 5 天
---

# 新开发者入职工作流

> 标准化的入职流程。确保新成员在 3-5 天内建立起独立开发能力：环境搭建 → 代码理解 → 小任务实践 → 首次上线。

---

## 流程总览

```
day-0:prepare → day-1:orientation → day-2:setup →
day-3:first-task → day-4:review → day-5:first-deploy
```

---

## Day 0: 入职前准备

**角色**: `tech-lead`、HR（协调）

**输入**:
- 新开发者信息（姓名、角色、技术背景、入职日期）

**产出**:
- 入职任务清单已创建
- Git/Slack/Jira 等工具账号已开通
- Mentor（Buddy）已指定（由 senior-developer 担任）
- 电脑/开发设备已准备

**提前发送**:
- 公司/团队简介
- 技术栈概览
- 推荐阅读材料（架构文档、代码规范）

**产出交付**:
- [ ] 系统账号全部开通
- [ ] Mentor 已确认
- [ ] 入职 calendar 同步（Day 1 的 30min 会议、全天安排）

---

## Day 1: 团队融合与产品认知

**角色**: `product-manager`、`scrum-master`、`tech-lead`

**上午 — 团队与流程**（2-3 小时）：
- 团队介绍与组织架构
- 编码规范与分支策略
- Code Review 流程与标准
- 工作节奏（Sprint、站会、评审）
- 故障响应流程（仅了解）

**下午 — 产品与业务**（2-3 小时）：
- 产品核心价值观与目标用户
- 当前版本的 Demo
- 核心业务概念词汇表（Ubiquitous Language）
- 产品路线图概览

**Hook 触发**:
- `on_new_hire_day1` → 自动发送欢迎消息到团队频道

**产出**:
- [ ] 新人已在团队 channel 自我接下
- [ ] 已了解产品核心价值和用户路径
- [ ] 已理解团队工作流程

---

## Day 2: 开发环境搭建

**角色**: 新开发者（操作）、`senior-developer`（协助 Mentor）

**目标**：本机能成功运行前后端。

**环境搭建步骤**:
1. **克隆仓库** + 切换到开发分支
2. **安装依赖**、配置 IDE（推荐配置已分享）
3. **配置环境变量**（.env.example → .env.local）
4. **数据库准备**（本地安装或使用 Docker）
5. **运行 migration** + 种子数据
6. **启动前后端 dev server**
7. **验证**：访问 localhost 确认页面可打开

**环境验证脚本**（`scripts/verify-env.sh`）:
```bash
#!/bin/bash
echo "=== 开发环境验证 ==="
node --version  || echo "node 缺失"
npm --version   || echo "npm 缺失"
git --version   || echo "git 缺失"
npx prisma migrate status || echo "DB 不可达"
curl -s http://localhost:3000/api/health || echo "前端未运行"
curl -s http://localhost:4000/health    || echo "后端未运行"
echo "=== 验证完成 ==="
```

**Hooks 触发**:
- `on_env_setup_complete` → 标记 Day 2 完成

**产出**:
- [ ] 本地可运行的项目
- [ ] 能登录开发版并操作核心功能
- [ ] Mentor 确认环境问题已解决

---

## Day 3: 代码探索与首个小任务

**角色**: 新开发者、`senior-developer`（Mentor）

**上午 — 代码探索**（2-3 小时）：
- 代码仓库结构概览
- 前端目录 → 组件、路由、状态管理
- 后端目录 → 路由、服务层、数据层
- 关键设计决策（为什么选了这个方案）
- 在 Mentor 引导下 trace 一个完整的请求（从 UI 到 DB）

**下午 — 首个任务**（2-3 小时）：
- 从 Good First Issues 中挑选一个任务
- 典型首个任务：
  - 修复一个 typo 或文案
  - 添加一个组件的 unit test
  - 更新文档
  - 添加一个新的 env var 配置

**任务分配规则**:
- 不超过 4 小时工作量
- 有明确的 Done 标准
- 不影响线上系统

**Hooks 触发**:
- `on_first_task_assigned` → 自动关联 Mentor 评审
- `on_first_pr_opened` → 触发 onboarding review 流程

**产出**:
- [ ] 理解了代码组织方式
- [ ] 首个 PR 已发送
- [ ] Mentor 已完成 review 并给出反馈

---

## Day 4: Code Review 反馈与迭代

**角色**: 新开发者、`senior-developer`（Mentor）

**目标**：通过首轮 PR 的 feedback 学习和改进。

**流程**:
1. Mentor 的 review 反馈讲解（面对面或视频）
2. 新开发者理解问题并修改
3. 再次提交
4. Approve + Merge

**Review 反馈要点**（教而非判）:
- 规范使用（而非"你错了"）
- 提供团队约定的最佳实践链接
- 鼓励提问："为什么这样更好？"

**Hooks 触发**:
- `on_first_pr_merged` → 发送庆祝消息到团队频道

**产出**:
- [ ] 首个 PR 已合并
- [ ] 了解了团队的 CR 标准
- [ ] 熟悉了完整的提交-审查-合并流程

---

## Day 5: 首 deploy 与后续规划

**角色**: `tech-lead`、新开发者、`devops-engineer`

**上午 — 首个功能向任务**:
- 分配一个真实的、小型的功能开发任务
- Mentor 协助设计拆分
- 开始前后端实现的熟悉

**下午 — 首 deploy 体验**:
- 在指导者的陪同下执行发布流程
- 体验 staging 验证 → 生产发布 → 监控查看
- 理解发布是团队协作行为，不是个人行为

**Hooks 触发**:
- `on_first_deploy_done` → 团队分享里程碑消息
- `on_onboarding_complete` → 标记入职流程结束

**产出**:
- [ ] 首个功能地完成并合并
- [ ] 体验了一次发布流程
- [ ] Tech Lead 评估是否可独立完成常规任务
- [ ] 制定 30-60-90 天成长目标

---

## 入职后持续跟进

**Week 2-4**:
- 每周 1:1 with Mentor（30 分钟）
- 参与团队会议并主动发言
- 开始处理更复杂的任务

**Month 2-3**:
- 独立负责模块
- 参与 code review 他人 PR
- 开始贡献架构改进建议

**Mentor 退出标准**:
- 新人可独立处理常规任务
- 不需要额外解释团队规范
- 首次独立发布成功

---

## 环境准备清单

| 类别 | 工具 | 获取方式 |
|------|------|---------|
| 沟通 | Slack / 飞书 | IT 开通 |
| 代码 | GitHub / GitLab | Tech Lead 加权限 |
| 文档 | Notion / 飞书文档 | 邀请链接 |
| 项目 | Jira / Linear | 加入项目 |
| 设计 | Figma | 邀请链接 |
| 监控 | Sentry / Grafana | Tech Lead 配置 |
| CI/CD | GitHub Actions | 默认有权限 |
| 数据库 | 本地 Postgres / Docker | 看 README |
| 包管理 | npm / pnpm | 安装即可 |

---

## 异常情况

| 场景 | 处理 |
|------|------|
| 环境问题无法解决 | Mentor 远程协助，必要时替换为云端开发环境（Gitpod/Codespaces） |
| 首个 PR 多次返工 | 保持耐心，这不是能力问题；考虑调小任务粒度 |
| 新开发者进度超预期 | 提前安排真实功能任务 |
| 新开发者压力大 | 1:1 主动沟通，强调完成比完美重要 |
