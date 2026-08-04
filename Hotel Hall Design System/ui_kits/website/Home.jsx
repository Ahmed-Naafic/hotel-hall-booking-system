const { Button, Card, CardTitle, CardMeta, Badge, Tag, Rating, DateField, Select } = window.HotelHallDesignSystem_6ae9d5;

function SearchBar({ onSearch, floating = false }) {
  return (
    <div style={{
      display: "flex", alignItems: "flex-end", gap: 12,
      background: floating ? "var(--surface-glass)" : "var(--surface-card)",
      backdropFilter: floating ? "var(--blur-glass)" : "none",
      border: "1px solid var(--border-subtle)",
      borderRadius: "var(--radius-lg)", boxShadow: "var(--shadow-md)",
      padding: 16,
    }}>
      <DateField checkIn="Aug 12" checkOut="Aug 15" nights={3} style={{ flex: 1.6 }} />
      <Select label="Guests" options={["2 guests", "1 guest", "3 guests", "4 guests"]} size="lg" style={{ height: "calc(var(--control-h-md) + 8px)" }} />
      <Select label="Occasion" options={["A stay", "A celebration", "A meeting"]} size="lg" style={{ height: "calc(var(--control-h-md) + 8px)" }} />
      <Button size="lg" onClick={onSearch} style={{ height: "calc(var(--control-h-md) + 8px)" }}>Check availability</Button>
    </div>
  );
}

function Hero({ go }) {
  return (
    <div style={{ position: "relative", marginTop: -76 }}>
      <Photo tone="deep" ratio="auto" radius="0" label="Full-bleed hero photography" style={{ height: 620, alignItems: "flex-end", justifyContent: "flex-start" }}>
        <div style={{ position: "absolute", inset: 0, background: "var(--scrim-bottom)" }} />
        <div style={{ position: "absolute", inset: 0, background: "var(--scrim-top)" }} />
        <div style={{ position: "relative", maxWidth: "var(--container-max)", width: "100%", margin: "0 auto", padding: "0 var(--gutter) 74px" }}>
          <div className="hh-eyebrow" style={{ color: "var(--gold-400)" }}>Harbour Road · Est. 1974</div>
          <h1 style={{ color: "#fff", fontSize: "var(--display-xl)", margin: "18px 0 0", maxWidth: 760 }}>Stay comfortable<br />Celebrate memorable</h1>
          <p style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-md)", color: "rgba(255,255,255,.86)", maxWidth: 520, marginTop: 18 }}>
            Ninety-four rooms above the harbour, and a hall that seats 180 for the evening after.
          </p>
        </div>
      </Photo>
      <div style={{ maxWidth: "var(--container-max)", margin: "-44px auto 0", padding: "0 var(--gutter)", position: "relative", zIndex: 5 }}>
        <SearchBar onSearch={() => go("rooms")} floating />
      </div>
    </div>
  );
}

function RoomCard({ room, go }) {
  return (
    <Card image="" interactive onClick={() => go("rooms")}>
      <Photo label="Room 4:3" ratio="4 / 3" radius="0" style={{ margin: "-20px -20px 18px" }} />
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 10 }}>
        <CardTitle>{room.name}</CardTitle>
        <Rating value={room.rating} label={false} size={14} />
      </div>
      <CardMeta style={{ marginTop: 6 }}>{room.meta}</CardMeta>
      <div style={{ display: "flex", gap: 6, marginTop: 14, flexWrap: "wrap" }}>
        {room.tags.map((t) => <Badge key={t} tone="neutral" size="sm">{t}</Badge>)}
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginTop: 18, paddingTop: 16, borderTop: "1px solid var(--border-subtle)" }}>
        <span style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-xl)", color: "var(--text-heading)" }}>${room.price}</span>
        <span style={{ fontSize: "var(--text-xs)", color: "var(--text-muted)" }}>per night</span>
      </div>
    </Card>
  );
}

function Home({ go }) {
  return (
    <div>
      <Hero go={go} />
      <Section eyebrow="Book • Stay" title="Rooms & suites" intro="Every rate includes Wi-Fi, the harbour breakfast, and a 6 PM hold on your arrival.">
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 20 }}>
          {ROOMS.map((r) => <RoomCard key={r.id} room={r} go={go} />)}
        </div>
        <div style={{ marginTop: 32 }}><Button variant="secondary" onClick={() => go("rooms")}>See all 94 rooms</Button></div>
      </Section>

      <section style={{ background: "var(--surface-navy)", color: "var(--text-on-navy)", padding: "var(--section-y) 0" }}>
        <div style={{ maxWidth: "var(--container-max)", margin: "0 auto", padding: "0 var(--gutter)", display: "grid", gridTemplateColumns: "1fr 1.05fr", gap: 64, alignItems: "center" }}>
          <Photo tone="deep" ratio="3 / 4" radius="var(--arch-top)" label="Venue archway 3:4" style={{ border: "1px solid rgba(204,156,36,.4)" }} />
          <div>
            <div className="hh-eyebrow" style={{ color: "var(--gold-400)" }}>Celebrate</div>
            <h2 style={{ color: "#fff", marginTop: 16 }}>The Grand Hall</h2>
            <p style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-md)", color: "rgba(232,239,246,.8)", maxWidth: 460 }}>
              A chandeliered hall under the original 1974 arch. Seats 180 for dinner, 240 standing, with a dance floor and a service kitchen of its own.
            </p>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 24, margin: "32px 0", maxWidth: 460 }}>
              {[["180", "seated"], ["240", "standing"], ["12", "hours exclusive"]].map(([n, l]) => (
                <div key={l}>
                  <div style={{ fontFamily: "var(--font-display)", fontSize: 34, color: "var(--gold-500)" }}>{n}</div>
                  <div style={{ fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "rgba(232,239,246,.6)", marginTop: 4 }}>{l}</div>
                </div>
              ))}
            </div>
            <div style={{ display: "flex", gap: 10 }}>
              <Button variant="gold" onClick={() => go("venue")}>Request a quote</Button>
              <Button variant="inverse" onClick={() => go("venue")}>See the Grand Hall</Button>
            </div>
          </div>
        </div>
      </section>

      <Section eyebrow="In the hotel" title="Amenities">
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 20 }}>
          {AMENITIES.map((a) => (
            <div key={a.label} style={{ display: "flex", gap: 14 }}>
              <span style={{ color: "var(--teal-700)", marginTop: 2 }}><Icon name={a.icon} size={22} /></span>
              <div>
                <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: "var(--text-heading)" }}>{a.label}</div>
                <div style={{ fontSize: "var(--text-sm)", color: "var(--text-muted)", marginTop: 4 }}>{a.note}</div>
              </div>
            </div>
          ))}
        </div>
      </Section>

      <section style={{ background: "var(--surface-sunken)", padding: "var(--section-y-tight) 0" }}>
        <div style={{ maxWidth: "var(--container-narrow)", margin: "0 auto", padding: "0 var(--gutter)", textAlign: "center" }}>
          <div className="hh-rule-gold"><span className="hh-eyebrow">Guest reviews</span></div>
          <p style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-lg)", fontStyle: "italic", color: "var(--text-heading)", margin: "26px 0 18px" }}>
            “We held the wedding in the hall and put forty guests upstairs. Both halves ran without a single question from us.”
          </p>
          <Rating value={4.7} count={780} style={{ justifyContent: "center" }} />
        </div>
      </section>
    </div>
  );
}

Object.assign(window, { Home, SearchBar, RoomCard, Hero });
