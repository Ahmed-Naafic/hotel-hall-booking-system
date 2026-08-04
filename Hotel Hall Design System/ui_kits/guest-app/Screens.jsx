const { Button, Card, CardTitle, CardMeta, Badge, Tag, Switch, Rating, IconButton, Tabs, Checkbox } = window.HotelHallDesignSystem_6ae9d5;

function StayScreen({ go }) {
  return (
    <div style={{ padding: "0 20px 24px" }}>
      <AppBar subtitle="Reservation 4821-HH" title="Your stay" action={<IconButton icon={<Icon name="bell" size={18} />} label="Notifications" variant="outline" size="sm" />} />
      <Card padding="0" style={{ overflow: "hidden" }}>
        <Photo tone="deep" ratio="16 / 10" radius="0" label="Harbour Suite">
          <div style={{ position: "absolute", inset: 0, background: "var(--scrim-bottom)" }} />
          <div style={{ position: "absolute", left: 18, bottom: 14, color: "#fff" }}>
            <div className="hh-eyebrow" style={{ color: "var(--gold-400)", fontSize: 10 }}>Room 812</div>
            <div style={{ fontFamily: "var(--font-serif)", fontSize: 22, marginTop: 4 }}>Harbour Suite</div>
          </div>
          <div style={{ position: "absolute", top: 14, right: 14 }}><Badge tone="solid" size="sm">Checked in</Badge></div>
        </Photo>
        <div style={{ padding: "18px 18px 20px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", fontFamily: "var(--font-sans)", fontSize: "var(--text-sm)" }}>
            {[["Check in", "Aug 12 · 3:00 PM"], ["Check out", "Aug 15 · 11:00 AM"]].map(([l, v]) => (
              <div key={l}>
                <div style={{ fontSize: 10, letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-subtle)" }}>{l}</div>
                <div style={{ color: "var(--text-body)", marginTop: 4 }}>{v}</div>
              </div>
            ))}
            <div>
              <div style={{ fontSize: 10, letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-subtle)" }}>Guests</div>
              <div style={{ color: "var(--text-body)", marginTop: 4 }}>2</div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 18 }}>
            <Button fullWidth onClick={() => go("key")} iconLeft={<Icon name="key-round" size={16} />}>Open door</Button>
            <Button variant="secondary" onClick={() => go("services")}>Services</Button>
          </div>
        </div>
      </Card>

      <div style={{ marginTop: 22 }}>
        <div className="hh-eyebrow" style={{ fontSize: 10, marginBottom: 12 }}>Today</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {[
            { icon: "utensils", t: "Breakfast", n: "7:00 – 10:00 AM · Harbour restaurant", tag: "Included" },
            { icon: "sparkles", t: "Wedding in the Grand Hall", n: "6:00 PM · Osei & Lindqvist", tag: null },
            { icon: "car", t: "Valet collected your car", n: "8:12 AM · Level 2, bay 14", tag: null },
          ].map((r) => (
            <Card key={r.t} padding="14px 16px" style={{ display: "flex", alignItems: "center", gap: 14 }}>
              <span style={{ color: "var(--teal-700)" }}><Icon name={r.icon} size={20} /></span>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: "var(--text-heading)" }}>{r.t}</div>
                <div style={{ fontSize: "var(--text-sm)", color: "var(--text-muted)", marginTop: 2 }}>{r.n}</div>
              </div>
              {r.tag ? <Badge tone="teal" size="sm">{r.tag}</Badge> : <Icon name="chevron-right" size={16} style={{ color: "var(--text-subtle)" }} />}
            </Card>
          ))}
        </div>
      </div>

      <div style={{ marginTop: 22 }}>
        <div className="hh-eyebrow" style={{ fontSize: 10, marginBottom: 12 }}>Preferences</div>
        <Card padding="16px 18px" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <Switch label="Daily housekeeping" defaultChecked />
          <Switch label="Do not disturb" />
          <Switch label="Late checkout · $45" />
        </Card>
      </div>
    </div>
  );
}

