import React from "react";

/** Check-in / check-out pair. Cosmetic: a real datepicker is out of scope. */
export function DateField({ label = "Dates", checkIn, checkOut, nights, onClick, size = "md", style, ...rest }) {
  const [hover, setHover] = React.useState(false);
  const h = size === "lg" ? "var(--control-h-lg)" : "var(--control-h-md)";
  const cell = (cap, val) => (
    <span style={{ display: "flex", flexDirection: "column", justifyContent: "center", flex: 1, minWidth: 0, padding: "0 12px" }}>
      <span style={{ fontSize: "var(--text-2xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-subtle)" }}>{cap}</span>
      <span style={{ fontSize: "var(--text-sm)", color: val ? "var(--text-body)" : "var(--text-subtle)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{val || "Add date"}</span>
    </span>
  );
  return (
    <div style={{ fontFamily: "var(--font-sans)", ...style }} {...rest}>
      {label ? <div style={{ fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-muted)", marginBottom: 6 }}>{label}</div> : null}
      <div
        onClick={onClick}
        onMouseEnter={() => setHover(true)}
        onMouseLeave={() => setHover(false)}
        style={{
          display: "flex", alignItems: "stretch", height: `calc(${h} + 8px)`,
          background: "var(--surface-card)",
          border: `1px solid ${hover ? "var(--border-strong)" : "var(--border-default)"}`,
          borderRadius: "var(--radius-control)", cursor: "pointer",
          transition: "var(--transition-control)",
        }}
      >
        {cell("Check in", checkIn)}
        <span style={{ width: 1, background: "var(--border-subtle)", margin: "8px 0" }} />
        {cell("Check out", checkOut)}
        {nights ? (
          <span style={{ display: "flex", alignItems: "center", padding: "0 14px", fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wide)", color: "var(--text-accent)", borderLeft: "1px solid var(--border-subtle)" }}>
            {nights} {nights === 1 ? "night" : "nights"}
          </span>
        ) : null}
      </div>
    </div>
  );
}
