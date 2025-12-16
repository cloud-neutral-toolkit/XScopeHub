# Observability DataGateway 规划与最小实现

本文汇总统一字段规范、URL Contract 以及 Nginx/Go 的最小实现示例，目标是让 Grafana 只需配置一个入口即可无感切换后端。

## 统一字段规范（一次性约定）
为保证 Logs / Metrics / Traces 联动时的“同名、同语义、同格式”，强制使用以下字段：

| 字段 | 类型 | 说明 |
| ---- | ---- | ---- |
| `service` | string | 建议等同于 OTel `service.name` |
| `trace_id` | string | 32 位小写十六进制，OTel TraceID |
| `span_id` | string | 16 位小写十六进制，OTel SpanID |
| `level` | enum | `debug` \| `info` \| `warn` \| `error` \| `fatal`（需统一映射） |

落地建议：
- **Traces**：`service` 取自资源属性 `service.name`；`trace_id`/`span_id` 为 OTel 原生；`level` 可选（来源于 span event/status）。
- **Logs**：`service` 由 K8s labels / 应用名 / OTel resource 注入；`trace_id`/`span_id` 从上下文或日志字段注入；`level` 通过 Vector 等组件规范化（如 `warning` → `warn`）。
- **Metrics**：指标不强求 `trace_id`/`span_id`；`service` 统一 label 名为 `service`；`level` 不建议作为指标 label，仅在少量错误计数类指标使用。

## DataGateway 职责边界
- **负责**：统一入口（`/metrics`、`/logs`、`/traces`），统一鉴权（可选 OIDC/JWT 或 API Key），统一多租户（`X-ScopeHub-Tenant`/`X-Org-Id`），统一跳转（“热查 → 冷回放”固化 URL）。
- **不负责**：不解析 PromQL/MetricsQL/LogsQL；不改写结果 JSON（除非最小兼容）；不做重缓存或查询合并/跨后端 join。

## URL Contract（接口规范）
建议统一前缀 `/api/obs/v1/...` 以便未来演进。

### Metrics（Prometheus/MetricsQL 兼容代理）
- 基础路径：`GET /api/obs/v1/metrics/*`
- 直通 Prometheus API：
  - `GET /api/obs/v1/metrics/api/v1/query`
  - `GET /api/obs/v1/metrics/api/v1/query_range`
  - `GET /api/obs/v1/metrics/api/v1/labels`
  - `GET /api/obs/v1/metrics/api/v1/series`
  - `GET /api/obs/v1/metrics/api/v1/metadata`
- 推荐实现：完全反代到 VictoriaMetrics 的 Prometheus 兼容端点（通常 `:8428/api/v1/*`）。
- 可选请求头：`Authorization: Bearer <token>`、`X-ScopeHub-Tenant: <tenant>`、`X-ScopeHub-User: <user>`。

### Logs（VictoriaLogs LogsQL 代理）
- 基础路径：`GET /api/obs/v1/logs/*`
- 透传 VictoriaLogs HTTP API：
  - `GET /api/obs/v1/logs/select/logsql/query`
  - `GET /api/obs/v1/logs/select/logsql/tail`
- 查询参数按 VictoriaLogs 实际 API 透传（`query`/`start`/`end`/`limit` 等）。
- 联动约定：日志记录中必须可展示 `trace_id`（字段名固定）。

### Traces（热/冷分层语义路由）
- 基础路径：`GET /api/obs/v1/traces/*`
- **热层搜索（OpenObserve）**：`GET /api/obs/v1/traces/search`
  - 建议查询参数：`service`、`operation`、`min_duration_ms`、`max_duration_ms`、`status` (`ok|error`)、`start`/`end`、`limit`
  - 网关负责参数映射后转发至 OpenObserve trace search API。
- **冷层回放（Tempo）**：`GET /api/obs/v1/traces/{trace_id}`（`trace_id` 为 32 位 hex）
  - 直通 Tempo `api/traces/<traceID>`。
- **统一跳转（DataLink）**：`GET /api/obs/v1/traces/go/{trace_id}`
  - 默认 302 到冷层 `/api/obs/v1/traces/{trace_id}`；可带 `?view=hot` 跳转热层。

## 最小实现示例

### Nginx 反代版（快速上线）
```nginx
server {
  listen 80;
  server_name obs-gw.local;

  # Metrics -> VictoriaMetrics
  location /api/obs/v1/metrics/ {
    proxy_pass http://victoriametrics:8428/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }

  # Logs -> VictoriaLogs
  location /api/obs/v1/logs/ {
    proxy_pass http://victorialogs:9428/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }

  # Traces cold -> Tempo by trace_id
  location ~ ^/api/obs/v1/traces/([0-9a-f]{32})$ {
    proxy_pass http://tempo:3200/api/traces/$1;
    proxy_set_header Host $host;
  }

  # Traces search -> OpenObserve
  location = /api/obs/v1/traces/search {
    proxy_pass http://openobserve:5080/api/traces/search;
    proxy_set_header Host $host;
  }

  # Unified redirect helper
  location ~ ^/api/obs/v1/traces/go/([0-9a-f]{32})$ {
    return 302 /api/obs/v1/traces/$1;
  }
}
```

### Go 最小实现骨架
- 完全透明反代，Trace 做“语义路由”（search vs trace_id）。
- 预留多租户/鉴权 Header 注入（如 `X-ScopeHub-Tenant` → `X-Org-Id`）。
- 入口：`observe-gateway/cmd/obsgw/main.go`，监听 `:8080`。
- 健康检查：`GET /healthz` 返回 `200 ok`。

启动示例：
```bash
cd observe-gateway
go run ./cmd/obsgw
```

### Grafana 最简配置
- Prometheus datasource：`http://obsgw:8080/api/obs/v1/metrics`
- VictoriaLogs datasource：`http://obsgw:8080/api/obs/v1/logs`
- Tempo datasource：`http://obsgw:8080/api/obs/v1/traces`
- OpenObserve traces datasource：`http://obsgw:8080/api/obs/v1/traces/search`
- 日志 DataLink 统一指向：`/api/obs/v1/traces/go/${trace_id}`
```
