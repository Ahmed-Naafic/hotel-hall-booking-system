import { Skeleton } from '../../shared/components/Skeleton.jsx'
import { StateMessage } from '../../shared/components/StateMessage.jsx'

/**
 * A visual summary of where Hotels sit in the lifecycle — Pending Review,
 * Approved/Active, Rejected, Suspended/Restricted (the same four buckets
 * as the metric cards). `counts`/`loadState`/`error`/`reload` come from a
 * single shared `useHotelStatusCounts()` call in OverviewView, passed down
 * as props, so this and HotelMetricCards read one fetch, not two, and can
 * never disagree. No chart library is installed in admin-web
 * (package.json has only react/react-dom), so this is a plain CSS
 * horizontal bar list rather than pulling in a new dependency for one
 * visualization.
 */
const ROWS = [
  { key: 'pending', label: 'Pending Review', barColor: 'var(--navy-600)' },
  { key: 'active', label: 'Approved / Active', barColor: 'var(--success-500)' },
  { key: 'rejected', label: 'Rejected', barColor: 'var(--danger-500)' },
  { key: 'suspendedRestricted', label: 'Suspended / Restricted', barColor: 'var(--gold-600)' },
]

export function HotelStatusSummary({ counts, loadState, error, reload }) {
  if (loadState === 'error') {
    return <StateMessage tone="error" title="Couldn’t load the status summary" message={error} onRetry={reload} />
  }

  const max = loadState === 'ready' ? Math.max(1, ...ROWS.map((row) => counts[row.key])) : 1

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
      {ROWS.map((row) => {
        const value = loadState === 'ready' ? counts[row.key] : null
        const pct = value === null ? 0 : Math.round((value / max) * 100)
        return (
          <div key={row.key}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'baseline',
                marginBottom: 6,
                fontSize: 'var(--text-sm)',
              }}
            >
              <span style={{ color: 'var(--text-body)' }}>{row.label}</span>
              {loadState === 'loading' ? (
                <Skeleton width={20} height={14} />
              ) : (
                <span style={{ color: 'var(--text-heading)', fontWeight: 'var(--weight-semibold)' }}>{value}</span>
              )}
            </div>
            <div
              style={{
                height: 8,
                borderRadius: 'var(--radius-pill)',
                background: 'var(--surface-sunken)',
                overflow: 'hidden',
              }}
            >
              <div
                style={{
                  height: '100%',
                  width: loadState === 'ready' ? `${pct}%` : '0%',
                  minWidth: loadState === 'ready' && value > 0 ? 6 : 0,
                  borderRadius: 'var(--radius-pill)',
                  background: row.barColor,
                  transition: 'width var(--dur-slow) var(--ease-standard)',
                }}
              />
            </div>
          </div>
        )
      })}
    </div>
  )
}
