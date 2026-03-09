package blackroad

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"strconv"
)

// AgentAPI provides access to agent operations.
type AgentAPI struct {
	client *Client
}

// List returns a list of agents with optional filters.
func (a *AgentAPI) List(ctx context.Context, opts *AgentListOptions) ([]Agent, error) {
	params := url.Values{}
	if opts != nil {
		if opts.Type != "" {
			params.Set("type", opts.Type)
		}
		if opts.Division != "" {
			params.Set("division", opts.Division)
		}
		if opts.Level > 0 {
			params.Set("level", strconv.Itoa(opts.Level))
		}
		if opts.Status != "" {
			params.Set("status", opts.Status)
		}
		if opts.Limit > 0 {
			params.Set("limit", strconv.Itoa(opts.Limit))
		}
		if opts.Offset > 0 {
			params.Set("offset", strconv.Itoa(opts.Offset))
		}
	}

	resp, err := a.client.Get(ctx, "/agents", params)
	if err != nil {
		return nil, err
	}

	var result struct {
		Agents []Agent `json:"agents"`
	}
	if err := json.Unmarshal(resp, &result); err != nil {
		return nil, NewConnectionError("failed to parse agents response", err)
	}
	return result.Agents, nil
}

// Get returns a specific agent by ID.
func (a *AgentAPI) Get(ctx context.Context, agentID string) (*Agent, error) {
	resp, err := a.client.Get(ctx, fmt.Sprintf("/agents/%s", agentID), nil)
	if err != nil {
		return nil, err
	}

	var agent Agent
	if err := json.Unmarshal(resp, &agent); err != nil {
		return nil, NewConnectionError("failed to parse agent response", err)
	}
	return &agent, nil
}

// Register creates a new agent.
func (a *AgentAPI) Register(ctx context.Context, opts *RegisterAgentOptions) (*Agent, error) {
	if opts.Type == "" {
		opts.Type = "ai"
	}
	if opts.Level == 0 {
		opts.Level = 4
	}

	resp, err := a.client.Post(ctx, "/agents", opts)
	if err != nil {
		return nil, err
	}

	var agent Agent
	if err := json.Unmarshal(resp, &agent); err != nil {
		return nil, NewConnectionError("failed to parse agent response", err)
	}
	return &agent, nil
}

// Heartbeat sends a heartbeat for an agent.
func (a *AgentAPI) Heartbeat(ctx context.Context, agentID string, load float64) error {
	body := map[string]interface{}{}
	if load > 0 {
		body["load"] = load
	}

	_, err := a.client.Post(ctx, fmt.Sprintf("/agents/%s/heartbeat", agentID), body)
	return err
}

// UpdateStatus updates an agent's status.
func (a *AgentAPI) UpdateStatus(ctx context.Context, agentID string, status string) (*Agent, error) {
	resp, err := a.client.Put(ctx, fmt.Sprintf("/agents/%s", agentID), map[string]string{"status": status})
	if err != nil {
		return nil, err
	}

	var agent Agent
	if err := json.Unmarshal(resp, &agent); err != nil {
		return nil, NewConnectionError("failed to parse agent response", err)
	}
	return &agent, nil
}

// Delete removes an agent.
func (a *AgentAPI) Delete(ctx context.Context, agentID string) error {
	_, err := a.client.Delete(ctx, fmt.Sprintf("/agents/%s", agentID))
	return err
}

// Stats returns agent statistics.
func (a *AgentAPI) Stats(ctx context.Context) (*Stats, error) {
	resp, err := a.client.Get(ctx, "/agents/stats", nil)
	if err != nil {
		return nil, err
	}

	var stats Stats
	if err := json.Unmarshal(resp, &stats); err != nil {
		return nil, NewConnectionError("failed to parse stats response", err)
	}
	return &stats, nil
}

// ByDivision returns agents filtered by division.
func (a *AgentAPI) ByDivision(ctx context.Context, division string) ([]Agent, error) {
	return a.List(ctx, &AgentListOptions{Division: division})
}

// Commanders returns Level 2 commander agents.
func (a *AgentAPI) Commanders(ctx context.Context) ([]Agent, error) {
	return a.List(ctx, &AgentListOptions{Level: 2})
}

// Managers returns Level 3 manager agents.
func (a *AgentAPI) Managers(ctx context.Context) ([]Agent, error) {
	return a.List(ctx, &AgentListOptions{Level: 3})
}

// Workers returns Level 4 worker agents.
func (a *AgentAPI) Workers(ctx context.Context) ([]Agent, error) {
	return a.List(ctx, &AgentListOptions{Level: 4})
}
