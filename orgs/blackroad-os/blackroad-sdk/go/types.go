// Package blackroad provides the official Go SDK for the BlackRoad API.
package blackroad

import "time"

// Agent represents a BlackRoad agent.
type Agent struct {
	ID         string                 `json:"id"`
	Name       string                 `json:"name"`
	Type       string                 `json:"type"`
	Division   string                 `json:"division"`
	Level      int                    `json:"level"`
	Status     string                 `json:"status"`
	Load       float64                `json:"load"`
	Hash       string                 `json:"hash"`
	CreatedAt  time.Time              `json:"created_at"`
	LastSeen   time.Time              `json:"last_seen"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

// Task represents a BlackRoad task.
type Task struct {
	ID            string                 `json:"id"`
	Title         string                 `json:"title"`
	Description   string                 `json:"description,omitempty"`
	Status        string                 `json:"status"`
	Priority      string                 `json:"priority"`
	Division      string                 `json:"division,omitempty"`
	TargetLevel   int                    `json:"target_level,omitempty"`
	AssignedAgent string                 `json:"assigned_agent,omitempty"`
	Result        string                 `json:"result,omitempty"`
	CreatedAt     time.Time              `json:"created_at"`
	UpdatedAt     time.Time              `json:"updated_at"`
	CompletedAt   *time.Time             `json:"completed_at,omitempty"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
}

// MemoryEntry represents an entry in the BlackRoad memory system.
type MemoryEntry struct {
	Hash      string                 `json:"hash"`
	Timestamp time.Time              `json:"timestamp"`
	Action    string                 `json:"action"`
	Entity    string                 `json:"entity"`
	Details   string                 `json:"details,omitempty"`
	Agent     string                 `json:"agent,omitempty"`
	Tags      []string               `json:"tags,omitempty"`
	PrevHash  string                 `json:"prev_hash,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

// Stats represents statistics from the API.
type Stats struct {
	Total     int            `json:"total"`
	ByStatus  map[string]int `json:"by_status,omitempty"`
	ByType    map[string]int `json:"by_type,omitempty"`
	ByLevel   map[string]int `json:"by_level,omitempty"`
	Active    int            `json:"active,omitempty"`
	Pending   int            `json:"pending,omitempty"`
	Completed int            `json:"completed,omitempty"`
}

// HealthStatus represents the API health status.
type HealthStatus struct {
	Status    string            `json:"status"`
	Version   string            `json:"version"`
	Timestamp time.Time         `json:"timestamp"`
	Services  map[string]string `json:"services,omitempty"`
}

// RegisterAgentOptions contains options for registering an agent.
type RegisterAgentOptions struct {
	Name     string                 `json:"name"`
	Type     string                 `json:"type,omitempty"`
	Division string                 `json:"division,omitempty"`
	Level    int                    `json:"level,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// AgentListOptions contains options for listing agents.
type AgentListOptions struct {
	Type     string `url:"type,omitempty"`
	Division string `url:"division,omitempty"`
	Level    int    `url:"level,omitempty"`
	Status   string `url:"status,omitempty"`
	Limit    int    `url:"limit,omitempty"`
	Offset   int    `url:"offset,omitempty"`
}

// DispatchTaskOptions contains options for dispatching a task.
type DispatchTaskOptions struct {
	Title       string                 `json:"title"`
	Description string                 `json:"description,omitempty"`
	Priority    string                 `json:"priority,omitempty"`
	Division    string                 `json:"division,omitempty"`
	TargetLevel int                    `json:"target_level,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// TaskListOptions contains options for listing tasks.
type TaskListOptions struct {
	Status   string `url:"status,omitempty"`
	Priority string `url:"priority,omitempty"`
	Division string `url:"division,omitempty"`
	Limit    int    `url:"limit,omitempty"`
	Offset   int    `url:"offset,omitempty"`
}

// LogMemoryOptions contains options for logging a memory entry.
type LogMemoryOptions struct {
	Action   string                 `json:"action"`
	Entity   string                 `json:"entity"`
	Details  string                 `json:"details,omitempty"`
	Tags     []string               `json:"tags,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// MemoryQueryOptions contains options for querying memory.
type MemoryQueryOptions struct {
	Search string     `url:"q,omitempty"`
	Action string     `url:"action,omitempty"`
	Entity string     `url:"entity,omitempty"`
	Tags   []string   `url:"tags,omitempty"`
	Since  *time.Time `url:"since,omitempty"`
	Until  *time.Time `url:"until,omitempty"`
	Limit  int        `url:"limit,omitempty"`
	Offset int        `url:"offset,omitempty"`
}
