"use client";

import { useState } from "react";

interface PiNode {
  name: string;
  ip: string;
  role: string;
  agents: number;
  status: "online" | "offline";
  temp?: string;
  load?: string;
  uptime?: string;
}

const NODES: PiNode[] = [
  { name: "blackroad-pi",  ip: "192.168.4.64", role: "CF Tunnel",  agents: 7500,  status: "online", temp: "52°C", load: "0.42", uptime: "14 days" },
  { name: "aria64",        ip: "192.168.4.38", role: "Primary",    agents: 22500, status: "online", temp: "61°C", load: "1.87", uptime: "30 days" },
  { name: "alice",         ip: "192.168.4.49", role: "Secondary",  agents: 0,     status: "online", temp: "44°C", load: "0.12", uptime: "7 days" },
  { name: "lucidia-alt",   ip: "192.168.4.99", role: "Backup",     agents: 0,     status: "offline" },
];

export default function FleetPage() {
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <div style={{ background: "#000", minHeight: "100vh", padding: "32px", color: "#fff", fontFamily: "-apple-system, sans-serif" }}>
      <h1 style={{ fontSize: "24px", fontWeight: 700, marginBottom: "8px" }}>Pi Fleet</h1>
      <p style={{ color: "#666", marginBottom: "32px" }}>Raspberry Pi node management</p>

      <div style={{ display: "grid", gap: "12px" }}>
        {NODES.map(node => (
          <div
            key={node.name}
            onClick={() => setSelected(selected === node.name ? null : node.name)}
            style={{
              background: "#111",
              border: selected === node.name ? "1px solid #FF1D6C" : "1px solid #222",
              borderRadius: "10px",
              padding: "16px 20px",
              cursor: "pointer",
              transition: "border-color 0.2s",
            }}
          >
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <div style={{
                  width: "10px", height: "10px", borderRadius: "50%",
                  background: node.status === "online" ? "#4CAF50" : "#F44336",
                  boxShadow: node.status === "online" ? "0 0 8px #4CAF50" : "none",
                }} />
                <div>
                  <div style={{ fontWeight: 600 }}>{node.name}</div>
                  <div style={{ color: "#666", fontSize: "12px" }}>{node.ip} • {node.role}</div>
                </div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontWeight: 600, color: "#FF1D6C" }}>{node.agents.toLocaleString()}</div>
                <div style={{ color: "#666", fontSize: "12px" }}>agents</div>
              </div>
            </div>

            {selected === node.name && node.status === "online" && (
              <div style={{ marginTop: "16px", paddingTop: "16px", borderTop: "1px solid #222", display: "flex", gap: "24px" }}>
                <Stat label="Temp" value={node.temp || "N/A"} />
                <Stat label="Load" value={node.load || "N/A"} />
                <Stat label="Uptime" value={node.uptime || "N/A"} />
                <div style={{ marginLeft: "auto", display: "flex", gap: "8px" }}>
                  <button style={{ background: "#1a1a2e", border: "1px solid #2979FF", color: "#2979FF", padding: "6px 14px", borderRadius: "6px", cursor: "pointer", fontSize: "13px" }}>
                    SSH
                  </button>
                  <button style={{ background: "#1a1a1a", border: "1px solid #333", color: "#888", padding: "6px 14px", borderRadius: "6px", cursor: "pointer", fontSize: "13px" }}>
                    Deploy
                  </button>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div style={{ fontWeight: 600, fontSize: "15px" }}>{value}</div>
      <div style={{ color: "#666", fontSize: "11px" }}>{label}</div>
    </div>
  );
}
