use crate::errors::Error;
use crate::types::HealthStatus;
use crate::{AgentAPI, MemoryAPI, TaskAPI};
use reqwest::{Client, Response, StatusCode};
use serde::de::DeserializeOwned;
use serde::Serialize;
use std::collections::HashMap;
use std::env;
use std::time::Duration;

const DEFAULT_BASE_URL: &str = "https://api.blackroad.io/v1";
const DEFAULT_TIMEOUT_SECS: u64 = 30;
const DEFAULT_MAX_RETRIES: u32 = 3;

/// Configuration for the BlackRoad client.
#[derive(Debug, Clone)]
pub struct ClientConfig {
    /// API key. If None, reads from BLACKROAD_API_KEY env var.
    pub api_key: Option<String>,
    /// Base URL for the API. Defaults to https://api.blackroad.io/v1
    pub base_url: Option<String>,
    /// Request timeout in seconds. Defaults to 30.
    pub timeout_secs: Option<u64>,
    /// Maximum retry attempts. Defaults to 3.
    pub max_retries: Option<u32>,
}

impl Default for ClientConfig {
    fn default() -> Self {
        Self {
            api_key: None,
            base_url: None,
            timeout_secs: None,
            max_retries: None,
        }
    }
}

/// The BlackRoad API client.
#[derive(Debug, Clone)]
pub struct BlackRoadClient {
    api_key: String,
    base_url: String,
    max_retries: u32,
    http_client: Client,
}

impl BlackRoadClient {
    /// Creates a new BlackRoad client.
    ///
    /// # Example
    ///
    /// ```rust,no_run
    /// use blackroad::{BlackRoadClient, ClientConfig};
    ///
    /// let client = BlackRoadClient::new(ClientConfig {
    ///     api_key: Some("your-api-key".to_string()),
    ///     ..Default::default()
    /// }).expect("Failed to create client");
    /// ```
    pub fn new(config: ClientConfig) -> Result<Self, Error> {
        let api_key = config
            .api_key
            .or_else(|| env::var("BLACKROAD_API_KEY").ok())
            .ok_or_else(|| {
                Error::Authentication(
                    "API key required. Set BLACKROAD_API_KEY environment variable or pass api_key in config.".to_string()
                )
            })?;

        let base_url = config
            .base_url
            .or_else(|| env::var("BLACKROAD_API_URL").ok())
            .unwrap_or_else(|| DEFAULT_BASE_URL.to_string())
            .trim_end_matches('/')
            .to_string();

        let timeout_secs = config.timeout_secs.unwrap_or(DEFAULT_TIMEOUT_SECS);
        let max_retries = config.max_retries.unwrap_or(DEFAULT_MAX_RETRIES);

        let http_client = Client::builder()
            .timeout(Duration::from_secs(timeout_secs))
            .build()
            .map_err(|e| Error::Connection(format!("Failed to create HTTP client: {}", e)))?;

        Ok(Self {
            api_key,
            base_url,
            max_retries,
            http_client,
        })
    }

    /// Returns the agents API.
    pub fn agents(&self) -> AgentAPI {
        AgentAPI::new(self.clone())
    }

    /// Returns the tasks API.
    pub fn tasks(&self) -> TaskAPI {
        TaskAPI::new(self.clone())
    }

    /// Returns the memory API.
    pub fn memory(&self) -> MemoryAPI {
        MemoryAPI::new(self.clone())
    }

    /// Makes an HTTP request to the API.
    pub(crate) async fn request<T, B>(
        &self,
        method: reqwest::Method,
        endpoint: &str,
        body: Option<&B>,
        params: Option<&HashMap<String, String>>,
    ) -> Result<T, Error>
    where
        T: DeserializeOwned,
        B: Serialize,
    {
        let mut url = format!("{}/{}", self.base_url, endpoint.trim_start_matches('/'));

        if let Some(params) = params {
            let query: Vec<String> = params
                .iter()
                .map(|(k, v)| format!("{}={}", k, urlencoding::encode(v)))
                .collect();
            if !query.is_empty() {
                url = format!("{}?{}", url, query.join("&"));
            }
        }

        let mut last_error: Option<Error> = None;

        for attempt in 0..self.max_retries {
            let mut request = self
                .http_client
                .request(method.clone(), &url)
                .header("Authorization", format!("Bearer {}", self.api_key))
                .header("Content-Type", "application/json")
                .header("User-Agent", "blackroad-rust/1.0.0");

            if let Some(body) = body {
                request = request.json(body);
            }

            match request.send().await {
                Ok(response) => {
                    return self.handle_response(response).await;
                }
                Err(e) => {
                    last_error = Some(Error::Connection(format!("Request failed: {}", e)));
                    if attempt < self.max_retries - 1 {
                        tokio::time::sleep(Duration::from_secs(1 << attempt)).await;
                    }
                }
            }
        }

        Err(last_error.unwrap_or_else(|| Error::Connection("Max retries exceeded".to_string())))
    }

    async fn handle_response<T: DeserializeOwned>(&self, response: Response) -> Result<T, Error> {
        let status = response.status();

        if status.is_success() {
            return response.json::<T>().await.map_err(Error::from);
        }

        let error_body = response.text().await.unwrap_or_default();

        match status {
            StatusCode::UNAUTHORIZED => Err(Error::Authentication("Invalid API key".to_string())),
            StatusCode::NOT_FOUND => Err(Error::NotFound(error_body)),
            StatusCode::UNPROCESSABLE_ENTITY => Err(Error::Validation(error_body)),
            StatusCode::TOO_MANY_REQUESTS => {
                Err(Error::RateLimit { retry_after: 1 })
            }
            _ => Err(Error::Api {
                status: status.as_u16(),
                message: error_body,
            }),
        }
    }

    /// Makes a GET request.
    pub(crate) async fn get<T: DeserializeOwned>(
        &self,
        endpoint: &str,
        params: Option<&HashMap<String, String>>,
    ) -> Result<T, Error> {
        self.request::<T, ()>(reqwest::Method::GET, endpoint, None, params)
            .await
    }

    /// Makes a POST request.
    pub(crate) async fn post<T: DeserializeOwned, B: Serialize>(
        &self,
        endpoint: &str,
        body: &B,
    ) -> Result<T, Error> {
        self.request(reqwest::Method::POST, endpoint, Some(body), None)
            .await
    }

    /// Makes a PUT request.
    pub(crate) async fn put<T: DeserializeOwned, B: Serialize>(
        &self,
        endpoint: &str,
        body: &B,
    ) -> Result<T, Error> {
        self.request(reqwest::Method::PUT, endpoint, Some(body), None)
            .await
    }

    /// Makes a DELETE request.
    pub(crate) async fn delete<T: DeserializeOwned>(&self, endpoint: &str) -> Result<T, Error> {
        self.request::<T, ()>(reqwest::Method::DELETE, endpoint, None, None)
            .await
    }

    /// Checks the API health status.
    pub async fn health(&self) -> Result<HealthStatus, Error> {
        self.get("/health", None).await
    }

    /// Gets the API version.
    pub async fn version(&self) -> Result<String, Error> {
        #[derive(serde::Deserialize)]
        struct VersionResponse {
            version: String,
        }
        let response: VersionResponse = self.get("/version", None).await?;
        Ok(response.version)
    }
}
