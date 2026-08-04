import React from "react";

export function Radio({ label, description, checked, name, onChange, disabled, value, style, ...rest }) {
  return (
    <label
      onClick={() => !disabled && onChange && onChange(value)}
      style={{ display: "flex", gap: 10, alignItems: description ? "flex-start" : "center", fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: disabled ? "var(--action-disabled-text)" : "var(--text-body)", cursor: disabled ? "not-allowed" : "pointer", ...style }}
      {...rest}
    >
      <span style={{
        flex: "0 0 auto", width: 18, height: 18, marginTop: description ? 2 : 0, borderRadius: "var(--radius-pill)",
        border: `1.5px solid ${checked ? "var(--teal-700)" : "var(--border-default)"}`,
        background: disabled ? "var(--action-disabled-bg)" : "var(--surface-card)",
        display: "flex", alignItems: "center", justifyContent: "center",
        transition: "var(--transition-control)",
      }}>
        <span style={{ width: 9, height: 9, borderRadius: "var(--radius-pill)", background: checked ? "var(--teal-700)" : "transparent", transition: "var(--transition-control)" }} />
      </span>
      <span>
        {label}
        {description ? <span style={{ display: "block", fontSize: "var(--text-sm)", color: "var(--text-muted)", marginTop: 2 }}>{description}</span> : null}
      </span>
    </label>
  );
}

export function RadioGroup({ label, name, value, options = [], onChange, style }) {
  return (
    <div style={{ fontFamily: "var(--font-sans)", ...style }}>
      {label ? <div style={{ fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-muted)", marginBottom: 10 }}>{label}</div> : null}
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {options.map((o) => (
          <Radio
            key={o.value}
            name={name}
            value={o.value}
            label={o.label}
            description={o.description}
            checked={value === o.value}
            onChange={onChange}
          />
        ))}
      </div>
    </div>
  );
}
