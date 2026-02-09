package plugins

import (
	"fmt"

	"github.com/xscopehub/mcp-server/internal/types"
)

type ObservabilityPlugin struct {
	config map[string]interface{}
}

func NewObservabilityPlugin() *ObservabilityPlugin {
	return &ObservabilityPlugin{}
}

func (p *ObservabilityPlugin) ID() string   { return "observability" }
func (p *ObservabilityPlugin) Name() string { return "Observability Hub" }
func (p *ObservabilityPlugin) Description() string {
	return "Unified access to logs, metrics, and traces"
}

func (p *ObservabilityPlugin) Init(config map[string]interface{}) error {
	p.config = config
	return nil
}

func (p *ObservabilityPlugin) Resources() []types.ResourcePayload {
	return []types.ResourcePayload{
		{
			Name:        "logs",
			Description: "Recent log events captured by XScopeHub",
			Data: []map[string]interface{}{
				{"timestamp": "2024-01-01T00:00:00Z", "service": "observe-gateway", "level": "info", "message": "startup complete"},
			},
		},
		{
			Name:        "metrics",
			Description: "Key service metrics aggregated from OpenObserve",
			Data: map[string]interface{}{
				"observe_bridge.latency_p95_ms": 120.0,
			},
		},
	}
}

func (p *ObservabilityPlugin) Tools() []types.ToolDescriptor {
	return []types.ToolDescriptor{
		{
			Name:        "query_logs",
			Description: "Filter logs by service name and severity.",
			InputSchema: "{\"service\":\"string\",\"level\":\"string\"}",
		},
		{
			Name:        "summarize_alerts",
			Description: "Summarize active alerts for operator review.",
			InputSchema: "{}",
		},
	}
}

func (p *ObservabilityPlugin) ExecuteTool(name string, args map[string]interface{}) (types.ToolResult, error) {
	switch name {
	case "query_logs":
		service, _ := args["service"].(string)
		level, _ := args["level"].(string)
		result := fmt.Sprintf("queried logs for service=%s level=%s (plugin implementation)", service, level)
		return types.ToolResult{Name: "query_logs", Output: map[string]string{"result": result}}, nil
	case "summarize_alerts":
		summary := "1 alert active: 1 critical (OpenObserve ingestion stalled) - summarized by plugin"
		return types.ToolResult{Name: "summarize_alerts", Output: map[string]string{"summary": summary}}, nil
	default:
		return types.ToolResult{}, fmt.Errorf("tool %s not found in observability plugin", name)
	}
}
