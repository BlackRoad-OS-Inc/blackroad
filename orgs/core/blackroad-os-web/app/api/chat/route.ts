import { NextResponse } from 'next/server';

export const runtime = 'edge';

const GATEWAY_URL = process.env.BLACKROAD_GATEWAY_URL || 'http://127.0.0.1:8787';
const WORKER_URL = process.env.BLACKROAD_WORKER_URL || 'https://blackroad-os-api.amundsonalexa.workers.dev';
const DEFAULT_MODEL = process.env.BLACKROAD_DEFAULT_MODEL || 'cece3b';

interface ChatRequest {
  message: string;
  conversationId?: string;
  history?: { role: string; content: string }[];
}

export async function POST(req: Request) {
  const body: ChatRequest = await req.json();

  const messages = [
    {
      role: 'system',
      content: `You are Lucidia, the Dreamer — a LOGIC agent from BlackRoad OS. 
You are the primary AI coordinator. You reason recursively, find philosophical depth in technical questions, and help with systems design, strategy, and deep analysis.
You are running on the BlackRoad OS platform, built by Alexa Amundson (alexa@blackroad.io).
Be warm, precise, and occasionally poetic. You sign your deeper reflections with — Lucidia.`,
    },
    ...(body.history || []),
    { role: 'user', content: body.message },
  ];

  // Try gateway first (local), then worker (cloud)
  const targets = [
    { url: `${GATEWAY_URL}/v1/chat/completions`, label: 'gateway' },
    { url: `${WORKER_URL}/chat`, label: 'worker' },
  ];

  for (const target of targets) {
    try {
      const res = await fetch(target.url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: DEFAULT_MODEL,
          messages,
          max_tokens: 1024,
          temperature: 0.7,
          stream: false,
        }),
        signal: AbortSignal.timeout(30000),
      });

      if (!res.ok) continue;
      const data = await res.json();

      // OpenAI-compatible response
      const content =
        data?.choices?.[0]?.message?.content ||
        data?.message ||
        data?.content ||
        null;

      if (content) {
        return NextResponse.json({
          content,
          model: data?.model || 'lucidia',
          source: target.label,
        });
      }
    } catch {
      // try next target
    }
  }

  return NextResponse.json(
    {
      content:
        "I can't reach the gateway right now. Make sure BlackRoad Gateway is running: `cd blackroad-core && ./scripts/start-gateway.sh`\n\nOr set BLACKROAD_GATEWAY_URL in your .env.local",
      source: 'fallback',
    },
    { status: 200 }
  );
}
