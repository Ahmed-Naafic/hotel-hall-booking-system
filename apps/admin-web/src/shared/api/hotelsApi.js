import { apiRequest, apiRequestPage } from './apiClient.js'

/**
 * Hotel Management module's API client (backend Technical Design §11).
 * Admin Web only ever calls the Platform-Administrator-facing query
 * interface (`GET /hotels`, `GET /hotels/:id`) — no approve/reject/suspend/
 * deactivate action exists here, since that endpoint belongs to
 * Administration & Platform Management's own future API surface
 * (BR-HOTEL-14), not built yet.
 */
export function listHotels(accessToken, { status, page = 1, limit = 20 } = {}) {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) })
  if (status) {
    params.set('status', status)
  }
  return apiRequestPage(`/hotels?${params.toString()}`, { accessToken })
}

/**
 * The count-only shape of `listHotels` — `limit: 1` since only
 * `pagination.total` is needed, not the records themselves (used by the
 * Overview dashboard's summary cards).
 */
export async function countHotels(accessToken, { status } = {}) {
  const { pagination } = await listHotels(accessToken, { status, page: 1, limit: 1 })
  return pagination?.total ?? 0
}

export function getHotel(accessToken, id) {
  return apiRequest(`/hotels/${id}`, { accessToken })
}

export function listHotelApplications(accessToken, hotelId) {
  return apiRequest(`/admin/hotels/${hotelId}/applications`, { accessToken })
}

export function approveHotelApplication(accessToken, hotelId, applicationId) {
  return apiRequest(`/admin/hotels/${hotelId}/applications/${applicationId}/approval`, {
    method: 'POST',
    accessToken,
  })
}

export function rejectHotelApplication(accessToken, hotelId, applicationId, reason) {
  return apiRequest(`/admin/hotels/${hotelId}/applications/${applicationId}/rejection`, {
    method: 'POST',
    accessToken,
    body: { reason },
  })
}
