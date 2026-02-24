import { NextResponse } from "next/server";

const GATEWAY = process.env.BLACKROAD_GATEWAY_URL || "http://127.0.0.1:8787";
const SETTINGS_KEY = "user.settings";

const DEFAULTS = {
  theme: "dark",
  defaultAgent: "LUCIDIA",
  defaultModel: "llama3.2",
  streamingEnabled: true,
  memoryEnabled: true,
  gatewayUrl: GATEWAY,
};

export async function GET() {
  try {
    const r = await fetch(`${GATEWAY}/memory/${SETTINGS_KEY}`, { signal: AbortSignal.timeout(3000) });
    if (r.ok) {
      const data = await r.json();
      return NextResponse.json({ settings: { ...DEFAULTS, ...data.value } });
    }
  } catch { /* gateway not available */ }
  return NextResponse.json({ settings: DEFAULTS });
}

export async function POST(request: Request) {
  const body = await request.json();
  const settings = { ...DEFAULTS, ...body };
  
  // Validate
  const valid = ["dark", "light", "system"].includes(settings.theme)
    && typeof settings.streamingEnabled === "boolean";
  if (!valid) {
    return NextResponse.json({ error: "Invalid settings" }, { status: 400 });
  }

  try {
    await fetch(`${GATEWAY}/memory`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ key: SETTINGS_KEY, value: settings }),
      signal: AbortSignal.timeout(3000),
    });
  } catch { /* non-fatal */ }

  return NextResponse.json({ settings, saved: true });
}
