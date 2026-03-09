use reqwest::Client;
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
struct GenerateRequest {
    model: String,
    prompt: String,
    stream: bool,
    options: OllamaOptions,
}

#[derive(Serialize)]
struct OllamaOptions {
    temperature: f64,
    num_predict: i32,
}

#[derive(Deserialize)]
struct GenerateResponse {
    response: String,
}

pub struct OllamaClient {
    endpoint: String,
    client: Client,
}

impl OllamaClient {
    pub fn new() -> Self {
        let endpoint = std::env::var("OLLAMA_ENDPOINT")
            .unwrap_or_else(|_| "http://localhost:11434".to_string());
        Self {
            endpoint,
            client: Client::builder()
                .timeout(std::time::Duration::from_secs(60))
                .build()
                .unwrap_or_default(),
        }
    }

    pub async fn is_available(&self) -> bool {
        self.client
            .get(format!("{}/api/tags", self.endpoint))
            .timeout(std::time::Duration::from_secs(3))
            .send()
            .await
            .map(|r| r.status().is_success())
            .unwrap_or(false)
    }

    pub async fn generate(&self, model: &str, prompt: &str) -> Result<String, String> {
        let request = GenerateRequest {
            model: model.to_string(),
            prompt: prompt.to_string(),
            stream: false,
            options: OllamaOptions {
                temperature: 0.1, // Low temperature for factual accuracy
                num_predict: 2048,
            },
        };

        let response = self
            .client
            .post(format!("{}/api/generate", self.endpoint))
            .json(&request)
            .send()
            .await
            .map_err(|e| format!("Ollama request failed: {}", e))?;

        if !response.status().is_success() {
            return Err(format!("Ollama returned status {}", response.status()));
        }

        let data: GenerateResponse = response
            .json()
            .await
            .map_err(|e| format!("Failed to parse Ollama response: {}", e))?;

        Ok(data.response)
    }

    /// Extract verifiable claims from page content
    pub async fn extract_claims(&self, content: &str) -> Result<Vec<ExtractedClaim>, String> {
        let truncated = if content.len() > 3000 {
            &content[..3000]
        } else {
            content
        };

        let prompt = format!(
            r#"You are a fact-checking assistant. Analyze the following text and extract all verifiable factual claims.

For each claim, output EXACTLY one line in this format:
[TYPE] claim text here

Where TYPE is one of:
- FACT: A verifiable factual statement
- STAT: A statistical claim with numbers
- QUOTE: An attributed quote
- OPINION: A subjective opinion (not verifiable)
- PREDICTION: A claim about the future

Only extract clear, specific claims. Skip vague statements. Output ONLY the tagged claims, nothing else.

TEXT:
{}

CLAIMS:"#,
            truncated
        );

        let response = self.generate("llama3:latest", &prompt).await?;
        let claims = parse_claims(&response);
        Ok(claims)
    }

    /// Verify a single factual claim
    pub async fn verify_claim(&self, claim: &str) -> Result<ClaimVerdict, String> {
        let prompt = format!(
            r#"You are a rigorous fact-checker. Evaluate the following claim for accuracy.

CLAIM: "{}"

Respond in EXACTLY this format (one line each):
VERDICT: [VERIFIED|LIKELY|UNCERTAIN|DISPUTED|FALSE]
CONFIDENCE: [0-100]
REASONING: [one sentence explanation]
SOURCES: [comma-separated list of what would verify this, or "none"]

Be conservative. If you're not sure, say UNCERTAIN. Only say VERIFIED for well-established facts."#,
            claim
        );

        let response = self.generate("llama3:latest", &prompt).await?;
        parse_verdict(&response, claim)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtractedClaim {
    pub text: String,
    pub claim_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClaimVerdict {
    pub verdict: String,
    pub confidence: f64,
    pub reasoning: String,
    pub sources: Vec<String>,
}

fn parse_claims(response: &str) -> Vec<ExtractedClaim> {
    let mut claims = Vec::new();
    for line in response.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }

        let (claim_type, text) = if line.starts_with("[FACT]") {
            ("Factual", line.trim_start_matches("[FACT]").trim())
        } else if line.starts_with("[STAT]") {
            ("Statistical", line.trim_start_matches("[STAT]").trim())
        } else if line.starts_with("[QUOTE]") {
            ("Quote", line.trim_start_matches("[QUOTE]").trim())
        } else if line.starts_with("[OPINION]") {
            ("Opinion", line.trim_start_matches("[OPINION]").trim())
        } else if line.starts_with("[PREDICTION]") {
            ("Prediction", line.trim_start_matches("[PREDICTION]").trim())
        } else {
            continue;
        };

        if !text.is_empty() {
            claims.push(ExtractedClaim {
                text: text.to_string(),
                claim_type: claim_type.to_string(),
            });
        }
    }
    claims
}

fn parse_verdict(response: &str, original_claim: &str) -> Result<ClaimVerdict, String> {
    let mut verdict = "Uncertain".to_string();
    let mut confidence = 0.0;
    let mut reasoning = String::new();
    let mut sources = Vec::new();

    for line in response.lines() {
        let line = line.trim();
        if let Some(v) = line.strip_prefix("VERDICT:") {
            let v = v.trim().trim_matches('[').trim_matches(']');
            verdict = match v.to_uppercase().as_str() {
                "VERIFIED" => "Verified",
                "LIKELY" => "Likely",
                "UNCERTAIN" => "Uncertain",
                "DISPUTED" => "Disputed",
                "FALSE" => "False",
                _ => "Uncertain",
            }
            .to_string();
        } else if let Some(c) = line.strip_prefix("CONFIDENCE:") {
            let c = c.trim().trim_matches('[').trim_matches(']').trim_end_matches('%');
            confidence = c.parse::<f64>().unwrap_or(0.0) / 100.0;
        } else if let Some(r) = line.strip_prefix("REASONING:") {
            reasoning = r.trim().trim_matches('[').trim_matches(']').to_string();
        } else if let Some(s) = line.strip_prefix("SOURCES:") {
            let s = s.trim().trim_matches('[').trim_matches(']');
            if s.to_lowercase() != "none" {
                sources = s.split(',').map(|s| s.trim().to_string()).collect();
            }
        }
    }

    if reasoning.is_empty() {
        reasoning = format!("Analysis of claim: \"{}\"", original_claim);
    }

    Ok(ClaimVerdict {
        verdict,
        confidence,
        reasoning,
        sources,
    })
}
