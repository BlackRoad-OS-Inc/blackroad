export type ClaimType =
  | "Factual"
  | "Statistical"
  | "Quote"
  | "Opinion"
  | "Prediction";

export type Verdict =
  | "Verified"
  | "Likely"
  | "Uncertain"
  | "Disputed"
  | "False";

export interface ClaimResult {
  text: string;
  claim_type: ClaimType;
  confidence: number;
  verdict: Verdict;
  reasoning: string;
  sources: string[];
}

export interface VerificationResult {
  url: string;
  overall_score: number;
  source_reputation: number;
  source_category: string;
  source_bias: string;
  claims: ClaimResult[];
  claims_checked: number;
  verification_time_ms: number;
  method: string;
  ai_available: boolean;
}
