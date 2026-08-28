import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { countHotels } from '../../shared/api/hotelsApi.js'
import { ApiError } from '../../shared/api/apiClient.js'

/**
 * The one place that turns `GET /hotels` (Technical Design §11) into the
 * counts both the Overview metric cards and the Hotel Status Summary chart
 * need — each status bucket is a real `pagination.total` read at
 * `limit=1`, never a hardcoded or estimated number. Shared here so the two
 * screens don't each issue their own duplicate set of requests.
 */
export function useHotelStatusCounts() {
  const { accessToken } = useAuth()
  const [counts, setCounts] = useState(null)
  const [loadState, setLoadState] = useState('loading')
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    setLoadState('loading')
    setError('')
    try {
      const [total, underReview, approvedActive, rejected, suspended, restricted] = await Promise.all([
        countHotels(accessToken),
        countHotels(accessToken, { status: 'UNDER_REVIEW' }),
        countHotels(accessToken, { status: 'APPROVED_ACTIVE' }),
        countHotels(accessToken, { status: 'REJECTED' }),
        countHotels(accessToken, { status: 'SUSPENDED' }),
        countHotels(accessToken, { status: 'RESTRICTED_UNDER_REVIEW' }),
      ])
      setCounts({
        total,
        pending: underReview,
        active: approvedActive,
        rejected,
        suspendedRestricted: suspended + restricted,
      })
      setLoadState('ready')
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong. Please try again.')
      setLoadState('error')
    }
  }, [accessToken])

  useEffect(() => {
    load()
  }, [load])

  return { counts, loadState, error, reload: load }
}
