import { apiRequestPage } from './apiClient.js'

/**
 * Hotel Management module's API client (backend Technical Design §11).
 * Admin Web only ever calls the Platform-Administrator-facing query
 * interface (`GET /hotels`) — no approve/reject/suspend/deactivate action
 * exists here, since that endpoint belongs to Administration & Platform
 * Management's own future API surface (BR-HOTEL-14), not built yet.
 */
export function listHotels(accessToken, { status, page = 1, limit = 20 } = {}) {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) })
  if (status) {
    params.set('status', status)
  }
  return apiRequestPage(`/hotels?${params.toString()}`, { accessToken })
}
