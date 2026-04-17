---
name: qa-orchestrator
description: |
  在原版基础上新增：.env 环境变量检查、Playwright 工程配置最佳实践建议、移动端测试支持。
  QA 全链路编排器。串联测试设计、执行、覆盖审查三个阶段，形成完整闭环：
  test-case-designer → tdd-guide → e2e-runner → test-coverage-reviewer。
  Use when: "运行完整 QA 流程"、"qa 全链路"、"端到端测试流程"、"从测试计划到覆盖报告"、
  "run qa pipeline"、"full qa"。
  支持三种入口：全新项目（从零生成计划）、已有计划（跳过设计直接执行）、仅审查（只跑覆盖审查）。
  禁止自动调用——必须由用户显式触发。
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
---

# qa-orchestrator

QA 全链路编排器。不做具体测试工作，只负责按正确顺序调度已有 skills 和 agents，并在每个阶段交接时传递正确的上下文。

---

## 可用 agents 分工

| Agent | 职责 | 在本流程中的位置 |
|-------|------|-----------------|
| `test-case-designer` | 生成 specs/ 测试计划文档 | Step 1 |
| `tdd-guide` | 测试先行约束，生成测试代码，确保 80%+ 覆盖率 | Step 2 |
| `e2e-runner` | 执行 Playwright 测试，浏览器验证 | Step 3 |
| `build-error-resolver` | 修复测试执行中的 TypeScript / 构建错误 | Step 3（失败时） |
| `code-reviewer` | 审查生成的测试代码质量和安全性 | Step 2 完成后 |
| `test-coverage-reviewer` | 对照计划审查覆盖缺口，输出覆盖报告 | Step 4 |

**不在本流程中的 agents**（各自独立触发）：
- `architect` — 架构设计，在测试流程之外
- `planner` — 功能规划，在测试流程之外
- `refactor-cleaner` — 发现冗余测试后可手动调用，不在主链路内
- `security-reviewer` — 可在 Step 2 后选择性插入，不强制
- `doc-updater` — 流程结束后可选调用

---

## 固定目录约定

```
项目根目录/
├── specs/                              ← 测试计划文档（按模块拆分、编号）
│   ├── 00-test-strategy.md             ← 全局策略（必须首先生成）
│   ├── 01-auth-test-plan.md
│   ├── 02-repair-request-test-plan.md
│   ├── 03-work-order-test-plan.md
│   ├── 04-permission-test-plan.md
│   └── 05-api-test-plan.md
├── src/                                ← 业务代码
├── tests/                              ← Playwright 测试文件
│   ├── smoke/
│   ├── e2e/
│   ├── api/
│   └── edge/
├── test-results/                       ← Playwright 运行结果（自动生成）
└── qa/
    └── coverage/
        └── coverage-report.md          ← test-coverage-reviewer 的输出
```
 
移动端测试文件放在 `tests/e2e/` 下，文件名加 `-mobile` 后缀，例如：
```
tests/e2e/01-auth-login-mobile.spec.ts
tests/e2e/02-repair-request-submit-mobile.spec.ts
```

---

## specs/ 文件命名规范

| 编号段 | 用途 | 示例 |
|--------|------|------|
| `00` | 全局测试策略，固定唯一 | `00-test-strategy.md` |
| `01`–`09` | 核心业务模块，按重要性排序 | `01-auth-test-plan.md` |
| `10`–`19` | API 层专项 | `10-api-contract-test-plan.md` |
| `20`–`29` | 权限、安全专项 | `20-permission-test-plan.md` |
| `90`–`99` | 性能、压测等专项保留 | `90-performance-test-plan.md` |

**命名格式**：`NN-[module-name]-test-plan.md`（`00` 除外后缀为 `-test-strategy.md`）

**测试文件命名**：`NN-[module]-[scenario].spec.ts`，例如：
```
tests/smoke/01-auth-login.spec.ts
tests/e2e/02-repair-request-submit.spec.ts
tests/e2e/02-repair-request-submit-mobile.spec.ts   ← 移动端对应文件
tests/api/03-work-order-status.spec.ts
tests/edge/04-permission-unauthorized.spec.ts
```

