import { Env } from '../index';

// Trinary logic: 1 (true), 0 (unknown), -1 (false)
type TrinaryValue = 1 | 0 | -1;

interface Claim {
  id: string;
  content: string;
  truth_state: TrinaryValue;
  confidence: number;
  source: string;
  timestamp: number;
}

interface ContradictionResult {
  detected: boolean;
  claims: Claim[];
  resolution?: 'quarantine' | 'branch' | 'reconcile';
  recommendation?: string;
}

export class ReasoningTools {
  static async handle(request: Request, env: Env, corsHeaders: Record<string, string>): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.replace('/tools/reasoning', '');
    const agentId = request.headers.get('X-Agent-ID') || 'system';

    // POST /tools/reasoning/evaluate - Evaluate a claim
    if (path === '/evaluate' && request.method === 'POST') {
      const body = await request.json() as {
        claim: string;
        context?: Record<string, any>;
        check_contradictions?: boolean;
      };

      // Check for existing claims that might contradict
      const existingKey = `claims:${agentId}`;
      const existingClaims = await env.TOOLS_KV.get(existingKey);
      const claims: Claim[] = existingClaims ? JSON.parse(existingClaims) : [];

      // Simple contradiction detection (would use embeddings in production)
      const potentialContradictions = claims.filter(c => 
        c.truth_state !== 0 && // Skip unknown claims
        (c.content.includes('not') !== body.claim.includes('not')) && // Negation check
        this.semanticSimilarity(c.content, body.claim) > 0.7
      );

      const result: any = {
        claim: body.claim,
        evaluated: true,
        initial_state: 0 as TrinaryValue, // Unknown until verified
        contradictions: potentialContradictions.length > 0 ? {
          detected: true,
          count: potentialContradictions.length,
          conflicts: potentialContradictions.map(c => ({
            id: c.id,
            content: c.content,
            truth_state: c.truth_state
          }))
        } : { detected: false },
        recommendation: potentialContradictions.length > 0 
          ? 'Quarantine claim pending resolution'
          : 'Claim can be accepted with confidence adjustment'
      };

      return Response.json(result, { headers: corsHeaders });
    }

    // POST /tools/reasoning/commit - Commit a claim to truth state
    if (path === '/commit' && request.method === 'POST') {
      const body = await request.json() as {
        claim: string;
        truth_state: TrinaryValue;
        confidence: number;
        source?: string;
      };

      const claimId = `claim_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      const claim: Claim = {
        id: claimId,
        content: body.claim,
        truth_state: body.truth_state,
        confidence: Math.min(1, Math.max(0, body.confidence)),
        source: body.source || agentId,
        timestamp: Date.now()
      };

      // Store claim
      const existingKey = `claims:${agentId}`;
      const existingClaims = await env.TOOLS_KV.get(existingKey);
      const claims: Claim[] = existingClaims ? JSON.parse(existingClaims) : [];
      claims.push(claim);
      await env.TOOLS_KV.put(existingKey, JSON.stringify(claims.slice(-500))); // Keep last 500

      return Response.json({
        committed: true,
        claim,
        truth_state_label: claim.truth_state === 1 ? 'true' : claim.truth_state === -1 ? 'false' : 'unknown'
      }, { headers: corsHeaders });
    }

    // POST /tools/reasoning/quarantine - Quarantine contradicting claims
    if (path === '/quarantine' && request.method === 'POST') {
      const body = await request.json() as {
        claim_ids: string[];
        reason: string;
        resolution_strategy?: 'await_evidence' | 'human_review' | 'auto_resolve';
      };

      const quarantineId = `q_${Date.now()}`;
      const quarantine = {
        id: quarantineId,
        claim_ids: body.claim_ids,
        reason: body.reason,
        strategy: body.resolution_strategy || 'await_evidence',
        created_at: new Date().toISOString(),
        status: 'active'
      };

      const key = `quarantine:${agentId}:${quarantineId}`;
      await env.TOOLS_KV.put(key, JSON.stringify(quarantine));

      return Response.json({
        quarantined: true,
        quarantine_id: quarantineId,
        claims_affected: body.claim_ids.length,
        resolution_strategy: quarantine.strategy
      }, { headers: corsHeaders });
    }

    // POST /tools/reasoning/resolve - Resolve a quarantined contradiction
    if (path === '/resolve' && request.method === 'POST') {
      const body = await request.json() as {
        quarantine_id: string;
        resolution: 'accept_first' | 'accept_second' | 'reject_both' | 'merge';
        new_truth_state?: TrinaryValue;
        justification: string;
      };

      const key = `quarantine:${agentId}:${body.quarantine_id}`;
      const quarantine = await env.TOOLS_KV.get(key);

      if (!quarantine) {
        return Response.json({ error: 'Quarantine not found' }, { status: 404, headers: corsHeaders });
      }

      const parsed = JSON.parse(quarantine);
      parsed.status = 'resolved';
      parsed.resolution = body.resolution;
      parsed.justification = body.justification;
      parsed.resolved_at = new Date().toISOString();

      await env.TOOLS_KV.put(key, JSON.stringify(parsed));

      return Response.json({
        resolved: true,
        quarantine_id: body.quarantine_id,
        resolution: body.resolution,
        justification: body.justification
      }, { headers: corsHeaders });
    }

    // GET /tools/reasoning/claims - List committed claims
    if (path === '/claims' || path === '/claims/') {
      const truthState = url.searchParams.get('truth_state');
      
      const existingKey = `claims:${agentId}`;
      const existingClaims = await env.TOOLS_KV.get(existingKey);
      let claims: Claim[] = existingClaims ? JSON.parse(existingClaims) : [];

      if (truthState !== null) {
        const state = parseInt(truthState) as TrinaryValue;
        claims = claims.filter(c => c.truth_state === state);
      }

      return Response.json({
        claims: claims.slice(-100).reverse(),
        count: claims.length
      }, { headers: corsHeaders });
    }

    return Response.json({ error: 'Unknown reasoning endpoint', path }, { status: 404, headers: corsHeaders });
  }

  // Simple semantic similarity (would use embeddings in production)
  private static semanticSimilarity(a: string, b: string): number {
    const wordsA = new Set(a.toLowerCase().split(/\s+/));
    const wordsB = new Set(b.toLowerCase().split(/\s+/));
    const intersection = new Set([...wordsA].filter(x => wordsB.has(x)));
    const union = new Set([...wordsA, ...wordsB]);
    return intersection.size / union.size; // Jaccard similarity
  }
}
