#!/bin/bash

echo "🚀 安装 qa-orchestrator 及依赖..."

# 创建目录
mkdir -p ~/.claude/skills/qa-orchestrator
mkdir -p ~/.claude/skills/test-case-designer
mkdir -p ~/.claude/skills/test-coverage-reviewer
mkdir -p ~/.claude/skills/tdd-workflow
mkdir -p ~/.claude/agents

# 安装 skills
cp skills/qa-orchestrator.md ~/.claude/skills/qa-orchestrator/SKILL.md
echo "✅ 安装 skill: qa-orchestrator"

cp skills/test-case-designer.md ~/.claude/skills/test-case-designer/SKILL.md
echo "✅ 安装 skill: test-case-designer"

cp skills/test-coverage-reviewer.md ~/.claude/skills/test-coverage-reviewer/SKILL.md
echo "✅ 安装 skill: test-coverage-reviewer"

cp skills/tdd-workflow.md ~/.claude/skills/tdd-workflow/SKILL.md
echo "✅ 安装 skill: tdd-workflow"

# 安装 agents
cp agents/tdd-guide.md ~/.claude/agents/
echo "✅ 安装 agent: tdd-guide"

cp agents/e2e-runner.md ~/.claude/agents/
echo "✅ 安装 agent: e2e-runner"

cp agents/code-reviewer.md ~/.claude/agents/
echo "✅ 安装 agent: code-reviewer"

cp agents/build-error-resolver.md ~/.claude/agents/
echo "✅ 安装 agent: build-error-resolver"

echo ""
echo "🎉 安装完成！重启 Claude Code 后即可使用："
echo "  /qa-orchestrator"
