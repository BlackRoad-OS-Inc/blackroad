"use client";

import { useState } from "react";

interface Setting {
  key: string;
  label: string;
  description: string;
  type: "toggle" | "text" | "select";
  value: boolean | string;
  options?: string[];
}

const SETTINGS: Setting[] = [
  { key: "tokenless_mode",  label: "Tokenless Gateway",      description: "Route all AI calls through gateway (never expose keys to agents)",  type: "toggle", value: true },
  { key: "ps_sha_memory",   label: "PS-SHA∞ Memory",         description: "Hash-chain all state mutations for tamper detection",               type: "toggle", value: true },
  { key: "trinary_logic",   label: "Trinary Logic",          description: "Use 1/0/-1 truth states instead of boolean",                       type: "toggle", value: true },
  { key: "edge_rate_limit", label: "Edge Rate Limiting",      description: "100 req/min per IP via Cloudflare KV",                             type: "toggle", value: true },
  { key: "default_model",   label: "Default Model",          description: "Model used by agents when none specified",                          type: "select", value: "qwen2.5:7b", options: ["qwen2.5:7b", "llama3.2:3b", "deepseek-r1:7b", "mistral:7b"] },
  { key: "gateway_url",     label: "Gateway URL",            description: "BlackRoad Gateway endpoint",                                        type: "text",   value: "http://127.0.0.1:8787" },
];

export default function SettingsPage() {
  const [settings, setSettings] = useState(SETTINGS);
  const [saved, setSaved] = useState(false);

  const update = (key: string, value: boolean | string) => {
    setSettings(s => s.map(x => x.key === key ? { ...x, value } : x));
    setSaved(false);
  };

  const save = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  return (
    <div style={{ background: "#000", minHeight: "100vh", padding: "32px", color: "#fff", fontFamily: "-apple-system, sans-serif", maxWidth: "720px" }}>
      <h1 style={{ fontSize: "24px", fontWeight: 700, marginBottom: "8px" }}>Settings</h1>
      <p style={{ color: "#666", marginBottom: "32px" }}>Configure your BlackRoad OS instance</p>

      <div style={{ display: "grid", gap: "12px" }}>
        {settings.map(s => (
          <div key={s.key} style={{ background: "#111", border: "1px solid #222", borderRadius: "10px", padding: "16px 20px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ flex: 1, marginRight: "24px" }}>
              <div style={{ fontWeight: 600 }}>{s.label}</div>
              <div style={{ color: "#666", fontSize: "12px", marginTop: "2px" }}>{s.description}</div>
            </div>
            {s.type === "toggle" && (
              <div onClick={() => update(s.key, !(s.value as boolean))} style={{
                width: "44px", height: "24px", borderRadius: "12px",
                background: s.value ? "#FF1D6C" : "#333",
                cursor: "pointer", position: "relative", transition: "background 0.2s", flexShrink: 0,
              }}>
                <div style={{
                  position: "absolute", top: "3px",
                  left: s.value ? "23px" : "3px",
                  width: "18px", height: "18px", borderRadius: "50%",
                  background: "#fff", transition: "left 0.2s",
                }} />
              </div>
            )}
            {s.type === "text" && (
              <input
                value={s.value as string}
                onChange={e => update(s.key, e.target.value)}
                style={{ background: "#000", border: "1px solid #333", color: "#fff", padding: "6px 10px", borderRadius: "6px", fontSize: "13px", width: "200px" }}
              />
            )}
            {s.type === "select" && (
              <select value={s.value as string} onChange={e => update(s.key, e.target.value)}
                style={{ background: "#000", border: "1px solid #333", color: "#fff", padding: "6px 10px", borderRadius: "6px", fontSize: "13px" }}>
                {s.options?.map(o => <option key={o} value={o}>{o}</option>)}
              </select>
            )}
          </div>
        ))}
      </div>

      <button onClick={save} style={{
        marginTop: "24px",
        background: saved ? "#1a3a1a" : "linear-gradient(135deg, #FF1D6C, #9C27B0)",
        border: "none", color: "#fff", padding: "12px 32px",
        borderRadius: "8px", fontSize: "15px", fontWeight: 600, cursor: "pointer",
      }}>
        {saved ? "✓ Saved" : "Save Settings"}
      </button>
    </div>
  );
}
