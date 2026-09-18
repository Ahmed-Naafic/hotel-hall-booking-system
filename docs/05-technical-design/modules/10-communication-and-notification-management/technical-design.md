---
title: "Notification & Communication Management — Technical Design (Notification V1, Communication V1)"
document_type: Technical Design
module: 10-communication-and-notification-management
status: Approved
owner: Engineering
reviewer: Approved by stakeholder
depends_on: ["docs/04-business/modules/10-communication-and-notification-management/business-specification.md", "docs/02-architecture/system-architecture-overview.md", "docs/02-architecture/mobile-application-architecture.md"]
last_updated: 2026-09-14
---

## Architecture

A new feature module, `backend/src/modules/notifications`, owns Notification persistence,
read/unread state, and push delivery orchestration — following the same
routes/controller/service/repository/validation/mapper split every other module already
uses (`coding-standards.md` §5). It is a pure consumer of other modules' events, never the
other way around: `bookings` and `hotels` call into `notifications`' own small
`notification.events.js` (one function per Notification Catalog row, e.g.
`onBookingCreated(booking)`, `onHotelApplicationWithdrawn(application, hotel)`), the same
shape those modules already use for `recordBookingAudit`/`recordAuditEvent` — added at the
same call sites, not new ones. `notifications` never imports from `bookings`/`hotels` beyond
the plain data already handed to it by the caller.

Push delivery reuses the existing Provider abstraction pattern
(`architecture-principles.md` §10–§11) already established for SMS
(`smsProvider.js`/`ADR-0005`) and Storage (`storageProvider.js`/`ADR-0006`) — a new
`backend/src/shared/providers/pushProvider.js` selects `FcmPushProvider` when Firebase Admin
credentials are present, or `MockPushProvider` otherwise. Firebase Cloud Messaging is already
the platform's approved push provider (`technology-stack.md`, **ADR-0001** — no new ADR is
needed to select it).

## Data Model

```prisma
model Notification {
  id                 String             @id @default(uuid()) @db.Uuid
  recipientUserId    String             @map("recipient_user_id") @db.Uuid
  type               NotificationType
  status             NotificationStatus @default(UNREAD)
  title              String
  body               String
  bookingId          String?            @map("booking_id") @db.Uuid
  hotelId            String?            @map("hotel_id") @db.Uuid
  hotelApplicationId String?            @map("hotel_application_id") @db.Uuid
  readAt             DateTime?          @map("read_at")
  createdAt          DateTime           @default(now()) @map("created_at")

  recipient        User              @relation(fields: [recipientUserId], references: [id], onDelete: Cascade)
  booking          Booking?          @relation(fields: [bookingId], references: [id], onDelete: Cascade)
  hotel            Hotel?            @relation(fields: [hotelId], references: [id], onDelete: Cascade)
  hotelApplication HotelApplication? @relation(fields: [hotelApplicationId], references: [id], onDelete: Cascade)

  @@index([recipientUserId, createdAt], map: "idx_notifications_recipient_created_at")
  @@index([recipientUserId, status], map: "idx_notifications_recipient_status")
  @@map("notifications")
}

enum NotificationType {
  BOOKING_REQUEST_SUBMITTED    // Customer — C1
  BOOKING_CONFIRMED            // Customer — C2
  BOOKING_REJECTED             // Customer — C3
  BOOKING_CANCELLED            // Customer — C4
  PAYMENT_REPORTED             // Customer — C5 (confirms their own report)
  PAYMENT_VERIFIED             // Customer — C6
  PAYMENT_REJECTED             // Customer — C7
  BOOKING_EXPIRED              // Customer — C8
  NEW_BOOKING_REQUEST          // Hotel Manager — M1
  CUSTOMER_PAYMENT_REPORTED    // Hotel Manager — M2
  CUSTOMER_BOOKING_CANCELLED   // Hotel Manager — M3
  NEW_HOTEL_APPLICATION        // Platform Administrator — A1
  HOTEL_APPLICATION_WITHDRAWN  // Platform Administrator — A2
  HOTEL_APPLICATION_RESUBMITTED // Platform Administrator — A3
  HOTEL_APPLICATION_APPROVED   // Hotel Manager — M4 (`BDR-021`)
  HOTEL_APPLICATION_REJECTED   // Hotel Manager — M5 (`BDR-021`)
  HOTEL_SUSPENDED              // Hotel Manager — M6 (`BDR-022`)
  HOTEL_DEACTIVATED            // Hotel Manager — M7 (`BDR-022`)
  HOTEL_REACTIVATED            // Hotel Manager — M8 (`BDR-022`)

  @@map("notification_type")
}

enum NotificationStatus {
  UNREAD
  READ

  @@map("notification_status")
}

model DeviceToken {
  id        String   @id @default(uuid()) @db.Uuid
  userId    String   @map("user_id") @db.Uuid
  token     String   @unique
  platform  String?
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId], map: "idx_device_tokens_user_id")
  @@map("device_tokens")
}
```

