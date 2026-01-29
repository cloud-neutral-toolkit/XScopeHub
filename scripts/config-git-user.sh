#!/bin/bash

# XScopeHub Git 用户配置脚本

set -e

echo "🔧 XScopeHub Git 用户配置"
echo "================================"
echo ""

USER_NAME="Hai Tao Pan"
USER_EMAIL="haitaopanhq@gmail.com"

echo "📋 配置信息："
echo "   用户名: $USER_NAME"
echo "   邮箱: $USER_EMAIL"
echo ""

echo "🔄 配置Git用户..."

# 配置全局用户名
echo "1. 配置用户名..."
git config --global user.name "$USER_NAME"
if [ $? -eq 0 ]; then
    VERIFIED_NAME=$(git config --global user.name)
    if [ "$VERIFIED_NAME" = "$USER_NAME" ]; then
        echo "   ✅ 用户名已配置: $VERIFIED_NAME"
    else
        echo "   ❌ 用户名配置失败: 当前为 $VERIFIED_NAME"
        exit 1
    fi
else
    echo "   ❌ 用户名配置失败"
    exit 1
fi
echo ""

# 配置全局邮箱
echo "2. 配置邮箱..."
git config --global user.email "$USER_EMAIL"
if [ $? -eq 0 ]; then
    VERIFIED_EMAIL=$(git config --global user.email)
    if [ "$VERIFIED_EMAIL" = "$USER_EMAIL" ]; then
        echo "   ✅ 邮箱已配置: $VERIFIED_EMAIL"
    else
        echo "   ❌ 邮箱配置失败: 当前为 $VERIFIED_EMAIL"
        exit 1
    fi
else
    echo "   ❌ 邮箱配置失败"
    exit 1
fi
echo ""

echo "================================"
echo "✅ Git 用户配置完成！"
echo ""
echo "配置摘要："
echo "   用户名: $USER_NAME"
echo "   邮箱: $USER_EMAIL"
echo ""

echo "全局配置文件位置："
echo "   ~/.gitconfig"
echo ""

echo "查看当前配置："
echo "   git config --global user.name"
echo "   git config --global user.email"
echo ""

echo "下一步："
echo "1. ✅ Git用户配置已完成"
echo "2. 📝 现在可以重新提交文档"
echo "3. 🚀 推送到GitHub"
echo ""
echo "重新提交命令："
echo "   cd /root/clawd/XScopeHub"
echo "   git commit --amend --reset-author"
echo ""
echo "推送到GitHub："
echo "   git push origin main"
echo ""
echo "================================"
