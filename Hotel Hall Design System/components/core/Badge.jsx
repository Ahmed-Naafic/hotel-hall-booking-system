import React from "react";

const tones = {
  navy: { background: "var(--navy-100)", color: "var(--navy-700)" },
  teal: { background: "var(--teal-100)", color: "var(--teal-800)" },
  gold: { background: "var(--gold-200)", color: "var(--gold-900)" },
  success: { background: "var(--success-100)", color: "var(--success-700)" },
  warning: { background: "var(--warning-100)", color: "var(--warning-700)" },
  danger: { background: "var(--danger-100)", color: "var(--danger-700)" },
  neutral: { background: "var(--gray-100)", color: "var(--gray-600)" },
  solid: { background: "var(--surface-navy)", color: "var(--text-inverse)" },
};

export function Badge({ children, tone = "navy", size = "md", style, ...rest }) {
  return (
    <span
      style={{
        display: "inline-flex", alignItems: "center", gap: 5,
        fontFamily: "var(--font-sans)",
        fontSize: size === "sm" ? "var(--text-2xs)" : "var(--text-xs)",
        fontWeight: "var(--weight-medium)",
        letterSpacing: "var(--tracking-wider)",
        textTransform: "uppercase",
        padding: size === "sm" ? "3px 8px" : "4px 10px",
        borderRadius: "var(--radius-sm)",
        ...tones[tone],
        ...style,
      }}
      {...rest}
    >
      {children}
    </span>
  );
}
