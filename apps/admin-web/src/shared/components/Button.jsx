import React from "react";

const base = {
  fontFamily: "var(--font-sans)",
  textTransform: "uppercase",
  letterSpacing: "var(--tracking-wider)",
  fontWeight: "var(--weight-medium)",
  border: "1px solid transparent",
  borderRadius: "var(--radius-control)",
  cursor: "pointer",
  display: "inline-flex",
  alignItems: "center",
  justifyContent: "center",
  gap: "var(--control-gap)",
  whiteSpace: "nowrap",
  transition: "var(--transition-control), transform var(--dur-instant) var(--ease-standard)",
};

const sizes = {
  sm: { height: "var(--control-h-sm)", padding: "0 14px", fontSize: "var(--text-2xs)" },
  md: { height: "var(--control-h-md)", padding: "0 var(--control-pad-x)", fontSize: "var(--text-xs)" },
  lg: { height: "var(--control-h-lg)", padding: "0 26px", fontSize: "var(--text-sm)" },
};

const variants = {
  primary: { background: "var(--action-primary)", color: "var(--text-inverse)" },
  accent: { background: "var(--action-accent)", color: "var(--text-inverse)" },
  gold: { background: "var(--action-gold)", color: "var(--navy-800)", boxShadow: "var(--shadow-inset)" },
  secondary: { background: "transparent", color: "var(--text-heading)", borderColor: "var(--border-default)" },
  ghost: { background: "transparent", color: "var(--text-heading)" },
  inverse: { background: "var(--white)", color: "var(--navy-700)" },
};

const hovers = {
  primary: { background: "var(--action-primary-hover)" },
  accent: { background: "var(--action-accent-hover)" },
  gold: { background: "var(--action-gold-hover)" },
  secondary: { background: "var(--surface-navy-tint)", borderColor: "var(--border-strong)" },
  ghost: { background: "var(--surface-navy-tint)" },
  inverse: { background: "var(--navy-050)" },
};

const actives = {
  primary: { background: "var(--action-primary-active)" },
  accent: { background: "var(--action-accent-active)" },
  gold: { background: "var(--action-gold-active)" },
  secondary: { background: "var(--navy-100)" },
  ghost: { background: "var(--navy-100)" },
  inverse: { background: "var(--navy-100)" },
};

export function Button({
  children,
  variant = "primary",
  size = "md",
  disabled = false,
  loading = false,
  fullWidth = false,
  iconLeft,
  iconRight,
  as = "button",
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const [press, setPress] = React.useState(false);
  const Tag = as;
  const off = disabled || loading;
  const s = {
    ...base,
    ...sizes[size],
    ...variants[variant],
    ...(hover && !off ? hovers[variant] : null),
    ...(press && !off ? actives[variant] : null),
    ...(press && !off ? { transform: "scale(var(--press-scale))" } : null),
    ...(off
      ? {
          background: "var(--action-disabled-bg)",
          color: "var(--action-disabled-text)",
          borderColor: "transparent",
          boxShadow: "none",
          cursor: "not-allowed",
        }
      : null),
    ...(fullWidth ? { width: "100%" } : null),
    ...style,
  };
  return (
    <Tag
      style={s}
      disabled={as === "button" ? off : undefined}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => { setHover(false); setPress(false); }}
      onMouseDown={() => setPress(true)}
      onMouseUp={() => setPress(false)}
      {...rest}
    >
      {loading ? <span style={{ letterSpacing: ".2em" }}>• • •</span> : (<>
        {iconLeft}
        {children}
        {iconRight}
      </>)}
    </Tag>
  );
}
