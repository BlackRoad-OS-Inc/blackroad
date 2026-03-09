# blackroad-sdk-go

Official Go SDK for the BlackRoad API.

## Installation

```bash
go get github.com/BlackRoad-OS/blackroad-sdk-go
```

## Quick Start

```go
package main

import (
    "context"
    "fmt"
    "log"

    blackroad "github.com/BlackRoad-OS/blackroad-sdk-go"
)

func main() {
    // Initialize the client
    client, err := blackroad.NewClient(&blackroad.ClientConfig{
        APIKey: "your-api-key", // or set BLACKROAD_API_KEY env var
    })
    if err != nil {
        log.Fatal(err)
    }

    ctx := context.Background()

    // List agents
    agents, err := client.Agents.List(ctx, nil)
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Found %d agents\n", len(agents))

    // Dispatch a task
    task, err := client.Tasks.Dispatch(ctx, &blackroad.DispatchTaskOptions{
        Title:    "Deploy authentication service",
        Priority: "high",
        Division: "Security",
    })
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Created task: %s\n", task.ID)

    // Log to memory
    entry, err := client.Memory.Log(ctx, &blackroad.LogMemoryOptions{
        Action:  "deployed",
        Entity:  "auth-service",
        Details: "Deployed v2.0.0 to production",
        Tags:    []string{"deployment", "security"},
    })
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Logged entry: %s\n", entry.Hash)
}
```

## Configuration

```go
client, err := blackroad.NewClient(&blackroad.ClientConfig{
    APIKey:     "your-api-key",              // Required (or BLACKROAD_API_KEY env var)
    BaseURL:    "https://api.blackroad.io/v1", // Optional, custom API endpoint
    Timeout:    30 * time.Second,            // Optional, request timeout
    MaxRetries: 3,                           // Optional, max retry attempts
    HTTPClient: &http.Client{},              // Optional, custom HTTP client
})
```

## API Reference

### Agents

```go
ctx := context.Background()

// List all agents
agents, err := client.Agents.List(ctx, nil)

// List with filters
agents, err := client.Agents.List(ctx, &blackroad.AgentListOptions{
    Type:     "ai",
    Division: "Security",
    Level:    4,
})

// Get specific agent
agent, err := client.Agents.Get(ctx, "agent-id")

// Register a new agent
agent, err := client.Agents.Register(ctx, &blackroad.RegisterAgentOptions{
    Name:     "my-agent",
    Type:     "ai",
    Division: "Labs",
    Level:    4,
    Metadata: map[string]interface{}{"capabilities": []string{"analysis"}},
})

// Send heartbeat
err := client.Agents.Heartbeat(ctx, "agent-id", 0.75) // 75% load

// Update status
agent, err := client.Agents.UpdateStatus(ctx, "agent-id", "busy")

// Delete agent
err := client.Agents.Delete(ctx, "agent-id")

// Get statistics
stats, err := client.Agents.Stats(ctx)

// Convenience methods
commanders, err := client.Agents.Commanders(ctx)       // Level 2
managers, err := client.Agents.Managers(ctx)           // Level 3
workers, err := client.Agents.Workers(ctx)             // Level 4
secAgents, err := client.Agents.ByDivision(ctx, "Security")
```

### Tasks

```go
// Dispatch a task
task, err := client.Tasks.Dispatch(ctx, &blackroad.DispatchTaskOptions{
    Title:       "Build authentication system",
    Description: "Implement OAuth2 + JWT authentication",
    Priority:    "high",
    Division:    "Security",
    TargetLevel: 4,
})

// Get task by ID
task, err := client.Tasks.Get(ctx, "task-id")

// List tasks with filters
tasks, err := client.Tasks.List(ctx, &blackroad.TaskListOptions{
    Status:   "pending",
    Priority: "high",
    Division: "AI",
})

// Complete a task
task, err := client.Tasks.Complete(ctx, "task-id", "Successfully deployed")

// Fail a task
task, err := client.Tasks.Fail(ctx, "task-id", "Dependency unavailable")

// Assign to agent
task, err := client.Tasks.Assign(ctx, "task-id", "agent-id")

// Cancel task
err := client.Tasks.Cancel(ctx, "task-id")

// Get statistics
stats, err := client.Tasks.Stats(ctx)

// Convenience methods
pending, err := client.Tasks.Pending(ctx)
inProgress, err := client.Tasks.InProgress(ctx)
urgent, err := client.Tasks.Urgent(ctx)
aiTasks, err := client.Tasks.ByDivision(ctx, "AI")
```

### Memory

```go
// Log an entry
entry, err := client.Memory.Log(ctx, &blackroad.LogMemoryOptions{
    Action:   "deployed",
    Entity:   "user-service",
    Details:  "Deployed v2.1.0 with new auth flow",
    Tags:     []string{"deployment", "auth"},
    Metadata: map[string]interface{}{"version": "2.1.0"},
})

// Query entries
since := time.Now().AddDate(0, -1, 0)
entries, err := client.Memory.Query(ctx, &blackroad.MemoryQueryOptions{
    Search: "deployment",
    Action: "deployed",
    Tags:   []string{"production"},
    Since:  &since,
    Limit:  100,
})

// Get entry by hash
entry, err := client.Memory.Get(ctx, "entry-hash")

// Get recent entries
recent, err := client.Memory.Recent(ctx, 50)

// Agent state management
state, err := client.Memory.AgentState(ctx, "agent-id")
err = client.Memory.SyncState(ctx, "agent-id", map[string]interface{}{
    "lastTask": "task-123",
    "load":     0.5,
})

// Broadcast a message
broadcastID, err := client.Memory.Broadcast(ctx, "alert", "Maintenance at 3 PM")

// Share a TIL
entry, err := client.Memory.TIL(ctx, "security", "Always validate JWT server-side")

// Get statistics
stats, err := client.Memory.Stats(ctx)

// Verify hash chain
result, err := client.Memory.VerifyChain(ctx, "")
fmt.Printf("Valid: %v, Checked: %d\n", result.Valid, result.Checked)
```

### Health & Version

```go
// Check API health
health, err := client.Health(ctx)
fmt.Println(health.Status) // "healthy"

// Get API version
version, err := client.Version(ctx)
fmt.Println(version) // "1.0.0"
```

## Error Handling

```go
import "errors"

agent, err := client.Agents.Get(ctx, "nonexistent")
if err != nil {
    var notFoundErr *blackroad.NotFoundError
    var authErr *blackroad.AuthenticationError
    var rateLimitErr *blackroad.RateLimitError
    var validationErr *blackroad.ValidationError
    var connErr *blackroad.ConnectionError

    switch {
    case errors.As(err, &notFoundErr):
        fmt.Println("Agent not found")
    case errors.As(err, &authErr):
        fmt.Println("Invalid API key")
    case errors.As(err, &rateLimitErr):
        fmt.Printf("Rate limited. Retry after %d seconds\n", rateLimitErr.RetryAfter)
    case errors.As(err, &validationErr):
        fmt.Printf("Validation error: %s\n", validationErr.Details)
    case errors.As(err, &connErr):
        fmt.Printf("Connection error: %v\n", connErr.Cause)
    default:
        fmt.Printf("Error: %v\n", err)
    }
}
```

## Requirements

- Go 1.21 or higher

## License

See [LICENSE](./LICENSE) for details.

## Links

- [Documentation](https://docs.blackroad.io/sdk/go)
- [API Reference](https://docs.blackroad.io/api)
- [GitHub](https://github.com/BlackRoad-OS/blackroad-sdk-go)
