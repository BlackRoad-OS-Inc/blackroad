/**
 * Card — Brand-compliant card with agent colors
 */
import React from "react";

type AgentColor = "lucidia" | "alice" | "octavia" | "prism" | "echo" | "cipher";

interface CardProps {
  title?: string;
  subtitle?: string;
  agent?: AgentColor;
  badge?: string;
  footer?: React.ReactNode;
  children: React.ReactNode;
  className?: string;
  onClick?: () => void;
}

const AGENT_COLORS: Record<AgentColor, { border: string; badge: string }> = {
  lucidia: { border: "border-red-500",    badge: "bg-red-500/20 text-red-400"    },
  alice:   { border: "border-blue-500",   badge: "bg-blue-500/20 text-blue-400"  },
  octavia: { border: "border-green-500",  badge: "bg-green-500/20 text-green-400"},
  prism:   { border: "border-yellow-500", badge: "bg-yellow-500/20 text-yellow-400"},
  echo:    { border: "border-purple-500", badge: "bg-purple-500/20 text-purple-400"},
  cipher:  { border: "border-cyan-500",   badge: "bg-cyan-500/20 text-cyan-400"  },
};

export function Card({ title, subtitle, agent, badge, footer, children, className = "", onClick }: CardProps) {
  const agentStyle = agent ? AGENT_COLORS[agent] : null;
  return (
    <div
      onClick={onClick}
      className={[
        "rounded-xl border bg-black/40 backdrop-blur-sm p-5 transition-all duration-200",
        agentStyle?.border ?? "border-white/10",
        onClick ? "cursor-pointer hover:border-[#FF1D6C]/50 hover:shadow-lg hover:shadow-[#FF1D6C]/10" : "",
        className,
      ].join(" ")}
    >
      {(title || badge) && (
        <div className="flex items-start justify-between mb-3">
          <div>
            {title && <h3 className="text-white font-semibold text-lg leading-tight">{title}</h3>}
            {subtitle && <p className="text-white/50 text-sm mt-0.5">{subtitle}</p>}
          </div>
          {badge && (
            <span className={["text-xs px-2 py-1 rounded-full font-medium", agentStyle?.badge ?? "bg-white/10 text-white/60"].join(" ")}>
              {badge}
            </span>
          )}
        </div>
      )}
      <div className="text-white/80">{children}</div>
      {footer && <div className="mt-4 pt-4 border-t border-white/10 text-sm text-white/50">{footer}</div>}
    </div>
  );
}

export default Card;
