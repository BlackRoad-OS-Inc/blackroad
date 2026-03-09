//! # BlackRoad SDK
//!
//! Official Rust SDK for the BlackRoad API.
//!
//! ## Quick Start
//!
//! ```rust,no_run
//! use blackroad::{BlackRoadClient, ClientConfig};
//!
//! #[tokio::main]
//! async fn main() -> Result<(), blackroad::Error> {
//!     let client = BlackRoadClient::new(ClientConfig {
//!         api_key: Some("your-api-key".to_string()),
//!         ..Default::default()
//!     })?;
//!
//!     // List agents
//!     let agents = client.agents().list(None).await?;
//!     println!("Found {} agents", agents.len());
//!
//!     Ok(())
//! }
//! ```

mod client;
mod errors;
mod types;
mod agents;
mod tasks;
mod memory;

pub use client::{BlackRoadClient, ClientConfig};
pub use errors::Error;
pub use types::*;
pub use agents::AgentAPI;
pub use tasks::TaskAPI;
pub use memory::MemoryAPI;
