#!/bin/bash

# XScopeHub Git 用户配置脚本（自动化版本）

set -e

echo "🔧 XScopeHub Git 自动配置脚本"
echo "================================"
echo ""

USER_NAME="Hai Tao Pan"
USER_EMAIL="haitaopanhq@gmail.com"

echo "📋 配置信息："
echo "   用户名: $USER_NAME"
echo "   邮箱: $USER_EMAIL"
echo ""

echo "🔄 自动配置Git用户..."

# 配置全局用户名
echo "1. 配置用户名..."
git config --global user.name "$USER_NAME"
if [ $? -eq 0 ]; then
    VERIFIED_NAME=$(git config --global user.name)
    if [ "$VERIFIED_NAME" = "$USER_NAME" ]; then
        echo "   ✅ 用户名已配置: $VERIFIED_NAME"
    else
        echo "   ⚠️  用户名验证失败: $VERIFIED_NAME"
    fi
else
    echo "   ❌ 用户名配置失败"
    exit 1
fi

# 配置全局邮箱
echo ""
echo "2. 配置邮箱..."
git config --global user.email "$USER_EMAIL"
if [ $? -eq 0 ]; then
    VERIFIED_EMAIL=$(git config --global user.email)
    if [ "$VERIFIED_EMAIL" = "$USER_EMAIL" ]; then
        echo "   ✅ 邮箱已配置: $VERIFIED_EMAIL"
    else
        echo "   ⚠️  邮箱验证失败: $VERIFIED_EMAIL"
    fi
else
    echo "   ❌ 邮箱配置失败"
    exit 1
fi

echo ""
echo "================================"
echo "✅ Git用户配置完成！"
echo ""

echo "配置摘要："
echo "   全局用户名: $VERIFIED_NAME"
echo "   全局邮箱: $VERIFIED_EMAIL"
echo ""

echo "全局配置文件位置："
echo "   ~/.gitconfig"
echo ""

echo "验证配置："
git config --global user.name
git config --global user.email
echo ""

echo "下一步："
echo "1. ✅ Git用户配置已完成"
echo "2. 📝 现在可以重新提交XScopeHub文档"
echo "3. 🚀 执行: cd /root/clawd/XScopeHub && bash scripts/commit_design_docs.sh"
echo ""
echo "================================"
