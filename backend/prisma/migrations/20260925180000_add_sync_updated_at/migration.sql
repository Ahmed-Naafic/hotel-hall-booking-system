-- Local-first synchronisation, Phase 0 / S-02.
--
-- Six tables clients would cache carry `created_at` but no `updated_at`, so
-- a change to an existing row is undetectable. Two of them hold state that
-- must be reconciled across devices: a Notification's `status`/`read_at`,
-- and a ChatMessage's `read_at`. Nothing reads this column yet.
--
-- Each table follows the same four steps, in this order, for two reasons:
--
--   1. ADD COLUMN nullable, so a populated table is not rewritten and no
--      NOT NULL violation is possible on rows that already exist.
--   2. SET DEFAULT *before* the backfill and before SET NOT NULL. The
--      database this runs against serves a live application, and an INSERT
--      arriving mid-migration would otherwise write a NULL that step 4
--      then rejects. A first attempt at this migration failed exactly that
--      way. The default also means application code that predates this
--      column keeps inserting successfully until it is redeployed.
--   3. Backfill from `created_at` — accurate for an existing row, unlike
--      the default's CURRENT_TIMESTAMP, which is only right for a new one.
--   4. SET NOT NULL, now safe because steps 2 and 3 leave no NULLs.
--
-- The default is kept, not dropped: `schema.prisma` declares these columns
-- `@default(now()) @updatedAt`, so the database default and the schema
-- agree, and Prisma still assigns the value on every write.
--
-- Every statement is idempotent (`IF NOT EXISTS`, `WHERE ... IS NULL`), so
-- re-running after a partial failure is safe.

ALTER TABLE "notifications" ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3);
ALTER TABLE "notifications" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;
UPDATE "notifications" SET "updated_at" = "created_at" WHERE "updated_at" IS NULL;
ALTER TABLE "notifications" ALTER COLUMN "updated_at" SET NOT NULL;

ALTER TABLE "chat_messages" ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3);
ALTER TABLE "chat_messages" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;
UPDATE "chat_messages" SET "updated_at" = "created_at" WHERE "updated_at" IS NULL;
ALTER TABLE "chat_messages" ALTER COLUMN "updated_at" SET NOT NULL;

ALTER TABLE "saved_hotels" ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3);
ALTER TABLE "saved_hotels" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;
UPDATE "saved_hotels" SET "updated_at" = "created_at" WHERE "updated_at" IS NULL;
ALTER TABLE "saved_hotels" ALTER COLUMN "updated_at" SET NOT NULL;

ALTER TABLE "reviews" ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3);
ALTER TABLE "reviews" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;
UPDATE "reviews" SET "updated_at" = "created_at" WHERE "updated_at" IS NULL;
ALTER TABLE "reviews" ALTER COLUMN "updated_at" SET NOT NULL;

ALTER TABLE "hotel_applications" ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3);
ALTER TABLE "hotel_applications" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;
UPDATE "hotel_applications" SET "updated_at" = "created_at" WHERE "updated_at" IS NULL;
ALTER TABLE "hotel_applications" ALTER COLUMN "updated_at" SET NOT NULL;

ALTER TABLE "critical_information_change_requests" ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3);
ALTER TABLE "critical_information_change_requests" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;
UPDATE "critical_information_change_requests" SET "updated_at" = "created_at" WHERE "updated_at" IS NULL;
ALTER TABLE "critical_information_change_requests" ALTER COLUMN "updated_at" SET NOT NULL;
