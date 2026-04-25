# QA-Orchestrator

> 基于 Claude Code Skills 体系构建的全链路 QA 自动化编排器。将测试设计、代码生成、执行验证、覆盖审查四个阶段串联成完整闭环，支持本地项目和远程测试环境两种场景。

---

## 项目背景

传统 QA 流程依赖人工设计测试用例、手动执行测试、主观判断覆盖是否充分，效率低且难以标准化。本项目探索将 AI 编排能力引入测试流程，实现从需求文档到覆盖报告的全自动化。

---

## 项目结构

```
test-skills/
├── skills/
│   ├── qa-orchestrator.md          # 全链路 QA 编排器（核心）
│   ├── test-case-designer.md       # 测试用例设计
│   ├── test-coverage-reviewer.md   # 覆盖审查
│   └── tdd-workflow.md             # TDD 规范知识库
├── agents/
│   ├── tdd-guide.md                # 测试先行，生成测试代码
│   ├── e2e-runner.md               # 执行 Playwright 测试
│   ├── code-reviewer.md            # 审查测试代码质量
│   └── build-error-resolver.md     # 修复构建错误
├── install.sh                      # 一键安装脚本
└── README.md
```

---

## 核心模块

### qa-orchestrator（通用版）

适用于任何本地 Web 项目，四阶段全链路：

| 阶段 | 执行者 | 输入 | 输出 |
|------|--------|------|------|
| Step 1 测试设计 | test-case-designer | 需求/PRD/代码 | specs/NN-*.md |
| Step 2 代码生成 | tdd-guide + code-reviewer | specs/ 文件 | tests/**/*.spec.ts |
| Step 3 执行测试 | e2e-runner | 测试文件 | test-results/ |
| Step 4 覆盖审查 | test-coverage-reviewer | specs/ + tests/ + test-results/ | coverage-report.md |

**四种运行入口：**

```
# 全链路（从零开始）
/qa-orchestrator

# 跳过设计（specs/ 已有计划）
/qa-orchestrator

# 单模块
/qa-orchestrator 只测 auth 模块

# 仅覆盖审查
/qa-orchestrator 只跑覆盖审查
```

### test-case-designer

结构化测试用例设计 skill，支持需求描述、PRD、代码三种输入，输出包含优先级（P0-P3）、测试层次、场景分类的 Markdown 表格，并明确标注"本轮不覆盖项"。

### test-coverage-reviewer

覆盖审查 skill，对照测试计划检查已覆盖/未覆盖场景，识别高风险缺口，给出量化发版评估：

- ✅ 可以发版
- ⚠️ 建议补测后发版
- ❌ 不建议发版

### tdd-workflow

TDD 规范知识库，包含单元测试、集成测试、E2E 测试的代码模式和反模式示例，作为 tdd-guide agent 的知识支撑。

---

## 快速开始

### 环境要求

- [Claude Code](https://claude.ai/code)
- Node.js 18+
- Playwright v1.49+

### 安装

```bash
# 克隆仓库
git clone https://github.com/juice-hh/test-skills
cd test-skills

# 一键安装所有 skills 和 agents
chmod +x install.sh
./install.sh
```

### 配置环境变量

在项目根目录创建 `.env` 文件：

```bash
BASE_URL=http://localhost:3000       # 前端页面地址（必需）
API_BASE=http://localhost:3001/api   # 后端 API 根路径（必需）
MOCK_LOGIN_URL=                      # Mock 登录接口（推荐，提升稳定性）
```

### 运行

重启 Claude Code 后，在项目目录下输入：

```
/qa-orchestrator
```

---

## 测试产出示例

### 测试计划（specs/）

```markdown
# Test Plan — Auth (01)

## Recommended First Batch
- [ ] P0 A01: 正常登录流程
- [ ] P0 A02: 错误密码拦截
- [ ] P1 A03: Token 过期处理
- [ ] P1 A04: 无权限页面跳转
```

### 覆盖报告（qa/coverage/coverage-report.md）

```markdown
# Coverage Review — 2026-04-15

## 概览
本轮测试：32 条（通过 32 / 失败 0）
高风险缺口：4 项

## 高风险缺口
| 优先级 | 缺口 | 原因 |
|--------|------|------|
| P0 | 跨租户数据隔离 | 数据安全盲区 |
| P1 | PATCH 接口边界 | 整合更新路径零覆盖 |

## 发版建议：不建议直接发版
```

---

## 设计决策

**为什么用 Skills 而不是脚本？**

传统测试脚本是固定流程，Skills 是可调度的智能模块。每个 skill/agent 有独立职责，orchestrator 只负责按顺序调度和传递上下文，任何一个模块可以单独升级而不影响整体。

**为什么测试计划（specs/）是核心？**

测试计划是整个流程的单一数据源。测试代码基于计划生成，覆盖审查对照计划检查，避免"测了但不知道测了什么"的问题。

**为什么强制 Red-Green-Refactor？**

tdd-guide 强制测试先行，确保测试驱动实现而不是实现完再补测试，从根本上保证测试的有效性。

---

## 技术栈

- Claude Code Skills / Agents
- Playwright v1.49+
- TypeScript
- Python / openpyxl（缺陷报告填写）

---

## License

MIT