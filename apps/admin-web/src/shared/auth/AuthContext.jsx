import { useCallback, useEffect, useMemo, useState } from 'react'
import * as authApi from '../api/authApi.js'
import { AuthContext } from './authContext.js'

/**
 * Session state for the whole app (folder-structure.md §3, core/). The
 * access token lives only in memory (React state) — never localStorage —
 * to limit its exposure window; only the refresh token persists, so a page
 * reload doesn't force a fresh login every time.
 */
const REFRESH_TOKEN_STORAGE_KEY = 'hh_admin_refresh_token'

export function AuthProvider({ children }) {
  const [accessToken, setAccessToken] = useState(null)
  const [user, setUser] = useState(null)
  // 'loading' while restoring a session from a stored refresh token, so the
  // app doesn't flash the login screen before that check resolves.
  const [status, setStatus] = useState('loading')

  const clearSession = useCallback(() => {
    setAccessToken(null)
    setUser(null)
    localStorage.removeItem(REFRESH_TOKEN_STORAGE_KEY)
    setStatus('unauthenticated')
  }, [])

  useEffect(() => {
    const storedRefreshToken = localStorage.getItem(REFRESH_TOKEN_STORAGE_KEY)
    if (!storedRefreshToken) {
      setStatus('unauthenticated')
      return
    }

    authApi
      .refresh(storedRefreshToken)
      .then(async ({ accessToken: newAccessToken, refreshToken: newRefreshToken }) => {
        localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, newRefreshToken)
        const currentUser = await authApi.getCurrentUser(newAccessToken)
        setAccessToken(newAccessToken)
        setUser(currentUser)
        setStatus('authenticated')
      })
      .catch(() => {
        // Expired/invalid refresh token (BR-AUTH-11) — treated as
        // unauthenticated, not as an error the user needs to see.
        clearSession()
      })
  }, [clearSession])

  const login = useCallback(async (mobileNumber, password) => {
    const result = await authApi.login({ mobileNumber, password })
    localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, result.refreshToken)
    setAccessToken(result.accessToken)
    setUser(result.user)
    setStatus('authenticated')
  }, [])

  const logout = useCallback(async () => {
    try {
      if (accessToken) {
        await authApi.logout(accessToken)
      }
    } finally {
      // Session ends locally even if the network call fails — the whole
      // point of logging out is to stop trusting the local session.
      clearSession()
    }
  }, [accessToken, clearSession])

  const changePassword = useCallback(
    async (currentPassword, newPassword) => {
      await authApi.changePassword(accessToken, { currentPassword, newPassword })
      // BR-AUTH-08 side effect: the backend ends every Session on a
      // password change, including this one's refresh token — the access
      // token in memory still works until it naturally expires, but there
      // is no longer a valid refresh token to renew it with, so the
      // clean, honest UX is to end the session locally too.
      clearSession()
    },
    [accessToken, clearSession],
  )

  const value = useMemo(
    () => ({ status, user, accessToken, login, logout, changePassword }),
    [status, user, accessToken, login, logout, changePassword],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
