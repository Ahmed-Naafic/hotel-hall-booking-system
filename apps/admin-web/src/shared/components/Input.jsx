import React from "react";

export function Field({ label, hint, error, required, htmlFor, children, style }) {
  return (
    <label htmlFor={htmlFor} style={{ display: "block", fontFamily: "var(--font-sans)", ...style }}>
      {label ? (
        <span style={{ display: "block", fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-muted)", marginBottom: 6 }}>
          {label}{required ? <span style={{ color: "var(--gold-700)" }}> *</span> : null}
        </span>
      ) : null}
      {children}
      {error ? (
        <span style={{ display: "block", fontSize: "var(--text-xs)", color: "var(--danger-700)", marginTop: 6 }}>{error}</span>
      ) : hint ? (
        <span style={{ display: "block", fontSize: "var(--text-xs)", color: "var(--text-subtle)", marginTop: 6 }}>{hint}</span>
      ) : null}
    </label>
  );
}

export function Input({ label, hint, error, required, size = "md", iconLeft, iconRight, disabled, style, wrapperStyle, ...rest }) {
  const [focus, setFocus] = React.useState(false);
  const h = size === "sm" ? "var(--control-h-sm)" : size === "lg" ? "var(--control-h-lg)" : "var(--control-h-md)";
  const box = (
    <span style={{
      display: "flex", alignItems: "center", gap: 8, height: h,
      padding: "0 12px",
      background: disabled ? "var(--action-disabled-bg)" : "var(--surface-card)",
      border: `1px solid ${error ? "var(--danger-500)" : focus ? "var(--teal-600)" : "var(--border-default)"}`,
      borderRadius: "var(--radius-control)",
      boxShadow: focus ? "var(--shadow-focus)" : "none",
      transition: "var(--transition-control)",
      color: "var(--text-subtle)",
      ...wrapperStyle,
    }}>
      {iconLeft}
      <input
        disabled={disabled}
        onFocus={() => setFocus(true)}
        onBlur={() => setFocus(false)}
        style={{
          flex: 1, minWidth: 0, border: 0, outline: "none", background: "transparent",
          fontFamily: "var(--font-sans)", fontSize: size === "sm" ? "var(--text-sm)" : "var(--text-md)",
          color: disabled ? "var(--action-disabled-text)" : "var(--text-body)",
          ...style,
        }}
        {...rest}
      />
      {iconRight}
    </span>
  );
  if (!label && !hint && !error) return box;
  return <Field label={label} hint={hint} error={error} required={required}>{box}</Field>;
}
