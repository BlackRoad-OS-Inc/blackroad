use thiserror::Error;

/// Errors that can occur when using the BlackRoad SDK.
#[derive(Error, Debug)]
pub enum Error {
    /// Invalid or missing API key.
    #[error("authentication error: {0}")]
    Authentication(String),

    /// Resource not found.
    #[error("not found: {0}")]
    NotFound(String),

    /// Rate limit exceeded.
    #[error("rate limit exceeded, retry after {retry_after} seconds")]
    RateLimit { retry_after: u64 },

    /// Validation error.
    #[error("validation error: {0}")]
    Validation(String),

    /// Network or connection error.
    #[error("connection error: {0}")]
    Connection(String),

    /// HTTP request error.
    #[error("request error: {0}")]
    Request(#[from] reqwest::Error),

    /// JSON serialization/deserialization error.
    #[error("serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    /// Generic API error.
    #[error("API error ({status}): {message}")]
    Api { status: u16, message: String },
}
