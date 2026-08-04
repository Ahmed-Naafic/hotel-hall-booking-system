const { Button, Card, CardTitle, CardMeta, Badge, Tag, Tabs, Switch, Rating, IconButton, Input, Toast } = window.HotelHallDesignSystem_6ae9d5;

function Icon({ name, size = 20, style }) {
  const r = React.useRef(null);
  React.useEffect(() => {
    if (r.current && window.lucide) {
      r.current.innerHTML = "";
      const el = document.createElement("i");
      el.setAttribute("data-lucide", name);
      r.current.appendChild(el);
      window.lucide.createIcons({ attrs: { width: size, height: size, "stroke-width": 1.5 }, nameAttr: "data-lucide" });
    }
  }, [name, size]);
  return <span ref={r} style={{ display: "inline-flex", lineHeight: 0, ...style }} />;
}

function Photo({ label = "Photography", ratio = "16 / 9", tone = "sand", radius = "var(--radius-image)", children, style }) {
  const bg = { sand: "var(--sand-100)", navy: "var(--navy-100)", deep: "var(--navy-700)" }[tone];
  return (
    <div style={{ position: "relative", aspectRatio: ratio, background: bg, borderRadius: radius, overflow: "hidden", display: "flex", alignItems: "center", justifyContent: "center", ...style }}>
      <span style={{ fontFamily: "var(--font-sans)", fontSize: 10, letterSpacing: ".18em", textTransform: "uppercase", color: tone === "deep" ? "rgba(255,255,255,.35)" : "var(--text-subtle)" }}>{label}</span>
      {children}
    </div>
  );
}

function StatusBar({ dark }) {
  return (
    <div style={{ height: 44, display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 22px", fontFamily: "var(--font-sans)", fontSize: 13, fontWeight: 500, color: dark ? "#fff" : "var(--navy-800)" }}>
      <span>9:41</span>
      <span style={{ display: "flex", gap: 6, alignItems: "center", opacity: .9 }}><Icon name="signal" size={14} /><Icon name="wifi" size={14} /><Icon name="battery-full" size={16} /></span>
    </div>
  );
}

const TABS = [
  { id: "stay", label: "Stay", icon: "bed-double" },
  { id: "key", label: "Key", icon: "key-round" },
  { id: "services", label: "Services", icon: "concierge-bell" },
];

function TabBar({ route, go }) {
  return (
    <div style={{ borderTop: "1px solid var(--border-subtle)", background: "rgba(251,250,247,.96)", backdropFilter: "var(--blur-glass)", padding: "8px 12px 22px", display: "flex" }}>
      {TABS.map((t) => {
        const on = route === t.id;
        return (
          <button key={t.id} onClick={() => go(t.id)} style={{ flex: 1, border: 0, background: "none", cursor: "pointer", display: "flex", flexDirection: "column", alignItems: "center", gap: 5, padding: "8px 0", color: on ? "var(--teal-700)" : "var(--text-subtle)" }}>
            <Icon name={t.icon} size={22} />
            <span style={{ fontFamily: "var(--font-sans)", fontSize: 10, letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", fontWeight: on ? 500 : 400 }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

function AppBar({ title, subtitle, action }) {
  return (
    <div style={{ padding: "6px 20px 16px", display: "flex", alignItems: "flex-end", justifyContent: "space-between", gap: 12 }}>
      <div>
        {subtitle ? <div className="hh-eyebrow" style={{ fontSize: 10 }}>{subtitle}</div> : null}
        <div style={{ fontFamily: "var(--font-display)", fontSize: 24, letterSpacing: ".05em", textTransform: "uppercase", color: "var(--text-heading)", marginTop: subtitle ? 8 : 0 }}>{title}</div>
      </div>
      {action}
    </div>
  );
}

Object.assign(window, { Icon, Photo, StatusBar, TabBar, AppBar, TABS });
