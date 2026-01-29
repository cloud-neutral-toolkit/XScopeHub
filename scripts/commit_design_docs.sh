#!/bin/bash

# XScopeHub MCP Server 设计文档提交脚本

set -e

echo "📝 XScopeHub MCP Server - 提交设计文档到GitHub"
echo "===================================="
echo ""

cd /root/clawd/XScopeHub

# 检查当前状态
echo "🔍 检查Git状态..."
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT_COUNT=$(git rev-list --count HEAD)
UNTRACKED_COUNT=$(git status --porcelain | wc -l)

echo "   当前分支: $BRANCH"
echo "   提交次数: $COMMIT_COUNT"
echo "   未跟踪文件: $UNTRACKED_COUNT"
echo ""

# 显示未跟踪的文件
if [ $UNTRACKED_COUNT -gt 0 ]; then
    echo "📄 未跟踪的文件："
    git status --short
    echo ""
else
    echo "✅ 没有未跟踪的文件"
    echo ""
fi

# 添加所有文件到Git
echo "📥 添加文件到Git..."
git add .

if [ $? -eq 0 ]; then
    echo "✅ 文件已添加到暂存区"
else
    echo "❌ 添加文件失败"
    exit 1
fi
echo ""

# 查看将要提交的更改
echo "📋 查看将要提交的更改..."
git diff --cached --stat
echo ""

# 提交更改
echo "💾 提交更改..."
COMMIT_MESSAGE="docs: Add MCP Server design documentation and architecture plan"
COMMIT_BODY="

- Add MCP Server design specification (docs/MCP_SERVER_DESIGN.md)
- Add Gateway integration guide (docs/Gateway_A2A_INTEGRATION.md)
- Add workflow automation documentation
- Update deployment configuration files
- Add test scripts for distributed A2A setup
- Add Antigravity OAuth integration guide

This commit adds:
1. Complete MCP Server architecture design
2. Plugin system specification (Chrome, GitHub, Ansible, IaC)
3. Workflow engine YAML format definition
4. Session management and routing design
5. Security and observability planning
6. Deployment configurations (Docker, K8s)
7. A2A integration patterns for distributed agents
"

git commit -m "$COMMIT_MESSAGE" -m "$COMMIT_BODY"

if [ $? -eq 0 ]; then
    COMMIT_HASH=$(git rev-parse --short HEAD)
    echo "✅ 提交成功！"
    echo "   提交哈希: $COMMIT_HASH"
    echo "   提交消息: $COMMIT_MESSAGE"
else
    echo "❌ 提交失败"
    exit 1
fi
echo ""

# 显示当前分支和远程仓库
echo "🌐 检查远程仓库..."
REMOTE_URL=$(git remote get-url origin)
REMOTE_NAME=$(git remote)

if [ -z "$REMOTE_URL" ]; then
    echo "⚠️  未找到远程仓库"
    echo ""
    echo "请先添加远程仓库："
    echo "  git remote add origin https://github.com/cloud-neutral-toolkit/XScopeHub.git"
    echo ""
    echo "或者如果已经forked："
    echo "  git remote add origin https://github.com/<your-username>/XScopeHub.git"
    exit 0
else
    echo "✅ 找到远程仓库"
    echo "   远程名称: $REMOTE_NAME"
    echo "   远程URL: $REMOTE_URL"
    echo ""
fi

# 推送到GitHub
echo "📤 推送到GitHub..."

echo "推送选项："
echo "1. 推送当前分支 (origin $BRANCH)"
echo "2. 推送到 main分支 (origin main)"
echo "3. 创建Pull Request"
echo ""
read -p "请选择 (1/2/3): " push_choice

case $push_choice in
    1)
        echo ""
        echo "📤 推送当前分支 ($BRANCH)..."
        git push origin "$BRANCH"
        
        if [ $? -eq 0 ]; then
            echo "✅ 推送成功！"
            echo ""
            echo "🎉 提交已完成！"
            echo ""
            echo "提交信息："
            echo "   仓库: $REMOTE_URL"
            echo "  分支: $BRANCH"
            echo "  提交: $COMMIT_HASH"
            echo "  消息: $COMMIT_MESSAGE"
            echo ""
            echo "查看提交："
            echo "  $REMOTE_URL/commits/$COMMIT_HASH"
        else
            echo "❌ 推送失败"
            echo "   可能原因："
            echo "   1. 网络问题（GFW阻拦？）"
            echo "   2. 认证失败"
            echo "   3. 权限不足"
            echo ""
            echo "建议："
            echo "   1. 使用VPN或代理"
            echo "   2. 检查SSH密钥配置"
            echo "   3. 确认仓库权限"
        fi
        ;;
    
    2)
        echo ""
        echo "📤 推送到main分支..."
        git push origin main
        
        if [ $? -eq 0 ]; then
            echo "✅ 推送成功！"
            echo ""
            echo "🎉 提交已完成！"
            echo ""
            echo "提交信息："
            echo "  仓库: $REMOTE_URL"
            echo "  分支: main"
            echo "  提交: $COMMIT_HASH"
            echo "  消息: $COMMIT_MESSAGE"
            echo ""
            echo "查看提交："
            echo "  $REMOTE_URL/commits/$COMMIT_HASH"
        else
            echo "❌ 推送失败"
            echo "   可能原因："
            echo "   1. 网络问题（GFW阻拦？）"
            echo "   2. 认证失败"
            echo "   3. 权限不足"
            echo ""
            echo "建议："
            echo "   1. 使用VPN或代理"
            echo "   2. 检查SSH密钥配置"
            echo "   3. 确认仓库权限"
        fi
        ;;
    
    3)
        echo ""
        echo "📤 创建Pull Request..."
        echo "   推送当前分支并创建PR..."
        git push origin "$BRANCH" --create-pr -m "MCP Server design documentation"
        
        if [ $? -eq 0 ]; then
            echo "✅ Pull Request创建成功！"
            echo ""
            echo "🎉 提交已完成！"
            echo ""
            echo "Pull Request信息："
            echo "  源分支: $BRANCH"
            echo "  目标分支: main"
            echo "  提交: $COMMIT_HASH"
            echo "  标题: MCP Server design documentation"
        else
            echo "❌ Pull Request创建失败"
            echo "   可能原因："
            echo "   1. 网络问题（GFW阻拦？）"
            echo "   2. 认证失败"
            echo "   3. 权限不足"
            echo ""
            echo "建议："
            echo "   1. 使用VPN或代理"
            echo "   2. 检查SSH密钥配置"
            echo "   3. 确认仓库权限"
        fi
        ;;
    
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "===================================="
echo "✅ 流程完成"
echo "===================================="
echo ""
