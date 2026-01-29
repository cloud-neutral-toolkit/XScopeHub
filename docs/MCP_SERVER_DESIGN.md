# XScopeHub MCP Server 设计规划文档

## 🎯 设计目标

XScopeHub MCP Server 是一个**集中式MCP（Model Context Protocol）Hub**，用于编排基础设施、部署、可观测性和LLM Agent自动化。

### 核心功能

1. ✅ **MCP协议实现** - 完整的MCP Server/Client
2. ✅ **工作流编排** - YAML驱动的多阶段工作流执行
3. ✅ **插件系统** - 模块化的插件适配层
4. ✅ **资源管理** - 统一的资源注册和调度
5. ✅ **Agent协同** - 支持跨Agent的通信和协作
6. ✅ **审计追踪** - 完整的执行日志和审计轨迹

---

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Clients                              │
│    ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│    │ Clawdbot │  │ VS Code    │  │ 其他工具   │       │
│    └─────┬────┘  └─────┬─────�  └─────┬────┘       │
└────────────────┼────────────┼────────────┼───────────┘
                 │            │            │
                 ▼            ▼            ▼
         ┌─────────────────────────────────────┐
         │         MCP Gateway           │
         │     (WebSocket / HTTP)       │
         └──────────────┬──────────────┘
                        │
                        ▼
         ┌─────────────────────────────────────┐
         │      XScopeHub MCP Server    │
         ├─────────────────────────────────┤
         │  Internal MCP Protocol       │
         ├─────────────────────────────────┤
         │       Plugin Layer           │
         └──────────────┬──────────────┘
                        │
        ┌───────────────┼───────────────┬─────────────┐
        ▼               ▼               ▼             ▼
┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
│  Registry  │ │  Workflow  │ │   Plugins   │ │  Session    │
│            │ │  Executor  │ │    Layer    │ │  Manager   │
└────────────┘ └────────────┘ └────────────┘ └────────────┘
     │               │               │             │
     └───────────────┴───────────────┴─────────────┘
                        │
                        ▼
         ┌─────────────────────────────────────┐
         │      External Plugins         │
         ├─────────────────────────────────┤
         │  GitHub, Chrome, Ansible   │
         │  Terraform, Postgres, LLM  │
         └─────────────────────────────────┘
