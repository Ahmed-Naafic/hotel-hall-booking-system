import { apiRequest, apiRequestPage } from './apiClient.js'

/**
 * Communication & Notification Management module's API client
 * (backend Technical Design §11) — the same `/notifications` routes
 * Customer Mobile and Manager Mobile already use (a Notification's scope is
 * the caller's own identity, not a role-gated capability). No device-token
 * registration here — push delivery to a browser is new frontend
 * infrastructure the Business Specification's "Out of Scope for V1" already
 * excludes; only the in-app list/unread-count/mark-read surface is wired.
 */
export function listNotifications(accessToken, { cursor, limit = 20 } = {}) {
  const params = new URLSearchParams({ limit: String(limit) })
  if (cursor) {
    params.set('cursor', cursor)
  }
  return apiRequestPage(`/notifications?${params.toString()}`, { accessToken })
}

export async function getUnreadCount(accessToken) {
  const data = await apiRequest('/notifications/unread-count', { accessToken })
  return data.count
}

export function markNotificationRead(accessToken, id) {
  return apiRequest(`/notifications/${id}/read`, { method: 'POST', accessToken })
}

export function markAllNotificationsRead(accessToken) {
  return apiRequest('/notifications/read-all', { method: 'POST', accessToken })
}