`bookingId`/`hotelId`/`hotelApplicationId` are nullable and independent (never all required
together) — they exist purely so the client can compute a navigation target, never as a
foreign key the backend re-derives business rules from. No separate "deep link" string is
persisted; encoding a route inside the backend would leak a frontend concern into the data
model (`architecture-principles.md` §5). `DeviceToken.token` is globally unique (not
per-user) so re-registering the same physical device under a different logged-in account
(a shared device, or logout/login as someone else) moves the token to the new owner via
upsert-by-token rather than leaving it duplicated under both.

This is a genuinely new, explicitly-approved entity — it does not resurrect the "no approved
module owns a persisted Audit Record" gap `hotels/audit.js`/`bookings/audit.js` both note.
Those remain structured logs; `Notification` is a distinct, user-facing history with its own
approved business rules (Business Specification §"Business Rules").

## Idempotency

Every Notification Catalog trigger sits at an existing state-transition call site already
guarded by `assertTransition` (Booking) or an application-status check (Hotel Application) —
the same guard that already makes the transition itself impossible to double-apply makes the
notification-triggering call alongside it impossible to double-fire under normal use. No
separate idempotency key or unique constraint is introduced; V1 relies on the guarantee the
platform already has, per `Project Rule 4` (reuse existing architecture).

**The one case needing care: Booking expiration (C8).** Lazy expiration
(`booking.repository.js#expireOverdue`, `availability.repository.js#expireOverdueBookings`)
is a **pre-existing, independent duplication** — two different modules each sweep overdue
`PENDING` Bookings to `EXPIRED` from their own repository, on their own read/write paths
(Booking Management's own list/get calls; Availability's checks). This predates Notification
V1 and is not refactored away here (`Project Rule 9`, no unrelated refactoring) — but it does
mean a Booking could expire via *either* path. Both functions are changed from `updateMany`
(which returns only a count) to Prisma's `updateManyAndReturn` (confirmed available on this
Prisma version), and the calling **service** (never the repository — `coding-standards.md`
§5) triggers `notificationEvents.onBookingExpired(row)` once per row actually returned.
Because both sweeps share the identical `status: 'PENDING'` guard, whichever one commits
first is the only one that can still match and return a given row — the second sweep's `WHERE
status = 'PENDING'` simply no longer matches it. This is the same database-level guard
already relied on elsewhere in this codebase, not new machinery.

## API

All routes under `/api/v1/notifications`, `authenticate` only (every account type — a
Notification's scope is the caller's own identity, not a role-gated capability):

- `GET /` — cursor-paginated, newest first, optional `?status=UNREAD` filter. Scoped to
  `recipientUserId = req.identity.userId` — no Hotel-ownership indirection is needed at read
  time, since a Notification was already addressed to the correct user at creation.
- `GET /unread-count` — `{ count }` for a badge.
- `POST /:id/read` — marks one of the caller's own Notifications `READ`; 404 (never a
  different user's Notification, matching this codebase's existing cross-tenant convention)
  if it does not belong to the caller.
- `POST /read-all` — marks every one of the caller's own `UNREAD` Notifications `READ`.
- `PUT /device-tokens` — upserts the caller's device token (body: `{ token, platform? }`),
  moving it from a previous owner if the same token was already registered elsewhere.
- `DELETE /device-tokens?token=...` (query parameter, not a URL path segment or a request
  body — an FCM token's character set is not guaranteed URL-path-safe, and the shared Flutter
  `ApiClient.delete()` does not support a request body) — unregisters a token (called on
  logout so a shared device never receives another account's push after sign-out).

## Push Delivery

`notification.service.js#notify(...)` persists the Notification first (this call is
`await`ed by the triggering business service, so the row reliably exists before that
service's own HTTP response returns), then calls `deliverPush(notification)` **without
awaiting it** — push delivery continues in the background against this project's long-lived
Node/Docker process (`technology-stack.md`; not a serverless target, so a fire-and-forget
promise reliably completes). `deliverPush` looks up the recipient's `DeviceToken`s and calls
`pushProvider.sendPush(...)` for each; any rejection is caught and logged
(`logger.error`), never rethrown — satisfying Business Rules 15/19 (a push failure can never
reach, let alone roll back, the business operation that already committed and already
returned its own response).

