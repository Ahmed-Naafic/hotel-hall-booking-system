-- Local-first synchronisation, Phase 0 / S-05 (constraint half). REQUIRED by
-- the soft-delete change in `availability.repository.js` — that change is a
-- regression without this one.
--
-- `hall_availability_blocks_no_overlap` (availability_foundation migration)
-- was written when rows were deleted outright, so it has no WHERE clause and
-- every row in the table occupies its period:
--
--   EXCLUDE USING gist (hall_id WITH =, tsrange(starts_at, ends_at, '[)') WITH &&)
--
-- Now that a deleted block is a tombstone rather than a removed row, that
-- constraint keeps enforcing the period of blocks the Manager already
-- deleted. Measured: create a block, delete it, re-block the same period ->
-- 409, while `hasOverlap` correctly reports the period free. A Manager
-- deleting a maintenance block would poison that slot permanently, and the
-- error would blame "an existing availability block" that no longer exists.
--
-- The fix mirrors what `bookings_no_blocking_overlap` already does — that
-- constraint scopes itself with `WHERE (status IN ('PENDING','CONFIRMED'))`
-- so a CANCELLED or EXPIRED Booking stops reserving its period. This is the
-- same idea with the same shape: only live rows exclude each other.
--
-- Dropping and recreating rebuilds the GiST index. That takes a brief
-- ACCESS EXCLUSIVE lock on a table holding on the order of ten rows.
--
-- The anti-overlap guarantee itself is unchanged for live blocks: still the
-- database, still immune to application-level races, still the authority the
-- Approved Technical Design (Availability & Calendar V1, decision 2) named.

ALTER TABLE "hall_availability_blocks" DROP CONSTRAINT "hall_availability_blocks_no_overlap";

ALTER TABLE "hall_availability_blocks" ADD CONSTRAINT "hall_availability_blocks_no_overlap"
  EXCLUDE USING gist (
    "hall_id" WITH =,
    tsrange("starts_at", "ends_at", '[)') WITH &&
  ) WHERE ("deleted_at" IS NULL);