---

## 入口判断

启动时先扫描 `specs/` 目录：

| 入口 | 触发条件 | 跳过步骤 |
|------|----------|----------|
| **全链路**（默认）| `specs/` 为空，或用户要求重新设计 | 无 |
| **跳过设计** | `specs/` 已有有效编号文件 | 跳过 Step 1 |
| **单模块** | 用户指定某个模块，如"只测 auth" | 只处理对应编号文件 |
| **仅覆盖审查** | 用户说"只跑审查"或"coverage review" | 直接跳到 Step 4 |

---

## Step 0 — 环境检查

```bash
# 检查 Playwright 是否已安装
npx playwright --version 2>/dev/null || echo "PLAYWRIGHT_NOT_INSTALLED"

# 列出现有 specs/ 文件，判断跳过哪些步骤
ls specs/*.md 2>/dev/null || echo "SPECS_EMPTY"
```

如果 Playwright 未安装，停止并提示用户先运行 `npx playwright install`。

```bash
mkdir -p specs tests/smoke tests/e2e tests/api tests/edge qa/coverage
```
 
### .env 环境变量检查（新增）
 
```bash
# 检查 .env 文件是否存在
[ -f .env ] || echo "ENV_FILE_MISSING"
 
# 验证必需变量
for var in BASE_URL API_BASE; do
  grep -q "^${var}=" .env 2>/dev/null || echo "MISSING_VAR: ${var}"
done
```
 
**处理规则**：
- `.env` 不存在 → 停止，提示用户复制 `.env.example` 并填写实际值
- `BASE_URL` 缺失 → 停止，浏览器测试无法确定页面根地址
- `API_BASE` 缺失 → 停止，API 测试无法确定接口根路径
- 其他变量（如 `MOCK_LOGIN_URL`）缺失 → 警告，但不阻止流程（项目可能用其他认证方式）

---

## 工程配置最佳实践
 
在开始测试设计前，检查项目是否已有 Playwright 配置文件：
 
```bash
ls playwright.config.js playwright.config.ts e2e/playwright.config.js e2e/playwright.config.ts 2>/dev/null \
  || echo "CONFIG_NOT_FOUND"
```
 
**如果不存在**，按以下推荐值生成 `playwright.config.js`：
 
| 配置项 | 推荐值 | 原因 |
|--------|--------|------|
| `timeout` | `60000` | 单条用例最长 60 秒，应对慢接口 |
| `retries` | `1` | 失败自动重试一次，应对网络抖动 |
| `workers` | `1` | 串行执行，避免并发登录 session 冲突 |
| `screenshot` | `'only-on-failure'` | 失败时自动截图，存入 `test-results/` |
| `trace` | `'on-first-retry'` | 首次重试时录制操作 trace，便于排查 |
| PC 视口 | `1440 × 900` | 桌面端标准分辨率 |
| 移动端视口 | `375 × 812` | iPhone 尺寸，用于移动端测试 project |
 
**如果已存在**，不自动修改，仅提示用户对照以上推荐值检查，尤其确认 `workers: 1` 和 `retries: 1` 是否设置。
 
### Mock 登录模式（推荐）
 
优先使用 Mock 登录接口获取认证 Cookie，而不是驱动登录页面 UI，原因：
- 速度更快（无需等待登录页渲染和交互）
- 不受登录页 UI 改版影响，测试更稳定
- API 测试和浏览器测试可共用同一套认证逻辑
如果项目提供 mock 登录接口，建议在 `auth/login.js`（或 `auth/login.ts`）中封装：
 
```js
// auth/login.js 推荐结构
async function mockLogin({ agent = 'PC' } = {}) { ... }   // 返回 { cookieHeader, cookies }
async function injectCookies(context, cookies) { ... }     // 注入浏览器 context
```
 
