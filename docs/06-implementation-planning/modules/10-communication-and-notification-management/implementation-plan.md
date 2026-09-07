---
title: "Notification Management — Implementation Plan (Notification V1)"
document_type: Implementation Planning
module: 10-communication-and-notification-management
status: In Progress
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/05-technical-design/modules/10-communication-and-notification-management/technical-design.md"]
last_updated: 2026-09-07
---

## Backend

1. Add `Notification`, `NotificationType`, `NotificationStatus`, and `DeviceToken` to
   `prisma/schema.prisma`; migrate.
2. Add `backend/src/shared/providers/{pushProvider,mockPushProvider,fcmPushProvider}.js`,
   mirroring `smsProvider.js`'s selection pattern exactly.
3. Add `backend/src/modules/notifications/` (routes, controller, service, repository,
   validation, mapper) — list, unread-count, mark-read, mark-all-read, device-token
   upsert/delete.
4. Add `notification.events.js` (one function per Notification Catalog row) and call each
   from the existing `bookings`/`hotels` call sites already used for
   `recordBookingAudit`/`recordAuditEvent` — no new call sites invented.
5. Change `booking.repository.js#expireOverdue` and
   `availability.repository.js#expireOverdueBookings` from `updateMany` to
   `updateManyAndReturn`; have each calling **service** fire
   `notificationEvents.onBookingExpired(row)` per row returned.
6. Add device-token registration/removal to `authentication` app's session lifecycle touch
   points only via the new endpoints — no change to token/session logic itself.
7. Add the Notification and Device Token contracts to OpenAPI.

## Customer Mobile

1. `NotificationRepository` + app-wide `NotificationController` (list, unread count, mark
   read/all-read), registered in `main.dart` alongside the other app-wide controllers.
2. Notification Center screen (list, unread visual state, pull-to-refresh, empty/loading/
   error+retry states) reachable from an existing header/nav entry point.
3. Unread badge wherever the entry point lives.
4. `firebase_messaging`/`firebase_core` added; foreground handler + tap-to-navigate (table in
   Technical Design) for both foreground and background/terminated launch.
5. Register the device token after login; unregister it on logout.

## Manager Mobile

1. Same `NotificationRepository`/`NotificationController`/Notification Center/badge shape as
   Customer Mobile.
2. Manager-specific navigation targets (own-Hotel Bookings queue).
3. Same FCM wiring and login/logout token lifecycle.

## Admin Web

Only if Phase 7 finds the existing Admin Web shell supports a notification bell/list without
inventing new frontend infrastructure beyond this feature's own scope — otherwise deferred,
per the Business Specification's "Out of Scope for V1."

## FCM Configuration Required Later (Developer Action)

Notification V1's persistence, API, and in-app behavior work fully today via
`MockPushProvider` — nothing here blocks on Firebase being configured. Once the developer is
ready to enable real push delivery:

1. Create a Firebase project (or reuse an existing one) and enable Cloud Messaging.
2. Generate a service-account credential (Firebase Console → Project Settings → Service
   Accounts → Generate new private key) and set, server-side only, never committed:
   `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`.
3. Add each mobile app to the Firebase project (Android package name / iOS bundle id) and
   place the generated `google-services.json` (Android) /
   `GoogleService-Info.plist` (iOS) into each app locally — neither is committed by this
   feature.
4. Add `backend/scripts/testEnv.js`'s three Firebase variables to its forced-empty list
   (mirroring the existing Supabase override) so automated tests keep using
   `MockPushProvider` even after real credentials exist in `.env`.

## Rollout Note

New tables only — no existing data requires migration. Every Notification Catalog event is
newly created going forward; there is no historical backfill (no past event has enough
retained context to reconstruct a faithful Notification, and V1 does not require one).
