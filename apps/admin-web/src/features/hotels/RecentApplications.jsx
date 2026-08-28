import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { listHotels } from '../../shared/api/hotelsApi.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { StateMessage } from '../../shared/components/StateMessage.jsx'
import { HotelsTable } from './HotelsTable.jsx'
import { APPLICATION_STATUSES } from './hotelStatus.js'

const RECENT_LIMIT = 5

/**
 * "Recent Hotel Applications" — the most recently updated Hotels across
 * every application-producing status (`APPLICATION_STATUSES`). `GET
 * /hotels` only filters on one status per call, so this issues one call
 * per status (small, bounded, parallel) and merges by `updatedAt`
 * client-side — still exactly the real records `GET /hotels` returns, no
 * synthetic "application" entity.
 */
export function RecentApplications({ onSelectHotel }) {
  const { accessToken } = useAuth()
  const [hotels, setHotels] = useState([])
  const [loadState, setLoadState] = useState('loading')
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoadState('loading')
    setError('')
    try {
      const results = await Promise.all(
        APPLICATION_STATUSES.map((status) => listHotels(accessToken, { status, page: 1, limit: RECENT_LIMIT })),
      )
      const merged = results
        .flatMap((result) => result.data)
        .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))
        .slice(0, RECENT_LIMIT)
      setHotels(merged)
      setLoadState('ready')
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong. Please try again.')
      setLoadState('error')
    }
  }, [accessToken])

  useEffect(() => {
    load()
  }, [load])

  if (loadState === 'error') {
    return <StateMessage tone="error" title="Couldn’t load recent applications" message={error} onRetry={load} />
  }

  if (loadState === 'ready' && hotels.length === 0) {
    return (
      <StateMessage
        title="No hotel applications found"
        message="No Hotel has submitted, been decided on, or withdrawn an application yet."
      />
    )
  }

  return (
    <HotelsTable
      hotels={hotels}
      loadState={loadState}
      caption="Most recently updated Hotel applications"
      getAction={(hotel) => ({
        label: hotel.status === 'UNDER_REVIEW' ? 'Review' : 'View',
        ariaLabel: `${hotel.status === 'UNDER_REVIEW' ? 'Review' : 'View'} application for hotel registered ${new Date(hotel.createdAt).toLocaleDateString()}`,
        onClick: () => onSelectHotel?.(hotel.id),
      })}
    />
  )
}
