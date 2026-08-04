import React from "react";

export function Tabs({ items, value, onChange, variant = "underline", style, ...rest }) {
  const [internal, setInternal] = React.useState(value ?? items?.[0]?.id);
  const active = value ?? internal;
  const select = (id) => { setInternal(id); onChange && onChange(id); };
  const underline = variant === "underline";
  return (
    <div
      role="tablist"
      style={{
        display: "flex",
        gap: underline ? 28 : 4,
        borderBottom: underline ? "1px solid var(--border-subtle)" : "none",
        background: underline ? "transparent" : "var(--surface-sunken)",
        padding: underline ? 0 : 4,
        borderRadius: underline ? 0 : "var(--radius-control)",
        ...style,
      }}
      {...rest}
    >
      {items.map((it) => {
        const on = it.id === active;
        return (
          <button
            key={it.id}
            role="tab"
            aria-selected={on}
            onClick={() => select(it.id)}
            style={{
              border: 0, cursor: "pointer", background: underline ? "none" : on ? "var(--surface-card)" : "transparent",
              fontFamily: "var(--font-sans)", fontSize: "var(--text-xs)",
              letterSpacing: "var(--tracking-wider)", textTransform: "uppercase",
              fontWeight: "var(--weight-medium)",
              color: on ? "var(--text-heading)" : "var(--text-muted)",
              padding: underline ? "0 0 12px" : "8px 16px",
              borderRadius: underline ? 0 : "var(--radius-sm)",
              boxShadow: underline ? (on ? "inset 0 -2px 0 var(--teal-700)" : "none") : on ? "var(--shadow-xs)" : "none",
              transition: "var(--transition-control)",
            }}
          >
            {it.label}
            {it.count != null ? <span style={{ color: "var(--text-subtle)", marginLeft: 6 }}>{it.count}</span> : null}
          </button>
        );
      })}
    </div>
  );
}
