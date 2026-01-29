# XScopeHub MCP Server 部署完成

## ✅ 已完成的工作

1. ✅ 克隆 XScopeHub 仓库到 `/root/clawd/XScopeHub`
2. ✅ 创建 MCP Server 快速启动脚本
3. ✅ 创建 mcporter 配置文件
4. ✅ 创建详细集成指南

## 🚀 快速开始

### 选项1: 启动MCP Server（推荐）

```bash
cd /root/clawd/XScopeHub/mcp-server
./quick_start.sh
```

这个脚本会：
- 检查Go环境
- 构建MCP Server
- 创建配置文件
- 启动服务
- 提供连接mcporter的命令

### 选项2: 手动启动

```bash
# 构建MCP Server
cd /root/clawd/XScopeHub/mcp-server
go build -o mcp-server ./cmd/mcp

# 启动Server（监听端口8000）
./mcp-server serve -addr :8000
```

## 🔗 连接到mcporter

MCP Server启动后，在另一个终端：

```bash
# 添加XScopeHub到mcporter
mcporter config add xscopehub http://localhost:8000/mcp

# 查看配置的服务器
mcporter list

# 查看XScopeHub的工具schema
mcporter list xscopehub --schema

# 测试调用
mcporter call xscopehub.query_logs limit:10
```

## 📚 文档

- **详细集成指南**: `/root/clawd/XScopeHub/MCP_INTEGRATION.md`
- **MCP Server代码**: `/root/clawd/XScopeHub/mcp-server/`
- **配置示例**: `/root/clawd/XScopeHub/mcporter-config.json`
- **快速启动脚本**: `/root/clawd/XScopeHub/mcp-server/quick_start.sh`

## 🎯 可用的MCP工具

### 1. query_logs
查询日志数据
```bash
mcporter call xscopehub.query_logs limit:100 time:1h level:error
```

### 2. summarize_alerts
汇总告警信息
```bash
mcporter call xscopehub.summarize_alerts time:6h severity:critical
```

### 3. get_metrics
获取指标数据
```bash
mcporter call xscopehub.get_metrics metric_name:cpu_usage time:1h
```

### 4. get_topology
获取系统拓扑
```bash
mcporter call xscopehub.get_topology service:api-gateway
```

## 🏗️ 架构说明

```
┌─────────────────────────────────────────────────────────────────┐
│                    Clawdbot (LLM Agent)                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
              ┌────────────────┐
              │  mcporter   │  <-- MCP Client
              │   (CLI)      │
              └────────┬───────┘
                       │
                       ▼
         ┌────────────────────────────┐
         │   XScopeHub MCP Server   │  <-- Hub & Orchestrator
         │   (Go, port 8000)       │
         └────────┬─────────────────┘
                  │
        ┌─────────┼─────────┐
        │         │         │
        ▼         ▼         ▼
   ┌──────┐ ┌──────┐ ┌──────┐
   │GitHub│ │Postgres│ │Vector │
   └──────┘ └──────┘ └──────┘
```

## 🔧 配置选项

### 环境变量（.env）
在 `/root/clawd/XScopeHub/.env.example` 基础上创建 `.env`:

```bash
# 数据库
PG_PASSWORD=your_password

# ClickHouse
CH_USER=default
CH_PASSWORD=

# Grafana
GRAFANA_ADMIN_PASSWORD=admin

# GitHub
GITHUB_TOKEN=ghp_xxxxxxxxxxxx
```

### MCP Server配置
编辑 `/root/clawd/XScopeHub/config/XOpsAgent.yaml` 修改：
- PostgreSQL连接
- OpenObserve端点
- LLM模型配置
- GitHub集成

## 🧪 测试

### 1. 测试MCP Server健康检查
```bash
curl http://localhost:8000/manifest
```

### 2. 测试mcporter连接
```bash
mcporter list
# 应该看到 xscopehub 在列表中
```

### 3. 测试工具调用
```bash
mcporter list xscopehub --schema
mcporter call xscopehub.query_logs limit:5
```

### 4. 在Clawdbot中测试
```
"查询最近1小时的error日志"
"汇总今天所有的critical告警"
"获取系统的拓扑信息"
```

## 🐛 故障排查

### MCP Server无法启动
```bash
# 检查Go版本
go version  # 需要Go 1.16+

# 检查端口
lsof -i :8000

# 查看详细日志
./mcp-server serve -addr :8000 -log-level=debug
```

### mcporter连接失败
```bash
# 测试HTTP连接
curl -v http://localhost:8000/mcp

# 移除并重新配置
mcporter config remove xscopehub
mcporter config add xscopehub http://localhost:8000/mcp
```

### PostgreSQL连接失败
```bash
# 检查Postgres是否运行
docker ps | grep postgres

# 测试连接
psql -h 127.0.0.1 -p 5432 -U postgres
```

## 📈 生产环境部署

### 使用Systemd服务

```bash
sudo cp /root/clawd/XScopeHub/mcp-server/mcp-server /usr/local/bin/xscopehub-mcp
sudo systemctl enable xscopehub-mcp
sudo systemctl start xscopehub-mcp
sudo systemctl status xscopehub-mcp
```

### 使用Docker Compose

```bash
cd /root/clawd/XScopeHub/deployments/docker-compose
docker compose -f poc.yaml up -d
```

### 反向代理（Nginx）

```nginx
upstream xscopehub {
    server localhost:8000;
}

server {
    listen 80;
    server_name your-domain.com;

    location /mcp {
        proxy_pass http://xscopehub;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 🎓 学习资源

- **官方文档**: https://github.com/cloud-neutral-toolkit/XScopeHub
- **MCP协议**: https://modelcontextprotocol.io/
- **mcporter文档**: https://mcporter.dev/
- **Clawdbot文档**: https://docs.clawd.bot/

## 💡 使用示例

### 示例1: 监控日志查询
```
"查询过去6小时内所有error级别的日志"
"显示最近50条系统日志"
```

### 示例2: 告警汇总
```
"汇总今天的所有critical告警"
"显示最近1小时warning级别的告警"
```

### 示例3: 系统拓扑
```
"显示当前系统的服务拓扑"
"获取api-gateway相关的拓扑信息"
```

### 示例4: 指标查询
```
"查询过去1小时的CPU使用率"
"获取最近24小时的内存指标"
```

## 📞 获取帮助

- **XScopeHub问题**: https://github.com/cloud-neutral-toolkit/XScopeHub/issues
- **mcporter问题**: https://github.com/mcporter/cli/issues
- **Clawdbot问题**: https://github.com/clawdbot/clawdbot/issues

---

**准备好开始了吗？运行快速启动脚本：**
```bash
cd /root/clawd/XScopeHub/mcp-server && ./quick_start.sh
```
