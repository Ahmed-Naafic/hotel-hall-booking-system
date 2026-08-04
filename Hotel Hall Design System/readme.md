# Hotel Hall — Design System

A hospitality brand system for **Hotel Hall**, a hotel with an attached event/banquet
venue. The logo lockup states the offer directly: **BOOK · STAY · CELEBRATE**, with the
descriptor **"Stay comfortable, celebrate memorable."**

## Sources given

| Source | Path / link | Notes |
| --- | --- | --- |
| Brand logo (raster) | `uploads/ChatGPT Image Aug 3, 2026, 09_52_36 PM.png` → `assets/logo-full.png` | The **only** asset provided. 1254×1254 PNG on white. |

No codebase, no Figma file, no live site, no slide template, and no font binaries were
provided. Everything below the logo — palette values, type substitutions, components,
UI kits — is **derived from that single asset** and from standard hospitality-product
patterns. Treat the palette as ground truth (sampled from pixels), and treat the
component/screen inventory as a proposal to be corrected against the real product.

### Products represented (inferred, needs confirmation)
1. **Marketing + booking website** — rooms, the celebration venue, availability search,
   checkout. Built as `ui_kits/website/`.
2. **Guest mobile app** — reservation card, mobile key, in-stay services.
   Built as `ui_kits/guest-app/`.

If Hotel Hall has other surfaces (front-desk/PMS console, event-planner portal,
kiosk, email), they are not represented yet.

---

## Index

| File / folder | What's in it |
| --- | --- |
| `styles.css` | Global entry point — `@import` list only. Consumers link this. |
| `tokens/colors.css` | Brand scales (navy/teal/gold), neutrals, status, semantic aliases |
| `tokens/typography.css` | Font stacks, display + serif + sans scales, tracking |
| `tokens/spacing.css` | 4px space scale, layout containers, control metrics |
| `tokens/radii.css` | Corner radii incl. the signature `--arch-top` |
| `tokens/elevation.css` | Navy-tinted shadow set, scrims, glass blur |
| `tokens/motion.css` | Durations, easings, hover-lift/press-scale |
| `tokens/fonts.css` | Google Fonts substitutions (see caveat) |
| `tokens/base.css` | Element defaults, `.hh-eyebrow`, `.hh-rule-gold` |
| `assets/` | Logo variants (full, trimmed lockup, mark) |
| `guidelines/` | Foundation specimen cards (Colors, Type, Spacing, Brand) |
| `components/core/` | Button, IconButton, Card, Badge, Tag, Tabs, Tooltip |
| `components/forms/` | Input, Select, Checkbox, Radio, Switch, DateField |
| `components/feedback/` | Dialog, Toast, Rating |
| `ui_kits/website/` | Booking-site screens (home, rooms, venue, checkout) |
| `ui_kits/guest-app/` | Mobile app screens (stay, key, services) |
| `SKILL.md` | Agent-Skills wrapper so this folder works in Claude Code |

### Intentional additions
Nothing in the sources defines a component inventory, so the standard primitive set was
authored from scratch. Two hospitality-specific extras beyond the generic list:
- **DateField** — check-in/check-out is the site's primary interaction; a plain Input
  can't carry it.
- **Rating** — star rating appears on every room and review surface in this category.

---

## CONTENT FUNDAMENTALS

**Voice.** Warm-formal. The brand is a mid-to-upscale hotel that also sells weddings and
banquets, so copy is hospitable and composed — never chatty, never luxury-parody.
The logo's own tagline sets the register: **"Stay comfortable, celebrate memorable."**
Short, parallel, slightly formal.

**Person.** Address the guest as **you**; the hotel speaks as **we**. Never "I".
- ✅ "Your room is ready from 3:00 PM."
- ✅ "We'll hold your reservation until 6:00 PM."
- ❌ "I've saved your booking!"

**Casing.**
- **Display headings and buttons: UPPERCASE** with wide tracking, mirroring the wordmark.
  `RESERVE YOUR STAY`, `VIEW ROOMS`, `PLAN AN EVENT`.
- **Eyebrows/overlines: UPPERCASE, `.22em` tracking, gold**, and may use the logo's
  interpunct rhythm: `BOOK • STAY • CELEBRATE`.
- **Body, labels, helper text: sentence case.** Never title-case a sentence.
- Room and venue names are proper nouns in title case: `Harbour Suite`, `The Grand Hall`.

**Sentence shape.** Body copy runs 1–3 sentences per block, ~12–22 words per sentence.
Lead with the guest benefit, then the detail.
- ✅ "Corner windows on the harbour side, with a king bed and a writing desk. Sleeps two."
- ❌ "Experience the ultimate in refined coastal living at our newly reimagined suite."

