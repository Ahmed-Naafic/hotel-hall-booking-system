import React from "react";

const sizes = { sm: 32, md: 40, lg: 48 };
const glyph = { sm: 16, md: 20, lg: 22 };

export function IconButton({
  icon,
  label,
  variant = "ghost",
  size = "md",
  disabled = false,
  round = false,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const tone = {
    ghost: { background: "transparent", color: "var(--text-heading)", border: "1px solid transparent" },
    outline: { background: "var(--surface-card)", color: "var(--text-heading)", border: "1px solid var(--border-default)" },
    solid: { background: "var(--action-primary)", color: "var(--text-inverse)", border: "1px solid transparent" },
    glass: { background: "var(--surface-glass)", color: "var(--navy-800)", border: "1px solid rgba(255,255,255,.5)", backdropFilter: "var(--blur-glass)" },
  }[variant];
  const hoverTone = {
    ghost: { background: "var(--surface-navy-tint)" },
    outline: { borderColor: "var(--border-strong)", background: "var(--surface-navy-tint)" },
    solid: { background: "var(--action-primary-hover)" },
    glass: { background: "rgba(255,255,255,.92)" },
  }[variant];
  return (
    <button
      aria-label={label}
      title={label}
      disabled={disabled}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        width: sizes[size], height: sizes[size], padding: 0,
        display: "inline-flex", alignItems: "center", justifyContent: "center",
        borderRadius: round ? "var(--radius-pill)" : "var(--radius-control)",
        cursor: disabled ? "not-allowed" : "pointer",
        fontSize: glyph[size], lineHeight: 0,
        transition: "var(--transition-control)",
        ...tone,
        ...(hover && !disabled ? hoverTone : null),
        ...(disabled ? { background: "var(--action-disabled-bg)", color: "var(--action-disabled-text)", borderColor: "transparent" } : null),
        ...style,
      }}
      {...rest}
    >
      {icon}
    </button>
  );
}
