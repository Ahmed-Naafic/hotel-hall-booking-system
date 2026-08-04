const ROOMS = [
  { id: "harbour", name: "Harbour Suite", meta: "King bed · Sleeps 2 · 38 m²", price: 248, rating: 4.8, reviews: 218, tags: ["Harbour view", "Balcony"], note: "Corner windows on the harbour side, with a king bed and a writing desk." },
  { id: "garden", name: "Garden Double", meta: "Queen bed · Sleeps 2 · 26 m²", price: 186, rating: 4.6, reviews: 164, tags: ["Quiet wing"], note: "Ground floor, opening onto the courtyard. Best for a longer stay." },
  { id: "hall", name: "Hall Family Room", meta: "King + twin · Sleeps 4 · 44 m²", price: 312, rating: 4.7, reviews: 96, tags: ["Connecting", "Breakfast"], note: "Two rooms joined by a private hallway, with a full bath in each." },
  { id: "tower", name: "Tower Studio", meta: "Queen bed · Sleeps 2 · 22 m²", price: 164, rating: 4.4, reviews: 302, tags: ["City view"], note: "Compact and high up, with a deep window seat over the old town." },
];

const AMENITIES = [
  { icon: "utensils", label: "Harbour restaurant", note: "Breakfast 7–10 AM, dinner from 6 PM" },
  { icon: "wifi", label: "Wi-Fi throughout", note: "Included in every rate" },
  { icon: "car", label: "Valet parking", note: "$32 per night" },
  { icon: "dumbbell", label: "Fitness room", note: "Open 24 hours" },
];

Object.assign(window, { ROOMS, AMENITIES });
