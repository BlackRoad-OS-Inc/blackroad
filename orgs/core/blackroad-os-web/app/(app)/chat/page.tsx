"use client";
import { useState, useRef, useEffect } from "react";

const AGENTS = ["LUCIDIA", "ALICE", "OCTAVIA", "PRISM", "ECHO", "CIPHER"] as const;
type Agent = typeof AGENTS[number];

const AGENT_COLORS: Record<Agent, string> = {
  LUCIDIA: "#9C27B0", ALICE: "#2979FF", OCTAVIA: "#F5A623",
  PRISM: "#00BCD4",   ECHO: "#4CAF50",  CIPHER: "#FF1D6C",
};

interface Message { role: "user" | "assistant"; content: string; agent?: Agent; }

export default function ChatPage() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [agent, setAgent] = useState<Agent>("LUCIDIA");
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: "smooth" }); }, [messages]);

  async function send() {
    if (!input.trim() || loading) return;
    const userMsg: Message = { role: "user", content: input };
    setMessages(m => [...m, userMsg]);
    setInput("");
    setLoading(true);

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: input, agent }),
      });
      const data = await res.json();
      setMessages(m => [...m, { role: "assistant", content: data.content, agent }]);
    } catch {
      setMessages(m => [...m, { role: "assistant", content: "Connection error. Is the gateway running?", agent }]);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-col h-screen bg-black text-white">
      {/* Header */}
      <div className="border-b border-white/10 p-4 flex items-center gap-4">
        <h1 className="text-lg font-bold">Agent Chat</h1>
        <div className="flex gap-2">
          {AGENTS.map(a => (
            <button key={a} onClick={() => setAgent(a)}
              className="px-3 py-1 rounded-full text-xs font-bold transition-all"
              style={{
                background: agent === a ? AGENT_COLORS[a] : "transparent",
                border: `1px solid ${AGENT_COLORS[a]}`,
                color: agent === a ? "#fff" : AGENT_COLORS[a],
              }}>
              {a}
            </button>
          ))}
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && (
          <div className="text-center text-white/40 mt-20">
            <p className="text-4xl mb-4">💜</p>
            <p>Select an agent and start chatting</p>
            <p className="text-sm mt-2">Current: <span style={{ color: AGENT_COLORS[agent] }}>{agent}</span></p>
          </div>
        )}
        {messages.map((msg, i) => (
          <div key={i} className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}>
            <div className={`max-w-2xl rounded-2xl px-4 py-3 ${msg.role === "user" ? "bg-white/10" : "bg-white/5 border border-white/10"}`}>
              {msg.role === "assistant" && msg.agent && (
                <p className="text-xs font-bold mb-1" style={{ color: AGENT_COLORS[msg.agent as Agent] }}>
                  {msg.agent}
                </p>
              )}
              <p className="text-sm leading-relaxed whitespace-pre-wrap">{msg.content}</p>
            </div>
          </div>
        ))}
        {loading && (
          <div className="flex justify-start">
            <div className="rounded-2xl px-4 py-3 bg-white/5 border border-white/10">
              <p className="text-xs font-bold mb-1" style={{ color: AGENT_COLORS[agent] }}>{agent}</p>
              <p className="text-sm text-white/40">Thinking…</p>
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      {/* Input */}
      <div className="border-t border-white/10 p-4 flex gap-3">
        <input
          value={input} onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === "Enter" && !e.shiftKey && (e.preventDefault(), send())}
          placeholder={`Message ${agent}…`} disabled={loading}
          className="flex-1 bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-sm outline-none focus:border-white/30 disabled:opacity-50" />
        <button onClick={send} disabled={loading || !input.trim()}
          className="px-6 py-3 rounded-xl text-sm font-bold disabled:opacity-40 transition-opacity"
          style={{ background: AGENT_COLORS[agent] }}>
          Send
        </button>
      </div>
    </div>
  );
}
