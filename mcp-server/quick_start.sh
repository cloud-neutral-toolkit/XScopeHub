#!/bin/bash

# XScopeHub MCP Server - 快速启动脚本

set -e

echo "🚀 XScopeHub MCP Server 启动脚本"
echo "=================================="

# 进入mcp-server目录
cd "$(dirname "$0")"

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "❌ 错误: 未安装 Go"
    echo "请先安装 Go: https://go.dev/dl/"
    exit 1
fi

echo "✅ Go 版本: $(go version)"

# 构建MCP Server
echo ""
echo "📦 构建 MCP Server..."
cd mcp-server
go build -o mcp-server ./cmd/mcp
echo "✅ 构建完成"

# 创建配置目录
CONFIG_DIR="./configs"
mkdir -p "$CONFIG_DIR"

# 创建基础配置
cat > "$CONFIG_DIR/hub.yaml" << 'EOF'
server:
  port: 8000
  log_level: info

plugins:
  - name: github
    enabled: true
    config:
      token_env: "GITHUB_TOKEN"

  - name: llm
    enabled: true
    config:
      endpoint: "http://localhost:11434/v1/chat/completions"
      model: "deepseek-r1:8b"

  - name: monitor
    enabled: true
    config:
      prometheus_url: "http://localhost:9090"

workflows:
  - name: dev_ci_pr
    description: "开发流水线（GitHub + Chrome）"
    steps:
      - type: github_check_pr
      - type: chrome_automation
      - type: llm_review

  - name: ops_deploy_ansible
    description: "运维自动化（Ansible + Chrome + GitHub）"
    steps:
      - type: github_trigger
      - type: ansible_playbook
      - type: monitor_check

  - name: iac_deploy_cloud
    description: "IaC部署（Terraform + Chrome + GitHub）"
    steps:
      - type: github_trigger
      - type: terraform_apply
      - type: monitor_verify
EOF

echo "✅ 配置已创建: $CONFIG_DIR/hub.yaml"

echo ""
echo "🎯 启动选项:"
echo "1. 启动 MCP Server (http://localhost:8000)"
echo "2. 查看可用工具"
echo "3. 连接到 mcporter"
echo ""
read -p "选择 (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo "🚀 启动 MCP Server..."
        ./mcp-server serve -addr :8000
        ;;
    2)
        echo ""
        echo "📋 查看可用工具..."
        curl -s http://localhost:8000/manifest | jq .
        ;;
    3)
        echo ""
        echo "🔗 连接到 mcporter..."
        echo "运行以下命令将XScopeHub添加到mcporter:"
        echo ""
        echo "  mcporter config add xscopehub http://localhost:8000/mcp"
        echo ""
        echo "然后可以调用工具:"
        echo "  mcporter list xscopehub"
        echo "  mcporter call xscopehub.query_logs limit:100"
        echo "  mcporter call xscopehub.summarize_alerts time:1h"
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac
