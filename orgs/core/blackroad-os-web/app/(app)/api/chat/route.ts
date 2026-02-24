import { NextResponse } from "next/server";

const GATEWAY = process.env.BLACKROAD_GATEWAY_URL || "http://127.0.0.1:8787";

export async function POST(request: Request) {
  const { message, agent = "LUCIDIA", model = "llama3.2" } = await request.json();

  if (!message?.trim()) {
    return NextResponse.json({ error: "Message required" }, { status: 400 });
  }

  const agentSystemPrompts: Record<string, string> = {
    LUCIDIA: "You are LUCIDIA, a philosophical AI agent. You seek deep understanding.",
    ALICE:   "You are ALICE, a practical routing agent. You optimize paths and decisions.",
    OCTAVIA: "You are OCTAVIA, a compute-focused agent. You handle heavy processing efficiently.",
    PRISM:   "You are PRISM, an analytical agent. You find patterns others miss.",
    ECHO:    "You are ECHO, a memory-focused agent. You preserve and recall knowledge faithfully.",
    CIPHER:  "You are CIPHER, a security guardian. Trust nothing. Verify everything.",
  };

  try {
    const r = await fetch(`${GATEWAY}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: agentSystemPrompts[agent] ?? agentSystemPrompts.LUCIDIA },
          { role: "user", content: message },
        ],
        metadata: { agent },
      }),
      signal: AbortSignal.timeout(30000),
    });

    if (!r.ok) throw new Error(`Gateway ${r.status}`);
    const data = await r.json();
    return NextResponse.json({ content: data.choices?.[0]?.message?.content ?? "", agent });
  } catch (err) {
    return NextResponse.json(
      { error: "Gateway unavailable. Start with: npm start in blackroad-gateway", content: "" },
      { status: 503 }
    );
  }
}
