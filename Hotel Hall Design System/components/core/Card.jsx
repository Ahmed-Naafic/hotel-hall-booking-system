import React from "react";

export function Card({
  children,
  image,
  imageAlt = "",
  arch = false,
  featured = false,
  interactive = false,
  padding = "var(--card-pad)",
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const lifted = interactive && hover;
  /* When the caller lays the card out itself (display:grid/flex on style), children are
     rendered directly so that layout applies to them instead of a padding wrapper. */
  const selfLaidOut = style && (style.display === "grid" || style.display === "flex");
  return (
    <div
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        background: featured ? "var(--surface-navy)" : "var(--surface-card)",
        color: featured ? "var(--text-on-navy)" : "var(--text-body)",
        border: featured ? "1px solid transparent" : "1px solid var(--border-subtle)",
        borderRadius: arch ? "var(--arch-top)" : "var(--radius-card)",
        boxShadow: lifted ? "var(--shadow-card-hover)" : "var(--shadow-card)",
        transform: lifted ? "var(--lift-hover)" : "none",
        transition: "var(--transition-card), border-color var(--dur-base) var(--ease-standard)",
        borderColor: lifted && !featured ? "var(--border-strong)" : undefined,
        overflow: "hidden",
        cursor: interactive ? "pointer" : "default",
        ...(selfLaidOut && !image ? { padding } : null),
        ...style,
      }}
      {...rest}
    >
      {image ? (
        <div style={{ overflow: "hidden", aspectRatio: "4 / 3", background: "var(--sand-100)" }}>
          <img src={image} alt={imageAlt} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block", transition: "transform var(--dur-slow) var(--ease-standard)", transform: lifted ? "scale(1.03)" : "none" }} />
        </div>
      ) : null}
      {selfLaidOut && !image ? children : <div style={{ padding }}>{children}</div>}
    </div>
  );
}

export function CardTitle({ children, style, ...rest }) {
  return (
    <div style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-md)", lineHeight: 1.25, color: "inherit", ...style }} {...rest}>
      {children}
    </div>
  );
}

export function CardMeta({ children, style, ...rest }) {
  return (
    <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-sm)", color: "var(--text-muted)", display: "flex", gap: 6, alignItems: "center", flexWrap: "wrap", ...style }} {...rest}>
      {children}
    </div>
  );
}
