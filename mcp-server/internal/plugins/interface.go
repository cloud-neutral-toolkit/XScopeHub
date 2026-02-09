package plugins

import "github.com/xscopehub/mcp-server/internal/types"

// Plugin defines the contract for XScopeHub MCP extensions.
type Plugin interface {
	ID() string
	Name() string
	Description() string
	
	Init(config map[string]interface{}) error
	
	Resources() []types.ResourcePayload
	Tools() []types.ToolDescriptor
	
	ExecuteTool(name string, args map[string]interface{}) (types.ToolResult, error)
}
