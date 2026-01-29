#!/bin/bash

# XScopeHub 提交设计文档脚本

set -e

echo "📝 提交 MCP Server 设计文档"
echo "================================"
echo ""

cd /root/clawd/XScopeHub

# 检查Git状态
echo "🔍 检查Git状态..."
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "当前分支: $BRANCH"

UNTRACKED_FILES=$(git status --porcelain | grep "^??" | wc -l)
if [ $UNTRACKED_FILES -gt 0 ]; then
    echo "发现 $UNTRACKED_FILES 个未跟踪文件"
    git status --short
    echo ""
    echo "📥 添加所有文件到暂存区..."
    git add .
    echo "✅ 文件已添加"
else
    echo "✅ 没有未跟踪的文件"
fi
echo ""

# 提交
echo "💾 创建提交..."
COMMIT_MESSAGE="docs: Add XScopeHub MCP Server design and architecture

Add comprehensive MCP Server design documentation including:

1. MCP Protocol Specification
   - JSON-RPC 2.0 message format
   - Core methods (tools/list, tools/call, resources/list, etc.)
   - Session management API

2. MCP Registry Design
   - Resource registration and routing
   - Tool registration with schema validation
   - Centralized plugin management

3. Plugin System
   - Plugin interface specification
   - Built-in plugins: Chrome, GitHub, Ansible, Terraform, Monitor
   - External plugin support

4. Workflow Engine
   - YAML-based workflow definition
   - Multi-step execution with dependencies
   - State management and checkpointing
   - Failure handling and rollback

5. Architecture Diagram
   - Layered architecture design
   - Client-Server communication
   - Plugin adapter layer
   - Session and state management

6. Deployment Strategy
   - Local development setup
   - Docker deployment
   - Kubernetes support (future)
   - Observability integration

7. Security & Observability
   - Authentication mechanisms
   - Policy control (allow/deny)
   - Prometheus metrics
   - Audit logging

This design document provides the foundation for implementing a centralized MCP Hub that orchestrates infrastructure, deployment, observability, and LLM agent automation."

git commit -m "$COMMIT_MESSAGE"

if [ $? -eq 0 ]; then
    COMMIT_HASH=$(git rev-parse --short HEAD)
    echo "✅ 提交成功！"
    echo ""
    echo "提交信息："
    echo "   哈希: $COMMIT_HASH"
    echo "   消息: docs: Add XScopeHub MCP Server design and architecture"
    echo ""
    echo "查看提交："
    echo "   https://github.com/cloud-neutral-toolkit/XScopeHub/commit/$COMMIT_HASH"
else
    echo "❌ 提交失败"
    echo ""
    echo "请检查错误并重试"
    exit 1
fi

echo ""
echo "================================"
echo "✅ 提交流程完成！"
echo ""
echo "下一步："
echo "1. 📤 推送到GitHub: git push origin main"
echo "2. 🌐 查看Pull Request: https://github.com/cloud-neutral-toolkit/XScopeHub/pull/new"
echo ""
echo "================================"
