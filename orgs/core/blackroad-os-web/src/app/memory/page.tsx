"use client";

import { useState } from "react";

interface MemoryEntry {
  hash: string;
  prev_hash: string;
  key: string;
  content: string;
  type: "fact" | "observation" | "inference" | "commitment";
  truth_state: 1 | 0 | -1;
  timestamp: string;
}

const MOCK_CHAIN: MemoryEntry[] = [
  { hash: "b3c8f0e9", prev_hash: "GENESIS",  key: "gateway.url",        content: "http://127.0.0.1:8787",                       type: "fact",        truth_state: 1,  timestamp: "2026-02-01T10:00:00Z" },
  { hash: "a7e3dfb7", prev_hash: "b3c8f0e9",  key: "agent.lucidia.role", content: "Primary reasoning coordinator",                type: "fact",        truth_state: 1,  timestamp: "2026-02-01T10:01:22Z" },
  { hash: "110cd92b", prev_hash: "a7e3dfb7",  key: "deploy.railway",     content: "Deployed blackroad-api@0.4.1 to production",   type: "observation", truth_state: 1,  timestamp: "2026-02-05T14:33:07Z" },
  { hash: "32e7558c", prev_hash: "110cd92b",  key: "model.preference",   content: "User prefers qwen2.5:7b for general tasks",    type: "inference",   truth_state: 0,  timestamp: "2026-02-08T09:12:44Z" },
  { hash: "980831ab", prev_hash: "32e7558c",  key: "security.hardened",  content: "CIS Level 1 applied to all Pi nodes",          type: "commitment",  truth_state: 1,  timestamp: "2026-02-10T16:55:12Z" },
];

const TYPE_COLORS = { fact: "#2979FF", observation: "#F5A623", inference: "#9C27B0", commitment: "#FF1D6C" };
const TRUTH_ICONS = { 1: { icon: "✓", color: "#4CAF50" }, 0: { icon: "?", color: "#FF9800" }, "-1": { icon: "✗", color: "#F44336" } };

export default function MemoryPage() {
  const [expanded, setExpanded] = useState<string | null>(null);

  return (
    <div style={{ background: "#000", minHeight: "100vh", padding: "32px", color: "#fff", fontFamily: "-apple-system, sans-serif" }}>
      <h1 style={{ fontSize: "24px", fontWeight: 700, marginBottom: "4px" }}>PS-SHA∞ Memory Chain</h1>
      <p style={{ color: "#666", marginBottom: "32px" }}>Tamper-evident hash-chained knowledge store</p>

      {/* Chain visualization */}
      <div style={{ position: "relative" }}>
        {MOCK_CHAIN.map((entry, i) => {
          const truth = TRUTH_ICONS[String(entry.truth_state) as keyof typeof TRUTH_ICONS];
          return (
            <div key={entry.hash} style={{ display: "flex", gap: "16px", marginBottom: "4px" }}>
              {/* Vertical line */}
              <div style={{ display: "flex", flexDirection: "column", alignItems: "center", width: "24px" }}>
                {i > 0 && <div style={{ width: "2px", height: "16px", background: "#333" }} />}
                <div style={{ width: "12px", height: "12px", borderRadius: "50%", background: TYPE_COLORS[entry.type], flexShrink: 0 }} />
                {i < MOCK_CHAIN.length - 1 && <div style={{ width: "2px", flex: 1, background: "#333" }} />}
              </div>

              {/* Card */}
              <div
                onClick={() => setExpanded(expanded === entry.hash ? null : entry.hash)}
                style={{
                  flex: 1, background: "#111", border: "1px solid #222",
                  borderLeft: `3px solid ${TYPE_COLORS[entry.type]}`,
                  borderRadius: "8px", padding: "12px 16px",
                  cursor: "pointer", marginBottom: "4px",
                }}
              >
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
                    <code style={{ color: TYPE_COLORS[entry.type], fontSize: "12px" }}>{entry.hash}</code>
                    <span style={{ background: "#1a1a1a", padding: "2px 8px", borderRadius: "4px", fontSize: "11px", color: TYPE_COLORS[entry.type] }}>{entry.type}</span>
                    <span style={{ fontWeight: 600 }}>{entry.key}</span>
                  </div>
                  <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
                    <span style={{ color: truth.color, fontSize: "14px", fontWeight: 700 }}>{truth.icon}</span>
                    <span style={{ color: "#444", fontSize: "11px" }}>{new Date(entry.timestamp).toLocaleDateString()}</span>
                  </div>
                </div>

                {expanded === entry.hash && (
                  <div style={{ marginTop: "12px", paddingTop: "12px", borderTop: "1px solid #222" }}>
                    <div style={{ color: "#ccc", marginBottom: "8px" }}>{entry.content}</div>
                    <div style={{ display: "flex", gap: "16px", fontSize: "11px", color: "#555" }}>
                      <span>hash: <code style={{ color: "#888" }}>{entry.hash}</code></span>
                      <span>prev: <code style={{ color: "#888" }}>{entry.prev_hash}</code></span>
                    </div>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Legend */}
      <div style={{ marginTop: "24px", display: "flex", gap: "16px", flexWrap: "wrap" }}>
        {Object.entries(TYPE_COLORS).map(([type, color]) => (
          <div key={type} style={{ display: "flex", alignItems: "center", gap: "6px" }}>
            <div style={{ width: "8px", height: "8px", borderRadius: "50%", background: color }} />
            <span style={{ color: "#666", fontSize: "12px" }}>{type}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
