import { useEffect, useRef } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

// Brand navy (`--navy-700` / `--action-primary`, colors.css) — a literal
// hex because Leaflet's icon is built outside React's styled tree (an SVG
// string handed to `L.divIcon`), where a CSS custom property can't resolve.
const PIN_COLOR = '#0c2a4e'

// A simple navy teardrop pin (brand color, not Leaflet's default blue) with
// a white center dot, built as an inline SVG so it needs no separate image
// asset. `iconAnchor` points at the pin's tip — the exact coordinate — and
// `popupAnchor` opens the popup just above it.
const navyPinIcon = L.divIcon({
  className: 'hh-map-pin',
  html: `<svg width="28" height="38" viewBox="0 0 28 38" xmlns="http://www.w3.org/2000/svg">
    <path d="M14 0C6.268 0 0 6.268 0 14c0 10.5 14 24 14 24s14-13.5 14-24C28 6.268 21.732 0 14 0z" fill="${PIN_COLOR}"/>
    <circle cx="14" cy="14" r="5.5" fill="#ffffff"/>
  </svg>`,
  iconSize: [28, 38],
  iconAnchor: [14, 38],
  popupAnchor: [0, -34],
})

/**
 * Read-only OpenStreetMap view of a Hotel's exact coordinates
 * (`Hotel.profileData.location`, ADR-0008). Manager Mobile captures these
 * through its own OSM-tile location picker (`flutter_map`); this is the
 * Platform Administrator's equivalent read surface — a pin, not an editor —
 * so the Administrator can see where a Hotel actually is instead of only
 * its free-text address. Same tile provider and attribution as Manager
 * Mobile, per ADR-0008; the pin itself uses the brand navy rather than
 * Leaflet's default blue.
 */
export function HotelLocationMap({ latitude, longitude, label }) {
  const containerRef = useRef(null)

  useEffect(() => {
    if (!containerRef.current) return undefined
    const map = L.map(containerRef.current, {
      center: [latitude, longitude],
      zoom: 16,
      scrollWheelZoom: false,
    })
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19,
    }).addTo(map)
    const marker = L.marker([latitude, longitude], { icon: navyPinIcon }).addTo(map)
    if (label) marker.bindPopup(label)

    return () => {
      map.remove()
    }
  }, [latitude, longitude, label])

  return (
    <div
      ref={containerRef}
      aria-label={label ? `Map showing the location of ${label}` : 'Hotel location map'}
      style={{
        height: 260,
        width: '100%',
        borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--border-subtle)',
        overflow: 'hidden',
      }}
    />
  )
}
