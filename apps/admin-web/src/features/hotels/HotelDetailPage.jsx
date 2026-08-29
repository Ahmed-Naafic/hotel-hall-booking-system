import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../../shared/auth/useAuth.js'
import { approveHotelApplication, getHotel, listHotelApplications, rejectHotelApplication } from '../../shared/api/hotelsApi.js'
import { ApiError } from '../../shared/api/apiClient.js'
import { Button } from '../../shared/components/Button.jsx'
import { StateMessage } from '../../shared/components/StateMessage.jsx'
import { Skeleton } from '../../shared/components/Skeleton.jsx'
import { IconArrowLeft, IconMapPin } from '../../shared/components/Icon.jsx'
import { StatusBadge } from './StatusBadge.jsx'
import { describeStatus, describeApplicationStatus } from './hotelStatus.js'
import { getHotelDisplayName, getHotelLocation } from './hotelProfile.js'

/**
 * Platform Administrator's Hotel Details / Application Review view
 * (`GET /hotels/:id`, Technical Design §11 — `hotel.controller.js#getHotel`
 * already grants a Platform Administrator unrestricted access to any
 * Hotel). One page serves both roles the spec describes separately —
 * "Hotel Details" and "Application Review" — because they read the exact
 * same record; the page's framing (title, and whether the decision panel
 * shows) adapts to the Hotel's real `status`, so there's no second
 * near-duplicate page to keep in sync.
 *
 * The page reads the Hotel plus its application history through the
 * Administration API and wires Approve/Reject only when the Hotel has an
 * open application under review. Suspension/deactivation remain outside this
 * implementation slice.
 */
