import { apiRequest, apiRequestPage } from './apiClient.js'

/**
 * Hotel Management module's API client (backend Technical Design §11).
 * Admin Web calls the Platform-Administrator-facing query interface
 * (`GET /hotels`, `GET /hotels/:id`) here; the approve/reject/suspend/
 * deactivate actions below call Administration & Platform Management's own
 * API surface (`/admin/...`, BR-HOTEL-14, Module 13 Technical Design §API).
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

export function suspendHotel(accessToken, hotelId) {
  return apiRequest(`/admin/hotels/${hotelId}/suspension`, {
    method: 'POST',
    accessToken,
  })
}

export function deactivateHotel(accessToken, hotelId) {
  return apiRequest(`/admin/hotels/${hotelId}/deactivation`, {
    method: 'POST',
    accessToken,
  })
}

export function reactivateHotel(accessToken, hotelId) {
  return apiRequest(`/admin/hotels/${hotelId}/reactivation`, {
    method: 'POST',
    accessToken,
  })
}
