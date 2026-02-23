/**
 * Stripe Webhook Signature Verification
 * Ported from workers/payment-gateway/src/webhook-verify.ts
 * Uses Node.js crypto instead of Web Crypto API.
 */

import { createHmac, timingSafeEqual } from 'node:crypto';

const DEFAULT_TOLERANCE_SECONDS = 300; // 5 minutes

function parseSignatureHeader(header: string): { timestamp: number; signatures: string[] } {
  const parts = header.split(',');
  let timestamp = 0;
  const signatures: string[] = [];

  for (const part of parts) {
    const [key, value] = part.split('=', 2);
    if (key === 't') {
      timestamp = parseInt(value, 10);
    } else if (key === 'v1') {
      signatures.push(value);
    }
  }

  return { timestamp, signatures };
}

function computeSignature(payload: string, timestamp: number, secret: string): string {
  const signedPayload = `${timestamp}.${payload}`;
  return createHmac('sha256', secret).update(signedPayload).digest('hex');
}

function secureCompare(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  try {
    return timingSafeEqual(Buffer.from(a), Buffer.from(b));
  } catch {
    return false;
  }
}

export interface VerifyResult {
  valid: boolean;
  error?: string;
  timestamp?: number;
}

export async function verifyWebhookSignature(
  payload: string,
  sigHeader: string,
  secret: string,
  tolerance: number = DEFAULT_TOLERANCE_SECONDS,
): Promise<VerifyResult> {
  if (!sigHeader) {
    return { valid: false, error: 'Missing Stripe-Signature header' };
  }

  if (!secret) {
    return { valid: false, error: 'Webhook secret not configured' };
  }

  const { timestamp, signatures } = parseSignatureHeader(sigHeader);

  if (!timestamp || signatures.length === 0) {
    return { valid: false, error: 'Invalid signature header format' };
  }

  // Replay attack protection
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - timestamp) > tolerance) {
    return {
      valid: false,
      error: `Timestamp outside tolerance (${tolerance}s). Event age: ${Math.abs(now - timestamp)}s`,
      timestamp,
    };
  }

  const expectedSig = computeSignature(payload, timestamp, secret);

  const matched = signatures.some((sig) => secureCompare(sig, expectedSig));

  if (!matched) {
    return { valid: false, error: 'Signature mismatch', timestamp };
  }

  return { valid: true, timestamp };
}