各测试文件在 `test.beforeAll` 中统一调用，不在每条用例中重复登录。

---

## Step 1 — 测试设计（调用 test-case-designer）

**触发条件**：`specs/` 为空，或用户明确要求重新设计。

### Step 1a — 确认模块清单

先与用户确认编号分配，例如：
```
请确认 specs/ 文件清单：
00-test-strategy.md
01-auth-test-plan.md
02-repair-request-test-plan.md
03-work-order-test-plan.md
04-permission-test-plan.md
05-api-test-plan.md

是否需要调整编号或模块名？
```

### Step 1b — 按编号顺序生成

调用 `test-case-designer`，依次生成：

1. 先生成 `specs/00-test-strategy.md`
2. 再按编号逐个生成各模块文件，每个生成后等用户确认再继续

每次调用时传入：
- 需求描述 / PRD / 相关代码
- `specs/00-test-strategy.md`（作为一致性约束）
- 项目 `src/` 目录结构
- 当前 `tests/` 已有文件列表

每个模块文件固定格式：
```markdown
# Test Plan — [模块名] (NN)

## Scope
## Core Flows
## Frontend Cases
## API Cases
## Edge Cases
## Mobile Cases（如果模块需要移动端测试）
## Out of Scope
## Recommended First Batch
```

**完成标志**：`specs/00-test-strategy.md` 存在，且至少一个 `NN-*-test-plan.md` 包含 `## Recommended First Batch`。

---

## Step 2 — 生成测试代码（调用 tdd-guide + code-reviewer）

### Step 2a — tdd-guide 生成测试

调用 `tdd-guide`，遵循测试先行原则：

- 读取各 `specs/NN-*-test-plan.md` 的 `## Recommended First Batch`
- **只**生成该节列出的测试（每模块：1 smoke + 1-2 e2e + 1 api）
- 强制遵循 Red-Green-Refactor 循环
- 外部依赖（Supabase、Redis、API）必须 mock
- 文件开头注明来源：`// Source: specs/NN-module-test-plan.md`
- 覆盖率目标：新增代码 80%+（对应 SonarQube 要求）

**不生成全部测试**，先跑通 Recommended First Batch 再扩展。

#### 移动端测试（可选）
 
如果 `specs/NN-*-test-plan.md` 中包含 `## Mobile Cases`，在生成对应 e2e 测试时同步生成移动端版本：
 
```ts
// tests/e2e/01-auth-login-mobile.spec.ts
// Source: specs/01-auth-test-plan.md — Mobile Cases
 
test.beforeAll(async ({ browser }) => {
  const auth = await mockLogin({ agent: 'MOBILE' });
  context = await browser.newContext({
    viewport: { width: 375, height: 812 },
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) ...',
    isMobile: true,
  });
  await injectCookies(context, auth.cookies);
  page = await context.newPage();
});
```
 
**约定**：
- 移动端测试文件名加 `-mobile` 后缀，放在 `tests/e2e/` 下
- `mockLogin({ agent: 'MOBILE' })` 获取移动端 cookie
- `newContext` 中配置 `viewport: { width: 375, height: 812 }`、`isMobile: true`、对应 UA
- 移动端测试只验证移动端特有的交互和布局，不重复 PC 端已有的业务逻辑断言
如果项目不需要移动端测试，跳过此节，不生成 `-mobile` 文件。

### Step 2b — code-reviewer 审查测试代码

调用 `code-reviewer` 对生成的测试文件做 review：

重点检查：
- 无硬编码凭证（API key、密码）
- mock 正确隔离了外部依赖
- 断言具体有意义，不是 `expect(true).toBe(true)`
- 测试互相独立，无共享状态
- 测试名称清晰描述被测行为

**code-reviewer 标记为 CRITICAL 或 HIGH 的问题必须修复后才能进入 Step 3。**

---

## Step 3 — 执行测试（调用 e2e-runner）

调用 `e2e-runner` 执行 Playwright 测试：

