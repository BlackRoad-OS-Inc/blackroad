import type { Config } from "tailwindcss";

export default {
  content: ["./src/**/*.{tsx,ts,jsx,js}", "./index.html"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        hotpink: "#FF1D6C",
        amber: "#F5A623",
        electricblue: "#2979FF",
        violet: "#9C27B0",
        surface: "#0A0A0A",
        "surface-elevated": "#1A1A1A",
        muted: "#666666",
        background: "#000000",
      },
      fontFamily: {
        mono: ['"JetBrains Mono"', '"SF Mono"', '"Fira Code"', "monospace"],
      },
      boxShadow: {
        glow: "0 0 40px rgba(255, 29, 108, 0.3)",
        "glow-blue": "0 0 40px rgba(41, 121, 255, 0.3)",
      },
    },
  },
  plugins: [],
} satisfies Config;
