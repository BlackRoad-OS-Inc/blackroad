import { BlackRoadClient } from './client';
import { TrinaryValue, Claim, Contradiction } from './types';

export class ReasoningTools {
  constructor(private client: BlackRoadClient) {}

  async evaluate(claim: string, options?: {
    context?: Record<string, any>;
    checkContradictions?: boolean;
  }): Promise<{
    claim: string;
    evaluated: boolean;
    initial_state: TrinaryValue;
    contradictions: Contradiction;
    recommendation: string;
  }> {
    return this.client.fetch('/tools/reasoning/evaluate', {
      method: 'POST',
      body: JSON.stringify({
        claim,
        context: options?.context,
        check_contradictions: options?.checkContradictions
      })
    });
  }

  async commitClaim(options: {
    claim: string;
    truthState: TrinaryValue;
    confidence: number;
    source?: string;
  }): Promise<{ committed: boolean; claim: Claim }> {
    return this.client.fetch('/tools/reasoning/commit', {
      method: 'POST',
      body: JSON.stringify({
        claim: options.claim,
        truth_state: options.truthState,
        confidence: options.confidence,
        source: options.source
      })
    });
  }

  async quarantine(claimIds: string[], reason: string, strategy?: 'await_evidence' | 'human_review' | 'auto_resolve'): Promise<{
    quarantined: boolean;
    quarantine_id: string;
  }> {
    return this.client.fetch('/tools/reasoning/quarantine', {
      method: 'POST',
      body: JSON.stringify({
        claim_ids: claimIds,
        reason,
        resolution_strategy: strategy
      })
    });
  }

  async resolve(quarantineId: string, options: {
    resolution: 'accept_first' | 'accept_second' | 'reject_both' | 'merge';
    justification: string;
    newTruthState?: TrinaryValue;
  }): Promise<{ resolved: boolean }> {
    return this.client.fetch('/tools/reasoning/resolve', {
      method: 'POST',
      body: JSON.stringify({
        quarantine_id: quarantineId,
        resolution: options.resolution,
        justification: options.justification,
        new_truth_state: options.newTruthState
      })
    });
  }

  async getClaims(truthState?: TrinaryValue): Promise<{ claims: Claim[]; count: number }> {
    const params = truthState !== undefined ? `?truth_state=${truthState}` : '';
    return this.client.fetch(`/tools/reasoning/claims${params}`);
  }

  // Convenience methods
  async assertTrue(claim: string, confidence = 0.9): Promise<Claim> {
    const result = await this.commitClaim({ claim, truthState: 1, confidence });
    return result.claim;
  }

  async assertFalse(claim: string, confidence = 0.9): Promise<Claim> {
    const result = await this.commitClaim({ claim, truthState: -1, confidence });
    return result.claim;
  }

  async assertUnknown(claim: string): Promise<Claim> {
    const result = await this.commitClaim({ claim, truthState: 0, confidence: 0 });
    return result.claim;
  }
}
