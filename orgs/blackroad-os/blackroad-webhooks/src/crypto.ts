/**
 * Webhook Signature Verification
 * HMAC-SHA256 signatures for webhook security
 */

// Generate webhook signature
export async function generateSignature(
  payload: string,
  secret: string,
  timestamp: number
): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(`${timestamp}.${payload}`);
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const signature = await crypto.subtle.sign('HMAC', key, data);
  return arrayBufferToHex(signature);
}

// Verify webhook signature
export async function verifySignature(
  payload: string,
  signature: string,
  secret: string,
  timestamp: number,
  toleranceSeconds: number = 300 // 5 minutes
): Promise<{ valid: boolean; error?: string }> {
  // Check timestamp is within tolerance
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - timestamp) > toleranceSeconds) {
    return { valid: false, error: 'Timestamp outside tolerance window' };
  }

  // Generate expected signature
  const expectedSignature = await generateSignature(payload, secret, timestamp);

  // Constant-time comparison
  if (!timingSafeEqual(signature, expectedSignature)) {
    return { valid: false, error: 'Signature mismatch' };
  }

  return { valid: true };
}

// Parse signature header
export function parseSignatureHeader(header: string): { timestamp: number; signature: string } | null {
  // Format: t=1234567890,v1=abc123...
  const parts = header.split(',');
  let timestamp = 0;
  let signature = '';

  for (const part of parts) {
    const [key, value] = part.split('=');
    if (key === 't') {
      timestamp = parseInt(value, 10);
    } else if (key === 'v1') {
      signature = value;
    }
  }

  if (!timestamp || !signature) {
    return null;
  }

  return { timestamp, signature };
}

// Create signature header
export function createSignatureHeader(signature: string, timestamp: number): string {
  return `t=${timestamp},v1=${signature}`;
}

// Generate webhook secret
export function generateSecret(): string {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return 'whsec_' + arrayBufferToHex(array.buffer);
}

// Generate webhook ID
export function generateWebhookId(): string {
  const array = new Uint8Array(16);
  crypto.getRandomValues(array);
  return 'wh_' + arrayBufferToHex(array.buffer);
}

// Generate event ID
export function generateEventId(): string {
  const array = new Uint8Array(16);
  crypto.getRandomValues(array);
  return 'evt_' + arrayBufferToHex(array.buffer);
}

// Generate delivery ID
export function generateDeliveryId(): string {
  const array = new Uint8Array(16);
  crypto.getRandomValues(array);
  return 'del_' + arrayBufferToHex(array.buffer);
}

// Helper: ArrayBuffer to hex string
function arrayBufferToHex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

// Helper: Timing-safe string comparison
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}
