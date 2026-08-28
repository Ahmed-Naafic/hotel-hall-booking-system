import { Skeleton } from '../../shared/components/Skeleton.jsx'
import { StateMessage } from '../../shared/components/StateMessage.jsx'
import { IconGrid, IconClipboard, IconBuilding, IconAlertTriangle } from '../../shared/components/Icon.jsx'

/**
 * Overview metric cards — Total Hotels, Pending Applications, Active
 * Hotels, Suspended/Restricted Hotels. `counts`/`loadState`/`error`/
 * `reload` come from a single shared `useHotelStatusCounts()` call in
 * OverviewView, passed down as props — both this and HotelStatusSummary
 * read the same real `GET /hotels` data, so the fetch happens once, not
 * once per card.
 */
const CARDS = [
  { key: 'total', label: 'Total Hotels', accent: 'navy', Icon: IconGrid },
  { key: 'pending', label: 'Pending Applications', accent: 'teal', Icon: IconClipboard },
  { key: 'active', label: 'Active Hotels', accent: 'success', Icon: IconBuilding },
  { key: 'suspendedRestricted', label: 'Suspended / Restricted', accent: 'gold', Icon: IconAlertTriangle },
]

const ACCENT_STYLES = {
  navy: { fg: 'var(--navy-700)', bg: 'var(--navy-050)' },
  teal: { fg: 'var(--teal-700)', bg: 'var(--teal-100)' },
  success: { fg: 'var(--success-700)', bg: 'var(--success-100)' },
  gold: { fg: 'var(--gold-700)', bg: 'var(--gold-100)' },
}

export function HotelMetricCards({ counts, loadState, error, reload }) {
  if (loadState === 'error') {
    return <StateMessage tone="error" title="Couldn’t load the Hotels overview" message={error} onRetry={reload} />
  }

  return (
    <div
      role="group"
      aria-label="Hotels overview"
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 'var(--space-4)',
      }}
    >
      {CARDS.map(({ key, label, accent, Icon }) => {
        const tone = ACCENT_STYLES[accent]
        return (
          <div
            key={key}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 'var(--space-4)',
              background: 'var(--surface-card)',
              border: '1px solid var(--border-subtle)',
              borderRadius: 'var(--radius-lg)',
              boxShadow: 'var(--shadow-sm)',
              padding: 'var(--card-pad)',
            }}
          >
            <span
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 40,
                height: 40,
                flex: '0 0 auto',
                borderRadius: 'var(--radius-md)',
                background: tone.bg,
                color: tone.fg,
              }}
            >
              <Icon size={20} />
            </span>
            <div style={{ minWidth: 0 }}>
              <p
                style={{
                  margin: '0 0 2px',
                  fontSize: 'var(--text-xs)',
                  letterSpacing: 'var(--tracking-wide)',
                  color: 'var(--text-muted)',
                }}
              >
                {label}
              </p>
              {loadState === 'loading' ? (
                <Skeleton width={44} height={26} />
              ) : (
                <p
                  style={{
                    margin: 0,
                    fontFamily: 'var(--font-display)',
                    fontSize: 'var(--display-sm)',
                    color: 'var(--text-heading)',
                  }}
                >
                  {counts[key]}
                </p>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
