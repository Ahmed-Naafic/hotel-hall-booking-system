import { useState } from 'react'
import { AuthProvider } from './shared/auth/AuthContext.jsx'
import { ThemeProvider } from './shared/theme/ThemeContext.jsx'
import { useAuth } from './shared/auth/useAuth.js'
import { LoginPage } from './features/authentication/LoginPage.jsx'
import { DashboardShell } from './features/authentication/DashboardShell.jsx'

/**
 * No router (architecture-principles.md §2, Simplicity before complexity —
 * two screens don't justify one; folder-structure.md §3's routes/ applies
 * once Administration & Platform Management's real multi-page dashboard is
 * scoped, Module 13, not yet). Session status alone decides what renders.
 */
function AppShell() {
  const { status } = useAuth()
  const [notice, setNotice] = useState('')

  if (status === 'loading') {
    return null
  }

  if (status === 'authenticated') {
    return (
      <DashboardShell
        onPasswordChanged={() => setNotice('Password changed. Please log in again.')}
        onLogout={() => setNotice('')}
      />
    )
  }

  return <LoginPage notice={notice} />
}

function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <AppShell />
      </AuthProvider>
    </ThemeProvider>
  )
}

export default App
