import React from "react";

export function Tag({ children, icon, selected = false, onRemove, onClick, style, ...rest }) {
  const [hover, setHover] = React.useState(false);
  const clickable = !!onClick;
  return (
    <span
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        display: "inline-flex", alignItems: "center", gap: 6,
        fontFamily: "var(--font-sans)", fontSize: "var(--text-sm)",
        letterSpacing: "var(--tracking-wide)",
        padding: "6px 12px",
        borderRadius: "var(--radius-pill)",
        cursor: clickable ? "pointer" : "default",
        transition: "var(--transition-control)",
        background: selected ? "var(--teal-100)" : hover && clickable ? "var(--surface-navy-tint)" : "var(--surface-card)",
        color: selected ? "var(--teal-800)" : "var(--text-body)",
        border: selected ? "1.5px solid var(--teal-600)" : "1px solid var(--border-default)",
        ...style,
      }}
      {...rest}
    >
      {icon}
      {children}
      {onRemove ? (
        <button
          onClick={(e) => { e.stopPropagation(); onRemove(e); }}
          aria-label="Remove"
          style={{ border: 0, background: "none", padding: 0, marginLeft: 2, cursor: "pointer", color: "var(--text-subtle)", fontSize: 14, lineHeight: 1 }}
        >×</button>
      ) : null}
    </span>
  );
}
