use crate::client::BlackRoadClient;
use crate::errors::Error;
use crate::types::{DispatchTaskOptions, Stats, Task, TaskListOptions};
use serde::Deserialize;
use std::collections::HashMap;

/// API for managing tasks.
#[derive(Debug, Clone)]
pub struct TaskAPI {
    client: BlackRoadClient,
}

#[derive(Deserialize)]
struct TasksResponse {
    tasks: Vec<Task>,
}

#[derive(Deserialize)]
struct CancelResponse {
    #[allow(dead_code)]
    cancelled: bool,
}

impl TaskAPI {
    pub(crate) fn new(client: BlackRoadClient) -> Self {
        Self { client }
    }

    /// Dispatches a new task.
    pub async fn dispatch(&self, opts: DispatchTaskOptions) -> Result<Task, Error> {
        let mut body = serde_json::json!({
            "title": opts.title,
            "priority": opts.priority.unwrap_or_else(|| "medium".to_string()),
        });

        if let Some(desc) = opts.description {
            body["description"] = serde_json::Value::String(desc);
        }
        if let Some(div) = opts.division {
            body["division"] = serde_json::Value::String(div);
        }
        if let Some(level) = opts.target_level {
            body["target_level"] = serde_json::Value::Number(level.into());
        }
        if let Some(meta) = opts.metadata {
            body["metadata"] = serde_json::to_value(meta)?;
        }

        self.client.post("/tasks", &body).await
    }

    /// Gets a specific task by ID.
    pub async fn get(&self, task_id: &str) -> Result<Task, Error> {
        self.client.get(&format!("/tasks/{}", task_id), None).await
    }

    /// Lists tasks with optional filters.
    pub async fn list(&self, opts: Option<TaskListOptions>) -> Result<Vec<Task>, Error> {
        let mut params = HashMap::new();

        if let Some(opts) = opts {
            if let Some(s) = opts.status {
                params.insert("status".to_string(), s);
            }
            if let Some(p) = opts.priority {
                params.insert("priority".to_string(), p);
            }
            if let Some(d) = opts.division {
                params.insert("division".to_string(), d);
            }
            if let Some(l) = opts.limit {
                params.insert("limit".to_string(), l.to_string());
            }
            if let Some(o) = opts.offset {
                params.insert("offset".to_string(), o.to_string());
            }
        }

        let params_opt = if params.is_empty() { None } else { Some(&params) };
        let response: TasksResponse = self.client.get("/tasks", params_opt).await?;
        Ok(response.tasks)
    }

    /// Completes a task.
    pub async fn complete(&self, task_id: &str, result: Option<&str>) -> Result<Task, Error> {
        let mut body = serde_json::json!({ "status": "completed" });
        if let Some(r) = result {
            body["result"] = serde_json::Value::String(r.to_string());
        }
        self.client.put(&format!("/tasks/{}", task_id), &body).await
    }

    /// Fails a task.
    pub async fn fail(&self, task_id: &str, reason: Option<&str>) -> Result<Task, Error> {
        let mut body = serde_json::json!({ "status": "failed" });
        if let Some(r) = reason {
            body["result"] = serde_json::Value::String(r.to_string());
        }
        self.client.put(&format!("/tasks/{}", task_id), &body).await
    }

    /// Assigns a task to an agent.
    pub async fn assign(&self, task_id: &str, agent_id: &str) -> Result<Task, Error> {
        let body = serde_json::json!({
            "assigned_agent": agent_id,
            "status": "assigned"
        });
        self.client.put(&format!("/tasks/{}", task_id), &body).await
    }

    /// Cancels a task.
    pub async fn cancel(&self, task_id: &str) -> Result<(), Error> {
        let _: CancelResponse = self.client.delete(&format!("/tasks/{}", task_id)).await?;
        Ok(())
    }

    /// Gets task statistics.
    pub async fn stats(&self) -> Result<Stats, Error> {
        self.client.get("/tasks/stats", None).await
    }

    /// Gets pending tasks.
    pub async fn pending(&self) -> Result<Vec<Task>, Error> {
        self.list(Some(TaskListOptions {
            status: Some("pending".to_string()),
            ..Default::default()
        }))
        .await
    }

    /// Gets in-progress tasks.
    pub async fn in_progress(&self) -> Result<Vec<Task>, Error> {
        self.list(Some(TaskListOptions {
            status: Some("in_progress".to_string()),
            ..Default::default()
        }))
        .await
    }

    /// Gets tasks by division.
    pub async fn by_division(&self, division: &str) -> Result<Vec<Task>, Error> {
        self.list(Some(TaskListOptions {
            division: Some(division.to_string()),
            ..Default::default()
        }))
        .await
    }

    /// Gets urgent tasks.
    pub async fn urgent(&self) -> Result<Vec<Task>, Error> {
        self.list(Some(TaskListOptions {
            priority: Some("urgent".to_string()),
            ..Default::default()
        }))
        .await
    }
}