```bash
# 运行全部测试（含移动端）
npx playwright test --reporter=json,html 

# 只运行某个模块
npx playwright test tests/ --grep "01-auth" --reporter=json

# 只运行 PC 端测试（排除移动端）
npx playwright test tests/ --grep-invert "mobile" --reporter=json

# 只运行移动端测试
npx playwright test tests/e2e/ --grep "mobile" --reporter=json

# 只运行某个层次
npx playwright test tests/smoke/ --reporter=json
```

### 失败处理

**少量失败（1-2 条）**：
- 先判断失败原因类型
- TypeScript / 构建错误 → 调用 `build-error-resolver`（最小 diff 原则，不做架构修改）
- 业务逻辑错误 → 回到 `tdd-guide` 修正测试或实现

**超过一半失败**：停止，不进入 Step 4，报告环境或实现问题。

---

## Step 4 — 覆盖审查（调用 test-coverage-reviewer）

调用 `test-coverage-reviewer`，传入三层输入：

| 输入层 | 路径 |
|--------|------|
| 全局策略 | `specs/00-test-strategy.md` |
| 各模块计划 | `specs/NN-*-test-plan.md`（全部按编号读取） |
| 测试代码 | `tests/**/*.spec.ts` |
| 运行结果 | `test-results/` 下最新 JSON report |

reviewer 逐模块对照 `NN-*-test-plan.md` 检查，输出到 `qa/coverage/coverage-report.md`：

```markdown
# Coverage Review — [日期]

## 概览
## 各模块覆盖情况
### 01 - auth
### 02 - repair-request
### ...（按编号逐模块）
## 高风险缺口（跨模块汇总）
## 低价值冗余测试
## 下一轮建议（按优先级）
## 发版评估
```

---

## Step 5 — 输出摘要

```
=== QA 流程完成 ===

测试计划文件：
  specs/00-test-strategy.md
  specs/01-auth-test-plan.md
  ...（列出全部）

本轮测试：N 条（通过 X / 失败 Y / 跳过 Z）
覆盖报告：qa/coverage/coverage-report.md

高风险缺口：[数量]
发版建议：[可以发版 / 建议补测后发版 / 不建议发版]

下一轮优先补测：
- [来自 coverage-report 的 Top 3 建议]
```

---

## 注意事项

**不要做的事**：
- 不要跳过 `00-test-strategy.md`
- 不要跳过 code-reviewer 标记的 CRITICAL / HIGH 问题
- 不要一次生成全部测试，先跑通 Recommended First Batch
- 不要在 Step 3 超过 50% 失败时强行进入 Step 4
- 不要修改 `specs/` 下任何文件（那是 test-case-designer 的职责）
- 不要打乱编号顺序，新增模块取当前最大编号 +1
- 不要在 `.env` 缺失关键变量时继续执行测试（会得到误导性结果）
- 不要强制修改已有的 `playwright.config`，只提示对照检查

**新增模块时**：
```bash
ls specs/[0-9]*.md | sort | tail -1  # 查找当前最大编号
```
新文件取最大编号 +1，同步更新 `00-test-strategy.md` 中的模块清单。

---

## 完整调用关系

```
qa-orchestrator
├── Step 0 → 环境检查（Playwright + .env 变量 + 工程配置建议）
├── Step 1 → test-case-designer   (生成 specs/NN-*.md，含可选 Mobile Cases)
├── Step 2 → tdd-guide            (测试先行，生成 tests/NN-*.spec.ts + *-mobile.spec.ts)
│         → code-reviewer         (审查测试代码质量)
├── Step 3 → e2e-runner           (执行 Playwright 测试，支持 --grep "mobile" 过滤)
│         → build-error-resolver  (失败时修复构建错误，最小 diff)
└── Step 4 → test-coverage-reviewer (读取 specs/ + tests/ + test-results/)
 
可选（不在主链路）：
         → security-reviewer      (Step 2 后，选择性插入)
         → refactor-cleaner       (发现大量冗余测试后手动调用)
         → doc-updater            (流程结束后更新文档)
```
