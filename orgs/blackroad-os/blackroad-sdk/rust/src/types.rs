use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Represents a BlackRoad agent.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Agent {
    pub id: String,
    pub name: String,
    #[serde(rename = "type")]
    pub agent_type: String,
    #[serde(default)]
    pub division: Option<String>,
    pub level: i32,
    pub status: String,
    #[serde(default)]
    pub load: f64,
    #[serde(default)]
    pub hash: Option<String>,
    pub created_at: DateTime<Utc>,
    #[serde(default)]
    pub last_seen: Option<DateTime<Utc>>,
    #[serde(default)]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

/// Represents a BlackRoad task.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    pub id: String,
    pub title: String,
    #[serde(default)]
    pub description: Option<String>,
    pub status: String,
    pub priority: String,
    #[serde(default)]
    pub division: Option<String>,
    #[serde(default)]
    pub target_level: Option<i32>,
    #[serde(default)]
    pub assigned_agent: Option<String>,
    #[serde(default)]
    pub result: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    #[serde(default)]
    pub completed_at: Option<DateTime<Utc>>,
    #[serde(default)]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

/// Represents an entry in the BlackRoad memory system.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryEntry {
    pub hash: String,
    pub timestamp: DateTime<Utc>,
    pub action: String,
    pub entity: String,
    #[serde(default)]
    pub details: Option<String>,
    #[serde(default)]
    pub agent: Option<String>,
    #[serde(default)]
    pub tags: Option<Vec<String>>,
    #[serde(default)]
    pub prev_hash: Option<String>,
    #[serde(default)]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

/// Statistics from the API.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stats {
    pub total: i64,
    #[serde(default)]
    pub by_status: Option<HashMap<String, i64>>,
    #[serde(default)]
    pub by_type: Option<HashMap<String, i64>>,
    #[serde(default)]
    pub by_level: Option<HashMap<String, i64>>,
    #[serde(default)]
    pub active: Option<i64>,
    #[serde(default)]
    pub pending: Option<i64>,
    #[serde(default)]
    pub completed: Option<i64>,
}

/// API health status.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthStatus {
    pub status: String,
    pub version: String,
    pub timestamp: DateTime<Utc>,
    #[serde(default)]
    pub services: Option<HashMap<String, String>>,
}

/// Options for registering an agent.
#[derive(Debug, Clone, Default, Serialize)]
pub struct RegisterAgentOptions {
    pub name: String,
    #[serde(rename = "type", skip_serializing_if = "Option::is_none")]
    pub agent_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub division: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub level: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

/// Options for listing agents.
#[derive(Debug, Clone, Default)]
pub struct AgentListOptions {
    pub agent_type: Option<String>,
    pub division: Option<String>,
    pub level: Option<i32>,
    pub status: Option<String>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

/// Options for dispatching a task.
#[derive(Debug, Clone, Default, Serialize)]
pub struct DispatchTaskOptions {
    pub title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub priority: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub division: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub target_level: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

/// Options for listing tasks.
#[derive(Debug, Clone, Default)]
pub struct TaskListOptions {
    pub status: Option<String>,
    pub priority: Option<String>,
    pub division: Option<String>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

/// Options for logging a memory entry.
#[derive(Debug, Clone, Default, Serialize)]
pub struct LogMemoryOptions {
    pub action: String,
    pub entity: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tags: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<HashMap<String, serde_json::Value>>,
}

/// Options for querying memory.
#[derive(Debug, Clone, Default)]
pub struct MemoryQueryOptions {
    pub search: Option<String>,
    pub action: Option<String>,
    pub entity: Option<String>,
    pub tags: Option<Vec<String>>,
    pub since: Option<DateTime<Utc>>,
    pub until: Option<DateTime<Utc>>,
    pub limit: Option<i32>,
    pub offset: Option<i32>,
}

/// Result of chain verification.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerifyChainResult {
    pub valid: bool,
    pub checked: i64,
}
