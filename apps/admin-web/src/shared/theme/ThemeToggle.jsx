import { IconMonitor, IconMoon, IconSun } from '../components/Icon.jsx'

const OPTIONS = [
  { value: 'light', label: 'Light', Icon: IconSun },
  { value: 'dark', label: 'Dark', Icon: IconMoon },
  { value: 'system', label: 'System', Icon: IconMonitor },
]

/**
 * Three-way theme control for the top bar. All three choices are shown at
 * once rather than cycled through one button, so "System" is discoverable
 * and the current choice is readable without interacting.
 *
 * Colours are fixed translucent-white here, like the other top-bar controls
 * — this sits on `--surface-navy`, which is a dark surface in both themes.
 */
export function ThemeToggle({ preference, onChange }) {
  return (
    <div
      role="radiogroup"
      aria-label="Colour theme"
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 2,
        padding: 2,
        border: '1px solid rgba(255,255,255,0.18)',
        borderRadius: 'var(--radius-md)',
        background: 'rgba(255,255,255,0.06)',
      }}
    >
      {OPTIONS.map(({ value, label, Icon }) => {
        const selected = preference === value
        return (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={selected}
            aria-label={label}
            title={label}
            onClick={() => onChange(value)}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 28,
              height: 28,
              border: 'none',
              borderRadius: 'calc(var(--radius-md) - 2px)',
              background: selected ? 'rgba(255,255,255,0.18)' : 'transparent',
              color: selected ? 'var(--white)' : 'rgba(255,255,255,0.65)',
              cursor: 'pointer',
            }}
          >
            <Icon size={15} />
          </button>
        )
      })}
    </div>
  )
}
