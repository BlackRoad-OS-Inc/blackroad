"use client";

import { useState, useEffect } from "react";

interface Agent {
  name: string;
  type: string;
  status: "online" | "offline" | "busy";
  tasks_today: number;
  uptime: number;
}

const AGENT_COLORS: Record<string, string> = {
  LUCIDIA: "#2979FF",
  ALICE:   "#FF1D6C",
  OCTAVIA: "#F5A623",
  PRISM:   "#9C27B0",
  ECHO:    "#00BCD4",
  CIPHER:  "#4CAF50",
};

export default function AgentDashboard() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [totalTasks, setTotalTasks] = useState(0);

  useEffect(() => {
    const mock: Agent[] = [
      { name: "LUCIDIA", type: "LOGIC",    status: "online", tasks_today: 847,  uptime: 99.9 },
      { name: "CIPHER",  type: "SECURITY", status: "online", tasks_today: 932,  uptime: 99.99 },
      { name: "ALICE",   type: "GATEWAY",  status: "busy",   tasks_today: 1243, uptime: 99.95 },
      { name: "OCTAVIA", type: "COMPUTE",  status: "online", tasks_today: 689,  uptime: 99.9 },
      { name: "ECHO",    type: "MEMORY",   status: "online", tasks_today: 612,  uptime: 99.99 },
      { name: "PRISM",   type: "SOUL",     status: "online", tasks_today: 534,  uptime: 99.95 },
    ];
    setAgents(mock);
    setTotalTasks(mock.reduce((s, a) => s + a.tasks_today, 0));
  }, []);

  return (
    <div style={{ background: "#000", minHeight: "100vh", padding: "32px", color: "#fff", fontFamily: "-apple-system, BlinkMacSystemFont, sans-serif" }}>
      {/* Header */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
        <div>
          <h1 style={{ fontSize: "28px", fontWeight: 700, margin: 0 }}>
            <span style={{ background: "linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
              BlackRoad OS
            </span>
          </h1>
          <p style={{ margin: "4px 0 0", color: "#888", fontSize: "14px" }}>Agent Control Center</p>
        </div>
        <div style={{ textAlign: "right" }}>
          <div style={{ fontSize: "32px", fontWeight: 700, color: "#FF1D6C" }}>{totalTasks.toLocaleString()}</div>
          <div style={{ color: "#888", fontSize: "12px" }}>Tasks Today</div>
        </div>
      </div>

      {/* Agent Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: "16px" }}>
        {agents.map((agent) => (
          <div key={agent.name} style={{
            background: "#111",
            border: "1px solid #222",
            borderRadius: "12px",
            padding: "20px",
            borderLeft: `4px solid ${AGENT_COLORS[agent.name] || "#444"}`,
          }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: "18px" }}>{agent.name}</div>
                <div style={{ color: "#888", fontSize: "12px", marginTop: "2px" }}>{agent.type}</div>
              </div>
              <span style={{
                background: agent.status === "online" ? "#1a3a1a" : agent.status === "busy" ? "#3a2a0a" : "#3a1a1a",
                color: agent.status === "online" ? "#4CAF50" : agent.status === "busy" ? "#FF9800" : "#F44336",
                padding: "4px 10px",
                borderRadius: "20px",
                fontSize: "12px",
                fontWeight: 600,
              }}>
                {agent.status.toUpperCase()}
              </span>
            </div>
            <div style={{ marginTop: "16px", display: "flex", gap: "24px" }}>
              <div>
                <div style={{ fontSize: "22px", fontWeight: 700, color: AGENT_COLORS[agent.name] }}>
                  {agent.tasks_today.toLocaleString()}
                </div>
                <div style={{ color: "#666", fontSize: "11px" }}>tasks today</div>
              </div>
              <div>
                <div style={{ fontSize: "22px", fontWeight: 700 }}>{agent.uptime}%</div>
                <div style={{ color: "#666", fontSize: "11px" }}>uptime</div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Stats Bar */}
      <div style={{ marginTop: "32px", display: "flex", gap: "16px", flexWrap: "wrap" }}>
        {[
          { label: "Total Agents", value: "30,000", color: "#FF1D6C" },
          { label: "Online", value: agents.filter(a => a.status !== "offline").length.toString(), color: "#4CAF50" },
          { label: "Requests/s", value: "1,247", color: "#2979FF" },
          { label: "Avg Latency", value: "42ms", color: "#F5A623" },
        ].map(stat => (
          <div key={stat.label} style={{ background: "#111", border: "1px solid #222", borderRadius: "8px", padding: "12px 20px", flex: "1", minWidth: "120px" }}>
            <div style={{ fontSize: "24px", fontWeight: 700, color: stat.color }}>{stat.value}</div>
            <div style={{ color: "#666", fontSize: "11px", marginTop: "2px" }}>{stat.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
