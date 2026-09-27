-- Local-first synchronisation, Phase 0 / S-03 (assignment on update).
--
-- Inserts already get a `sync_seq` from the column default. Updates need one
-- too, or a changed row keeps its original number and no client ever learns
-- it changed — the quietest possible failure in a sync design.
--
-- WHY A TRIGGER, rather than the repository-layer assignment the
-- Implementation Plan originally specified:
--
--   1. Prisma cannot express it. There is no way to write
--      `sync_seq = nextval('sync_seq')` in an `update`/`updateMany` data
--      payload — Prisma has no SQL-function escape there. Repository-layer
--      assignment would mean rewriting every write as raw SQL, or issuing a
--      second statement per write.
--   2. There are ~25 production write paths across 12 files, including
--      `updateMany` sweeps that run on every booking read
--      (`expireOverdue`, `completeEnded`), `markAllReadForUser`, chat's
--      `markConversationRead`, a `savedHotel` upsert, and writes scoped to
--      a transaction client via `db(client)`. Missing any one of them
--      silently stops that table syncing.
--   3. The plan's stated objection — that a trigger's value would not be
--      visible in the same transaction and would need database
--      introspection to test — is simply wrong for a BEFORE trigger. It
--      fires during the UPDATE, so the row Prisma returns already carries
--      the new value, and a test asserts it by reading the row back.
--
-- This also follows the precedent this project already set for invariants
-- that only the database can enforce: the `EXCLUDE` constraints on
-- `bookings` and `hall_availability_blocks` are hand-added SQL for the same
-- class of reason, and `schema.prisma` documents them in a comment rather
-- than modelling them.
--
-- The trigger fires on every UPDATE, including one that changes no other
-- column. That is deliberate: a write is a write, and a client re-reading an
-- unchanged row is harmless, whereas missing a real change is not.

CREATE OR REPLACE FUNCTION sync_seq_bump() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.sync_seq := nextval('sync_seq');
  RETURN NEW;
END;
$$;

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
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I', 'trg_sync_seq_' || t, t);
    EXECUTE format(
      'CREATE TRIGGER %I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION sync_seq_bump()',
      'trg_sync_seq_' || t, t
    );
  END LOOP;
END $$;
