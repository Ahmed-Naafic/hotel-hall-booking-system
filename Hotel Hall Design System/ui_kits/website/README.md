# UI kit — Hotel Hall booking website

Desktop marketing + booking site at a 1280px design width. Four routes, click-through:

| File | Screen | Notes |
| --- | --- | --- |
| `Shell.jsx` | Header, Footer, Section, `Photo`, `Icon` | Header is transparent over the hero (Home, Venue) and solid ivory elsewhere |
| `Home.jsx` | Home + `SearchBar`, `Hero`, `RoomCard` | Hero → search bar → rooms → navy "Celebrate" band → amenities → review band |
| `Rooms.jsx` | Rooms & suites | Filter rail (Tag / RadioGroup / Checkbox) + horizontal room cards |
| `Venue.jsx` | The Grand Hall | Layout switcher + quote form in an arch-motif section |
| `Checkout.jsx` | Confirm your stay | 3-step form, sticky summary card, Dialog → Toast on reserve |
| `data.jsx` | `ROOMS`, `AMENITIES` | Shared fake content |

Flow: Home → *Check availability* → Rooms → *Reserve* → Checkout → *Reserve* → Dialog →
Home with a success Toast.

**All components come from the design system bundle** (`window.HotelHallDesignSystem_6ae9d5`);
nothing is re-implemented here. The only local pieces are layout (`Header`, `Footer`,
`Section`) and `Photo`.

## Caveat: no photography
No image assets were supplied with the brand, so every image is a flat `Photo`
placeholder labelled with its aspect ratio. Drop real photography in and the layouts hold:
16:9 hero (full-bleed, scrim), 4:3 room card, 3:2 room row / venue, 3:4 arch panel.
