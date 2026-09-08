---
title: "Notification Management — Implementation Plan (Notification V1)"
document_type: Implementation Planning
module: 10-communication-and-notification-management
status: Done — FCM configured end-to-end (backend + Customer Mobile Android + Manager Mobile Android); see "FCM Configuration Required Later" for what remains (iOS)
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

**Done (2026-09-07, later same day):** Backend now has real Firebase service-account
credentials (`FIREBASE_PROJECT_ID`/`CLIENT_EMAIL`/`PRIVATE_KEY` in `.env`, gitignored; the raw
downloaded `hotel-hall-booking-sys-firebase-adminsdk-*.json` is also gitignored) —
`FcmPushProvider` is active and confirmed sending real pushes. This surfaced and fixed a real
bug in `fcmPushProvider.js`: it used the pre-v12 `admin.credential.cert(...)` /
`admin.messaging()` namespaced API, which does not exist on `firebase-admin` v14.3.0's ESM
default export (`admin.credential` was `undefined`, crashing the server at startup the moment
real credentials were supplied) — fixed to use the modular API (`cert`/`initializeApp` from
`firebase-admin/app`, `getMessaging` from `firebase-admin/messaging`).

Manager Mobile's Android app is now fully wired the same way Customer Mobile's is:
`firebase_core`/`firebase_messaging` dependencies, the `com.google.gms.google-services`
Gradle plugin, `lib/firebase_options.dart` (hand-written from its `google-services.json`,
which already had both apps' entries — the Firebase-console registration step had been done
ahead of the client wiring), `lib/core/push_notification_service.dart`, device-token
registration in `AuthGate` and unregistration in `ProfileScreen`'s logout (Manager Mobile's
only reachable logout site — it has no `VerifyScreen`-based logout path). Its
`NotificationController`/`NotificationRepository` were missing the
`registerDeviceToken`/`unregisterDeviceToken` methods Customer Mobile's already had; added to
match. `kotlin.incremental=false` was already present in its `gradle.properties` from an
earlier fix.

Also found and fixed the actual reason no push notification was ever visible on a real device
even with everything above correctly wired: **Android 13+ (API 33+) blocks all notifications
for an app until it is granted the runtime `POST_NOTIFICATIONS` permission**, and neither app
declared it or requested it. Added `<uses-permission
android:name="android.permission.POST_NOTIFICATIONS"/>` to both apps'
`AndroidManifest.xml` and `await FirebaseMessaging.instance.requestPermission();` to both
apps' `PushNotificationService.initialize()`. Confirmed via `adb shell dumpsys notification`
that Customer Mobile's per-app setting changed from `importance=NONE` to `importance=DEFAULT,
userSet=true` after reinstalling. Confirmed end-to-end on a physical device for both the
Customer role (`BOOKING_REQUEST_SUBMITTED`) and the Hotel Manager role (`NEW_BOOKING_REQUEST`,
`CUSTOMER_BOOKING_CANCELLED`) once each account had a registered device token.

**Done (2026-09-08), delivery-mechanics hardening pass** (prompted by "implement whatever
needs push notification in the entire code" — an audit of the delivery path itself, not the
event catalog, which was already complete at 14/14):

- **Dead-token cleanup.** `notification.service.js#deliverPush` now prunes a `DeviceToken`
  row when `admin.messaging()` reports the token itself is permanently gone
  (`messaging/registration-token-not-registered`, `.../invalid-registration-token`,
  `.../invalid-argument`) — otherwise a reinstalled/uninstalled device's dead token would fail
  forever on every future Notification for that recipient. Any other failure (quota, network,
  transient) leaves the token in place. `MockPushProvider.failNextSend(code)` now accepts an
  optional FCM-style error code and wraps its thrown error the same way `FcmPushProvider` does
  (`Error('Push delivery failed.', { cause })`) — the two were inconsistent before this pass,
  which would have made the cleanup logic untestable against the mock. Two new integration
  tests cover both branches.
- **Token-refresh handling.** Neither app previously listened for
  `FirebaseMessaging.instance.onTokenRefresh` — a rotated token (reinstall, cleared app data,
  a security-driven rotation) would silently stop receiving push until the next cold start
  happened to call `getToken()` again on its own. Both apps' `PushNotificationService` now
  expose an `onTokenRefreshed` stream; `AuthGate` subscribes and re-registers.
- **Tap-to-navigate from background/terminated state.** Previously documented as not
  implemented ("needs a global `navigatorKey`"). Solved without one: `PushNotificationService`
  exposes `onNotificationTapped` (warm tap) and `consumeInitialTap()` (cold-start tap);
  `AuthGate` — already the app's root routing decision — subscribes/checks these using its own
  `State`'s `BuildContext` (which sits directly inside `MaterialApp`'s Navigator) and pushes
  the existing `NotificationCenterScreen`, reusing its already-correct per-Notification
  tap-to-navigate/mark-read behavior rather than resolving a route a second time elsewhere.
- **`platform` field.** Was always stored `null` — neither app's `NotificationController`
  passed it. Both now send `'android'`/`'ios'` via `dart:io Platform`.

**Still pending (developer action):**

1. Register an iOS app for each Flutter app if/when iOS is targeted, and add the resulting
   `GoogleService-Info.plist` + iOS entries in each `firebase_options.dart`.
2. Add `backend/scripts/testEnv.js`'s three Firebase variables to its forced-empty list
   (mirroring the existing Supabase override) so automated tests keep using
   `MockPushProvider` even after real credentials exist in `.env` — **already done**, no
   further action needed here.
3. Cosmetic only: neither app declares a `default_notification_icon`/`default_notification_color`
   meta-data in `AndroidManifest.xml`, so FCM falls back to the full-color launcher icon as the
   status-bar icon, which Android may render as a plain white silhouette on some versions. Not
   implemented here — it needs a real monochrome icon asset (a design deliverable), not just
   wiring; a placeholder would look worse than the current fallback.

## Rollout Note

New tables only — no existing data requires migration. Every Notification Catalog event is
newly created going forward; there is no historical backfill (no past event has enough
retained context to reconstruct a faithful Notification, and V1 does not require one).
