import { useCallback, useEffect, useMemo, useState } from 'react'
import { ThemeContext } from './themeContext.js'
import {
  applyTheme,
  readThemePreference,
  resolveTheme,
  storeThemePreference,
  watchSystemTheme,
} from './theme.js'

/**
 * Owns the theme for the whole app, above the session split — the login
 * screen honours the admin's choice just as the dashboard does.
 */
export function ThemeProvider({ children }) {
  const [preference, setPreferenceState] = useState(readThemePreference)
  const [theme, setTheme] = useState(() => resolveTheme(readThemePreference()))

  useEffect(() => {
    const resolved = resolveTheme(preference)
    setTheme(resolved)
    applyTheme(resolved)
  }, [preference])

  useEffect(() => {
    // An explicit light/dark choice outranks the OS, so only follow the
    // system while the preference is still 'system'.
    if (preference !== 'system') return undefined
    return watchSystemTheme((resolved) => {
      setTheme(resolved)
      applyTheme(resolved)
    })
  }, [preference])

  const setPreference = useCallback((next) => {
    setPreferenceState(next)
    storeThemePreference(next)
  }, [])

  const value = useMemo(
    () => ({ preference, theme, setPreference }),
    [preference, theme, setPreference],
  )

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}
