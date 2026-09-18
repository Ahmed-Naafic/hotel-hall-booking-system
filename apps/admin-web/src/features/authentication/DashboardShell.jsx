import { useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { Button } from '../../shared/components/Button.jsx'
import { TopNav } from './TopNav.jsx'
import { ChangePasswordCard } from './ChangePasswordCard.jsx'
import { HotelsPage } from '../hotels/HotelsPage.jsx'
import { ApplicationsPage } from '../hotels/ApplicationsPage.jsx'
import { HotelDetailPage } from '../hotels/HotelDetailPage.jsx'
import { HotelMetricCards } from '../hotels/HotelMetricCards.jsx'
import { HotelStatusSummary } from '../hotels/HotelStatusSummary.jsx'
import { RecentApplications } from '../hotels/RecentApplications.jsx'
import { QuickActions } from '../hotels/QuickActions.jsx'
import { useHotelStatusCounts } from '../hotels/useHotelStatusCounts.js'

/**
 * The authenticated shell — top navigation (Technical Design §11's Hotel
 * Management query interface is the only real data source behind
 * Overview/Hotels/Applications) plus a `view` state switch instead of a
 * router (architecture-principles.md §2, Simplicity before complexity —
 * five screens don't justify one; folder-structure.md §3's routes/ applies
 * once Administration & Platform Management's own multi-page dashboard is
 * scoped, Module 13, not yet).
 */
export function DashboardShell({ onPasswordChanged, onLogout }) {
  const { user, logout } = useAuth()
  const [view, setView] = useState('overview')
  const [selectedHotelId, setSelectedHotelId] = useState(null)
  const isPlatformAdministrator = user?.accountType === 'PLATFORM_ADMINISTRATOR'

  function navigate(nextView) {
    setSelectedHotelId(null)
    setView(nextView)
  }

  function openHotel(hotelId) {
    setSelectedHotelId(hotelId)
    setView('hotel-detail')
  }

  return (
    <div style={{ minHeight: '100vh', background: 'var(--surface-page)' }}>
      <TopNav
        activeView={view === 'hotel-detail' ? 'hotels' : view}
        onNavigate={navigate}
        user={user}
        onChangePassword={() => setView('password')}
        onLogout={() => {
          logout()
          onLogout?.()
        }}
        onSelectHotel={isPlatformAdministrator ? openHotel : undefined}
      />

      <main style={{ padding: 'var(--space-6)', maxWidth: 1200, margin: '0 auto' }}>
        {!isPlatformAdministrator ? (
          <NonAdministratorView view={view} onPasswordChanged={onPasswordChanged} onCancel={() => setView('overview')} />
        ) : view === 'password' ? (
          <PasswordCard onPasswordChanged={onPasswordChanged} onCancel={() => setView('overview')} />
        ) : view === 'hotels' ? (
          <PageCard title="Hotels" subtitle="Every Hotel registered on the Platform.">
            <HotelsPage onSelectHotel={openHotel} />
          </PageCard>
        ) : view === 'applications' ? (
          <PageCard title="Applications" subtitle="Hotel applications awaiting or already given a decision.">
            <ApplicationsPage onSelectHotel={openHotel} />
          </PageCard>
        ) : view === 'hotel-detail' ? (
          <PageCard>
            <HotelDetailPage hotelId={selectedHotelId} onBack={() => setView('hotels')} />
          </PageCard>
        ) : (
          <OverviewView
            user={user}
            onViewHotels={() => navigate('hotels')}
            onReviewApplications={() => navigate('applications')}
            onSelectHotel={openHotel}
          />
        )}
      </main>
    </div>
  )
}

function OverviewView({ user, onViewHotels, onReviewApplications, onSelectHotel }) {
  const statusCounts = useHotelStatusCounts()

  return (
    <div>
      <h1 style={{ fontSize: 'var(--display-sm)', margin: '0 0 4px' }}>Welcome back, Platform Administrator</h1>
      <p style={{ color: 'var(--text-subtle)', marginBottom: 'var(--space-6)' }}>
        Signed in as {user?.mobileNumber} &middot; {user?.accountType}
      </p>

      <div style={{ marginBottom: 'var(--space-7)' }}>
        <HotelMetricCards {...statusCounts} />
      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-5)', marginBottom: 'var(--space-7)' }}>
        <div style={{ flex: '2 1 480px', minWidth: 0 }}>
          <Card title="Recent Hotel Applications" subtitle="The five most recently updated applications, across every status.">
            <RecentApplications onSelectHotel={onSelectHotel} />
          </Card>
        </div>
        <div style={{ flex: '1 1 260px', minWidth: 0 }}>
          <Card title="Hotel Status Summary">
            <HotelStatusSummary {...statusCounts} />
          </Card>
        </div>
      </div>

      <Card title="Quick Actions">
        <QuickActions onViewHotels={onViewHotels} onReviewApplications={onReviewApplications} />
      </Card>
    </div>
  )
}

function NonAdministratorView({ view, onPasswordChanged, onCancel }) {
  const { user } = useAuth()
  if (view === 'password') {
    return <PasswordCard onPasswordChanged={onPasswordChanged} onCancel={onCancel} />
  }
  return (
    <div>
      <h1 style={{ fontSize: 'var(--display-sm)', margin: '0 0 4px' }}>Welcome back</h1>
      <p style={{ color: 'var(--text-subtle)', marginBottom: 'var(--space-6)' }}>
        Signed in as {user?.mobileNumber} &middot; {user?.accountType}
      </p>
    </div>
  )
}

function PasswordCard({ onPasswordChanged, onCancel }) {
  return (
    <Card title="Change password">
      <ChangePasswordCard onChanged={onPasswordChanged} />
      <Button variant="ghost" size="sm" style={{ marginTop: 'var(--space-4)' }} onClick={onCancel}>
        Cancel
      </Button>
    </Card>
  )
}

function PageCard({ title, subtitle, children }) {
  return (
    <Card title={title} subtitle={subtitle} bodyOnly={!title}>
      {children}
    </Card>
  )
}

function Card({ title, subtitle, children, bodyOnly = false }) {
  return (
    <section
      style={{
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-sm)',
        padding: 'var(--space-6)',
      }}
    >
      {!bodyOnly && title ? (
        <div style={{ marginBottom: 'var(--space-4)' }}>
          <h2 style={{ fontSize: 'var(--text-lg)', margin: 0 }}>{title}</h2>
          {subtitle ? <p style={{ margin: '4px 0 0', fontSize: 'var(--text-sm)', color: 'var(--text-muted)' }}>{subtitle}</p> : null}
        </div>
      ) : null}
      {children}
    </section>
  )
}