export function HotelDetailPage({ hotelId, onBack }) {
  const { accessToken } = useAuth()
  const [hotel, setHotel] = useState(null)
  const [applications, setApplications] = useState([])
  const [loadState, setLoadState] = useState('loading')
  const [error, setError] = useState('')
  const [decisionState, setDecisionState] = useState('idle')
  const [decisionError, setDecisionError] = useState('')
  const [rejectReason, setRejectReason] = useState('')

  const load = useCallback(async () => {
    setLoadState('loading')
    setError('')
    try {
      const [hotelData, applicationData] = await Promise.all([
        getHotel(accessToken, hotelId),
        listHotelApplications(accessToken, hotelId),
      ])
      setHotel(hotelData)
      setApplications(applicationData)
      setLoadState('ready')
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong. Please try again.')
      setLoadState('error')
    }
  }, [accessToken, hotelId])

  useEffect(() => {
    load()
  }, [load])

  const isUnderReview = hotel?.status === 'UNDER_REVIEW'
  const openApplication = applications.find((application) => application.status === 'OPEN')
  const { text: displayName, variant: nameVariant } = hotel ? getHotelDisplayName(hotel) : { text: '', variant: 'named' }
  const location = hotel ? getHotelLocation(hotel) : null
  const profileEntries = hotel?.profileData ? Object.entries(hotel.profileData) : []

  return (
    <div>
      <Button variant="ghost" size="sm" onClick={onBack} iconLeft={<IconArrowLeft size={15} />} style={{ marginBottom: 'var(--space-5)' }}>
        Back
      </Button>

      {loadState === 'error' ? (
        <StateMessage tone="error" title="Couldn’t load this Hotel" message={error} onRetry={load} />
      ) : loadState === 'loading' ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-6)' }}>
          <Skeleton height={28} width="40%" />
          <Skeleton height={16} width="60%" />
          <Skeleton height={120} width="100%" />
        </div>
      ) : (
        <>
          <p style={{ margin: '0 0 var(--space-1)', fontSize: 'var(--text-xs)', letterSpacing: 'var(--tracking-wide)', color: 'var(--text-muted)' }}>
            {isUnderReview ? 'Application Review' : 'Hotel Details'}
          </p>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: 'var(--space-3)',
              marginBottom: 'var(--space-1)',
            }}
          >
            <h2 style={{ margin: 0, fontSize: 'var(--text-xl)', fontStyle: nameVariant === 'incomplete' ? 'italic' : 'normal' }}>
              {displayName}
            </h2>
            <StatusBadge status={hotel.status} />
          </div>
          {location ? (
            <p style={{ display: 'flex', alignItems: 'center', gap: 4, margin: '0 0 var(--space-2)', fontSize: 'var(--text-sm)', color: 'var(--text-muted)' }}>
              <IconMapPin size={14} /> {location}
            </p>
          ) : null}

          {isUnderReview ? (
            <div
              style={{
                marginTop: 'var(--space-4)',
                padding: 'var(--space-4)',
                borderRadius: 'var(--radius-lg)',
                border: '1px solid var(--gold-300)',
                background: 'var(--gold-100)',
              }}
            >
              <p style={{ margin: '0 0 var(--space-3)', fontSize: 'var(--text-sm)', color: 'var(--navy-800)' }}>
                This application is awaiting a decision.
              </p>
              {decisionError ? (
                <p style={{ margin: '0 0 var(--space-3)', fontSize: 'var(--text-sm)', color: 'var(--danger-700)' }}>
                  {decisionError}
                </p>
              ) : null}
              <textarea
                value={rejectReason}
                onChange={(event) => setRejectReason(event.target.value)}
                placeholder="Rejection reason"
                rows={3}
                style={{
                  width: '100%',
                  margin: '0 0 var(--space-3)',
                  padding: 'var(--space-3)',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-subtle)',
                  resize: 'vertical',
                }}
              />
              <div style={{ display: 'flex', gap: 'var(--space-3)', flexWrap: 'wrap' }}>
                <Button
                  variant="accent"
                  size="sm"
                  disabled={!openApplication || decisionState !== 'idle'}
                  onClick={() => decide('approve')}
                >
                  Approve Application
                </Button>
                <Button
                  variant="danger"
                  size="sm"
                  disabled={!openApplication || decisionState !== 'idle'}
                  onClick={() => decide('reject')}
                >
                  Reject Application
                </Button>
              </div>
            </div>
          ) : null}

          <Section title="Application">
            <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-body)' }}>
              {describeApplicationStatus(hotel.status)}
            </p>
          </Section>

          <Section title="Lifecycle Status">
            <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-body)' }}>{describeStatus(hotel.status)}</p>
          </Section>

          <Section title="Registration">
            <DefinitionList
              items={[
                { term: 'Registered by (User ID)', value: <code style={{ fontSize: 'var(--text-xs)' }}>{hotel.registeredByUserId}</code> },
                { term: 'Hotel ID', value: <code style={{ fontSize: 'var(--text-xs)' }}>{hotel.id}</code> },
                { term: 'Registered on', value: new Date(hotel.createdAt).toLocaleString() },
                { term: 'Last updated', value: new Date(hotel.updatedAt).toLocaleString() },
              ]}
            />
          </Section>

          <Section title="Hotel Profile">
            {profileEntries.length === 0 ? (
              <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-muted)' }}>
                This Hotel hasn’t completed its profile yet — no information has been submitted.
              </p>
            ) : (
              <DefinitionList
                items={profileEntries.map(([field, value]) => ({ term: formatFieldName(field), value: formatFieldValue(value) }))}
              />
            )}
          </Section>

          <Section title="Review Information">
            {applications.length === 0 ? (
              <p style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-muted)' }}>No application has been submitted yet.</p>
            ) : (
              <DefinitionList
                items={applications.map((application) => ({
                  term: application.status,
                  value: `${new Date(application.submittedAt).toLocaleString()}${
                    application.decisionReason ? ` — ${application.decisionReason}` : ''
                  }`,
                }))}
              />
            )}
          </Section>
        </>
      )}
    </div>
  )

  async function decide(action) {
    if (!openApplication) return
    setDecisionState(action)
    setDecisionError('')
    try {
      if (action === 'approve') {
        await approveHotelApplication(accessToken, hotel.id, openApplication.id)
      } else {
        await rejectHotelApplication(accessToken, hotel.id, openApplication.id, rejectReason)
      }
      setRejectReason('')
      await load()
    } catch (err) {
      setDecisionError(err instanceof ApiError ? err.message : 'Something went wrong. Please try again.')
    } finally {
      setDecisionState('idle')
    }
  }
}

function Section({ title, children }) {
  return (
    <div style={{ marginTop: 'var(--space-7)' }}>
      <h3
        style={{
          margin: '0 0 var(--space-3)',
          fontSize: 'var(--text-xs)',
          letterSpacing: 'var(--tracking-wider)',
          textTransform: 'uppercase',
          color: 'var(--text-muted)',
          fontFamily: 'var(--font-sans)',
          fontWeight: 'var(--weight-semibold)',
        }}
      >
        {title}
      </h3>
      {children}
    </div>
  )
}

function DefinitionList({ items }) {
  return (
    <dl style={{ margin: 0, display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 'var(--space-4) var(--space-6)' }}>
      {items.map(({ term, value }) => (
        <div key={term} style={{ minWidth: 0 }}>
          <dt style={{ fontSize: 'var(--text-xs)', letterSpacing: 'var(--tracking-wide)', textTransform: 'uppercase', color: 'var(--text-muted)', marginBottom: 4 }}>
            {term}
          </dt>
          <dd style={{ margin: 0, fontSize: 'var(--text-sm)', color: 'var(--text-body)', wordBreak: 'break-word' }}>{value}</dd>
        </div>
      ))}
    </dl>
  )
}

function formatFieldName(field) {
  const withSpaces = field.replace(/([a-z0-9])([A-Z])/g, '$1 $2').replace(/_/g, ' ')
  return withSpaces.charAt(0).toUpperCase() + withSpaces.slice(1)
}

function formatFieldValue(value) {
  if (value === null || value === undefined || value === '') return '—'
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}