```

---

## 📂 目录结构

```
mcp-server/
├── cmd/
│   └── mcp/
│       ├── main.go                # 主入口
│       ├── serve.go              # 启动Hub Server
│       ├── run.go                # 执行Workflow
│       ├── deploy.go             # IAC一键部署
│       └── version.go            # 版本信息
│
├── internal/
│   ├── mcp/
│   │   ├── server.go            # MCP Server (JSON-RPC)
│   │   ├── client.go            # MCP Client (下游）
│   │   ├── registry.go          # 统一路由注册
│   │   ├── protocol.go          # Request/Response定义
│   │   ├── auth.go              # Token/Env验证
│   │   └── logger.go            # 通用日志封装
│   │
│   ├── hub/
│   │   ├── hub.go               # 读取配置，注册插件
│   │   ├── workflow.go           # YAML工作流执行器
│   │   ├── state.go              # 状态保存和断点续跑
│   │   ├── audit.go             # 审计日志/执行轨迹
│   │   ├── policy.go             # allow/deny策略控制
│   │   └── metrics.go            # Prometheus指标
│   │
│   └── plugins/               # MCP插件适配层
│       ├── chrome.go             # 浏览器自动化
│       ├── ansible.go            # 远程部署
│       ├── github.go             # SCM/CI
│       ├── iac.go                # Terraform/Pulumi
│       ├── monitor.go            # Prometheus/Grafana
│       ├── llm.go                # LLM Agent / RAG
│       └── k8s.go                # (未来) K8S MCP
│
├── pkg/
│   ├── executil/               # 执行外部命令（带日志/超时）
│   ├── fileutil/               # 读写YAML/JSON/模板
│   ├── templating/             # Go Template引擎
│   └── ui/                     # CLI输出格式化（颜色/进度条）
│
├── configs/
│   ├── hub.yaml                # 全局Hub配置（端口、下游MCP）
│   ├── logging.yaml             # 日志格式/级别/路径
│   ├── policies.yaml            # 权限与白名单控制
│   └── workflows/
│       ├── dev-ci-pr.yaml      # 开发流水线（GitHub + Chrome）
│       ├── ops-deploy-ansible.yaml # 运维自动化（Ansible + Chrome + GitHub）
│       ├── iac-deploy-cloud.yaml   # IaC部署（Terraform + Chrome + GitHub）
│       └── rollback.yaml       # 回滚任务
│
├── scripts/
│   ├── install.sh              # 快速安装
│   ├── run_dev.sh              # 本地调试启动
│   └── docker-entrypoint.sh    # 容器启动
│
├── Makefile                    # 构建/测试/打包
├── go.mod                      # Go模块声明
├── go.sum
├── README.md                   # 项目说明
├── LICENSE
└── manifest.json               # MCP清单（resources/tools）
```

---

## 🔌 MCP协议设计

### 消息格式

#### Request
```json
{
  "jsonrpc": "2.0",
  "id": "request-id",
  "method": "tools/list",
  "params": {
    "session_id": "optional-session-id"
  }
}
```

#### Response
```json
{
  "jsonrpc": "2.0",
  "id": "request-id",
  "result": {
    "tools": [
      {
        "name": "query_logs",
        "description": "查询日志数据",
        "inputSchema": {
          "type": "object",
          "properties": {
            "limit": {"type": "number"},
            "time_range": {"type": "string"},
            "level": {"enum": ["info", "warn", "error"]}
          }
        }
      }
    ]
  }
}
```

### 核心方法

| 方法 | 说明 |
|------|------|
| `tools/list` | 列出所有可用工具 |
| `tools/call` | 调用特定工具 |
| `resources/list` | 列出所有可用资源 |
| `resources/read` | 读取特定资源 |
| `session/create` | 创建新会话 |
| `session/append` | 追加消息到会话 |
| `prompts/list` | 列出可用提示模板 |

---

## 🔌 MCP Registry设计

### 资源注册

```go
type Resource struct {
    ID      string
    Name    string
    URI     string  // 访问URI（例如：postgres://localhost/logs）
    Type    string  // 类型：database, api, file
    ReadOnly bool
}
```

### 工具注册

```go
type Tool struct {
    ID          string
    Name        string
    Description string
    InputSchema interface{}  // JSON Schema
    Handler     ToolHandler    // 处理函数
}
```

### 路由逻辑

```go
// 统一路由注册
registry.RegisterResource(Resource{
    ID:   "logs",
    Name: "查询日志",
    URI:  "postgres://localhost:5432/logs",
    Type: "database",
})

registry.RegisterTool(Tool{
    ID:   "query_logs",
    Name: "查询日志",
    InputSchema: map[string]interface{}{
        "type": "object",
        "properties": map[string]interface{}{
            "limit": map[string]interface{}{
                "type": "number",
                "default": 100
            },
            "level": map[string]interface{}{
                "type": "string",
                "enum": []string{"info", "warn", "error"}
            }
        }
    },
    Handler: QueryLogsHandler,
})
```

---

## 🔄 Workflow设计

### YAML工作流定义

```yaml
name: "dev-ci-pr"
description: "开发流水线（GitHub + Chrome）"

variables:
  repo: "owner/repo"
  pr_number: 0

steps:
  - name: "github_check_pr"
    type: github
    config:
      action: "check_pr"
      repo: "${{repo}}"
      pr_number: "${{pr_number}}"
    on_failure: rollback
  
  - name: "chrome_automation"
    type: chrome
    depends_on: github_check_pr
    config:
      action: "automate"
      url: "https://github.com/${{repo}}/pull/${{pr_number}}"
    on_success: llm_review
  
  - name: "llm_review"
    type: llm
    depends_on: chrome_automation
    config:
      action: "review"
      model: "deepseek-r1:8b"
      context:
        - chrome_screenshot
        - github_pr_diff
