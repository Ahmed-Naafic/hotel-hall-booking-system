-- Local-first synchronisation, Phase 0 / S-03 (schema half).
--
-- A client asks "what changed since X?". Timestamps cannot answer that
-- reliably: Prisma's `@updatedAt` is stamped by the application when the
-- statement is built, not when the transaction commits, so a transaction
-- that starts earlier can become visible later and a client scanning
-- `updated_at > lastSync` skips it permanently. This module's booking and
-- availability writes run inside widened 10-second transactions that take
-- an advisory lock first, which makes that window wider here than usual.
--
-- One shared sequence across every table gives a single monotonic ordering
-- for the whole database, so a client can hold one high-water mark per
-- collection and scan forward with `sync_seq > :mark ORDER BY sync_seq ASC`.
-- Sharing one sequence rather than one per table also means the numbers
-- never collide between collections, which keeps a combined change feed
-- possible later without renumbering anything.
--
-- The column is nullable here and backfilled by the next migration. The
-- DEFAULT is set in this migration, before the backfill, so any row
-- inserted while the backfill runs already carries a value — the same
-- ordering hazard that made the first attempt at the `updated_at`
-- migration fail against this live database.
--
-- Nothing reads this column yet. `users`, `sessions`,
-- `verification_requests`, `password_reset_requests` and `device_tokens`
-- are deliberately excluded: none is ever replicated to a client.

CREATE SEQUENCE IF NOT EXISTS "sync_seq" AS BIGINT START WITH 1;

ALTER TABLE "hotels" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "hotels" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "halls" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "halls" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "hotel_media" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "hotel_media" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "hall_media" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "hall_media" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "hall_availability_blocks" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "hall_availability_blocks" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "bookings" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "notifications" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "notifications" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "chat_messages" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "chat_messages" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "saved_hotels" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "saved_hotels" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "reviews" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "reviews" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "customer_profiles" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "customer_profiles" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "hotel_applications" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "hotel_applications" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');

ALTER TABLE "critical_information_change_requests" ADD COLUMN IF NOT EXISTS "sync_seq" BIGINT;
ALTER TABLE "critical_information_change_requests" ALTER COLUMN "sync_seq" SET DEFAULT nextval('sync_seq');
