import { apiRequest } from './apiClient.js'

/**
 * Authentication module's API client (backend Technical Design §10).
 * Admin Web only ever calls the endpoints A1-A3 need — no registration
 * (Platform Administrator accounts are provisioned internally, Business
 * Specification §3.2), no verification, no password reset.
 */

export function login({ mobileNumber, password }) {
  return apiRequest('/auth/login', { method: 'POST', body: { mobileNumber, password } })
}

export function logout(accessToken) {
  return apiRequest('/auth/logout', { method: 'POST', accessToken })
}

export function refresh(refreshToken) {
  return apiRequest('/auth/refresh', { method: 'POST', body: { refreshToken } })
}

export function getCurrentUser(accessToken) {
  return apiRequest('/auth/me', { accessToken })
}

export function changePassword(accessToken, { currentPassword, newPassword }) {
  return apiRequest('/auth/password', {
    method: 'PATCH',
    accessToken,
    body: { currentPassword, newPassword },
  })
}
