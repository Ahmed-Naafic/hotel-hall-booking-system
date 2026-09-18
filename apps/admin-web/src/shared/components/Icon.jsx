/**
 * A small hand-authored stroke-icon set — avoids pulling in an icon library
 * dependency for a handful of glyphs. Every icon shares the same visual
 * language (24x24 viewBox, 1.75 stroke, round joins) so they read as one
 * family regardless of which screen uses them.
 */
const base = {
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.75,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
}

function Svg({ size = 18, style, children, ...rest }) {
  return (
    <svg width={size} height={size} style={style} aria-hidden="true" focusable="false" {...base} {...rest}>
      {children}
    </svg>
  )
}

export function IconGrid(props) {
  return (
    <Svg {...props}>
      <rect x="3.5" y="3.5" width="7.5" height="7.5" rx="1.5" />
      <rect x="13" y="3.5" width="7.5" height="7.5" rx="1.5" />
      <rect x="3.5" y="13" width="7.5" height="7.5" rx="1.5" />
      <rect x="13" y="13" width="7.5" height="7.5" rx="1.5" />
    </Svg>
  )
}

export function IconBuilding(props) {
  return (
    <Svg {...props}>
      <rect x="5" y="3" width="14" height="18" rx="1" />
      <path d="M9 7h1.2M13.8 7H15M9 11h1.2M13.8 11H15M9 15h1.2M13.8 15H15" />
      <path d="M10.5 21v-3.5h3V21" />
    </Svg>
  )
}

export function IconClipboard(props) {
  return (
    <Svg {...props}>
      <rect x="5.5" y="4.5" width="13" height="16" rx="1.5" />
      <path d="M9 4.5V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v.5" />
      <path d="M8.5 11.5l2 2 4.5-4.5M8.5 16.5h7" />
    </Svg>
  )
}

export function IconBell(props) {
  return (
    <Svg {...props}>
      <path d="M6 10.5a6 6 0 0 1 12 0c0 3.2 1 4.8 1.6 5.5H4.4C5 15.3 6 13.7 6 10.5Z" />
      <path d="M10 19a2 2 0 0 0 4 0" />
    </Svg>
  )
}

export function IconChevronDown(props) {
  return (
    <Svg {...props}>
      <path d="M6 9l6 6 6-6" />
    </Svg>
  )
}

export function IconMenu(props) {
  return (
    <Svg {...props}>
      <path d="M4 6.5h16M4 12h16M4 17.5h16" />
    </Svg>
  )
}

export function IconClose(props) {
  return (
    <Svg {...props}>
      <path d="M6 6l12 12M18 6L6 18" />
    </Svg>
  )
}

export function IconArrowLeft(props) {
  return (
    <Svg {...props}>
      <path d="M19 12H5M11 6l-6 6 6 6" />
    </Svg>
  )
}

export function IconUser(props) {
  return (
    <Svg {...props}>
      <circle cx="12" cy="8" r="3.25" />
      <path d="M5 20c1-3.6 4-5.5 7-5.5s6 1.9 7 5.5" />
    </Svg>
  )
}

export function IconLock(props) {
  return (
    <Svg {...props}>
      <rect x="5.5" y="10.5" width="13" height="9.5" rx="1.5" />
      <path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" />
    </Svg>
  )
}

export function IconLogout(props) {
  return (
    <Svg {...props}>
      <path d="M14 8V6a2 2 0 0 0-2-2H6.5A1.5 1.5 0 0 0 5 5.5v13A1.5 1.5 0 0 0 6.5 20H12a2 2 0 0 0 2-2v-2" />
      <path d="M9.5 12H21M21 12l-3.5-3.5M21 12l-3.5 3.5" />
    </Svg>
  )
}

export function IconAlertTriangle(props) {
  return (
    <Svg {...props}>
      <path d="M12 4.5 21 19.5H3L12 4.5Z" />
      <path d="M12 10v4.2M12 17.2v.1" />
    </Svg>
  )
}

export function IconInbox(props) {
  return (
    <Svg {...props}>
      <path d="M4 12.5 6.5 5h11L20 12.5" />
      <path d="M4 12.5v6A1.5 1.5 0 0 0 5.5 20h13a1.5 1.5 0 0 0 1.5-1.5v-6h-4.6a2.4 2.4 0 0 1-4.8 0H4Z" />
    </Svg>
  )
}

export function IconMapPin(props) {
  return (
    <Svg {...props}>
      <path d="M12 21s7-6.3 7-11.5A7 7 0 0 0 5 9.5C5 14.7 12 21 12 21Z" />
      <circle cx="12" cy="9.5" r="2.25" />
    </Svg>
  )
}

export function IconSettingsSlider(props) {
  return (
    <Svg {...props}>
      <path d="M4 7h9M17 7h3M4 17h3M11 17h9" />
      <circle cx="13.5" cy="7" r="2.25" />
      <circle cx="8" cy="17" r="2.25" />
    </Svg>
  )
}

export function IconSun(props) {
  return (
    <Svg {...props}>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.2 5.2l1.4 1.4M17.4 17.4l1.4 1.4M18.8 5.2l-1.4 1.4M6.6 17.4l-1.4 1.4" />
    </Svg>
  )
}

export function IconMoon(props) {
  return (
    <Svg {...props}>
      <path d="M20 13.5A8 8 0 0 1 10.5 4a8 8 0 1 0 9.5 9.5Z" />
    </Svg>
  )
}

export function IconMonitor(props) {
  return (
    <Svg {...props}>
      <rect x="3" y="4.5" width="18" height="12" rx="1.5" />
      <path d="M9 20h6M12 16.5V20" />
    </Svg>
  )
}
