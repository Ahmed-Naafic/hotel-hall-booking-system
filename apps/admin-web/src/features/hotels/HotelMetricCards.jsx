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
  navy: { fg: 'var(--text-heading)', bg: 'var(--surface-navy-tint)' },
  teal: { fg: 'var(--text-accent)', bg: 'var(--surface-teal-tint)' },
  success: { fg: 'var(--success-700)', bg: 'var(--success-100)' },
  gold: { fg: 'var(--text-gold)', bg: 'var(--surface-gold-tint)' },
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
              position: 'relative',
              overflow: 'hidden',
              background: 'var(--surface-card)',
              border: '1px solid var(--border-subtle)',
              borderRadius: 'var(--radius-lg)',
              boxShadow: 'var(--shadow-sm)',
              padding: 'var(--space-7)',
            }}
          >
            {/* The icon retreats to a quiet mark in the corner rather than
                competing with the number for the eye. The count is the
                point of a stat tile; everything else is a label for it. */}
            <span
              aria-hidden="true"
              style={{
                position: 'absolute',
                top: 'var(--space-5)',
                right: 'var(--space-5)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 32,
                height: 32,
                borderRadius: 'var(--radius-md)',
                background: tone.bg,
                color: tone.fg,
              }}
            >
              <Icon size={16} />
            </span>

            <p
              className="hh-eyebrow"
              style={{ margin: 0, color: 'var(--text-muted)', paddingRight: 44 }}
            >
              {label}
            </p>

            {loadState === 'loading' ? (
              <div style={{ marginTop: 'var(--space-4)' }}>
                <Skeleton width={56} height={34} />
              </div>
            ) : (
              <p
                style={{
                  margin: 'var(--space-3) 0 0',
                  fontFamily: 'var(--font-display)',
                  fontSize: 'var(--display-md)',
                  lineHeight: 'var(--display-leading)',
                  letterSpacing: 'var(--display-tracking)',
                  color: 'var(--text-heading)',
                }}
              >
                {counts[key]}
              </p>
            )}

            {/* A gold hairline, the brand's rule device, sitting under the
                figure the way it sits under a section title. */}
            <div
              aria-hidden="true"
              style={{
                height: 1,
                width: 28,
                marginTop: 'var(--space-4)',
                background: 'var(--border-rule-gold)',
                opacity: 0.6,
              }}
            />
          </div>
        )
      })}
    </div>
  )
}
