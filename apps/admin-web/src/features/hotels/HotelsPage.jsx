import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { listHotels } from '../../shared/api/hotelsApi.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { Button } from '../../shared/components/Button.jsx'
import { StateMessage } from '../../shared/components/StateMessage.jsx'
import { HotelsTable } from './HotelsTable.jsx'
import { HOTEL_STATUSES, formatStatusLabel } from './hotelStatus.js'

/**
 * The full Hotel registry (Technical Design §11, `GET /hotels`) — every
 * Hotel regardless of lifecycle stage. The "Applications" area
 * (ApplicationsPage.jsx) is the narrower, application-focused view of the
 * same data; this page is the general directory. The only action offered
 * is "View" (`GET /hotels/:id`) — no approve/reject/suspend/deactivate
 * action exists here; that endpoint is Administration & Platform
 * Management's own future API surface (BR-HOTEL-14), not built yet.
 */
export function HotelsPage({ onSelectHotel }) {
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

  const isEmpty = loadState === 'ready' && hotels.length === 0

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
          <span style={{ fontSize: 'var(--text-xs)', letterSpacing: 'var(--tracking-wide)', color: 'var(--text-muted)' }}>
            Status
          </span>
          <select
            value={status}
            onChange={(e) => {
              setPage(1)
              setStatus(e.target.value)
            }}
            aria-label="Filter Hotels by status"
            style={selectStyle}
          >
            <option value="">All</option>
            {HOTEL_STATUSES.map((value) => (
              <option key={value} value={value}>
                {formatStatusLabel(value)}
              </option>
            ))}
          </select>
        </label>
        <Button variant="ghost" size="sm" onClick={load} disabled={loadState === 'loading'}>
          Refresh
        </Button>
      </div>

      {loadState === 'error' ? (
        <StateMessage tone="error" title="Couldn’t load Hotels" message={error} onRetry={load} />
      ) : isEmpty ? (
        <StateMessage
          title={status ? 'No Hotels match this filter' : 'No Hotels found'}
          message={
            status
              ? `There are currently no Hotels with status “${formatStatusLabel(status)}.” Try a different filter.`
              : 'No Hotels have been registered on the Platform yet.'
          }
          {...(status ? { retryLabel: 'Clear filter', onRetry: () => { setPage(1); setStatus('') } } : {})}
        />
      ) : (
        <>
          <HotelsTable
            hotels={hotels}
            loadState={loadState}
            caption="List of Hotels registered on the Platform"
            getAction={(hotel) => ({
              label: 'View',
              ariaLabel: `View details for hotel registered ${new Date(hotel.createdAt).toLocaleDateString()}`,
              onClick: () => onSelectHotel?.(hotel.id),
            })}
          />

          {pagination ? (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
                gap: 'var(--space-3)',
                marginTop: 'var(--space-4)',
              }}
            >
              <span style={{ fontSize: 'var(--text-xs)', color: 'var(--text-subtle)' }}>
                Page {pagination.page} of {pagination.totalPages} &middot; {pagination.total} total
              </span>
              <div style={{ display: 'flex', gap: 'var(--space-2)' }}>
                <Button variant="secondary" size="sm" disabled={!pagination.hasPrevious} onClick={() => setPage((p) => p - 1)}>
                  Previous
                </Button>
                <Button variant="secondary" size="sm" disabled={!pagination.hasNext} onClick={() => setPage((p) => p + 1)}>
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

const selectStyle = {
  height: 'var(--control-h-sm)',
  borderRadius: 'var(--radius-control)',
  border: '1px solid var(--border-default)',
  background: 'var(--surface-card)',
  color: 'var(--text-body)',
  padding: '0 10px',
  fontFamily: 'var(--font-sans)',
  fontSize: 'var(--text-sm)',
}
