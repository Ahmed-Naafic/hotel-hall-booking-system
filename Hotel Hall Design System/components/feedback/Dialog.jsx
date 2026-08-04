import React from "react";

export function Dialog({ open = true, title, eyebrow, children, footer, onClose, width = 480, style, ...rest }) {
  if (!open) return null;
  return (
    <div
      style={{
        position: "absolute", inset: 0, zIndex: 40,
        background: "var(--surface-overlay)",
        display: "flex", alignItems: "center", justifyContent: "center", padding: 24,
        animation: `hhFade var(--dur-slow) var(--ease-standard)`,
      }}
      onClick={onClose}
    >
      <style>{"@keyframes hhFade{from{opacity:0}to{opacity:1}}@keyframes hhRise{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}"}</style>
      <div
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
        style={{
          width, maxWidth: "100%", background: "var(--surface-card)",
          borderRadius: "var(--radius-modal)", boxShadow: "var(--shadow-modal)",
          animation: `hhRise var(--dur-slow) var(--ease-standard)`,
          overflow: "hidden", ...style,
        }}
        {...rest}
      >
        <div style={{ padding: "var(--card-pad-lg)", paddingBottom: 0 }}>
          {eyebrow ? <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--eyebrow-size)", letterSpacing: "var(--eyebrow-tracking)", textTransform: "uppercase", color: "var(--text-gold)", marginBottom: 10 }}>{eyebrow}</div> : null}
          {title ? <div style={{ fontFamily: "var(--font-display)", textTransform: "uppercase", letterSpacing: "var(--display-tracking)", fontSize: "var(--display-sm)", color: "var(--text-heading)", lineHeight: 1.15 }}>{title}</div> : null}
          <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: "var(--text-body)", marginTop: 12 }}>{children}</div>
        </div>
        <div style={{ display: "flex", justifyContent: "flex-end", gap: 8, padding: "var(--card-pad-lg)" }}>{footer}</div>
      </div>
    </div>
  );
}
