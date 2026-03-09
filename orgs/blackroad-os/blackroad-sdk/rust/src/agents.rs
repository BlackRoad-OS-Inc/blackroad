use crate::client::BlackRoadClient;
use crate::errors::Error;
use crate::types::{Agent, AgentListOptions, RegisterAgentOptions, Stats};
use serde::Deserialize;
use std::collections::HashMap;

/// API for managing agents.
#[derive(Debug, Clone)]
pub struct AgentAPI {
    client: BlackRoadClient,
}

#[derive(Deserialize)]
struct AgentsResponse {
    agents: Vec<Agent>,
}

#[derive(Deserialize)]
struct DeleteResponse {
    #[allow(dead_code)]
    deleted: bool,
}

impl AgentAPI {
    pub(crate) fn new(client: BlackRoadClient) -> Self {
        Self { client }
    }

    /// Lists agents with optional filters.
    pub async fn list(&self, opts: Option<AgentListOptions>) -> Result<Vec<Agent>, Error> {
        let mut params = HashMap::new();

        if let Some(opts) = opts {
            if let Some(t) = opts.agent_type {
                params.insert("type".to_string(), t);
            }
            if let Some(d) = opts.division {
                params.insert("division".to_string(), d);
            }
            if let Some(l) = opts.level {
                params.insert("level".to_string(), l.to_string());
            }
            if let Some(s) = opts.status {
                params.insert("status".to_string(), s);
            }
            if let Some(l) = opts.limit {
                params.insert("limit".to_string(), l.to_string());
            }
            if let Some(o) = opts.offset {
                params.insert("offset".to_string(), o.to_string());
            }
        }

        let params_opt = if params.is_empty() { None } else { Some(&params) };
        let response: AgentsResponse = self.client.get("/agents", params_opt).await?;
        Ok(response.agents)
    }

    /// Gets a specific agent by ID.
    pub async fn get(&self, agent_id: &str) -> Result<Agent, Error> {
        self.client.get(&format!("/agents/{}", agent_id), None).await
    }

    /// Registers a new agent.
    pub async fn register(&self, opts: RegisterAgentOptions) -> Result<Agent, Error> {
        let mut body = serde_json::json!({
            "name": opts.name,
            "type": opts.agent_type.unwrap_or_else(|| "ai".to_string()),
            "level": opts.level.unwrap_or(4),
        });

        if let Some(div) = opts.division {
            body["division"] = serde_json::Value::String(div);
        }
        if let Some(meta) = opts.metadata {
            body["metadata"] = serde_json::to_value(meta)?;
        }

        self.client.post("/agents", &body).await
    }

    /// Sends a heartbeat for an agent.
    pub async fn heartbeat(&self, agent_id: &str, load: Option<f64>) -> Result<(), Error> {
        let body = match load {
            Some(l) => serde_json::json!({ "load": l }),
            None => serde_json::json!({}),
        };

        let _: serde_json::Value = self
            .client
            .post(&format!("/agents/{}/heartbeat", agent_id), &body)
            .await?;
        Ok(())
    }

    /// Updates an agent's status.
    pub async fn update_status(&self, agent_id: &str, status: &str) -> Result<Agent, Error> {
        let body = serde_json::json!({ "status": status });
        self.client.put(&format!("/agents/{}", agent_id), &body).await
    }

    /// Deletes an agent.
    pub async fn delete(&self, agent_id: &str) -> Result<(), Error> {
        let _: DeleteResponse = self.client.delete(&format!("/agents/{}", agent_id)).await?;
        Ok(())
    }

    /// Gets agent statistics.
    pub async fn stats(&self) -> Result<Stats, Error> {
        self.client.get("/agents/stats", None).await
    }

    /// Gets agents by division.
    pub async fn by_division(&self, division: &str) -> Result<Vec<Agent>, Error> {
        self.list(Some(AgentListOptions {
            division: Some(division.to_string()),
            ..Default::default()
        }))
        .await
    }

    /// Gets Level 2 commander agents.
    pub async fn commanders(&self) -> Result<Vec<Agent>, Error> {
        self.list(Some(AgentListOptions {
            level: Some(2),
            ..Default::default()
        }))
        .await
    }

    /// Gets Level 3 manager agents.
    pub async fn managers(&self) -> Result<Vec<Agent>, Error> {
        self.list(Some(AgentListOptions {
            level: Some(3),
            ..Default::default()
        }))
        .await
    }

    /// Gets Level 4 worker agents.
    pub async fn workers(&self) -> Result<Vec<Agent>, Error> {
        self.list(Some(AgentListOptions {
            level: Some(4),
            ..Default::default()
        }))
        .await
    }
}
