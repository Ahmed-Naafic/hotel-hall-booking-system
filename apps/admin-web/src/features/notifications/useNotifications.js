import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { listNotifications, getUnreadCount, markNotificationRead, markAllNotificationsRead } from '../../shared/api/notificationsApi.js'
import { ApiError } from '../../shared/api/apiClient.js'

/**
 * The Admin Web side of Notification V1 (Technical Design "Admin Web" —
 * deferred unless the existing shell supports a bell/list cheaply; it does,
 * `NotificationsMenu`'s bell/dropdown already existed as a placeholder).
 * Mirrors Manager Mobile's `NotificationController`: an unread count kept
 * live from mount, and a list fetched lazily only once the menu is opened —
 * no polling, the same explicit-refresh pattern every mobile app already
 * uses.
 */
export function useNotifications() {
  const { accessToken } = useAuth()
  const [notifications, setNotifications] = useState([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [loadState, setLoadState] = useState('idle')
  const [error, setError] = useState('')

  const refreshUnreadCount = useCallback(async () => {
    try {
      setUnreadCount(await getUnreadCount(accessToken))
    } catch {
      // The badge is a convenience, not a source of truth — a transient
      // failure here should not surface as an app-wide error state.
    }
  }, [accessToken])

  useEffect(() => {
    refreshUnreadCount()
  }, [refreshUnreadCount])

  const load = useCallback(async () => {
    setLoadState('loading')
    setError('')
    try {
      const { data } = await listNotifications(accessToken)
      setNotifications(data)
      setLoadState('ready')
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Could not load notifications. Please try again.')
      setLoadState('error')
    }
    refreshUnreadCount()
  }, [accessToken, refreshUnreadCount])

  const markRead = useCallback(
    async (id) => {
      const target = notifications.find((n) => n.id === id)
      if (!target || target.status === 'READ') return
      const updated = await markNotificationRead(accessToken, id)
      setNotifications((current) => current.map((n) => (n.id === id ? updated : n)))
      setUnreadCount((count) => Math.max(0, count - 1))
    },
    [accessToken, notifications],
  )

  const markAllRead = useCallback(async () => {
    await markAllNotificationsRead(accessToken)
    setNotifications((current) => current.map((n) => ({ ...n, status: 'READ', readAt: new Date().toISOString() })))
    setUnreadCount(0)
  }, [accessToken])

  return { notifications, unreadCount, loadState, error, load, markRead, markAllRead }
}
