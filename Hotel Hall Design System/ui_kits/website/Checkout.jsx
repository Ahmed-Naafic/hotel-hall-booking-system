const { Button, Card, CardTitle, CardMeta, Badge, Input, Select, Checkbox, RadioGroup, Dialog, Toast, Rating } = window.HotelHallDesignSystem_6ae9d5;

function Checkout({ room, go, onConfirmed }) {
  const [rate, setRate] = React.useState("flex");
  const [confirming, setConfirming] = React.useState(false);
  const nights = 3;
  const base = room.price * nights;
  const extras = rate === "saver" ? -32 : 0;
  const tax = Math.round((base + extras) * 0.09);
  const total = base + extras + tax;
  return (
    <div style={{ position: "relative", maxWidth: "var(--container-max)", margin: "0 auto", padding: "var(--space-9) var(--gutter) 0" }}>
      <button onClick={() => go("rooms")} style={{ border: 0, background: "none", padding: 0, cursor: "pointer", display: "flex", alignItems: "center", gap: 6, fontFamily: "var(--font-sans)", fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-muted)" }}>
        <Icon name="chevron-left" size={14} /> Back to rooms
      </button>
      <h1 style={{ fontSize: "var(--display-md)", margin: "18px 0 32px" }}>Confirm your stay</h1>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 380px", gap: 40, alignItems: "start" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <Card padding="var(--card-pad-lg)">
            <div className="hh-eyebrow">1 · Rate</div>
            <div style={{ marginTop: 18 }}>
              <RadioGroup value={rate} onChange={setRate} options={[
                { value: "flex", label: `Flexible — $${room.price} / night`, description: "Free cancellation until Aug 12, pay at check-in" },
                { value: "saver", label: `Advance saver — $${room.price - 11} / night`, description: "Non-refundable, charged today · save $32" },
              ]} />
            </div>
          </Card>

          <Card padding="var(--card-pad-lg)">
            <div className="hh-eyebrow">2 · Guest details</div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14, marginTop: 18 }}>
              <Input label="First name" defaultValue="Amara" />
              <Input label="Last name" defaultValue="Osei" />
              <Input label="Email" defaultValue="amara@example.com" hint="Your confirmation goes here." />
              <Input label="Phone" defaultValue="+1 555 0134" />
              <Select label="Arrival time" options={["3:00 – 6:00 PM", "6:00 – 9:00 PM", "After 9:00 PM"]} />
              <Select label="Bed" options={["King", "Twin"]} />
            </div>
            <div style={{ marginTop: 20, display: "flex", flexDirection: "column", gap: 12, borderTop: "1px solid var(--border-subtle)", paddingTop: 20 }}>
              <Checkbox label="Add breakfast" description="$28 per guest, served 7–10 AM" defaultChecked />
              <Checkbox label="Valet parking" description="$32 per night" />
            </div>
          </Card>

          <Card padding="var(--card-pad-lg)">
            <div className="hh-eyebrow">3 · Payment</div>
            <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr", gap: 14, marginTop: 18 }}>
              <Input label="Card number" defaultValue="4242 4242 4242 4242" iconLeft={<Icon name="credit-card" size={16} />} />
              <Input label="Expiry" defaultValue="09 / 29" />
              <Input label="CVC" defaultValue="123" />
            </div>
            <p style={{ fontSize: "var(--text-xs)", color: "var(--text-subtle)", marginTop: 14, marginBottom: 0 }}>
              We hold the room until 6:00 PM on the day of arrival. Nothing is charged until check-in on the flexible rate.
            </p>
          </Card>
        </div>

        <Card padding="0" style={{ position: "sticky", top: 96 }}>
          <Photo label="Room 3:2" ratio="3 / 2" radius="0" />
          <div style={{ padding: "var(--card-pad-lg)" }}>
            <CardTitle>{room.name}</CardTitle>
            <CardMeta style={{ marginTop: 6 }}>{room.meta}</CardMeta>
            <Rating value={room.rating} count={room.reviews} style={{ marginTop: 12 }} />
            <div style={{ borderTop: "1px solid var(--border-subtle)", margin: "20px 0", paddingTop: 20, display: "flex", flexDirection: "column", gap: 10, fontFamily: "var(--font-sans)", fontSize: "var(--text-sm)" }}>
              {[["Aug 12 – Aug 15", `${nights} nights`], [`$${room.price} × ${nights} nights`, `$${base}`], ...(extras ? [["Advance saver", `−$${-extras}`]] : []), ["Taxes & fees", `$${tax}`]].map(([l, v]) => (
                <div key={l} style={{ display: "flex", justifyContent: "space-between", color: "var(--text-muted)" }}><span>{l}</span><span style={{ color: "var(--text-body)" }}>{v}</span></div>
              ))}
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", borderTop: "1px solid var(--border-subtle)", paddingTop: 16 }}>
              <span style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-muted)" }}>Total</span>
              <span style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-2xl)", color: "var(--text-heading)" }}>${total}</span>
            </div>
            <Button fullWidth size="lg" style={{ marginTop: 18 }} onClick={() => setConfirming(true)}>Reserve</Button>
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 12, fontSize: "var(--text-xs)", color: "var(--success-700)" }}>
              <Icon name="check" size={14} /> {rate === "flex" ? "Free cancellation until Aug 12" : "Non-refundable rate"}
            </div>
          </div>
        </Card>
      </div>

      <Dialog open={confirming} eyebrow="Almost there" title="Confirm your stay" onClose={() => setConfirming(false)}
        footer={<><Button variant="ghost" onClick={() => setConfirming(false)}>Back</Button><Button onClick={() => { setConfirming(false); onConfirmed(); }}>Reserve</Button></>}>
        {room.name}, Aug 12–15 for 2 guests. ${total} total{rate === "flex" ? ", charged at check-in." : ", charged today."}
      </Dialog>
    </div>
  );
}

Object.assign(window, { Checkout });
