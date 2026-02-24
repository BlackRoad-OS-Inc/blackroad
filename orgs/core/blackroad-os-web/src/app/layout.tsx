import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "BlackRoad OS",
  description: "Your AI. Your Hardware. Your Rules.",
};

const NAV = [
  { href: "/dashboard", label: "Dashboard", icon: "⬡" },
  { href: "/worlds",    label: "Worlds",    icon: "🌍" },
  { href: "/fleet",     label: "Fleet",     icon: "🍓" },
  { href: "/memory",    label: "Memory",    icon: "💾" },
  { href: "/settings",  label: "Settings",  icon: "⚙" },
];

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, background: "#050505", color: "#e0e0e0",
        fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif",
        minHeight: "100vh", display: "flex", flexDirection: "column" }}>

        <nav style={{
          display: "flex", alignItems: "center",
          borderBottom: "1px solid #1a1a1a",
          padding: "0 1.5rem", height: 52,
          position: "sticky", top: 0,
          background: "#050505cc", backdropFilter: "blur(12px)", zIndex: 100,
        }}>
          <Link href="/" style={{ textDecoration: "none", marginRight: "1.5rem" }}>
            <span style={{
              fontWeight: 800, fontSize: 15, letterSpacing: "0.05em",
              background: "linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0, #2979FF)",
              WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent",
            }}>BLACKROAD OS</span>
          </Link>

          <div style={{ display: "flex", gap: 4, flex: 1 }}>
            {NAV.map(({ href, label, icon }) => (
              <Link key={href} href={href} style={{
                display: "flex", alignItems: "center", gap: 6,
                padding: "6px 12px", borderRadius: 6,
                textDecoration: "none", color: "#777", fontSize: 13, fontWeight: 500,
              }}>
                <span>{icon}</span><span>{label}</span>
              </Link>
            ))}
          </div>

          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ width: 7, height: 7, borderRadius: "50%",
              background: "#4CAF50", boxShadow: "0 0 6px #4CAF50" }} />
            <span style={{ color: "#555", fontSize: 11 }}>Pi fleet online</span>
          </div>
        </nav>

        <main style={{ flex: 1 }}>{children}</main>

        <footer style={{
          borderTop: "1px solid #111", padding: "1rem 1.5rem",
          display: "flex", justifyContent: "space-between",
        }}>
          <span style={{ color: "#333", fontSize: 11 }}>
            © 2026 BlackRoad OS, Inc. — All rights reserved.
          </span>
          <span style={{ color: "#333", fontSize: 11 }}>aria64 + alice</span>
        </footer>
      </body>
    </html>
  );
}
