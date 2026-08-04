Switches between sections of a page or card (Rooms / Suites / Venue, Overview / Amenities / Reviews).

```jsx
<Tabs items={[{id:'rooms',label:'Rooms'},{id:'venue',label:'Venue',count:3}]} value={tab} onChange={setTab} />
```

`underline` (default) for page-level navigation; `segmented` inside a card or panel.
