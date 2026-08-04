import React from "react";

export function Tooltip({ children, label, placement = "top", style, ...rest }) {
  const [open, setOpen] = React.useState(false);
  const pos = {
    top: { bottom: "calc(100% + 8px)", left: "50%", transform: "translateX(-50%)" },
    bottom: { top: "calc(100% + 8px)", left: "50%", transform: "translateX(-50%)" },
    left: { right: "calc(100% + 8px)", top: "50%", transform: "translateY(-50%)" },
    right: { left: "calc(100% + 8px)", top: "50%", transform: "translateY(-50%)" },
  }[placement];
  return (
    <span
      onMouseEnter={() => setOpen(true)}
      onMouseLeave={() => setOpen(false)}
      onFocus={() => setOpen(true)}
      onBlur={() => setOpen(false)}
      style={{ position: "relative", display: "inline-flex", ...style }}
      {...rest}
    >
      {children}
      <span
        role="tooltip"
        style={{
          position: "absolute", ...pos,
          background: "var(--navy-800)", color: "var(--text-on-navy)",
          fontFamily: "var(--font-sans)", fontSize: "var(--text-xs)",
          letterSpacing: "var(--tracking-wide)",
          padding: "6px 10px", borderRadius: "var(--radius-sm)",
          boxShadow: "var(--shadow-md)", whiteSpace: "nowrap", pointerEvents: "none",
          opacity: open ? 1 : 0,
          transition: `opacity var(--dur-fast) var(--ease-standard)`,
          zIndex: 20,
        }}
      >
        {label}
      </span>
    </span>
  );
}
