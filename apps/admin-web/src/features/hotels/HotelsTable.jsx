import './responsiveTable.css'
import { Button } from '../../shared/components/Button.jsx'
import { SkeletonTableRow, Skeleton } from '../../shared/components/Skeleton.jsx'
import { StatusBadge } from './StatusBadge.jsx'
import { HotelIdentity } from './HotelIdentity.jsx'

const COLUMN_COUNT = 5

/**
 * The Hotel table shared by the Hotels page and the Applications page —
 * same real columns (Hotel, Status, Registered, Last Updated, Action) and
 * the same responsive behavior (a real `<table>` at comfortable widths, a
 * stacked card list below 720px via responsiveTable.css) either screen
 * would otherwise have to duplicate. Purely presentational: fetching,
 * filtering, and pagination stay with the caller.
 */
export function HotelsTable({ hotels, loadState, getAction, caption }) {
  return (
    <div>
      <div className="hh-table-view" style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <caption style={visuallyHidden}>{caption}</caption>
          <thead>
            <tr style={{ borderBottom: '1px solid var(--border-subtle)' }}>
              <th scope="col" style={headerCellStyle}>Hotel</th>
              <th scope="col" style={headerCellStyle}>Status</th>
              <th scope="col" style={headerCellStyle}>Registered</th>
              <th scope="col" style={headerCellStyle}>Last Updated</th>
              <th scope="col" style={{ ...headerCellStyle, textAlign: 'right' }}>Action</th>
            </tr>
          </thead>
          <tbody>
            {loadState === 'loading'
              ? Array.from({ length: 5 }).map((_, index) => <SkeletonTableRow key={index} columns={COLUMN_COUNT} />)
              : hotels.map((hotel) => {
                  const action = getAction(hotel)
                  return (
                    <tr key={hotel.id} className="hh-row-hover" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                      <td style={cellStyle}>
                        <HotelIdentity hotel={hotel} />
                      </td>
                      <td style={cellStyle}>
                        <StatusBadge status={hotel.status} />
                      </td>
                      <td style={cellStyle}>{new Date(hotel.createdAt).toLocaleDateString()}</td>
                      <td style={cellStyle}>{new Date(hotel.updatedAt).toLocaleDateString()}</td>
                      <td style={{ ...cellStyle, textAlign: 'right' }}>
                        <Button variant="ghost" size="sm" onClick={action.onClick} aria-label={action.ariaLabel}>
                          {action.label}
                        </Button>
                      </td>
                    </tr>
                  )
                })}
          </tbody>
        </table>
      </div>

      <div className="hh-card-view">
        {loadState === 'loading'
          ? Array.from({ length: 3 }).map((_, index) => (
              <div
                key={index}
                style={{
                  border: '1px solid var(--border-subtle)',
                  borderRadius: 'var(--radius-lg)',
                  padding: 'var(--space-5)',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 'var(--space-4)',
                }}
              >
                {/* Mirrors the real card's shape — name, badge, date pair,
                    action — so the layout does not jump when data lands. */}
                <Skeleton height={16} width="70%" />
                <Skeleton height={20} width={110} />
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--space-4)' }}>
                  <Skeleton height={28} />
                  <Skeleton height={28} />
                </div>
                <Skeleton height={36} />
              </div>
            ))
          : hotels.map((hotel) => {
              const action = getAction(hotel)
              return (
                <div
                  key={hotel.id}
                  style={{
                    border: '1px solid var(--border-subtle)',
                    borderRadius: 'var(--radius-lg)',
                    padding: 'var(--space-5)',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 'var(--space-4)',
                  }}
                >
                  {/* The name owns its own line. It used to share a
                      space-between row with the badge, which is nowrap
                      uppercase and runs past 200px on "Restricted Under
                      Review" — on a phone that crushed the name it was
                      meant to sit beside. */}
                  <HotelIdentity hotel={hotel} />

                  <div>
                    <StatusBadge status={hotel.status} />
                  </div>

                  {/* Two fixed columns rather than a wrapping flex row, so
                      the dates line up instead of reflowing into a ragged
                      pair at arbitrary widths. */}
                  <dl
                    style={{
                      margin: 0,
                      display: 'grid',
                      gridTemplateColumns: '1fr 1fr',
                      gap: 'var(--space-4)',
                      paddingTop: 'var(--space-4)',
                      borderTop: '1px solid var(--border-subtle)',
                    }}
                  >
                    {[
                      { label: 'Registered', value: hotel.createdAt },
                      { label: 'Last updated', value: hotel.updatedAt },
                    ].map(({ label, value }) => (
                      <div key={label} style={{ minWidth: 0 }}>
                        <dt
                          style={{
                            fontSize: 'var(--text-2xs)',
                            letterSpacing: 'var(--tracking-wider)',
                            textTransform: 'uppercase',
                            color: 'var(--text-muted)',
                          }}
                        >
                          {label}
                        </dt>
                        <dd style={{ margin: '4px 0 0', fontSize: 'var(--text-sm)', color: 'var(--text-body)' }}>
                          {new Date(value).toLocaleDateString()}
                        </dd>
                      </div>
                    ))}
                  </dl>

                  {/* Full width: a phone wants a real target, not a
                      small-size button parked at the left edge. */}
                  <Button variant="secondary" onClick={action.onClick} aria-label={action.ariaLabel} fullWidth>
                    {action.label}
                  </Button>
                </div>
              )
            })}
      </div>
    </div>
  )
}

const headerCellStyle = {
  textAlign: 'left',
  padding: 'var(--space-2) var(--space-3)',
  fontSize: 'var(--text-2xs)',
  letterSpacing: 'var(--tracking-wider)',
  textTransform: 'uppercase',
  color: 'var(--text-muted)',
}

const cellStyle = {
  padding: 'var(--space-3)',
  fontSize: 'var(--text-sm)',
  color: 'var(--text-body)',
}

const visuallyHidden = {
  position: 'absolute',
  width: 1,
  height: 1,
  padding: 0,
  margin: -1,
  overflow: 'hidden',
  clip: 'rect(0, 0, 0, 0)',
  whiteSpace: 'nowrap',
  border: 0,
}