`FcmPushProvider` (`firebase-admin`, HTTP v1 API via a service-account credential — the
legacy `FCM_SERVER_KEY` `naming-conventions.md` §10 illustrates is deprecated by Google;
using a service-account credential is the current, correct integration, not a deviation from
an actual mandate) is selected only when `FIREBASE_PROJECT_ID` / `FIREBASE_CLIENT_EMAIL` /
`FIREBASE_PRIVATE_KEY` are all present; otherwise `MockPushProvider` (logs, keeps an
in-memory list, always "succeeds" — same shape as `MockSmsProvider`/`MockStorageProvider`)
is selected, so the entire feature works end-to-end before Firebase is ever configured.

## Navigation Targets (Client)

Computed from `(type, bookingId, hotelId, hotelApplicationId)` — no new screens:

| Type | Customer Mobile / Manager Mobile / Admin Web destination |
|---|---|
| `BOOKING_REQUEST_SUBMITTED`, `BOOKING_CONFIRMED`, `BOOKING_REJECTED`, `BOOKING_CANCELLED`, `PAYMENT_REPORTED`, `PAYMENT_VERIFIED`, `PAYMENT_REJECTED`, `BOOKING_EXPIRED` | Customer Mobile → `BookingDetailScreen(bookingId)` |
| `NEW_BOOKING_REQUEST`, `CUSTOMER_PAYMENT_REPORTED`, `CUSTOMER_BOOKING_CANCELLED` | Manager Mobile → own-Hotel Bookings queue, scrolled/filtered to `bookingId` where that is already supported, otherwise the queue itself (the safest existing destination — `Project Rule` on not inventing a screen) |
| `HOTEL_APPLICATION_APPROVED`, `HOTEL_APPLICATION_REJECTED` (`BDR-021`) | Manager Mobile → `MyHotelScreen` (the existing own-Hotel status/identity screen every Manager already lands on — no new screen invented; the Hotel's now-current status, `APPROVED_ACTIVE` or `REJECTED`, is what the Manager needs to see next) |
| `HOTEL_SUSPENDED`, `HOTEL_DEACTIVATED`, `HOTEL_REACTIVATED` (`BDR-022`) | Manager Mobile → `MyHotelScreen`, the same destination as `HOTEL_APPLICATION_APPROVED`/`REJECTED` — the Hotel's now-current status (`SUSPENDED`, `DEACTIVATED`, or `APPROVED_ACTIVE` again) is what the Manager needs to see next |
| `NEW_HOTEL_APPLICATION`, `HOTEL_APPLICATION_WITHDRAWN`, `HOTEL_APPLICATION_RESUBMITTED` | Admin Web → `DashboardShell`'s `openHotel(hotelId)` (Hotel Detail), the same destination `RecentApplications`/`HotelsTable` already use — built, see "Admin Web" below |

## Backend Authorization & Tenant Isolation

Every route requires `authenticate`; no `requireAccountType` restriction (a Notification
belongs to whichever account type its `recipientUserId` is). Every repository query filters
by `recipientUserId = req.identity.userId` — this is simpler than most existing own-Hotel
checks (no join/ownership re-derivation needed at read time) and cannot leak cross-tenant
because the recipient was already resolved correctly at creation time, by the same
own-Hotel/own-Booking logic every other write path already trusts (`hotel.registeredByUserId`
for a Hotel Manager recipient; `booking.customerUserId` for a Customer recipient; every
`PLATFORM_ADMINISTRATOR` account for an Admin recipient).

## Customer Mobile / Manager Mobile Client Architecture

A `NotificationRepository` (per app) wraps the API above; a `NotificationController`
(`ChangeNotifier`, app-wide `ChangeNotifierProvider` — the same pattern
`PopularHotelsController` already established this session) holds the unread count and the
list. `firebase_messaging`/`firebase_core` are added to both apps' `pubspec.yaml`; a
foreground-message handler shows an in-app treatment (per
`mobile-application-architecture.md` §11) and refreshes the unread count; tapping a
notification (foreground or background/terminated launch) navigates via the table above. On
successful login, the app registers its FCM device token; on logout, it unregisters it —
both via the endpoints above, mirroring the existing session lifecycle already wired through
`AuthController`.

## Admin Web

**Resolved 2026-09-11 — built.** The Platform Administrator was not seeing
`NEW_HOTEL_APPLICATION` Notifications despite the backend already creating them correctly
(`notification.events.js#notifyEveryAdmin`, tested) — `NotificationsMenu.jsx`'s bell/dropdown
existed in the header (per the approved nav composition) but was a hardcoded placeholder,
never wired to real data, because no Notification module existed when it was built.

Wiring it up needed no new frontend infrastructure — no router, no push, no new screen — so
it satisfies the Business Specification's "cheaply, without inventing new frontend
infrastructure" condition:

- `shared/api/notificationsApi.js` — thin client for `GET /notifications`,
  `GET /notifications/unread-count`, `POST /notifications/:id/read`,
  `POST /notifications/read-all` (the same routes every client already uses; no device-token
  registration — browser push delivery remains out of scope).
- `features/notifications/useNotifications.js` — mirrors Manager Mobile's
  `NotificationController`: unread count kept live from mount, list fetched lazily only when
  the menu opens, no polling.
- `NotificationsMenu.jsx` — real list/unread-badge/mark-read/mark-all-read; tapping a
  Notification with a `hotelId` calls `DashboardShell`'s existing `openHotel(hotelId)` (the
  same navigation `RecentApplications`/`HotelsTable` already use) — no new destination
  invented, matching the Navigation Targets table above.

