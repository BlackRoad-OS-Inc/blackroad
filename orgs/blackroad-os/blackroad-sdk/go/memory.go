package blackroad

import (
	"context"
	"encoding/json"
	"fmt"
	"net/url"
	"strconv"
	"strings"
)

// MemoryAPI provides access to memory operations.
type MemoryAPI struct {
	client *Client
}

// Log creates a new memory entry.
func (m *MemoryAPI) Log(ctx context.Context, opts *LogMemoryOptions) (*MemoryEntry, error) {
	resp, err := m.client.Post(ctx, "/memory", opts)
	if err != nil {
		return nil, err
	}

	var entry MemoryEntry
	if err := json.Unmarshal(resp, &entry); err != nil {
		return nil, NewConnectionError("failed to parse memory entry response", err)
	}
	return &entry, nil
}

// Query searches memory entries.
func (m *MemoryAPI) Query(ctx context.Context, opts *MemoryQueryOptions) ([]MemoryEntry, error) {
	params := url.Values{}
	if opts != nil {
		if opts.Search != "" {
			params.Set("q", opts.Search)
		}
		if opts.Action != "" {
			params.Set("action", opts.Action)
		}
		if opts.Entity != "" {
			params.Set("entity", opts.Entity)
		}
		if len(opts.Tags) > 0 {
			params.Set("tags", strings.Join(opts.Tags, ","))
		}
		if opts.Since != nil {
			params.Set("since", opts.Since.Format("2006-01-02T15:04:05Z"))
		}
		if opts.Until != nil {
			params.Set("until", opts.Until.Format("2006-01-02T15:04:05Z"))
		}
		if opts.Limit > 0 {
			params.Set("limit", strconv.Itoa(opts.Limit))
		} else {
			params.Set("limit", "100")
		}
		if opts.Offset > 0 {
			params.Set("offset", strconv.Itoa(opts.Offset))
		}
	}

	resp, err := m.client.Get(ctx, "/memory", params)
	if err != nil {
		return nil, err
	}

	var result struct {
		Entries []MemoryEntry `json:"entries"`
	}
	if err := json.Unmarshal(resp, &result); err != nil {
		return nil, NewConnectionError("failed to parse memory response", err)
	}
	return result.Entries, nil
}

// Get returns a specific memory entry by hash.
func (m *MemoryAPI) Get(ctx context.Context, entryHash string) (*MemoryEntry, error) {
	resp, err := m.client.Get(ctx, fmt.Sprintf("/memory/%s", entryHash), nil)
	if err != nil {
		return nil, err
	}

	var entry MemoryEntry
	if err := json.Unmarshal(resp, &entry); err != nil {
		return nil, NewConnectionError("failed to parse memory entry response", err)
	}
	return &entry, nil
}

// Recent returns recent memory entries.
func (m *MemoryAPI) Recent(ctx context.Context, limit int) ([]MemoryEntry, error) {
	if limit <= 0 {
		limit = 50
	}
	return m.Query(ctx, &MemoryQueryOptions{Limit: limit})
}

// AgentState returns the state for an agent.
func (m *MemoryAPI) AgentState(ctx context.Context, agentID string) (map[string]interface{}, error) {
	resp, err := m.client.Get(ctx, fmt.Sprintf("/memory/agents/%s/state", agentID), nil)
	if err != nil {
		return nil, err
	}

	var state map[string]interface{}
	if err := json.Unmarshal(resp, &state); err != nil {
		return nil, NewConnectionError("failed to parse agent state response", err)
	}
	return state, nil
}

// SyncState syncs state for an agent.
func (m *MemoryAPI) SyncState(ctx context.Context, agentID string, state map[string]interface{}) error {
	_, err := m.client.Post(ctx, fmt.Sprintf("/memory/agents/%s/state", agentID), state)
	return err
}

// Broadcast sends a broadcast message.
func (m *MemoryAPI) Broadcast(ctx context.Context, msgType string, payload string) (string, error) {
	resp, err := m.client.Post(ctx, "/memory/broadcast", map[string]string{
		"type":    msgType,
		"payload": payload,
	})
	if err != nil {
		return "", err
	}

	var result struct {
		BroadcastID string `json:"broadcast_id"`
	}
	if err := json.Unmarshal(resp, &result); err != nil {
		return "", NewConnectionError("failed to parse broadcast response", err)
	}
	return result.BroadcastID, nil
}

// TIL creates a "Today I Learned" entry.
func (m *MemoryAPI) TIL(ctx context.Context, category string, learning string) (*MemoryEntry, error) {
	return m.Log(ctx, &LogMemoryOptions{
		Action:  "til",
		Entity:  category,
		Details: learning,
		Tags:    []string{"til", category},
	})
}

// Stats returns memory statistics.
func (m *MemoryAPI) Stats(ctx context.Context) (*Stats, error) {
	resp, err := m.client.Get(ctx, "/memory/stats", nil)
	if err != nil {
		return nil, err
	}

	var stats Stats
	if err := json.Unmarshal(resp, &stats); err != nil {
		return nil, NewConnectionError("failed to parse stats response", err)
	}
	return &stats, nil
}

// VerifyChainResult contains the result of a chain verification.
type VerifyChainResult struct {
	Valid   bool `json:"valid"`
	Checked int  `json:"checked"`
}

// VerifyChain verifies the hash chain integrity.
func (m *MemoryAPI) VerifyChain(ctx context.Context, startHash string) (*VerifyChainResult, error) {
	params := url.Values{}
	if startHash != "" {
		params.Set("start", startHash)
	}

	resp, err := m.client.Get(ctx, "/memory/verify", params)
	if err != nil {
		return nil, err
	}

	var result VerifyChainResult
	if err := json.Unmarshal(resp, &result); err != nil {
		return nil, NewConnectionError("failed to parse verify response", err)
	}
	return &result, nil
}
