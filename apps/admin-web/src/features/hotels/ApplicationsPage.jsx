import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { listHotels } from '../../shared/api/hotelsApi.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { Button } from '../../shared/components/Button.jsx'
import { StateMessage } from '../../shared/components/StateMessage.jsx'
import { HotelsTable } from './HotelsTable.jsx'
import { APPLICATION_STATUSES, formatStatusLabel } from './hotelStatus.js'

/**
 * The Hotel application queue — the same `GET /hotels` endpoint as
 * HotelsPage, scoped to the statuses an Application actually produces
 * (`APPLICATION_STATUSES` — UNDER_REVIEW, APPROVED_ACTIVE, REJECTED,
 * WITHDRAWN, per application.service.js/lifecycle.service.js). The API
 * only accepts one status per request, so each segment below is its own
 * `GET /hotels?status=...` call rather than a client-side merge — no new
 * endpoint, no invented "application" record.
 */
export function ApplicationsPage({ onSelectHotel }) {
  const { accessToken } = useAuth()
  const [status, setStatus] = useState('UNDER_REVIEW')
  const [page, setPage] = useState(1)
  const [hotels, setHotels] = useState([])
  const [pagination, setPagination] = useState(null)
  const [loadState, setLoadState] = useState('loading')
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoadState('loading')
    setError('')
    try {
      const { data, pagination: pageInfo } = await listHotels(accessToken, { status, page, limit: 20 })
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
        role="tablist"
        aria-label="Application status"
        style={{ display: 'flex', gap: 'var(--space-2)', marginBottom: 'var(--space-5)', flexWrap: 'wrap' }}
      >
        {APPLICATION_STATUSES.map((value) => (
          <button
            key={value}
            role="tab"
            aria-selected={status === value}
            onClick={() => {
              setPage(1)
              setStatus(value)
            }}
            style={{
              height: 'var(--control-h-sm)',
              padding: '0 16px',
              borderRadius: 'var(--radius-pill)',
              border: `1px solid ${status === value ? 'var(--teal-700)' : 'var(--border-default)'}`,
              background: status === value ? 'var(--teal-100)' : 'var(--surface-card)',
              color: status === value ? 'var(--teal-800)' : 'var(--text-body)',
              fontFamily: 'var(--font-sans)',
              fontSize: 'var(--text-sm)',
              fontWeight: status === value ? 'var(--weight-medium)' : 'var(--weight-regular)',
              cursor: 'pointer',
            }}
          >
            {formatStatusLabel(value)}
          </button>
        ))}
      </div>

      {loadState === 'error' ? (
        <StateMessage tone="error" title="Couldn’t load applications" message={error} onRetry={load} />
      ) : isEmpty ? (
        <StateMessage
          title="No hotel applications found"
          message={`There are currently no Hotels with an application in “${formatStatusLabel(status)}” status.`}
        />
      ) : (
        <>
          <HotelsTable
            hotels={hotels}
            loadState={loadState}
            caption={`Hotel applications with status ${formatStatusLabel(status)}`}
            getAction={(hotel) => ({
              label: status === 'UNDER_REVIEW' ? 'Review' : 'View',
              ariaLabel: `${status === 'UNDER_REVIEW' ? 'Review' : 'View'} application for hotel registered ${new Date(hotel.createdAt).toLocaleDateString()}`,
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
