import React from "react";

export function Checkbox({ label, description, checked, defaultChecked, onChange, disabled, style, ...rest }) {
  const [internal, setInternal] = React.useState(defaultChecked || false);
  const on = checked ?? internal;
  const toggle = () => {
    if (disabled) return;
    setInternal(!on);
    onChange && onChange(!on);
  };
  return (
    <label
      onClick={toggle}
      style={{ display: "flex", gap: 10, alignItems: description ? "flex-start" : "center", fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: disabled ? "var(--action-disabled-text)" : "var(--text-body)", cursor: disabled ? "not-allowed" : "pointer", ...style }}
      {...rest}
    >
      <span style={{
        flex: "0 0 auto", width: 18, height: 18, marginTop: description ? 2 : 0,
        borderRadius: "var(--radius-xs)",
        border: `1.5px solid ${on ? "var(--teal-700)" : "var(--border-default)"}`,
        background: disabled ? "var(--action-disabled-bg)" : on ? "var(--teal-700)" : "var(--surface-card)",
        color: "#fff", display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 12, lineHeight: 1, transition: "var(--transition-control)",
      }}>{on ? "✓" : ""}</span>
      <span>
        {label}
        {description ? <span style={{ display: "block", fontSize: "var(--text-sm)", color: "var(--text-muted)", marginTop: 2 }}>{description}</span> : null}
      </span>
    </label>
  );
}