**Numbers and facts are never fuzzy.** Prices as `$248 / night`, times as `3:00 PM`,
capacity as `Seats 180`, cancellation as `Free cancellation until Aug 12`. No "from just",
no "starting at only".

**Buttons and microcopy.** Verb-first, 1–3 words: `Check availability`, `Reserve`,
`Add to stay`, `Request a quote`, `Message the front desk`. Never `Submit`, `Click here`,
or `Learn more →` as the only affordance — say what's on the other side: `See the Grand Hall`.

**Empty / error / success states** are factual and offer the next step.
- Empty: "No rooms match those dates. Try shifting your stay by a night."
- Error: "That card was declined. Try another card, or hold the room for 24 hours."
- Success: "Reserved. Confirmation 4821-HH is in your inbox."

**Emoji: never.** Not in product UI, not in marketing, not in confirmation emails.
The one decorative glyph the brand does use is the **interpunct `•`** as a separator, and
short gold **em rules** flanking an eyebrow (as in the logo).

**Words to avoid:** "unlock", "elevate", "curated", "seamless", "journey" (unless literal
travel), "unforgettable" (the brand's own word is "memorable"), "luxury" as a self-claim.

**Words to use:** stay, celebrate, comfortable, memorable, hall, gather, host, welcome,
arrival, harbour, evening.

---

## VISUAL FOUNDATIONS

### Palette
Three brand colors, sampled from the logo pixels, in a fixed hierarchy:
- **Navy `#0C2A4E`** — the structural color. Primary buttons, headings, dark sections,
  footers, wordmark. Roughly 70% of brand ink.
- **Teal `#187884`** — the accent. Links, active/selected states, the "celebrate" half of
  the wordmark, small area fills. ~20%.
- **Gold `#CC9C24`** — the ceremonial highlight. Eyebrows, hairline rules, rating stars,
  event/venue CTAs, arch details. **~10% — never a large background fill.**

Neutrals are two-family on purpose: **warm ivory/sand** (`#FBFAF7`, `#F5F2EC`) for page
and sunken surfaces so photography reads warm, and **cool slate grays** for text, borders
and disabled states. Max two background colors in a single composition (ivory + one of
navy/sand). Status colors are desaturated so they sit inside the navy world.

### Type
Three roles, no more:
- **Cinzel** (Trajan-style titling serif) — display only, **always uppercase**,
  `.06em` tracking (`.14em` when small), line-height 1.08. Never for body, never below 18px.
- **Cormorant Garamond** — editorial serif for room descriptions, pull quotes,
  card titles. Line-height 1.45, comfortable with italic.
- **Jost** — geometric sans for all UI: labels, buttons, tables, navigation, helper text.
  Weights 300–600 only.

Body copy measures 60–72 characters (`--container-narrow: 760px`). Eyebrows are 12px /
`.22em` / gold. No font other than these three; no variable-weight tricks.

### Spacing and layout
4px base scale; the only half-step is 6px, used inside small controls. Content sits in a
1200px container with 24px gutters (40px above 1200px). Section rhythm is generous:
104px vertical between marketing sections, 64px in tighter app views. Grids are 12-column
on desktop, 6 on tablet, 1 on mobile.

Fixed elements: the site header is **sticky and transparent over the hero**, then becomes
solid ivory with a 1px bottom border and `--shadow-sm` after ~80px of scroll. The booking
bar is sticky at the bottom on mobile, and docks under the header on desktop room pages.
Nothing else is fixed — no floating chat bubbles.

### Backgrounds
Photography-led, never gradient-led. Marketing sections alternate:
1. **Full-bleed photography** with a bottom scrim (`--scrim-bottom`) for hero and venue
   sections;
2. **Flat ivory** for content;
3. **Flat navy** (`--surface-navy`) for one "celebrate" section and the footer;
4. **Sand** (`--surface-sunken`) for testimonial/quote bands.

The only permitted "pattern" is the **arch motif** taken from the venue archway in the
logo: an image or panel with `border-radius: var(--arch-top)` (120px 120px 4px 4px),
optionally with a 1px gold inner hairline. No repeating textures, no noise overlays,
no decorative blobs, no purple/blue mesh gradients. Gradients exist for exactly one job:
legibility scrims over photos.

### Imagery
Warm, evening-leaning, natural light — lamp-lit interiors, harbour blues, cream linens.
Mild warm grade, no heavy filters, no grain, no black-and-white except in the archival
"our history" context. People are shown mid-gesture (pouring, greeting, toasting), never
posed grinning at camera. Room photography is straight-on and uncluttered. Aspect ratios:
16:9 hero, 4:3 room cards, 3:2 venue, 1:1 amenity thumbs. All images get
`--radius-image: 10px` except full-bleed ones, which get none.

### Cards
White surface, `--radius-lg: 10px`, `1px solid var(--border-subtle)`, `--shadow-sm`.
On hover: shadow to `--shadow-md`, `translateY(-2px)`, border to `--border-strong`,
220ms `--ease-standard`. **No colored left-border cards.** Featured cards swap the
white surface for navy with `--text-on-navy` and drop the border. Image-topped cards clip
the image to the card radius and never inset it.

### Borders and rules
Hairlines only: 1px, `--border-subtle` inside components, `--border-default` on inputs.
Focus is a 2px teal ring at 2px offset (`--shadow-focus` for filled controls). The **gold
1px rule** is a brand device, not a divider — use it flanking an eyebrow
(`.hh-rule-gold`) or under a section title, never to separate list rows.

### Shadows
Navy-tinted, never neutral black: `rgba(12,42,78,·)`. Five steps, xs→xl. Inner shadow is
used once — a 1px white inset on gold buttons (`--shadow-inset`) to keep them from looking
flat. Dark sections use borders and value contrast instead of shadows.

### Transparency and blur
Sparingly, and only over imagery: the transparent hero header, `--surface-glass`
(78% white + `--blur-glass`) for a docked booking bar over a photo, and
`--surface-overlay` (62% navy) behind modals. Never blur over flat color.
Prefer a **scrim gradient** over a **glass capsule** for text on photos; use a capsule
only for a small badge (price, "2 left") where a gradient would tint the whole image.

### Motion
Calm and short. 140ms for control state changes, 220ms for cards and reveals, 360ms for
modals/drawers. Easing is `cubic-bezier(.2,.6,.2,1)` — decelerating, no overshoot,
**no bounce, no spring, no auto-carousel**. Entrances are fade + 8px rise. Page-level
scroll reveals are permitted once per section, 220ms, never staggered beyond 3 items.
Respect `prefers-reduced-motion` by dropping transforms and keeping opacity.

### Interactive states
- **Hover:** solid buttons go one step *lighter* (navy 700→600, teal 700→600, gold 600→500);
  ghost/tertiary gain a tinted background (`--navy-050`); cards lift 2px; links change color
  and their underline darkens. Never opacity-fade a solid button on hover.
- **Press:** one step *darker* plus `scale(.985)`, 80ms. No shadow change.
- **Focus:** 2px teal ring, 2px offset, always visible on keyboard.
- **Selected:** teal 1.5px border + `--teal-100` fill (dates, room options, tabs).
- **Disabled:** `--gray-100` fill, `--gray-400` text, no border change, `cursor:not-allowed`,
  no opacity trick.
- **Loading:** label swaps for a 3-dot pulse in place; the button keeps its width.

---

## ICONOGRAPHY

**No icon set was supplied.** The logo contains illustrative silhouettes (tower, gabled
hall, archway, chandelier, table-and-chairs, wave) but these are brand illustration, not
a UI icon system, and they are not reusable as icons.

**Substitution (flagged):** UI icons use **Lucide** from CDN
(`https://unpkg.com/lucide@latest/dist/umd/lucide.js`) at **1.5px stroke**, 20px default
(16px inside small controls, 24px in nav). Lucide is the closest match to the logo's even,
geometric, open-stroke drawing: rounded caps, no fills, single weight. Rules:
- Stroke only. Never fill an icon except the **gold star** in `Rating`.
- Icons inherit `currentColor` — they are never separately colored.
- Optical size pairs with type: 16px icon with 13px label, 20px with 15px.
- Icons never appear alone in a marketing headline, and never replace a word in body copy.
- Common set: `calendar`, `users`, `bed-double`, `wifi`, `car`, `utensils`, `dumbbell`,
  `map-pin`, `star`, `chevron-*`, `x`, `check`, `search`, `key-round`, `phone`,
  `concierge-bell` (fallback `bell`), `sparkles` (events only).

**Emoji: never used.** **Unicode as icon:** in page and marketing content, only the
interpunct `•` as a separator and `—` as a gold rule — never an arrow or check in body copy.
Inside primitives, four typographic glyphs are used deliberately because they scale with the
type and need no icon dependency: `★` (Rating), `✓` (Checkbox), `▾` (Select caret) and
`• • •` (Button loading). Everything else is Lucide.

If Hotel Hall owns a licensed icon set or hand-drawn amenity glyphs, replace Lucide and
delete this section's substitution note.

---

## CAVEATS

1. **Fonts are substitutions.** Cinzel / Cormorant Garamond / Jost approximate the
   logo's lettering. Real binaries needed.
2. **Icons are substitutions.** Lucide, chosen for stroke compatibility.
3. **Logo is raster only** (PNG on white). No SVG, no reversed/knockout version, no
   mark-only original. `assets/logo-mark.png` is a crop, not an official variant.
   Nothing was redrawn — no new mark was created.
4. **Component and screen inventory is proposed**, not observed. There is no source
   defining Hotel Hall's real UI.
