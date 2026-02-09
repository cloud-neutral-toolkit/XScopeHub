package registry

import (
	"fmt"

	"github.com/xscopehub/mcp-server/internal/plugins"
	"github.com/xscopehub/mcp-server/internal/types"
)

// Registry maintains the available plugins and orchestrates resource/tool access.
type Registry struct {
	plugins map[string]plugins.Plugin
}

// New creates an empty registry.
func New() *Registry {
	return &Registry{
		plugins: make(map[string]plugins.Plugin),
	}
}

// RegisterPlugin adds a plugin to the registry.
func (r *Registry) RegisterPlugin(p plugins.Plugin) error {
	if _, ok := r.plugins[p.ID()]; ok {
		return fmt.Errorf("plugin %s already registered", p.ID())
	}
	r.plugins[p.ID()] = p
	return nil
}

// ListResources returns all resource descriptors from all plugins.
func (r *Registry) ListResources() []types.ResourceDescriptor {
	var descriptors []types.ResourceDescriptor
	for _, p := range r.plugins {
		for _, res := range p.Resources() {
			descriptors = append(descriptors, types.ResourceDescriptor{
				Name:        res.Name,
				Title:       res.Name, // or some formatting
				Description: res.Description,
			})
		}
	}
	return descriptors
}

// Resource returns the payload for a resource by searching across plugins.
func (r *Registry) Resource(name string) (types.ResourcePayload, error) {
	for _, p := range r.plugins {
		for _, res := range p.Resources() {
			if res.Name == name {
				return res, nil
			}
		}
	}
	return types.ResourcePayload{}, fmt.Errorf("resource %s not found", name)
}

// ListTools returns tool descriptors from all plugins.
func (r *Registry) ListTools() []types.ToolDescriptor {
	var descriptors []types.ToolDescriptor
	for _, p := range r.plugins {
		descriptors = append(descriptors, p.Tools()...)
	}
	return descriptors
}

// InvokeTool executes a tool by searching for the plugin that provides it.
func (r *Registry) InvokeTool(name string, arguments map[string]interface{}) (types.ToolResult, error) {
	for _, p := range r.plugins {
		for _, td := range p.Tools() {
			if td.Name == name {
				return p.ExecuteTool(name, arguments)
			}
		}
	}
	return types.ToolResult{}, fmt.Errorf("tool %s not found", name)
}
