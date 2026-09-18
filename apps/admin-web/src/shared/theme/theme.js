/**
 * Theme preference — 'system' (default), 'light', or 'dark'.
 *
 * The preference and the applied theme are deliberately separate: 'system'
 * is a standing instruction to follow the OS, so it is what gets stored,
 * and the concrete light/dark value is re-resolved whenever the OS flips.
 * Storing the resolved value instead would freeze a device that later
 * changes its own setting.
 *
 * `data-theme` on <html> is always written explicitly, never left for a
 * `prefers-color-scheme` rule in CSS to infer — one source of truth for
 * which theme is live. `index.html` applies the same resolution inline
 * before first paint; keep the two in step.
 */

export const THEME_STORAGE_KEY = 'hh-admin-theme'
export const THEME_PREFERENCES = ['system', 'light', 'dark']

const DARK_QUERY = '(prefers-color-scheme: dark)'

/** Reads the stored preference, falling back to 'system' for anything unrecognised. */
export function readThemePreference() {
  try {
    const stored = localStorage.getItem(THEME_STORAGE_KEY)
    return THEME_PREFERENCES.includes(stored) ? stored : 'system'
  } catch {
    // Private browsing, or site data blocked — following the OS is the
    // right behaviour when we cannot remember anything.
    return 'system'
  }
}

export function storeThemePreference(preference) {
  try {
    localStorage.setItem(THEME_STORAGE_KEY, preference)
  } catch {
    // Not being able to remember the choice must not stop us applying it.
  }
}

/** Turns a preference into the theme actually shown. */
export function resolveTheme(preference) {
  if (preference === 'light' || preference === 'dark') return preference
  return window.matchMedia?.(DARK_QUERY).matches ? 'dark' : 'light'
}

export function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme)
  // Keeps form controls, scrollbars and the like in step with the page.
  document.documentElement.style.colorScheme = theme
}

/**
 * Calls `onChange` whenever the OS theme flips. Returns an unsubscribe
 * function. Only meaningful while the preference is 'system' — the caller
 * decides whether to act on it.
 */
export function watchSystemTheme(onChange) {
  const query = window.matchMedia?.(DARK_QUERY)
  if (!query) return () => {}
  const handler = (event) => onChange(event.matches ? 'dark' : 'light')
  query.addEventListener('change', handler)
  return () => query.removeEventListener('change', handler)
}
