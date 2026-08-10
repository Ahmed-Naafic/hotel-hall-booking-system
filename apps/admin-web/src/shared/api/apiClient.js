/**
 * Thin fetch wrapper matching the backend's api-standards.md §7-§8 envelopes.
 * Every module's API client can reuse this — feature-specific request
 * shaping belongs in that feature's own services/ (folder-structure.md §3).
 */
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api/v1'

export class ApiError extends Error {
  constructor({ status, error, message, details }) {
    super(message)
    this.status = status
    this.error = error
    this.details = details
  }
}

async function apiRequestRaw(path, { method = 'GET', body, accessToken } = {}) {
  const headers = { 'Content-Type': 'application/json' }
  if (accessToken) {
    headers.Authorization = `Bearer ${accessToken}`
  }

  const res = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  if (res.status === 204) {
    return null
  }

  const payload = await res.json()

  if (payload.status === 'error') {
    throw new ApiError({
      status: res.status,
      error: payload.error,
      message: payload.message,
      details: payload.details,
    })
  }

  return payload
}

export async function apiRequest(path, options) {
  const payload = await apiRequestRaw(path, options)
  return payload === null ? null : payload.data
}

/**
 * Same contract as apiRequest, but also returns `pagination`
 * (api-standards.md §7) — for list endpoints a caller needs to page
 * through, where `data` alone isn't enough.
 */
export async function apiRequestPage(path, options) {
  const payload = await apiRequestRaw(path, options)
  return payload === null ? { data: null, pagination: null } : { data: payload.data, pagination: payload.pagination }
}
