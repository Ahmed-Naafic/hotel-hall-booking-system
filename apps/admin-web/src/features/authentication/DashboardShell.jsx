import { useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { Button } from '../../shared/components/Button.jsx'
import { PageHeader } from '../../shared/components/PageHeader.jsx'
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
          <>
            <PageHeader
              eyebrow="PLATFORM"
              title="Hotels"
              subtitle="Every Hotel registered on the Platform, with its current lifecycle status."
            />
            <PageCard>
              <HotelsPage onSelectHotel={openHotel} />
            </PageCard>
          </>
        ) : view === 'applications' ? (
          <>
            <PageHeader
              eyebrow="REVIEW QUEUE"
              title="Applications"
              subtitle="Hotel applications awaiting a decision, and those already decided."
            />
            <PageCard>
              <ApplicationsPage onSelectHotel={openHotel} />
            </PageCard>
          </>
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
      <PageHeader
        eyebrow="OVERVIEW"
        title="Welcome back"
        subtitle={`Signed in as ${user?.mobileNumber ?? ''}. Every Hotel on the Platform, and the applications waiting on you.`}
      />

      {/* --space-11 is the system's own --section-y-tight: 64px between
          sections in app views, against 24px before. The panels were
          crowding each other into one undifferentiated block. */}
      <div style={{ marginBottom: 'var(--space-11)' }}>
        <HotelMetricCards {...statusCounts} />
      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-5)', marginBottom: 'var(--space-11)' }}>
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
    <PageHeader
      eyebrow="ACCOUNT"
      title="Welcome back"
      subtitle={`Signed in as ${user?.mobileNumber ?? ''}.`}
    />
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

/**
 * A content panel. Its heading is Cormorant Garamond, not the UI sans — the
 * design system assigns the editorial serif to card titles specifically,
 * and it is what stops a page of panels reading as a generic admin table
 * dump. Sentence case, because only display headings are uppercase here.
 */
function Card({ title, subtitle, children, bodyOnly = false }) {
  return (
    <section
      style={{
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-sm)',
        padding: 'var(--space-7)',
      }}
    >
      {!bodyOnly && title ? (
        <div style={{ marginBottom: 'var(--space-5)' }}>
          <h2
            style={{
              fontFamily: 'var(--font-serif)',
              fontSize: 'var(--serif-sm)',
              fontWeight: 'var(--weight-regular)',
              letterSpacing: 0,
              lineHeight: 'var(--serif-leading)',
              textTransform: 'none',
              color: 'var(--text-heading)',
              margin: 0,
            }}
          >
            {title}
          </h2>
          {subtitle ? <p style={{ margin: '6px 0 0', fontSize: 'var(--text-sm)', color: 'var(--text-muted)' }}>{subtitle}</p> : null}
        </div>
      ) : null}
      {children}
    </section>
  )
}
