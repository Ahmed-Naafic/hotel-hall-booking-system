import { useCallback, useEffect, useMemo, useState } from 'react'
import * as authApi from '../api/authApi.js'
import { ApiError } from '../api/apiClient.js'
import { AuthContext } from './authContext.js'

/**
 * Session state for the whole app (folder-structure.md §3, core/). The
 * access token lives only in memory (React state) — never localStorage —
 * to limit its exposure window; only the refresh token persists, so a page
 * reload doesn't force a fresh login every time.
 */
const REFRESH_TOKEN_STORAGE_KEY = 'hh_admin_refresh_token'

/**
 * This console serves one account type. A Customer or Hotel Manager holds
 * valid credentials for the same backend, so without this check they sign
 * in here perfectly well and land on a console with nothing in it — every
 * endpoint behind it refuses them (`requireAccountType`), which is a
 * confusing way to learn you are in the wrong app.
 *
 * Refusing at the door is a UX boundary, not the security one: the server
 * remains the authority on what any token may do.
 */
const ADMIN_ACCOUNT_TYPE = 'PLATFORM_ADMINISTRATOR'

const WRONG_APP_MESSAGE =
  'That account is not a Platform Administrator. This console is for Platform Administration only.'

function isAdministrator(user) {
  return user?.accountType === ADMIN_ACCOUNT_TYPE
}

export function AuthProvider({ children }) {
  const [accessToken, setAccessToken] = useState(null)
  const [user, setUser] = useState(null)
  // 'loading' while restoring a session from a stored refresh token, so the
  // app doesn't flash the login screen before that check resolves.
  const [status, setStatus] = useState('loading')
  // Set between proving the password and entering the texted code — the
  // window where the backend has issued no token at all. Holds the
  // credentials only for that window so "Resend" can ask for another code
  // without a re-typed password; re-running login is the only way to get
  // one, and requiring the password is what stops the endpoint being an
  // SMS-flood button.
  const [pendingLogin, setPendingLogin] = useState(null)

  const clearSession = useCallback(() => {
    setAccessToken(null)
    setUser(null)
    localStorage.removeItem(REFRESH_TOKEN_STORAGE_KEY)
    // Any half-finished sign-in belongs to the session that just ended.
    setPendingLogin(null)
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
        if (!isAdministrator(currentUser)) {
          // Same door, different entrance: a token left behind by the wrong
          // account type must not restore a console session either.
          await authApi.logout(newAccessToken).catch(() => {})
          clearSession()
          return
        }
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

  const adoptSession = useCallback(async (result) => {
    if (!isAdministrator(result.user)) {
      // End the session that was just created rather than abandoning a live
      // one server-side, then report it as the refusal it is.
      try {
        await authApi.logout(result.accessToken)
      } catch {
        // Best effort — the session is never adopted here either way.
      }
      setPendingLogin(null)
      throw new ApiError({ status: 403, error: 'AUTHORIZATION_ERROR', message: WRONG_APP_MESSAGE })
    }

    localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, result.refreshToken)
    setAccessToken(result.accessToken)
    setUser(result.user)
    setPendingLogin(null)
    setStatus('authenticated')
  }, [])

  /**
   * Step one. Resolves to `true` when a code was texted and the session is
   * still owed, so the caller knows to show the code form.
   */
  const login = useCallback(
    async (mobileNumber, password) => {
      const result = await authApi.login({ mobileNumber, password })
      if (result.verificationRequired) {
        setPendingLogin({ mobileNumber, password })
        return true
      }
      await adoptSession(result)
      return false
    },
    [adoptSession],
  )

  /** Step two — exchanges the texted code for the session. */
  const completeLogin = useCallback(
    async (code) => {
      if (!pendingLogin) throw new Error('No sign-in is waiting for a code.')
      await adoptSession(await authApi.completeLogin({ mobileNumber: pendingLogin.mobileNumber, code }))
    },
    [pendingLogin, adoptSession],
  )

  /** Asks for another code by re-running step one with the same credentials. */
  const resendLoginCode = useCallback(async () => {
    if (!pendingLogin) throw new Error('No sign-in is waiting for a code.')
    await authApi.login(pendingLogin)
  }, [pendingLogin])

  /** Abandons a half-finished sign-in and returns to the password form. */
  const cancelLogin = useCallback(() => setPendingLogin(null), [])

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
    () => ({
      status,
      user,
      accessToken,
      login,
      logout,
      changePassword,
      completeLogin,
      resendLoginCode,
      cancelLogin,
      awaitingLoginCode: pendingLogin !== null,
      pendingMobileNumber: pendingLogin?.mobileNumber ?? null,
    }),
    [
      status, user, accessToken, login, logout, changePassword,
      completeLogin, resendLoginCode, cancelLogin, pendingLogin,
    ],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
