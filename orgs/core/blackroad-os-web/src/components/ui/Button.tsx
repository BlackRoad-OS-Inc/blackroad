/**
 * Button — Brand-compliant button with variants
 * Uses BlackRoad brand gradient for primary actions.
 */
import React from "react";

type Variant = "primary" | "secondary" | "ghost" | "danger";
type Size = "sm" | "md" | "lg";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  icon?: React.ReactNode;
}

const VARIANTS: Record<Variant, string> = {
  primary:   "bg-gradient-to-r from-amber-500 via-pink-600 to-blue-600 text-white hover:opacity-90 shadow-lg",
  secondary: "border border-[#FF1D6C] text-[#FF1D6C] hover:bg-[#FF1D6C]/10",
  ghost:     "text-white hover:bg-white/10",
  danger:    "bg-red-600 text-white hover:bg-red-700",
};
const SIZES: Record<Size, string> = {
  sm: "px-3 py-1.5 text-sm",
  md: "px-5 py-2.5 text-base",
  lg: "px-8 py-4 text-lg",
};

export function Button({
  variant = "primary", size = "md", loading = false, icon, children, disabled, className = "", ...rest
}: ButtonProps) {
  return (
    <button
      {...rest}
      disabled={disabled || loading}
      className={[
        "inline-flex items-center gap-2 rounded-lg font-semibold transition-all duration-200",
        "focus:outline-none focus:ring-2 focus:ring-[#FF1D6C]/50",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        VARIANTS[variant], SIZES[size], className,
      ].join(" ")}
    >
      {loading ? (
        <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
        </svg>
      ) : icon}
      {children}
    </button>
  );
}

export default Button;
