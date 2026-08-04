const { Button, Card, CardTitle, CardMeta, Badge, Tag, Rating, Tabs, Checkbox, RadioGroup, Tooltip, IconButton } = window.HotelHallDesignSystem_6ae9d5;

function Rooms({ go, onReserve }) {
  const [filters, setFilters] = React.useState(["Harbour view"]);
  const [sort, setSort] = React.useState("price");
  const toggle = (t) => setFilters((f) => f.includes(t) ? f.filter((x) => x !== t) : [...f, t]);
  const chips = ["Harbour view", "Balcony", "Connecting", "Quiet wing", "Breakfast"];
  return (
    <div>
      <div style={{ borderBottom: "1px solid var(--border-subtle)", background: "var(--surface-card)" }}>
        <div style={{ maxWidth: "var(--container-max)", margin: "0 auto", padding: "var(--space-9) var(--gutter) var(--space-7)" }}>
          <div className="hh-eyebrow">Book • Stay</div>
          <h1 style={{ fontSize: "var(--display-lg)", margin: "14px 0 6px" }}>Rooms & suites</h1>
          <p style={{ color: "var(--text-muted)", marginBottom: 24 }}>94 rooms · Aug 12–15 · 2 guests</p>
          <SearchBar onSearch={() => {}} />
        </div>
      </div>

      <div style={{ maxWidth: "var(--container-max)", margin: "0 auto", padding: "var(--space-9) var(--gutter) 0", display: "grid", gridTemplateColumns: "236px 1fr", gap: 40 }}>
        <aside>
          <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-xs)", letterSpacing: "var(--tracking-wider)", textTransform: "uppercase", color: "var(--text-muted)", marginBottom: 14 }}>Filter</div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 6, marginBottom: 26 }}>
            {chips.map((c) => <Tag key={c} selected={filters.includes(c)} onClick={() => toggle(c)}>{c}</Tag>)}
          </div>
          <div style={{ borderTop: "1px solid var(--border-subtle)", paddingTop: 22 }}>
            <RadioGroup label="Rate" value={sort} onChange={setSort} options={[
              { value: "price", label: "Flexible", description: "Free cancellation until Aug 12" },
              { value: "saver", label: "Advance saver", description: "Non-refundable · save $32" },
            ]} />
          </div>
          <div style={{ borderTop: "1px solid var(--border-subtle)", marginTop: 22, paddingTop: 22, display: "flex", flexDirection: "column", gap: 12 }}>
            <Checkbox label="Add breakfast" description="$28 per guest" defaultChecked />
            <Checkbox label="Valet parking" description="$32 per night" />
            <Checkbox label="Accessible room" />
          </div>
        </aside>

        <div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
            <Tabs items={[{ id: "all", label: "All rooms", count: 4 }, { id: "suites", label: "Suites" }, { id: "family", label: "Family" }]} />
            <span style={{ fontSize: "var(--text-sm)", color: "var(--text-muted)" }}>Sorted by price</span>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            {ROOMS.map((r, i) => (
              <Card key={r.id} padding="0" interactive style={{ display: "grid", gridTemplateColumns: "300px 1fr" }}>
                <Photo label="Room 3:2" ratio="3 / 2" radius="0" />
                <div style={{ padding: "var(--card-pad-lg)", display: "flex", gap: 28 }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <CardTitle style={{ fontSize: "var(--serif-lg)" }}>{r.name}</CardTitle>
                      {i === 0 ? <Badge tone="gold" size="sm">2 left</Badge> : null}
                    </div>
                    <CardMeta style={{ marginTop: 8 }}>{r.meta}</CardMeta>
                    <p style={{ fontFamily: "var(--font-serif)", fontSize: "var(--serif-sm)", color: "var(--text-body)", margin: "12px 0 0", maxWidth: 420 }}>{r.note}</p>
                    <div style={{ display: "flex", gap: 6, marginTop: 16, flexWrap: "wrap" }}>
                      {r.tags.map((t) => <Badge key={t} tone="neutral" size="sm">{t}</Badge>)}
                      <Badge tone="teal" size="sm">Breakfast included</Badge>
                    </div>
                    <Rating value={r.rating} count={r.reviews} style={{ marginTop: 16 }} />
                  </div>
                  <div style={{ width: 170, borderLeft: "1px solid var(--border-subtle)", paddingLeft: 24, display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
                    <div>
                      <div style={{ fontFamily: "var(--font-sans)", fontSize: "var(--text-2xl)", color: "var(--text-heading)" }}>${r.price}</div>
                      <div style={{ fontSize: "var(--text-xs)", color: "var(--text-muted)", marginTop: 2 }}>per night · ${r.price * 3} total</div>
                      <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 12, fontSize: "var(--text-xs)", color: "var(--success-700)" }}>
                        <Icon name="check" size={14} /> Free cancellation
                      </div>
                    </div>
                    <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                      <Button fullWidth onClick={(e) => { e.stopPropagation(); onReserve(r); }}>Reserve</Button>
                      <div style={{ display: "flex", gap: 8 }}>
                        <Button variant="ghost" size="sm" style={{ flex: 1 }}>Details</Button>
                        <Tooltip label="Save for later"><IconButton icon={<Icon name="heart" size={16} />} label="Save" size="sm" variant="outline" /></Tooltip>
                      </div>
                    </div>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Rooms });
