const { IconButton, Button, Badge, Rating } = window.HotelHallDesignSystem_6ae9d5;

function Icon({ name, size = 18, style }) {
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

/* Flat placeholder — no photography was supplied with the brand assets. */
function Photo({ label = "Photography", ratio = "16 / 9", tone = "sand", radius = "var(--radius-image)", children, style }) {
  const bg = { sand: "var(--sand-100)", navy: "var(--navy-100)", teal: "var(--teal-100)", deep: "var(--navy-700)" }[tone];
  return (
    <div style={{ position: "relative", aspectRatio: ratio, background: bg, borderRadius: radius, overflow: "hidden", display: "flex", alignItems: "center", justifyContent: "center", ...style }}>
      <span style={{ fontFamily: "var(--font-sans)", fontSize: 11, letterSpacing: ".18em", textTransform: "uppercase", color: tone === "deep" ? "rgba(255,255,255,.35)" : "var(--text-subtle)" }}>{label}</span>
      {children}
    </div>
  );
}

const NAV = [
  { id: "home", label: "Stay" },
  { id: "rooms", label: "Rooms" },
  { id: "venue", label: "Celebrate" },
];

function Header({ route, go, overHero = false }) {
  const dark = overHero;
  return (
    <header style={{
      position: "sticky", top: 0, zIndex: 30,
      background: dark ? "transparent" : "rgba(251,250,247,.94)",
      backdropFilter: dark ? "none" : "var(--blur-glass)",
      borderBottom: dark ? "1px solid transparent" : "1px solid var(--border-subtle)",
      boxShadow: dark ? "none" : "var(--shadow-xs)",
      transition: "var(--transition-control)",
    }}>
      <div style={{ maxWidth: "var(--container-max)", margin: "0 auto", padding: "0 var(--gutter)", height: 76, display: "flex", alignItems: "center", gap: 40 }}>
        <a href="#" onClick={(e) => { e.preventDefault(); go("home"); }} style={{ border: 0, display: "flex", flexDirection: "column", lineHeight: 1 }}>
          <span style={{ fontFamily: "var(--font-display)", fontSize: 22, letterSpacing: ".08em", textTransform: "uppercase", color: dark ? "#fff" : "var(--navy-700)" }}>
            Hotel <span style={{ color: dark ? "var(--teal-400)" : "var(--teal-700)" }}>Hall</span>
          </span>
          <span style={{ fontFamily: "var(--font-sans)", fontSize: 8, letterSpacing: ".24em", textTransform: "uppercase", color: dark ? "var(--gold-400)" : "var(--gold-700)", marginTop: 5 }}>Book • Stay • Celebrate</span>
        </a>
        <nav style={{ display: "flex", gap: 28, flex: 1 }}>
          {NAV.map((n) => (
            <a key={n.id} href="#" onClick={(e) => { e.preventDefault(); go(n.id); }}
              style={{
                border: 0, fontFamily: "var(--font-sans)", fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase",
                color: dark ? (route === n.id ? "#fff" : "rgba(255,255,255,.75)") : route === n.id ? "var(--text-heading)" : "var(--text-muted)",
                paddingBottom: 3, borderBottom: route === n.id ? `1px solid ${dark ? "var(--gold-400)" : "var(--gold-600)"}` : "1px solid transparent",
              }}>{n.label}</a>
          ))}
        </nav>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <IconButton icon={<Icon name="phone" />} label="Call the hotel" variant={dark ? "glass" : "ghost"} />
          <Button variant={dark ? "inverse" : "primary"} onClick={() => go("rooms")}>Check availability</Button>
        </div>
      </div>
    </header>
  );
}

function Footer({ go }) {
  const col = (title, items) => (
    <div>
      <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-2xs)", letterSpacing: "var(--tracking-widest)", textTransform: "uppercase", color: "var(--gold-500)", marginBottom: 16 }}>{title}</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {items.map((i) => <span key={i} style={{ fontSize: "var(--text-sm)", color: "rgba(232,239,246,.72)" }}>{i}</span>)}
      </div>
    </div>
  );
  return (
    <footer style={{ background: "var(--surface-navy-deep)", color: "var(--text-on-navy)", marginTop: "var(--space-13)" }}>
      <div style={{ maxWidth: "var(--container-max)", margin: "0 auto", padding: "var(--space-12) var(--gutter) var(--space-9)", display: "grid", gridTemplateColumns: "1.4fr 1fr 1fr 1fr", gap: 40 }}>
        <div>
          <div style={{ fontFamily: "var(--font-display)", fontSize: 24, letterSpacing: ".08em", textTransform: "uppercase" }}>Hotel <span style={{ color: "var(--teal-400)" }}>Hall</span></div>
          <div style={{ fontFamily: "var(--font-serif)", fontSize: 18, color: "rgba(232,239,246,.72)", marginTop: 12, maxWidth: 280 }}>Stay comfortable, celebrate memorable.</div>
          <div style={{ display: "flex", gap: 8, marginTop: 22 }}>
            {["instagram", "facebook", "linkedin"].map((s) => (
              <span key={s} style={{ width: 34, height: 34, border: "1px solid rgba(255,255,255,.18)", borderRadius: "var(--radius-sm)", display: "flex", alignItems: "center", justifyContent: "center", color: "rgba(232,239,246,.8)" }}><Icon name={s} size={16} /></span>
            ))}
          </div>
        </div>
        {col("Stay", ["Rooms & suites", "Offers", "Amenities", "Dining"])}
        {col("Celebrate", ["The Grand Hall", "Weddings", "Corporate events", "Request a quote"])}
        {col("Visit", ["42 Harbour Road", "Front desk +1 555 0134", "stay@hotelhall.com", "Directions"])}
      </div>
      <div style={{ borderTop: "1px solid rgba(255,255,255,.12)" }}>
        <div style={{ maxWidth: "var(--container-max)", margin: "0 auto", padding: "20px var(--gutter)", display: "flex", justifyContent: "space-between", fontSize: "var(--text-xs)", color: "rgba(232,239,246,.5)" }}>
          <span>© 2026 Hotel Hall</span>
          <span style={{ display: "flex", gap: 22 }}><span>Privacy</span><span>Accessibility</span><span>Terms</span></span>
        </div>
      </div>
    </footer>
  );
}

function Section({ eyebrow, title, intro, children, background = "transparent", narrow = false, style }) {
  return (
    <section style={{ background, padding: "var(--section-y) 0", ...style }}>
      <div style={{ maxWidth: narrow ? "var(--container-narrow)" : "var(--container-max)", margin: "0 auto", padding: "0 var(--gutter)" }}>
        {eyebrow ? <div className="hh-eyebrow" style={{ marginBottom: 14 }}>{eyebrow}</div> : null}
        {title ? <h2 style={{ fontSize: "var(--display-md)", marginBottom: intro ? 12 : 32 }}>{title}</h2> : null}
        {intro ? <p style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-sm)", color: "var(--text-muted)", maxWidth: 560, marginBottom: 36 }}>{intro}</p> : null}
        {children}
      </div>
    </section>
  );
}

Object.assign(window, { Icon, Photo, Header, Footer, Section, NAV });