function KeyScreen({ go, onUnlock, unlocked }) {
  return (
    <div style={{ padding: "0 20px 24px" }}>
      <AppBar subtitle="Room 812" title="Mobile key" />
      <Card padding="28px 22px" style={{ textAlign: "center", background: "var(--surface-navy)", border: "1px solid transparent", color: "var(--text-on-navy)" }}>
        <div style={{ width: 168, height: 200, margin: "0 auto", borderRadius: "var(--arch-top)", border: `1px solid ${unlocked ? "var(--teal-400)" : "rgba(204,156,36,.55)"}`, display: "flex", alignItems: "center", justifyContent: "center", transition: "border-color var(--dur-base) var(--ease-standard)" }}>
          <span style={{ color: unlocked ? "var(--teal-400)" : "var(--gold-500)" }}><Icon name={unlocked ? "door-open" : "key-round"} size={56} /></span>
        </div>
        <div style={{ fontFamily: "var(--font-display)", fontSize: 20, letterSpacing: ".06em", textTransform: "uppercase", marginTop: 26 }}>{unlocked ? "Door unlocked" : "Hold near the door"}</div>
        <div style={{ fontSize: "var(--text-sm)", color: "rgba(232,239,246,.7)", marginTop: 8 }}>{unlocked ? "Relocks in 5 seconds." : "Room 812 · Floor 8, harbour side"}</div>
        <Button variant={unlocked ? "inverse" : "gold"} fullWidth size="lg" style={{ marginTop: 24 }} onClick={onUnlock}>{unlocked ? "Unlocked" : "Unlock"}</Button>
      </Card>
      <div style={{ marginTop: 20, display: "flex", flexDirection: "column", gap: 10 }}>
        {[["elevator", "Elevator, floors 1–12"], ["dumbbell", "Fitness room, 24 hours"], ["waves", "Pool deck, 7 AM – 9 PM"]].map(([i, t]) => (
          <Card key={t} padding="14px 16px" style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <span style={{ color: "var(--gold-700)" }}><Icon name={i} size={20} /></span>
            <span style={{ flex: 1, fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: "var(--text-heading)" }}>{t}</span>
            <Badge tone="neutral" size="sm">Access</Badge>
          </Card>
        ))}
      </div>
    </div>
  );
}

function ServicesScreen({ go, onOrder }) {
  const [tab, setTab] = React.useState("room");
  const items = {
    room: [
      { t: "Harbour club sandwich", n: "Fries, pickles · 25 min", p: 24 },
      { t: "Evening cheese board", n: "Three cheeses, quince · 20 min", p: 32 },
      { t: "Pot of tea", n: "Ceylon or mint · 10 min", p: 9 },
    ],
    housekeeping: [
      { t: "Extra towels", n: "Delivered within 15 min", p: 0 },
      { t: "Turn-down service", n: "Between 6 and 8 PM", p: 0 },
      { t: "Laundry pickup", n: "Back by 10 AM tomorrow", p: 38 },
    ],
    desk: [
      { t: "Airport transfer", n: "Sedan, up to 3 bags", p: 68 },
      { t: "Dinner reservation", n: "We'll call the restaurant", p: 0 },
      { t: "Late checkout", n: "Until 2:00 PM", p: 45 },
    ],
  }[tab];
  return (
    <div style={{ padding: "0 20px 24px" }}>
      <AppBar subtitle="Room 812" title="Services" />
      <Tabs variant="segmented" items={[{ id: "room", label: "Room" }, { id: "housekeeping", label: "House" }, { id: "desk", label: "Desk" }]} value={tab} onChange={setTab} style={{ marginBottom: 18 }} />
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {items.map((i) => (
          <Card key={i.t} padding="16px" style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-sm)", color: "var(--text-heading)" }}>{i.t}</div>
              <div style={{ fontSize: "var(--text-sm)", color: "var(--text-muted)", marginTop: 3 }}>{i.n}</div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: i.p ? "var(--text-heading)" : "var(--teal-700)" }}>{i.p ? `$${i.p}` : "No charge"}</div>
              <Button size="sm" variant="secondary" style={{ marginTop: 8 }} onClick={() => onOrder(i.t)}>Add</Button>
            </div>
          </Card>
        ))}
      </div>
      <Card padding="18px" style={{ marginTop: 18, display: "flex", gap: 14, alignItems: "center", background: "var(--surface-gold-tint)", border: "1px solid var(--gold-300)" }}>
        <span style={{ color: "var(--gold-800)" }}><Icon name="message-square" size={20} /></span>
        <div style={{ flex: 1 }}>
          <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-md)", color: "var(--navy-800)" }}>Message the front desk</div>
          <div style={{ fontSize: "var(--text-sm)", color: "var(--gold-900)", marginTop: 2 }}>Replies in a few minutes, 24 hours</div>
        </div>
        <Icon name="chevron-right" size={16} style={{ color: "var(--gold-800)" }} />
      </Card>
    </div>
  );
}

Object.assign(window, { StayScreen, KeyScreen, ServicesScreen });