## Testing Strategy

Backend: real-database integration tests (this codebase's established convention — see
`booking.integration.test.js`/`popular.integration.test.js`) for creation-on-event,
recipient correctness, ownership isolation, read/mark-all-read, pagination, unread count,
and — using `MockPushProvider` — that a simulated push failure never removes or blocks the
persisted Notification. Flutter: widget tests per app mirroring the patterns already
established this session (`hall_detail_booking_confirmation_test.dart`,
`bookings_coming_soon_screen_test.dart`).

---

## Communication V1

### Architecture

A new feature module, `backend/src/modules/chat`, owns message persistence, read state, and
authorization for a Booking's conversation — the same
routes/controller/service/repository/validation/mapper split every other module already uses.
`chat` calls into `notifications`' existing `notification.events.js` exactly the way
`bookings`/`hotels` already do (`onChatMessageSent`, one function, two Notification Catalog
rows depending on who sent it) — never the other way around, and never duplicating push
delivery logic that already exists.

No separate "Thread" entity is introduced (Business Rule 1 — a Booking already is the
thread; `bookingId` is the thread key). This is the same reasoning `Notification`'s data
model already documents for why it stores plain nullable foreign keys rather than inventing
a parallel concept.

### Data Model

```prisma
model ChatMessage {
  id           String   @id @default(uuid()) @db.Uuid
  bookingId    String   @map("booking_id") @db.Uuid
  senderUserId String   @map("sender_user_id") @db.Uuid
  body         String
  readAt       DateTime? @map("read_at")
  createdAt    DateTime @default(now()) @map("created_at")

  booking Booking @relation(fields: [bookingId], references: [id], onDelete: Cascade)
  sender  User    @relation(fields: [senderUserId], references: [id], onDelete: Cascade)

  @@index([bookingId, createdAt], map: "idx_chat_messages_booking_created_at")
  @@index([bookingId, senderUserId, readAt], map: "idx_chat_messages_unread_lookup")
  @@map("chat_messages")
}
```

`senderUserId` identifies which of the Booking's two participants sent it — the *other*
participant is derived at read time from the Booking/Hotel relationship already loaded for
authorization, never stored redundantly on the message itself. `readAt` is set on every
row where `senderUserId` is the *other* participant, the moment the reader opens the
conversation (Business Rule 7) — never on the sender's own messages, which have no
"read by me" concept.

### API

All routes under `/api/v1/bookings/:bookingId/messages`, `authenticate` only, scoped by a new
shared authorization check, `chatService.assertParticipant(booking, hotel, userId)` — true iff
`userId === booking.customerUserId` or `userId === hotel.registeredByUserId`; 404 otherwise
(matching this codebase's existing cross-tenant convention, e.g.
`booking.repository.js#findByIdForCustomer`/`findByIdForHotel`, which this reuses to load
`booking`/`hotel` before the check):

