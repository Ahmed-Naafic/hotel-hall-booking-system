-- Local-first synchronisation, Phase 0 / S-03 (backfill half).
--
-- Assigns every pre-existing row a `sync_seq`. Rows inserted since the
-- previous migration already have one from the column default, so only
-- NULLs are touched and re-running is a no-op.
--
-- Ordered by `created_at` (with `id` breaking ties, the same two-key
-- ordering every cursor-paginated list in this project uses) so the
-- backfilled numbers reflect the order the rows actually appeared in.
-- Nothing depends on that — a client's first sync fetches everything
-- regardless of order — but arbitrary numbering would make the sequence
-- useless for reading history, and the ordering costs nothing here.
--
-- One statement per table rather than a loop in batches: the largest table
-- is `notifications` at roughly 3,000 rows, small enough that batching
-- would add moving parts without reducing lock time meaningfully. At a
-- volume where that stopped being true, this would become a batched job
-- run outside a migration.

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'hotels', 'halls', 'hotel_media', 'hall_media', 'hall_availability_blocks',
    'bookings', 'notifications', 'chat_messages', 'saved_hotels', 'reviews',
    'customer_profiles', 'hotel_applications', 'critical_information_change_requests'
  ]
  LOOP
    EXECUTE format(
      'UPDATE %1$I AS target
         SET sync_seq = ordered.seq
        FROM (
          SELECT id, nextval(''sync_seq'') AS seq
            FROM (
              SELECT id FROM %1$I WHERE sync_seq IS NULL ORDER BY created_at ASC, id ASC
            ) AS by_age
        ) AS ordered
       WHERE target.id = ordered.id',
      t
    );
  END LOOP;
END $$;
