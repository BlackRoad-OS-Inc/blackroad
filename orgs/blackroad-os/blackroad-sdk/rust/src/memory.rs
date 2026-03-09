use crate::client::BlackRoadClient;
use crate::errors::Error;
use crate::types::{LogMemoryOptions, MemoryEntry, MemoryQueryOptions, Stats, VerifyChainResult};
use serde::Deserialize;
use std::collections::HashMap;

/// API for memory operations.
#[derive(Debug, Clone)]
pub struct MemoryAPI {
    client: BlackRoadClient,
}

#[derive(Deserialize)]
struct EntriesResponse {
    entries: Vec<MemoryEntry>,
}

#[derive(Deserialize)]
struct BroadcastResponse {
    broadcast_id: String,
}

impl MemoryAPI {
    pub(crate) fn new(client: BlackRoadClient) -> Self {
        Self { client }
    }

    /// Logs a new memory entry.
    pub async fn log(&self, opts: LogMemoryOptions) -> Result<MemoryEntry, Error> {
        self.client.post("/memory", &opts).await
    }

    /// Queries memory entries.
    pub async fn query(&self, opts: Option<MemoryQueryOptions>) -> Result<Vec<MemoryEntry>, Error> {
        let mut params = HashMap::new();
        params.insert("limit".to_string(), "100".to_string());

        if let Some(opts) = opts {
            if let Some(s) = opts.search {
                params.insert("q".to_string(), s);
            }
            if let Some(a) = opts.action {
                params.insert("action".to_string(), a);
            }
            if let Some(e) = opts.entity {
                params.insert("entity".to_string(), e);
            }
            if let Some(tags) = opts.tags {
                params.insert("tags".to_string(), tags.join(","));
            }
            if let Some(since) = opts.since {
                params.insert("since".to_string(), since.to_rfc3339());
            }
            if let Some(until) = opts.until {
                params.insert("until".to_string(), until.to_rfc3339());
            }
            if let Some(l) = opts.limit {
                params.insert("limit".to_string(), l.to_string());
            }
            if let Some(o) = opts.offset {
                params.insert("offset".to_string(), o.to_string());
            }
        }

        let response: EntriesResponse = self.client.get("/memory", Some(&params)).await?;
        Ok(response.entries)
    }

    /// Gets a specific memory entry by hash.
    pub async fn get(&self, entry_hash: &str) -> Result<MemoryEntry, Error> {
        self.client
            .get(&format!("/memory/{}", entry_hash), None)
            .await
    }

    /// Gets recent memory entries.
    pub async fn recent(&self, limit: Option<i32>) -> Result<Vec<MemoryEntry>, Error> {
        self.query(Some(MemoryQueryOptions {
            limit: Some(limit.unwrap_or(50)),
            ..Default::default()
        }))
        .await
    }

    /// Gets agent state.
    pub async fn agent_state(
        &self,
        agent_id: &str,
    ) -> Result<HashMap<String, serde_json::Value>, Error> {
        self.client
            .get(&format!("/memory/agents/{}/state", agent_id), None)
            .await
    }

    /// Syncs agent state.
    pub async fn sync_state(
        &self,
        agent_id: &str,
        state: HashMap<String, serde_json::Value>,
    ) -> Result<(), Error> {
        let _: serde_json::Value = self
            .client
            .post(&format!("/memory/agents/{}/state", agent_id), &state)
            .await?;
        Ok(())
    }

    /// Broadcasts a message.
    pub async fn broadcast(&self, msg_type: &str, payload: &str) -> Result<String, Error> {
        let body = serde_json::json!({
            "type": msg_type,
            "payload": payload
        });
        let response: BroadcastResponse = self.client.post("/memory/broadcast", &body).await?;
        Ok(response.broadcast_id)
    }

    /// Creates a TIL (Today I Learned) entry.
    pub async fn til(&self, category: &str, learning: &str) -> Result<MemoryEntry, Error> {
        self.log(LogMemoryOptions {
            action: "til".to_string(),
            entity: category.to_string(),
            details: Some(learning.to_string()),
            tags: Some(vec!["til".to_string(), category.to_string()]),
            metadata: None,
        })
        .await
    }

    /// Gets memory statistics.
    pub async fn stats(&self) -> Result<Stats, Error> {
        self.client.get("/memory/stats", None).await
    }

    /// Verifies hash chain integrity.
    pub async fn verify_chain(&self, start_hash: Option<&str>) -> Result<VerifyChainResult, Error> {
        let params = match start_hash {
            Some(h) => {
                let mut p = HashMap::new();
                p.insert("start".to_string(), h.to_string());
                Some(p)
            }
            None => None,
        };

        self.client.get("/memory/verify", params.as_ref()).await
    }
}
