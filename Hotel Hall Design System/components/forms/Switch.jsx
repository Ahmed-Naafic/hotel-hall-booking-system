import React from "react";

export function Switch({ label, checked, defaultChecked, onChange, disabled, style, ...rest }) {
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
      style={{ display: "inline-flex", gap: 10, alignItems: "center", fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: disabled ? "var(--action-disabled-text)" : "var(--text-body)", cursor: disabled ? "not-allowed" : "pointer", ...style }}
      {...rest}
    >
      <span
        role="switch"
        aria-checked={on}
        style={{
          width: 40, height: 22, borderRadius: "var(--radius-pill)", padding: 2,
          background: disabled ? "var(--action-disabled-bg)" : on ? "var(--teal-700)" : "var(--gray-300)",
          transition: `background-color var(--dur-fast) var(--ease-standard)`,
          display: "inline-flex", alignItems: "center",
        }}
      >
        <span style={{
          width: 18, height: 18, borderRadius: "var(--radius-pill)", background: "var(--white)",
          boxShadow: "var(--shadow-xs)",
          transform: on ? "translateX(18px)" : "translateX(0)",
          transition: `transform var(--dur-fast) var(--ease-standard)`,
        }} />
      </span>
      {label}
    </label>
  );
}