```

### Workflow执行器

```go
type WorkflowExecutor struct {
    // 工作流状态
    State     *WorkflowState
    Variables map[string]interface{}
    
    // 步骤执行
    Steps     []WorkflowStep
    
    // 并发控制
    MaxConcurrent int
}

type WorkflowStep struct {
    Name        string
    Type        string  // github, chrome, llm, etc.
    DependsOn   []string
    Config      interface{}
    OnSuccess   string
    OnFailure   string
}
```

---

## 🧩 Plugin系统设计

### 插件接口

```go
type Plugin interface {
    // 插件元数据
    ID() string
    Name() string
    Description() string
    Version() string
    
    // 初始化
    Init(config map[string]interface{}) error
    
    // 资源提供
    Resources() []Resource
    
    // 工具提供
    Tools() []Tool
    
    // 清理
    Cleanup() error
}
```

### 内置插件

| 插件 | 功能 | 资源 | 工具 |
|------|------|------|------|
| **Chrome** | 浏览器自动化 | `screenshot`, `page_source` | `automate`, `navigate`, `click` |
| **GitHub** | SCM/CI | `repo`, `pr`, `issue` | `create_pr`, `check_pr`, `list_issues` |
| **Ansible** | 远程部署 | `inventory`, `playbook` | `run_playbook`, `check_status` |
| **IaC** | Terraform/Pulumi | `state`, `plan`, `apply` | `plan`, `apply`, `destroy` |
| **Monitor** | Prometheus/Grafana | `metrics`, `alerts` | `query_metrics`, `summarize_alerts` |
| **LLM** | Agent/RAG | `knowledge`, `memory` | `generate`, `chat`, `rag` |
| **K8s** | Kubernetes (未来） | `pod`, `service`, `deployment` | `create_pod`, `scale` |

---

## 📊 Session管理

### Session数据结构

```go
type Session struct {
    ID          string
    CreatedAt   time.Time
    UpdatedAt   time.Time
    Messages    []Message
    Context     map[string]interface{}
    State       string  // running, paused, completed, failed
    WorkflowID  string  // 关联的Workflow
}
```

### Session API

| 方法 | 说明 |
|------|------|
| `session/create` | 创建新会话，返回session ID |
| `session/get` | 获取会话详情 |
| `session/append` | 追加消息到会话 |
| `session/list` | 列出所有会话 |
| `session/delete` | 删除会话 |
| `session/clear` | 清空会话消息 |

---

## 🔒 安全设计

### 认证

```go
type AuthConfig struct {
    Mode      string  // token, api_key, none
    Token     string  // 认证token
    APIKey    string  // API密钥
    AllowIPs []string  // 允许的IP列表
}
```

### 策略控制

```yaml
policies:
  tools:
    allow:
      - "chrome.*"
      - "github.*"
    deny:
      - "k8s.*"  # 禁用K8S工具
    
  sessions:
    max_concurrent: 10
    max_age: 24h
    
  agents:
    allow:
      - "research:*"
      - "writer:*"
    deny:
      - "admin:*"
```

---

## 📈 Observability

### Prometheus指标

```go
// HTTP请求指标
var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "mcp_server_http_requests_total",
            Help: "Total number of HTTP requests",
        },
    )
    
    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "mcp_server_http_request_duration_seconds",
            Help: "HTTP request duration in seconds",
        },
    )
)

