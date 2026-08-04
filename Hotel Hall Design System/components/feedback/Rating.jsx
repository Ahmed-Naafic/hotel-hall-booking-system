import React from "react";

/** Star rating. The one place a filled icon is allowed, in gold. */
export function Rating({ value = 0, max = 5, size = 16, count, label, style, ...rest }) {
  const stars = Array.from({ length: max }, (_, i) => {
    const fill = Math.max(0, Math.min(1, value - i));
    return (
      <span key={i} style={{ position: "relative", display: "inline-block", width: size, height: size, lineHeight: 1 }}>
        <span style={{ position: "absolute", inset: 0, color: "var(--gray-300)", fontSize: size, lineHeight: 1 }}>★</span>
        <span style={{ position: "absolute", inset: 0, overflow: "hidden", width: `${fill * 100}%`, color: "var(--gold-600)", fontSize: size, lineHeight: 1 }}>★</span>
      </span>
    );
  });
  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 6, fontFamily: "var(--font-sans)", ...style }} {...rest}>
      <span style={{ display: "inline-flex", gap: 2 }}>{stars}</span>
      {label !== false ? <span style={{ fontSize: "var(--text-sm)", color: "var(--text-body)" }}>{value.toFixed(1)}</span> : null}
      {count != null ? <span style={{ fontSize: "var(--text-sm)", color: "var(--text-muted)" }}>({count})</span> : null}
    </span>
  );
}
