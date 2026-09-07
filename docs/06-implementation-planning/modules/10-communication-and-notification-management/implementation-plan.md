---
title: "Notification Management — Implementation Plan (Notification V1)"
document_type: Implementation Planning
module: 10-communication-and-notification-management
status: In Progress (Customer Mobile Android FCM configured; see "FCM Configuration Required Later")
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
4. `firebase_core`/`firebase_messaging` added; `PushNotificationService`
   (`lib/core/push_notification_service.dart`) isolates every direct Firebase SDK call —
   `initialize()` never throws, so a build without real Firebase configuration degrades to
   "push disabled," never a crash. **Delivered for Android** (real `google-services.json` +
   hand-written `lib/firebase_options.dart`, both gitignored, developer-provided — see "FCM
   Configuration Required Later"); iOS remains unconfigured (no
   `GoogleService-Info.plist` yet). Tap-to-navigate from a background/terminated launch
   (`FirebaseMessaging.onMessageOpenedApp`/`getInitialMessage`) is **not yet implemented** —
   it needs a global `navigatorKey` this app's `MaterialApp` does not currently have, which
   is more than this pass's scope; foreground tap-through already works today via the
   in-app Notification Center.
5. Register the device token once per authenticated session (`AuthGate`); unregister it on
   the one reachable logout action (`VerifyScreen` — `HomeScreen`'s own logout button is
   dead code, unreferenced by any route, and was left alone per Project Rule 9).

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
`MockPushProvider` — nothing here blocks on Firebase being configured.

**Done (2026-09-07):** Firebase project `hotel-hall-booking-sys` created; Customer Mobile's
Android app registered (`com.hotelhallbooking.customer_mobile`) and its
`google-services.json` placed at `apps/customer-mobile/android/app/google-services.json`
(gitignored — gitignore updated for both apps' `google-services.json`/
`GoogleService-Info.plist`/`lib/firebase_options.dart`, none committed). The Android Gradle
plugin (`com.google.gms.google-services` 4.5.0) is applied in Customer Mobile's
`android/settings.gradle.kts`/`android/app/build.gradle.kts`; `lib/firebase_options.dart` was
hand-written from that file's own client identifiers (not secret — Firebase's security model
is Security Rules/App Check, not hiding these — kept out of git anyway for consistency with
`google-services.json`). **Windows-specific fix required to build at all:** Kotlin's
incremental-compilation cache fails with "this and base files have different roots" when the
Gradle project and the Flutter pub cache live on different drive letters (this machine: `D:`
project, `C:` pub cache) — `kotlin.incremental=false` added to Customer Mobile's
`android/gradle.properties` works around it (full recompiles only, never incorrect output).

**Still pending (developer action):**

1. Generate a service-account credential for `hotel-hall-booking-sys` (Firebase Console →
   Project Settings → Service Accounts → Generate new private key) and set, server-side
   only, never committed: `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`,
   `FIREBASE_PRIVATE_KEY` — this is what turns on `FcmPushProvider` on the backend; nothing
   client-side needs it.
2. Register Manager Mobile as a second Android app in the same Firebase project
   (`com.hotelhallbooking.manager_mobile`), download its own `google-services.json`, and
   repeat this same wiring for that app (plugin in its `settings.gradle.kts`/
   `build.gradle.kts`, its own `lib/firebase_options.dart`, the same
   `kotlin.incremental=false` workaround).
3. Register an iOS app for each Flutter app if/when iOS is targeted, and add the resulting
   `GoogleService-Info.plist` + iOS entries in each `firebase_options.dart`.
4. Add `backend/scripts/testEnv.js`'s three Firebase variables to its forced-empty list
   (mirroring the existing Supabase override) so automated tests keep using
   `MockPushProvider` even after real credentials exist in `.env` — **already done**, no
   further action needed here.

## Rollout Note

New tables only — no existing data requires migration. Every Notification Catalog event is
newly created going forward; there is no historical backfill (no past event has enough
retained context to reconstruct a faithful Notification, and V1 does not require one).