// Workflow执行指标
var (
    workflowDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "mcp_server_workflow_duration_seconds",
            Help: "Workflow execution duration in seconds",
            Buckets: []float64{.1, .5, 1, 5, 10, 30, 60, 300},
        },
    )
    
    workflowStatus = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "mcp_server_workflow_status_total",
            Help: "Total number of workflow executions by status",
        },
        []string{"status"},
    )
)
```

### 审计日志

```json
{
  "timestamp": "2026-01-28T16:30:00Z",
  "session_id": "session-abc123",
  "workflow_id": "dev-ci-pr",
  "step": "github_check_pr",
  "action": "check_pr",
  "input": "{\"repo\": \"owner/repo\", \"pr_number\": 123}",
  "output": "{\"status\": \"open\", \"title\": \"Update README\"}",
  "duration_ms": 1250,
  "status": "success"
}
```

---

## 🚀 部署设计

### 本地开发

```bash
# 安装依赖
go mod download

# 运行开发服务器
go run ./cmd/mcp/main.go serve -addr :8000

# 运行workflow
go run ./cmd/mcp/main.go run -config configs/workflows/dev-ci-pr.yaml
```

### Docker部署

```yaml
# docker-compose.yml
version: '3.8'

services:
  mcp-server:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./configs:/app/configs
      - ./workflows:/app/workflows
    environment:
      - LOG_LEVEL=info
      - METRICS_ENABLED=true
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: xscopehub
      POSTGRES_USER: xscopehub
      POSTGRES_PASSWORD: changeme
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redisdata:/data
```

### Kubernetes部署（未来）

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: xscopehub-mcp-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: xscopehub-mcp-server
  template:
    metadata:
      labels:
        app: xscopehub-mcp-server
    spec:
      containers:
      - name: mcp-server
        image: xscopehub/mcp-server:v1.0.0
        ports:
          - containerPort: 8000
        env:
          - name: LOG_LEVEL
            value: "info"
          - name: METRICS_ENABLED
            value: "true"
```

---

## 📝 API文档

### Health Check

```http
GET /health

Response:
{
  "status": "ok",
  "version": "1.0.0",
  "uptime": 3600
}
```

### Tools List

```http
GET /api/v1/tools

Response:
{
  "tools": [
    {
      "name": "query_logs",
      "description": "查询日志数据",
      "inputSchema": {...}
    }
  ]
}
```

### Tools Call

```http
POST /api/v1/tools/call

Request:
{
  "tool": "query_logs",
  "params": {
    "limit": 100,
    "level": "error"
  }
}

Response:
{
  "result": {
    "logs": [...]
  },
  "error": null
}
```

---

## 🎯 实施路线图

### Phase 1: 基础框架（2周）
- [x] MCP协议实现（Server/Client）
- [x] Registry系统
- [x] 基础Plugin接口
- [x] Session管理
- [ ] 基础Plugins（Chrome, GitHub）

### Phase 2: Workflow引擎（3周）
- [ ] YAML工作流解析
- [ ] Workflow执行器
- [ ] 状态管理（断点续跑）
- [ ] 并发执行
- [ ] 错误处理和回滚

### Phase 3: Plugin生态（4周）
- [ ] 完整Plugin接口
- [ ] 内置Plugins（全部）
- [ ] Plugin配置系统
- [ ] 插件热加载
- [ ] 第三方Plugin支持

### Phase 4: Observability（2周）
- [ ] Prometheus指标
- [ ] 审计日志
- [ ] Grafana Dashboards
- [ ] Tracing（Jaeger）
- [ ] 日志聚合

### Phase 5: K8s支持（3周）
- [ ] K8s Plugin
- [ ] Kubernetes Operator
- [ ] Helm Charts
- [ ] 监控和告警
- [ ] 自动扩缩容

---

## 📚 参考资料

- [MCP协议规范](https://modelcontextprotocol.io/)
- [JSON-RPC 2.0规范](https://www.jsonrpc.org/specification)
- [Go最佳实践](https://go.dev/doc/effective_go)
- [Docker部署指南](https://docs.docker.com/)
- [Kubernetes文档](https://kubernetes.io/docs/)

---

**文档版本**: 1.0.0
**最后更新**: 2026-01-28
**维护者**: Cloud Neutral Toolkit Team
