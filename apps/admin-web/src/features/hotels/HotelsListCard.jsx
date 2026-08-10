import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { listHotels } from '../../shared/api/hotelsApi.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { Button } from '../../shared/components/Button.jsx'

const STATUS_OPTIONS = [
  'REGISTERED',
  'PROFILE_COMPLETE',
  'UNDER_REVIEW',
  'APPROVED_ACTIVE',
  'REJECTED',
  'WITHDRAWN',
  'SUSPENDED',
  'DEACTIVATED',
  'RESTRICTED_UNDER_REVIEW',
]

const STATUS_BADGE_COLOR = {
  REGISTERED: 'var(--navy-400)',
  PROFILE_COMPLETE: 'var(--navy-500)',
  UNDER_REVIEW: 'var(--info-700)',
  APPROVED_ACTIVE: 'var(--success-700)',
  REJECTED: 'var(--danger-700)',
  WITHDRAWN: 'var(--navy-400)',
  SUSPENDED: 'var(--danger-700)',
  DEACTIVATED: 'var(--danger-700)',
  RESTRICTED_UNDER_REVIEW: 'var(--gold-700)',
}

const STATUS_BADGE_BG = {
  REGISTERED: 'var(--navy-050)',
  PROFILE_COMPLETE: 'var(--navy-050)',
  UNDER_REVIEW: 'var(--info-100)',
  APPROVED_ACTIVE: 'var(--success-100)',
  REJECTED: 'var(--danger-100)',
  WITHDRAWN: 'var(--navy-050)',
  SUSPENDED: 'var(--danger-100)',
  DEACTIVATED: 'var(--danger-100)',
  RESTRICTED_UNDER_REVIEW: 'var(--gold-100)',
}

function StatusBadge({ status }) {
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '2px 10px',
        borderRadius: 'var(--radius-full, 999px)',
        fontSize: 'var(--text-2xs)',
        fontWeight: 'var(--weight-medium)',
        letterSpacing: 'var(--tracking-wider)',
        textTransform: 'uppercase',
        color: STATUS_BADGE_COLOR[status] ?? 'var(--text-subtle)',
        background: STATUS_BADGE_BG[status] ?? 'var(--navy-050)',
      }}
    >
      {status.replaceAll('_', ' ')}
    </span>
  )
}

/**
 * Platform Administrator's Hotel list (Technical Design §11, `GET /hotels`)
 * — the query interface behind the Hotel approval queue
 * (system-architecture-overview.md §4). No approve/reject/suspend action
 * exists here; that endpoint is Administration & Platform Management's own
 * future API surface (BR-HOTEL-14), not built yet.
 */
export function HotelsListCard() {
  const { accessToken } = useAuth()
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)
  const [hotels, setHotels] = useState([])
  const [pagination, setPagination] = useState(null)
  const [loadState, setLoadState] = useState('loading')
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoadState('loading')
    setError('')
    try {
      const { data, pagination: pageInfo } = await listHotels(accessToken, {
        status: status || undefined,
        page,
        limit: 20,
      })
      setHotels(data)
      setPagination(pageInfo)
      setLoadState('ready')
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong. Please try again.')
      setLoadState('error')
    }
  }, [accessToken, status, page])

  useEffect(() => {
    load()
  }, [load])

  return (
    <div>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: 'var(--space-4)',
          gap: 'var(--space-4)',
          flexWrap: 'wrap',
        }}
      >
        <label style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
          <span
            style={{
              fontSize: 'var(--text-xs)',
              letterSpacing: 'var(--tracking-wider)',
              textTransform: 'uppercase',
              color: 'var(--text-muted)',
            }}
          >
            Status
          </span>
          <select
            value={status}
            onChange={(e) => {
              setPage(1)
              setStatus(e.target.value)
            }}
            style={{
              height: 'var(--control-h-sm)',
              borderRadius: 'var(--radius-control)',
              border: '1px solid var(--border-default)',
              background: 'var(--surface-card)',
              color: 'var(--text-body)',
              padding: '0 10px',
              fontFamily: 'var(--font-sans)',
              fontSize: 'var(--text-sm)',
            }}
          >
            <option value="">All</option>
            {STATUS_OPTIONS.map((value) => (
              <option key={value} value={value}>
                {value.replaceAll('_', ' ')}
              </option>
            ))}
          </select>
        </label>
        <Button variant="ghost" size="sm" onClick={load} disabled={loadState === 'loading'}>
          Refresh
        </Button>
      </div>

      {loadState === 'error' ? (
        <p style={{ color: 'var(--danger-700)' }}>{error}</p>
      ) : loadState === 'loading' ? (
        <p style={{ color: 'var(--text-subtle)' }}>Loading&hellip;</p>
      ) : hotels.length === 0 ? (
        <p style={{ color: 'var(--text-subtle)' }}>No Hotels match this filter.</p>
      ) : (
        <>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                  <th style={headerCellStyle}>Hotel ID</th>
                  <th style={headerCellStyle}>Status</th>
                  <th style={headerCellStyle}>Registered</th>
                </tr>
              </thead>
              <tbody>
                {hotels.map((hotel) => (
                  <tr key={hotel.id} style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                    <td style={cellStyle}>
                      <code style={{ fontSize: 'var(--text-xs)' }}>{hotel.id}</code>
                    </td>
                    <td style={cellStyle}>
                      <StatusBadge status={hotel.status} />
                    </td>
                    <td style={cellStyle}>{new Date(hotel.createdAt).toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {pagination ? (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginTop: 'var(--space-4)',
              }}
            >
              <span style={{ fontSize: 'var(--text-xs)', color: 'var(--text-subtle)' }}>
                Page {pagination.page} of {pagination.totalPages} &middot; {pagination.total} total
              </span>
              <div style={{ display: 'flex', gap: 'var(--space-2)' }}>
                <Button
                  variant="secondary"
                  size="sm"
                  disabled={!pagination.hasPrevious}
                  onClick={() => setPage((p) => p - 1)}
                >
                  Previous
                </Button>
                <Button
                  variant="secondary"
                  size="sm"
                  disabled={!pagination.hasNext}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Next
                </Button>
              </div>
            </div>
          ) : null}
        </>
      )}
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
  padding: 'var(--space-2) var(--space-3)',
  fontSize: 'var(--text-sm)',
  color: 'var(--text-body)',
}
