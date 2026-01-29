# XScopeHub MCP Server 集成指南

## 概述

XScopeHub是一个集中式MCP Hub Server，可以编排以下组件：

- ✅ GitHub PR自动化
- ✅ Chrome浏览器自动化
- ✅ Ansible远程部署
- ✅ Terraform/Pulumi IaC
- ✅ Prometheus/Grafana监控
- ✅ LLM Agent / RAG查询

## 快速开始

### 步骤1: 构建MCP Server

```bash
cd /root/clawd/XScopeHub/mcp-server
go build -o mcp-server ./cmd/mcp
```

### 步骤2: 启动MCP Server

```bash
# 方式1: 直接启动
./mcp-server serve -addr :8000

# 方式2: 使用快速启动脚本
cd /root/clawd/XScopeHub/mcp-server
chmod +x quick_start.sh
./quick_start.sh
```

Server将在 http://localhost:8000 启动

### 步骤3: 连接到mcporter

```bash
# 添加XScopeHub到mcporter配置
mcporter config add xscopehub http://localhost:8000/mcp

# 查看可用的MCP服务器
mcporter list

# 查看XScopeHub的工具列表
mcporter list xscopehub --schema

# 查看具体工具的schema
mcporter list xscopehub.query_logs
```

### 步骤4: 调用MCP工具

```bash
# 查询日志
mcporter call xscopehub.query_logs limit:100 time:1h

# 汇总告警
mcporter call xscopehub.summarize_alerts time:1h

# 触发GitHub PR
mcporter call xscopehub.github_pr title:"Test Report" repo:"owner/repo"
```

## MCP工具列表

根据manifest.json，XScopeHub提供以下工具：

### Resources
- **logs** - 日志资源
- **metrics** - 指标资源
- **traces** - 链路追踪资源
- **topology** - 拓扑资源
- **knowledge** - 知识库资源

### Tools
- **query_logs** - 查询日志
- **summarize_alerts** - 汇总告警

## 集成到Clawdbot

Clawdbot可以通过mcporter调用XScopeHub的MCP工具：

```bash
# Clawdbot会自动使用mcporter作为MCP客户端
# 只需要配置mcporter即可
```

### 在Clawdbot中使用

在对话中直接要求Clawdbot使用XScopeHub工具：

```
"帮我查询最近1小时的日志"
"汇总一下最近的告警"
"创建一个GitHub PR用于报告"
```

Clawdbot会自动：
1. 通过mcporter调用xscopehub的工具
2. 返回结果
3. 可以继续处理数据

## 工作流示例

XScopeHub支持预定义的工作流（YAML配置）：

### 开发流水线 (dev-ci-pr.yaml)
```yaml
steps:
  - type: github_check_pr
  - type: chrome_automation
  - type: llm_review
```

### 运维自动化 (ops-deploy-ansible.yaml)
```yaml
steps:
  - type: github_trigger
  - type: ansible_playbook
  - type: monitor_check
```

### IaC部署 (iac-deploy-cloud.yaml)
```yaml
steps:
  - type: github_trigger
  - type: terraform_apply
  - type: monitor_verify
```

## 配置说明

### 环境变量

编辑 `.env` 文件：

```bash
PG_PASSWORD=changeme
CH_USER=default
CH_PASSWORD=
GRAFANA_ADMIN_PASSWORD=admin
GITHUB_TOKEN=ghp_xxxxxxxxxxxx
```

### Postgres配置

```yaml
postgres:
  url: "postgres://user:password@127.0.0.1:5432/xscopehub"
```

### GitHub集成

```yaml
github:
  token_env: "GITHUB_TOKEN"
  default_repo: "owner/repo"
```

## 部署模式

### 本地开发
```bash
cd mcp-server
go run ./cmd/mcp/main.go serve -addr :8000
```

### Docker部署
```bash
cd /root/clawd/XScopeHub/deployments/docker-compose
docker compose -f poc.yaml up -d
```

### Systemd服务（生产环境）

创建 `/etc/systemd/system/xscopehub-mcp.service`:

```ini
[Unit]
Description=XScopeHub MCP Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/clawd/XScopeHub/mcp-server
ExecStart=/root/clawd/XScopeHub/mcp-server/mcp-server serve -addr :8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable xscopehub-mcp
sudo systemctl start xscopehub-mcp
```

## 故障排查

### MCP Server无法启动
```bash
# 检查端口占用
netstat -tuln | grep 8000

# 查看日志
./mcp-server serve -addr :8000 2>&1 | tee /tmp/mcp-server.log
```

### mcporter无法连接
```bash
# 测试MCP Server是否运行
curl http://localhost:8000/manifest

# 检查mcporter配置
mcporter config list

# 移除并重新添加
mcporter config remove xscopehub
mcporter config add xscopehub http://localhost:8000/mcp
```

## 架构图

```
┌─────────────┐     ┌──────────┐     ┌─────────────┐
│ Clawdbot  │────>│ mcporter │────>│ XScopeHub   │
│ (LLM)     │     │ (MCP CLI)│     │ (Hub Server)│
└─────────────┘     └──────────┘     └─────────────┘
                                              │
                    ┌─────────────────────────┼────────────────────┐
                    │                     │                     │
                    ▼                     ▼                     ▼
            ┌──────────┐        ┌──────────┐        ┌──────────┐
            │ GitHub   │        │ Postgres  │        │ Vector   │
            └──────────┘        └──────────┘        └──────────┘
```

## 下一步

1. ✅ 启动MCP Server: `./mcp-server/quick_start.sh`
2. ✅ 配置mcporter: `mcporter config add xscopehub http://localhost:8000/mcp`
3. ✅ 测试工具: `mcporter list xscopehub --schema`
4. ✅ 在Clawdbot中使用工具查询日志和指标

需要帮助配置特定组件吗？