- `GET /api/v1/bookings/:bookingId/messages` — cursor-paginated, **oldest first** (Business
  Rule 6 — the opposite order from `GET /notifications`, called out explicitly so it is never
  "fixed" to match Notification's order by mistake later).
- `POST /api/v1/bookings/:bookingId/messages` — body `{ body }` (1-2000 chars, trimmed,
  non-empty — same shape `specialRequest` validation already uses); creates the message as
  the caller, triggers `notificationEvents.onChatMessageSent`.
- `POST /api/v1/bookings/:bookingId/messages/read-all` — marks every message in this Booking's
  conversation sent by the *other* participant `readAt = now()` (Business Rule 7); a no-op
  (200, not an error) if there is nothing unread.
- `GET /api/v1/messages/unread-count` — `{ count }`, the caller's total unread messages across
  every Booking they participate in (Business Rule 8) — a second, independent badge source
  from `GET /notifications/unread-count`, never merged with it.

### Authorization & Tenant Isolation

Every route requires `authenticate`; no `requireAccountType` restriction (a participant is
whichever of Customer/Hotel Manager the Booking says, not a role-gated capability — the same
shape Notification V1's own routes already use). `assertParticipant` is the single choke
point every route calls before touching a message row — modeled directly on
`booking.controller.js`'s existing pattern of loading a Booking for-Customer or for-Hotel
before authorizing, generalized to "either, whichever this caller actually is."

### Push Delivery (Reuses Notification V1)

`chat.service.js#sendMessage` calls `notificationEvents.onChatMessageSent(message, booking)`
in the same fire-and-forget-after-persist shape every existing event function already uses —
no new push code, no new `DeviceToken` handling, no new provider. The two new
`NotificationType` values (`NEW_CHAT_MESSAGE` sent to the Customer, same type sent to the
Manager — recipient is what differs, not the type) are added to the existing enum:

```prisma
enum NotificationType {
  // ...existing Notification V1 values unchanged...
  NEW_CHAT_MESSAGE // Customer — C9, Hotel Manager — M9 (Communication V1)
}
```

The persisted `Notification` row's `bookingId` is what lets the client's existing Navigation
Targets table (above) route a tap straight to the conversation, following the same "nullable
FK the client uses to compute a destination" convention `Notification` already established
— extended by one row:

| Type | Destination |
|---|---|
| `NEW_CHAT_MESSAGE` | Customer Mobile → `BookingDetailScreen(bookingId)`'s conversation entry point; Manager Mobile → the same Booking's detail sheet's conversation entry point |

### Client Architecture (Both Mobile Apps)

Same shape as Notification V1's own client architecture: a `ChatRepository` wrapping the API
above, and a `ChatController` (`ChangeNotifier`) scoped to one open conversation (created per
screen instance, not app-wide like `NotificationController` — a conversation is opened,
used, and closed, not a persistent app-wide badge source by itself). A separate, small
app-wide unread-message-count value is read from `GET /messages/unread-count` the same way
`NotificationController` already tracks its own unread count, and shown as an independent
badge (Business Rule 8) — e.g. alongside the existing Notification bell/badge on each app's
entry point, never merged into it.

A `ChatScreen(bookingId)` is reachable from Customer Mobile's `BookingDetailScreen` and
Manager Mobile's Booking detail sheet (`bookings_coming_soon_screen.dart`'s
`_BookingDetailSheet`) — both already know their own `booking.id`, so no new navigation
plumbing beyond one new button/entry point on each existing screen. Opening `ChatScreen`
loads the conversation (oldest-first) and immediately calls `read-all` (Business Rule 7).

### Testing Strategy (Communication V1)

Backend: real-database integration tests mirroring Notification V1's own — message creation,
participant-only read/write (a third user gets 403/404), oldest-first pagination, read-all
correctness (only the other participant's messages flip, never the caller's own), unread
count across multiple Bookings, and — reusing `MockPushProvider` — that a simulated push
failure never removes or blocks the persisted message. Flutter: a widget test per app for
`ChatScreen` (send, receive via refresh, marks read on open, empty/loading/error states),
mirroring `notification_center_screen_test.dart`'s own patterns.
