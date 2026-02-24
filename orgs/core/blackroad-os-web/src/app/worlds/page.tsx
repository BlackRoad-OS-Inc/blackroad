"use client";
import { useEffect, useState } from "react";

interface WorldArtifact {
  id: string;
  filename: string;
  date: string;
  type: string;
  name: string;
  url: string;
  content?: string;
}

const TYPE_COLOR: Record<string, string> = {
  world: "#F5A623",
  lore:  "#9C27B0",
  code:  "#2979FF",
};

const TYPE_ICON: Record<string, string> = {
  world: "🌍",
  lore:  "📜",
  code:  "⚡",
};

function ArtifactCard({ artifact }: { artifact: WorldArtifact }) {
  const color = TYPE_COLOR[artifact.type] ?? "#FF1D6C";
  const icon  = TYPE_ICON[artifact.type]  ?? "✨";
  return (
    <div style={{
      border: `1px solid ${color}33`,
      borderLeft: `3px solid ${color}`,
      borderRadius: 8,
      padding: "1rem 1.25rem",
      background: "#0a0a0a",
      display: "flex",
      flexDirection: "column",
      gap: 6,
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <span style={{ fontSize: 20 }}>{icon}</span>
        <span style={{ color, fontWeight: 600, textTransform: "capitalize", fontSize: 13 }}>
          {artifact.type}
        </span>
        <span style={{ color: "#666", fontSize: 11, marginLeft: "auto" }}>
          {artifact.date}
        </span>
      </div>
      <div style={{ color: "#e0e0e0", fontWeight: 500, fontSize: 14 }}>
        {artifact.name.replace(/-/g, " ")}
      </div>
      <a
        href={artifact.url}
        target="_blank"
        rel="noopener noreferrer"
        style={{ color: "#2979FF", fontSize: 12, textDecoration: "none" }}
      >
        View on GitHub →
      </a>
    </div>
  );
}

export default function WorldsPage() {
  const [artifacts, setArtifacts] = useState<WorldArtifact[]>([]);
  const [loading, setLoading]     = useState(true);
  const [filter, setFilter]       = useState("all");

  useEffect(() => {
    fetch("/api/worlds")
      .then((r) => r.json())
      .then((data) => {
        setArtifacts(Array.isArray(data) ? data : data.worlds ?? []);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const filtered = filter === "all"
    ? artifacts
    : artifacts.filter((a) => a.type === filter);

  return (
    <div style={{ padding: "2rem", maxWidth: 900, margin: "0 auto", fontFamily: "system-ui" }}>
      {/* Header */}
      <div style={{ marginBottom: "2rem" }}>
        <h1 style={{
          fontSize: 32, fontWeight: 700, margin: 0,
          background: "linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0, #2979FF)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
        }}>
          🌍 World Engine
        </h1>
        <p style={{ color: "#888", marginTop: 6, fontSize: 14 }}>
          AI-generated artifacts from the BlackRoad Pi fleet — updating every 3 minutes
        </p>
      </div>

      {/* Stats */}
      <div style={{ display: "flex", gap: 12, marginBottom: "1.5rem", flexWrap: "wrap" }}>
        {["all", "world", "lore", "code"].map((t) => {
          const count = t === "all" ? artifacts.length
            : artifacts.filter((a) => a.type === t).length;
          const color = t === "all" ? "#FF1D6C" : (TYPE_COLOR[t] ?? "#666");
          return (
            <button
              key={t}
              onClick={() => setFilter(t)}
              style={{
                padding: "6px 16px",
                borderRadius: 20,
                border: `1px solid ${filter === t ? color : "#333"}`,
                background: filter === t ? `${color}22` : "transparent",
                color: filter === t ? color : "#888",
                cursor: "pointer",
                fontSize: 13,
                fontWeight: filter === t ? 600 : 400,
              }}
            >
              {t === "all" ? "All" : `${TYPE_ICON[t]} ${t}`} ({count})
            </button>
          );
        })}
        <div style={{ marginLeft: "auto", color: "#444", fontSize: 12, alignSelf: "center" }}>
          {loading ? "⟳ Loading..." : `${artifacts.length} artifacts`}
        </div>
      </div>

      {/* Grid */}
      {loading ? (
        <div style={{ color: "#555", textAlign: "center", padding: "3rem" }}>
          Loading worlds from Pi fleet…
        </div>
      ) : filtered.length === 0 ? (
        <div style={{ color: "#555", textAlign: "center", padding: "3rem" }}>
          No {filter} artifacts yet. Pi is generating…
        </div>
      ) : (
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))",
          gap: 12,
        }}>
          {filtered.map((a) => <ArtifactCard key={a.id} artifact={a} />)}
        </div>
      )}

      {/* Live indicator */}
      <div style={{ marginTop: "2rem", display: "flex", alignItems: "center", gap: 8 }}>
        <div style={{
          width: 8, height: 8, borderRadius: "50%",
          background: "#4CAF50",
          boxShadow: "0 0 6px #4CAF50",
          animation: "pulse 2s infinite",
        }} />
        <span style={{ color: "#555", fontSize: 12 }}>
          Pi fleet active · aria64 (octavia) · auto-pushes to GitHub every 5 min
        </span>
      </div>
    </div>
  );
}
