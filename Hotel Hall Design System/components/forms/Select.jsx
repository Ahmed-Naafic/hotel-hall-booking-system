import React from "react";
import { Field } from "./Input.jsx";

export function Select({ label, hint, error, required, options = [], size = "md", disabled, style, ...rest }) {
  const [focus, setFocus] = React.useState(false);
  const h = size === "sm" ? "var(--control-h-sm)" : size === "lg" ? "var(--control-h-lg)" : "var(--control-h-md)";
  const control = (
    <span style={{ position: "relative", display: "block" }}>
      <select
        disabled={disabled}
        onFocus={() => setFocus(true)}
        onBlur={() => setFocus(false)}
        style={{
          width: "100%", height: h, padding: "0 34px 0 12px",
          appearance: "none",
          fontFamily: "var(--font-sans)", fontSize: size === "sm" ? "var(--text-sm)" : "var(--text-md)",
          color: disabled ? "var(--action-disabled-text)" : "var(--text-body)",
          background: disabled ? "var(--action-disabled-bg)" : "var(--surface-card)",
          border: `1px solid ${error ? "var(--danger-500)" : focus ? "var(--teal-600)" : "var(--border-default)"}`,
          borderRadius: "var(--radius-control)",
          boxShadow: focus ? "var(--shadow-focus)" : "none",
          transition: "var(--transition-control)",
          outline: "none",
          ...style,
        }}
        {...rest}
      >
        {options.map((o) => {
          const v = typeof o === "string" ? o : o.value;
          const l = typeof o === "string" ? o : o.label;
          return <option key={v} value={v}>{l}</option>;
        })}
      </select>
      <span aria-hidden="true" style={{ position: "absolute", right: 12, top: "50%", transform: "translateY(-50%)", pointerEvents: "none", color: "var(--text-subtle)", fontSize: 11 }}>▾</span>
    </span>
  );
  if (!label && !hint && !error) return control;
  return <Field label={label} hint={hint} error={error} required={required}>{control}</Field>;
}
