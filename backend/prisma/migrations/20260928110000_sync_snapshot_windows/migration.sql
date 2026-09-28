-- Local-first synchronisation — correct delivery regardless of commit order.
--
-- THE DEFECT THIS FIXES. Phase 0 assumed `sync_seq` was monotonic in commit
-- order. It is not: `nextval()` is taken when the row is written, but the row
-- only becomes visible at COMMIT. A Booking transaction (which holds an
-- advisory lock and can run for seconds) takes seq 100; a short write takes 101
-- and commits first; a client syncing in between receives 101 and advances its
-- cursor past 100. When 100 commits, `sync_seq > cursor` never returns it. The
-- Manager's device silently and permanently misses a Booking. Reproduced on
-- PostgreSQL 17 before this migration was written — the same class of defect
-- the Technical Design rejected timestamps for (§2.1), with a smaller window.
--
-- THE FIX: snapshot windows (the design PgQ/Skytools uses for the same problem).
-- Every row records the top-level transaction that last wrote it. A cursor is
-- a pair of PostgreSQL snapshots, and a batch is exactly the rows whose writer
-- is visible in the newer snapshot and not in the older one. Visibility is a
-- property of COMMIT, not of when a number was drawn, so no commit order can
-- make a row fall between two batches. `sync_seq` remains, but only as the
-- keyset for paginating *within* one batch, where the set of rows is fixed.
--
-- A long-running transaction delays only its own rows (they are not yet
-- visible in the newer snapshot, so they arrive in a later batch); it does not
-- stall anyone else's sync — unlike an "oldest running transaction" horizon.
--
-- `xid8` (64-bit, epoch-extended) never wraps, so it is safe as a durable
-- value; it is stored as BIGINT so Prisma can read it, and cast back to `xid8`
-- only inside the visibility test.
--
-- Safety (database-standards and Technical Design §15 rules):
--   1. DEFAULT is set before anything depends on it; no backfill is needed —
--      NULL means "written before this column existed", which the sync query
--      treats as visible in every snapshot.
--   2. Every statement is idempotent.
--   3. `sync_seq` becomes NOT NULL. Phase 0 backfilled every row and kept the
--      DEFAULT, so this is verified rather than assumed: the DO block refuses
--      to proceed if any NULL remains, instead of failing half-way.

DO $$
DECLARE
  t text;
  nulls bigint;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'hotels', 'halls', 'hotel_media', 'hall_media', 'hall_availability_blocks',
    'bookings', 'notifications', 'chat_messages', 'saved_hotels', 'reviews',
    'customer_profiles', 'hotel_applications', 'critical_information_change_requests'
  ]
  LOOP
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS sync_txid BIGINT', t);
    EXECUTE format(
      'ALTER TABLE %I ALTER COLUMN sync_txid SET DEFAULT (pg_current_xact_id())::text::bigint', t
    );

    EXECUTE format('SELECT count(*) FROM %I WHERE sync_seq IS NULL', t) INTO nulls;
    IF nulls > 0 THEN
      RAISE EXCEPTION 'Table % has % rows with NULL sync_seq; backfill before SET NOT NULL', t, nulls;
    END IF;
    EXECUTE format('ALTER TABLE %I ALTER COLUMN sync_seq SET NOT NULL', t);
  END LOOP;
END $$;

-- The update path. Same trigger, same 13 tables (20260927100000); it now also
-- records who wrote the row. `pg_current_xact_id()` returns the top-level
-- transaction id even inside a savepoint, which is the id whose commit makes
-- the row visible.
CREATE OR REPLACE FUNCTION sync_seq_bump() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.sync_seq := nextval('sync_seq');
  NEW.sync_txid := (pg_current_xact_id())::text::bigint;
  RETURN NEW;
END;
$$;
