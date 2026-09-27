-- Local-first synchronisation, Phase 0 / S-05 (schema half).
--
-- `hotel_media`, `hall_media` and `hall_availability_blocks` are the only
-- three tables in this database whose rows are removed outright
-- (`mediaRepository.remove`, `availabilityRepository.deleteById`). Every
-- other soft-deletes with `deleted_at`. A client holding a replica cannot
-- detect an absence: a deleted photo stays on the device forever, and a
-- deleted availability block keeps a free Hall looking busy — which costs
-- the Hotel a booking silently, with nothing in any log to show for it.
--
-- This migration only adds the column. The repository call sites still
-- hard-delete until the code half of S-05 lands, so nothing changes
-- behaviourally here. That split is deliberate: the column can be added to
-- the live database well before the code that uses it is deployed, and in
-- that order neither step can break the other.
--
-- Partial indexes: every read of these tables will filter
-- `deleted_at IS NULL`, and a partial index both stays small and keeps
-- tombstones out of the common path.

ALTER TABLE "hotel_media" ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMP(3);
ALTER TABLE "hall_media" ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMP(3);
ALTER TABLE "hall_availability_blocks" ADD COLUMN IF NOT EXISTS "deleted_at" TIMESTAMP(3);

CREATE INDEX IF NOT EXISTS "idx_hotel_media_live" ON "hotel_media" ("hotel_id") WHERE "deleted_at" IS NULL;
CREATE INDEX IF NOT EXISTS "idx_hall_media_live" ON "hall_media" ("hall_id") WHERE "deleted_at" IS NULL;
CREATE INDEX IF NOT EXISTS "idx_hall_blocks_live" ON "hall_availability_blocks" ("hall_id", "starts_at") WHERE "deleted_at" IS NULL;
