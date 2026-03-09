use serde::{Deserialize, Serialize};
use std::time::Instant;
use tauri::command;

use crate::verification::ollama::OllamaClient;
use crate::verification::reputation::ReputationDb;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum ClaimType {
    Factual,
    Statistical,
    Quote,
    Opinion,
    Prediction,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub enum Verdict {
    Verified,
    Likely,
    Uncertain,
    Disputed,
    False,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ClaimResult {
    pub text: String,
    pub claim_type: ClaimType,
    pub confidence: f64,
    pub verdict: Verdict,
    pub reasoning: String,
    pub sources: Vec<String>,
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct VerificationResult {
    pub url: String,
    pub overall_score: f64,
    pub source_reputation: f64,
    pub source_category: String,
    pub source_bias: String,
    pub claims: Vec<ClaimResult>,
    pub claims_checked: usize,
    pub verification_time_ms: u64,
    pub method: String,
    pub ai_available: bool,
}

fn str_to_claim_type(s: &str) -> ClaimType {
    match s {
        "Statistical" => ClaimType::Statistical,
        "Quote" => ClaimType::Quote,
        "Opinion" => ClaimType::Opinion,
        "Prediction" => ClaimType::Prediction,
        _ => ClaimType::Factual,
    }
}

fn str_to_verdict(s: &str) -> Verdict {
    match s {
        "Verified" => Verdict::Verified,
        "Likely" => Verdict::Likely,
        "Disputed" => Verdict::Disputed,
        "False" => Verdict::False,
        _ => Verdict::Uncertain,
    }
}

/// Verify a page's content for accuracy using AI + source reputation.
#[command]
pub async fn verify_page(url: String, content: String) -> Result<VerificationResult, String> {
    let start = Instant::now();
    let ollama = OllamaClient::new();
    let reputation_db = ReputationDb::new();

    // 1. Get source reputation
    let rep = reputation_db.lookup(&url);
    let source_score = rep.as_ref().map(|r| r.score).unwrap_or(0.50);
    let source_category = rep
        .as_ref()
        .map(|r| r.category.to_string())
        .unwrap_or_else(|| "unknown".to_string());
    let source_bias = rep
        .as_ref()
        .map(|r| r.bias.to_string())
        .unwrap_or_else(|| "unknown".to_string());

    // 2. Check if Ollama is available for AI verification
    let ai_available = ollama.is_available().await;

    if !ai_available || content.trim().is_empty() || content.len() < 50 {
        // Fallback to reputation-only scoring
        return Ok(VerificationResult {
            url,
            overall_score: source_score,
            source_reputation: source_score,
            source_category,
            source_bias,
            claims: vec![],
            claims_checked: 0,
            verification_time_ms: start.elapsed().as_millis() as u64,
            method: if ai_available {
                "reputation-only (content too short)".to_string()
            } else {
                "reputation-only (AI offline)".to_string()
            },
            ai_available,
        });
    }

    // 3. Extract claims from content using Ollama
    let extracted = ollama.extract_claims(&content).await.unwrap_or_default();

    // 4. Verify each factual claim (skip opinions and predictions)
    let mut verified_claims = Vec::new();
    let max_claims = 5; // Limit to avoid long wait times
    let mut checked = 0;

    for claim in extracted.iter().take(10) {
        // Skip opinions and predictions - they can't be fact-checked
        if claim.claim_type == "Opinion" || claim.claim_type == "Prediction" {
            verified_claims.push(ClaimResult {
                text: claim.text.clone(),
                claim_type: str_to_claim_type(&claim.claim_type),
                confidence: 0.0,
                verdict: Verdict::Uncertain,
                reasoning: "Opinions and predictions are not fact-checkable".to_string(),
                sources: vec![],
            });
            continue;
        }

        if checked >= max_claims {
            verified_claims.push(ClaimResult {
                text: claim.text.clone(),
                claim_type: str_to_claim_type(&claim.claim_type),
                confidence: 0.0,
                verdict: Verdict::Uncertain,
                reasoning: "Skipped (verification limit reached)".to_string(),
                sources: vec![],
            });
            continue;
        }

        match ollama.verify_claim(&claim.text).await {
            Ok(verdict) => {
                verified_claims.push(ClaimResult {
                    text: claim.text.clone(),
                    claim_type: str_to_claim_type(&claim.claim_type),
                    confidence: verdict.confidence,
                    verdict: str_to_verdict(&verdict.verdict),
                    reasoning: verdict.reasoning,
                    sources: verdict.sources,
                });
                checked += 1;
            }
            Err(_) => {
                verified_claims.push(ClaimResult {
                    text: claim.text.clone(),
                    claim_type: str_to_claim_type(&claim.claim_type),
                    confidence: 0.0,
                    verdict: Verdict::Uncertain,
                    reasoning: "Verification failed".to_string(),
                    sources: vec![],
                });
            }
        }
    }

    // 5. Calculate overall score
    // Formula: 0.4 * source_reputation + 0.6 * claim_accuracy
    let claim_score = if verified_claims.is_empty() {
        source_score
    } else {
        let verifiable: Vec<&ClaimResult> = verified_claims
            .iter()
            .filter(|c| !matches!(c.claim_type, ClaimType::Opinion | ClaimType::Prediction))
            .collect();

        if verifiable.is_empty() {
            source_score
        } else {
            let total: f64 = verifiable
                .iter()
                .map(|c| match c.verdict {
                    Verdict::Verified => 1.0,
                    Verdict::Likely => 0.8,
                    Verdict::Uncertain => 0.5,
                    Verdict::Disputed => 0.3,
                    Verdict::False => 0.0,
                })
                .sum();
            total / verifiable.len() as f64
        }
    };

    let overall = 0.4 * source_score + 0.6 * claim_score;

    Ok(VerificationResult {
        url,
        overall_score: overall,
        source_reputation: source_score,
        source_category,
        source_bias,
        claims: verified_claims,
        claims_checked: checked,
        verification_time_ms: start.elapsed().as_millis() as u64,
        method: "ai+reputation".to_string(),
        ai_available: true,
    })
}

#[command]
pub async fn get_verification_status(url: String) -> Result<Option<VerificationResult>, String> {
    // TODO Phase 3: Check local SQLite cache
    let _ = url;
    Ok(None)
}

#[command]
pub async fn verify_claim(claim: String) -> Result<ClaimResult, String> {
    let ollama = OllamaClient::new();

    if !ollama.is_available().await {
        return Ok(ClaimResult {
            text: claim,
            claim_type: ClaimType::Factual,
            confidence: 0.0,
            verdict: Verdict::Uncertain,
            reasoning: "AI verification unavailable".to_string(),
            sources: vec![],
        });
    }

    match ollama.verify_claim(&claim).await {
        Ok(verdict) => Ok(ClaimResult {
            text: claim,
            claim_type: ClaimType::Factual,
            confidence: verdict.confidence,
            verdict: str_to_verdict(&verdict.verdict),
            reasoning: verdict.reasoning,
            sources: verdict.sources,
        }),
        Err(e) => Ok(ClaimResult {
            text: claim,
            claim_type: ClaimType::Factual,
            confidence: 0.0,
            verdict: Verdict::Uncertain,
            reasoning: format!("Verification error: {}", e),
            sources: vec![],
        }),
    }
}
