const { Button, Card, CardTitle, CardMeta, Badge, Tag, Input, Select, Tabs } = window.HotelHallDesignSystem_6ae9d5;

const LAYOUTS = [
  { name: "Banquet", seats: "180 seated", note: "Round tables of ten, dance floor at the harbour end." },
  { name: "Theatre", seats: "240 seated", note: "Full rows facing the arch, with a lectern and screen." },
  { name: "Reception", seats: "240 standing", note: "Bars at both ends, high tables under the chandelier." },
];

function Venue({ go }) {
  const [layout, setLayout] = React.useState("Banquet");
  const active = LAYOUTS.find((l) => l.name === layout);
  return (
    <div>
      <div style={{ position: "relative", marginTop: -76 }}>
        <Photo tone="deep" ratio="auto" radius="0" label="The Grand Hall — full bleed" style={{ height: 460, alignItems: "flex-end", justifyContent: "flex-start" }}>
          <div style={{ position: "absolute", inset: 0, background: "var(--scrim-bottom)" }} />
          <div style={{ position: "relative", maxWidth: "var(--container-max)", width: "100%", margin: "0 auto", padding: "0 var(--gutter) 56px" }}>
            <div className="hh-eyebrow" style={{ color: "var(--gold-400)" }}>Celebrate</div>
            <h1 style={{ color: "#fff", fontSize: "var(--display-lg)", margin: "16px 0 0" }}>The Grand Hall</h1>
            <p style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-md)", color: "rgba(255,255,255,.86)", maxWidth: 520, marginTop: 14 }}>
              Weddings, banquets and company evenings under the original 1974 arch.
            </p>
          </div>
        </Photo>
      </div>

      <Section eyebrow="Layouts" title="Three ways to set the room">
        <div style={{ display: "grid", gridTemplateColumns: "1.15fr 1fr", gap: 48, alignItems: "start" }}>
          <div>
            <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
              {LAYOUTS.map((l) => <Tag key={l.name} selected={layout === l.name} onClick={() => setLayout(l.name)}>{l.name}</Tag>)}
            </div>
            <Photo label={`${active.name} layout 3:2`} ratio="3 / 2" />
            <p style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-sm)", color: "var(--text-body)", marginTop: 18 }}>
              <strong style={{ fontWeight: 500 }}>{active.seats}.</strong> {active.note}
            </p>
          </div>
          <Card padding="var(--card-pad-lg)">
            <div className="hh-eyebrow">Request a quote</div>
            <CardTitle style={{ marginTop: 10, marginBottom: 18 }}>Tell us about the evening</CardTitle>
            <div style={{ display: "grid", gap: 14 }}>
              <Input label="Your name" placeholder="Full name" />
              <Input label="Email" placeholder="you@example.com" />
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
                <Select label="Occasion" options={["Wedding", "Banquet", "Corporate evening", "Conference"]} />
                <Select label="Guests" options={["Up to 80", "80–140", "140–180", "180+"]} />
              </div>
              <Input label="Preferred date" placeholder="Aug 12, 2026" iconRight={<Icon name="calendar" size={16} />} />
              <Button variant="gold" fullWidth style={{ marginTop: 4 }}>Request a quote</Button>
              <p style={{ fontSize: "var(--text-xs)", color: "var(--text-subtle)", margin: 0 }}>We reply within one business day, with a hold on the date for 72 hours.</p>
            </div>
          </Card>
        </div>
      </Section>

      <section style={{ background: "var(--surface-sunken)", padding: "var(--section-y-tight) 0" }}>
        <div style={{ maxWidth: "var(--container-max)", margin: "0 auto", padding: "0 var(--gutter)" }}>
          <div className="hh-eyebrow" style={{ marginBottom: 26 }}>Included with the hall</div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 20 }}>
            {[
              { icon: "utensils", t: "Service kitchen", n: "Plated or buffet, from our own kitchen" },
              { icon: "users", t: "Event manager", n: "One contact from booking to last dance" },
              { icon: "bed-double", t: "Guest room block", n: "Ten rooms held at the group rate" },
              { icon: "music", t: "Sound & lighting", n: "House system, dimmable chandelier" },
            ].map((x) => (
              <Card key={x.t}>
                <span style={{ color: "var(--gold-700)" }}><Icon name={x.icon} size={22} /></span>
                <CardTitle style={{ fontSize: "var(--serif-sm)", marginTop: 14 }}>{x.t}</CardTitle>
                <CardMeta style={{ marginTop: 6 }}>{x.n}</CardMeta>
              </Card>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}

Object.assign(window, { Venue });
