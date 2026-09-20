const tones = {
  info: { accent: "var(--navy-600)", bg: "var(--surface-navy)", fg: "var(--text-on-navy)" },
  success: { accent: "var(--success-500)", bg: "var(--surface-navy)", fg: "var(--text-on-navy)" },
  warning: { accent: "var(--warning-500)", bg: "var(--surface-navy)", fg: "var(--text-on-navy)" },
  danger: { accent: "var(--danger-500)", bg: "var(--surface-navy)", fg: "var(--text-on-navy)" },
};

export function Toast({ title, message, tone = "info", action, onDismiss, style, ...rest }) {
  const t = tones[tone];
  return (
    <div
      role="status"
      style={{
        display: "flex", alignItems: "flex-start", gap: 12,
        // Bounded by the viewport: a 300px floor overflows a narrow phone.
        minWidth: "min(300px, 100%)", maxWidth: 420,
        background: t.bg, color: t.fg,
        borderRadius: "var(--radius-lg)", boxShadow: "var(--shadow-lg)",
        padding: "14px 16px",
        fontFamily: "var(--font-sans)",
        ...style,
      }}
      {...rest}
    >
      <span style={{ flex: "0 0 auto", width: 3, alignSelf: "stretch", borderRadius: 2, background: t.accent }} />
      <span style={{ flex: 1 }}>
        {title ? <span style={{ display: "block", fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--white)" }}>{title}</span> : null}
        {message ? <span style={{ display: "block", fontSize: "var(--text-sm)", marginTop: 4, opacity: .85 }}>{message}</span> : null}
        {action ? <span style={{ display: "inline-block", marginTop: 10 }}>{action}</span> : null}
      </span>
      {onDismiss ? (
        <button onClick={onDismiss} aria-label="Dismiss" style={{ border: 0, background: "none", color: "inherit", opacity: .6, cursor: "pointer", fontSize: 15, lineHeight: 1, padding: 0 }}>×</button>
      ) : null}
    </div>
  );
}
