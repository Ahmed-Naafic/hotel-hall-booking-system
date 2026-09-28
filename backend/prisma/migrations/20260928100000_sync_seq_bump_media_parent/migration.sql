-- Local-first synchronisation, Phase 1 — a media change is a change to its parent.
--
-- A synced Hall or Hotel carries its photos (and a Hotel its logo) inside the
-- row, because sync returns the same shape the REST endpoints return
-- (`sync.mapper.js`) and the public URL can only be derived server-side. But
-- adding, replacing or deleting a photo writes only a `hall_media` /
-- `hotel_media` row. The parent's `sync_seq` did not move, so a replica kept
-- the parent exactly as it was: a deleted photo stayed visible on the device
-- forever, and a new one never appeared — until something unrelated happened
-- to touch the Hall.
--
-- WHY A TRIGGER, for the same reason `sync_seq_bump()` is one
-- (20260927100000): the rule is structural — the parent's representation
-- includes its media — so it must hold for every write path, including ones
-- not yet written. Repository code in the two media modules could be
-- forgotten by the third.
--
-- WHY AFTER, not BEFORE: the parent row is a different table. BEFORE triggers
-- exist to rewrite NEW; this one issues a separate UPDATE, which in turn fires
-- the parent's own BEFORE `sync_seq_bump()`.
--
-- WHY THE WHEN CLAUSE: `hotel.repository.js#touchSyncDependents` bumps every
-- media row's `sync_seq` when a Hotel's status changes, and has already bumped
-- the parents in the same statement. Without a column filter each of those
-- media bumps would bump its parent again, once per photo. Only the columns the
-- parent's mapped shape actually contains are listed: `type`, `storage_path`
-- (the URL), `display_order`, `deleted_at`, and the parent key itself.
--
-- Locking: the media write already holds FOR KEY SHARE on the parent through
-- the foreign key; the parent UPDATE takes FOR NO KEY UPDATE, which does not
-- conflict with it. Two concurrent photo uploads to one Hall serialise on the
-- parent row and cannot deadlock.
--
-- Idempotent: CREATE OR REPLACE for the functions, DROP ... IF EXISTS for the
-- triggers, so a partial run can be re-applied.

CREATE OR REPLACE FUNCTION sync_seq_bump_hall_from_media() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    UPDATE halls SET sync_seq = nextval('sync_seq') WHERE id = NEW.hall_id;
  END IF;
  -- The old parent, when a row is deleted outright (only by cascade) or moved.
  IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.hall_id IS DISTINCT FROM NEW.hall_id) THEN
    UPDATE halls SET sync_seq = nextval('sync_seq') WHERE id = OLD.hall_id;
  END IF;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION sync_seq_bump_hotel_from_media() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    UPDATE hotels SET sync_seq = nextval('sync_seq') WHERE id = NEW.hotel_id;
  END IF;
  IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.hotel_id IS DISTINCT FROM NEW.hotel_id) THEN
    UPDATE hotels SET sync_seq = nextval('sync_seq') WHERE id = OLD.hotel_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_parent_hall_media_ins_del ON hall_media;
CREATE TRIGGER trg_sync_parent_hall_media_ins_del
  AFTER INSERT OR DELETE ON hall_media
  FOR EACH ROW EXECUTE FUNCTION sync_seq_bump_hall_from_media();

DROP TRIGGER IF EXISTS trg_sync_parent_hall_media_upd ON hall_media;
CREATE TRIGGER trg_sync_parent_hall_media_upd
  AFTER UPDATE ON hall_media
  FOR EACH ROW
  WHEN (
    OLD.type IS DISTINCT FROM NEW.type
    OR OLD.storage_path IS DISTINCT FROM NEW.storage_path
    OR OLD.display_order IS DISTINCT FROM NEW.display_order
    OR OLD.deleted_at IS DISTINCT FROM NEW.deleted_at
    OR OLD.hall_id IS DISTINCT FROM NEW.hall_id
  )
  EXECUTE FUNCTION sync_seq_bump_hall_from_media();

DROP TRIGGER IF EXISTS trg_sync_parent_hotel_media_ins_del ON hotel_media;
CREATE TRIGGER trg_sync_parent_hotel_media_ins_del
  AFTER INSERT OR DELETE ON hotel_media
  FOR EACH ROW EXECUTE FUNCTION sync_seq_bump_hotel_from_media();

DROP TRIGGER IF EXISTS trg_sync_parent_hotel_media_upd ON hotel_media;
CREATE TRIGGER trg_sync_parent_hotel_media_upd
  AFTER UPDATE ON hotel_media
  FOR EACH ROW
  WHEN (
    OLD.type IS DISTINCT FROM NEW.type
    OR OLD.storage_path IS DISTINCT FROM NEW.storage_path
    OR OLD.display_order IS DISTINCT FROM NEW.display_order
    OR OLD.deleted_at IS DISTINCT FROM NEW.deleted_at
    OR OLD.hotel_id IS DISTINCT FROM NEW.hotel_id
  )
  EXECUTE FUNCTION sync_seq_bump_hotel_from_media();
