# blackroad

Official Rust SDK for the BlackRoad API.

## Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
blackroad = "1.0"
tokio = { version = "1", features = ["full"] }
```

## Quick Start

```rust
use blackroad::{BlackRoadClient, ClientConfig, DispatchTaskOptions, LogMemoryOptions};

#[tokio::main]
async fn main() -> Result<(), blackroad::Error> {
    // Initialize the client
    let client = BlackRoadClient::new(ClientConfig {
        api_key: Some("your-api-key".to_string()), // or set BLACKROAD_API_KEY env var
        ..Default::default()
    })?;

    // List agents
    let agents = client.agents().list(None).await?;
    println!("Found {} agents", agents.len());

    // Dispatch a task
    let task = client.tasks().dispatch(DispatchTaskOptions {
        title: "Deploy authentication service".to_string(),
        priority: Some("high".to_string()),
        division: Some("Security".to_string()),
        ..Default::default()
    }).await?;
    println!("Created task: {}", task.id);

    // Log to memory
    let entry = client.memory().log(LogMemoryOptions {
        action: "deployed".to_string(),
        entity: "auth-service".to_string(),
        details: Some("Deployed v2.0.0 to production".to_string()),
        tags: Some(vec!["deployment".to_string(), "security".to_string()]),
        ..Default::default()
    }).await?;
    println!("Logged entry: {}", entry.hash);

    Ok(())
}
```

## Configuration

```rust
let client = BlackRoadClient::new(ClientConfig {
    api_key: Some("your-api-key".to_string()),  // Required (or BLACKROAD_API_KEY env var)
    base_url: Some("https://api.blackroad.io/v1".to_string()), // Optional
    timeout_secs: Some(30),                      // Optional, request timeout
    max_retries: Some(3),                        // Optional, max retry attempts
})?;
```

## API Reference

### Agents

```rust
// List all agents
let agents = client.agents().list(None).await?;

// List with filters
let agents = client.agents().list(Some(AgentListOptions {
    agent_type: Some("ai".to_string()),
    division: Some("Security".to_string()),
    level: Some(4),
    ..Default::default()
})).await?;

// Get specific agent
let agent = client.agents().get("agent-id").await?;

// Register a new agent
let agent = client.agents().register(RegisterAgentOptions {
    name: "my-agent".to_string(),
    agent_type: Some("ai".to_string()),
    division: Some("Labs".to_string()),
    level: Some(4),
    ..Default::default()
}).await?;

// Send heartbeat
client.agents().heartbeat("agent-id", Some(0.75)).await?;

// Update status
let agent = client.agents().update_status("agent-id", "busy").await?;

// Delete agent
client.agents().delete("agent-id").await?;

// Get statistics
let stats = client.agents().stats().await?;

// Convenience methods
let commanders = client.agents().commanders().await?;      // Level 2
let managers = client.agents().managers().await?;          // Level 3
let workers = client.agents().workers().await?;            // Level 4
let sec_agents = client.agents().by_division("Security").await?;
```

### Tasks

```rust
// Dispatch a task
let task = client.tasks().dispatch(DispatchTaskOptions {
    title: "Build auth system".to_string(),
    description: Some("Implement OAuth2 + JWT".to_string()),
    priority: Some("high".to_string()),
    division: Some("Security".to_string()),
    target_level: Some(4),
    ..Default::default()
}).await?;

// Get task by ID
let task = client.tasks().get("task-id").await?;

// List tasks with filters
let tasks = client.tasks().list(Some(TaskListOptions {
    status: Some("pending".to_string()),
    priority: Some("high".to_string()),
    ..Default::default()
})).await?;

// Complete a task
let task = client.tasks().complete("task-id", Some("Successfully deployed")).await?;

// Fail a task
let task = client.tasks().fail("task-id", Some("Dependency unavailable")).await?;

// Assign to agent
let task = client.tasks().assign("task-id", "agent-id").await?;

// Cancel task
client.tasks().cancel("task-id").await?;

// Get statistics
let stats = client.tasks().stats().await?;

// Convenience methods
let pending = client.tasks().pending().await?;
let in_progress = client.tasks().in_progress().await?;
let urgent = client.tasks().urgent().await?;
let ai_tasks = client.tasks().by_division("AI").await?;
```

### Memory

```rust
// Log an entry
let entry = client.memory().log(LogMemoryOptions {
    action: "deployed".to_string(),
    entity: "user-service".to_string(),
    details: Some("Deployed v2.1.0".to_string()),
    tags: Some(vec!["deployment".to_string()]),
    ..Default::default()
}).await?;

// Query entries
let entries = client.memory().query(Some(MemoryQueryOptions {
    search: Some("deployment".to_string()),
    action: Some("deployed".to_string()),
    tags: Some(vec!["production".to_string()]),
    limit: Some(100),
    ..Default::default()
})).await?;

// Get entry by hash
let entry = client.memory().get("entry-hash").await?;

// Get recent entries
let recent = client.memory().recent(Some(50)).await?;

// Agent state management
let state = client.memory().agent_state("agent-id").await?;
client.memory().sync_state("agent-id", state).await?;

// Broadcast a message
let broadcast_id = client.memory().broadcast("alert", "Maintenance at 3 PM").await?;

// Share a TIL
let entry = client.memory().til("security", "Always validate JWT server-side").await?;

// Get statistics
let stats = client.memory().stats().await?;

// Verify hash chain
let result = client.memory().verify_chain(None).await?;
println!("Valid: {}, Checked: {}", result.valid, result.checked);
```

### Health & Version

```rust
// Check API health
let health = client.health().await?;
println!("Status: {}", health.status);

// Get API version
let version = client.version().await?;
println!("Version: {}", version);
```

## Error Handling

```rust
use blackroad::Error;

match client.agents().get("nonexistent").await {
    Ok(agent) => println!("Found: {}", agent.name),
    Err(Error::NotFound(resource)) => println!("Not found: {}", resource),
    Err(Error::Authentication(msg)) => println!("Auth error: {}", msg),
    Err(Error::RateLimit { retry_after }) => {
        println!("Rate limited. Retry after {} seconds", retry_after);
    }
    Err(Error::Validation(details)) => println!("Validation error: {}", details),
    Err(Error::Connection(msg)) => println!("Connection error: {}", msg),
    Err(Error::Api { status, message }) => {
        println!("API error ({}): {}", status, message);
    }
    Err(e) => println!("Error: {}", e),
}
```

## Requirements

- Rust 1.70 or higher
- Tokio runtime

## License

See [LICENSE](./LICENSE) for details.

## Links

- [Documentation](https://docs.blackroad.io/sdk/rust)
- [API Reference](https://docs.blackroad.io/api)
- [GitHub](https://github.com/BlackRoad-OS/blackroad-sdk-rust)
- [crates.io](https://crates.io/crates/blackroad)
