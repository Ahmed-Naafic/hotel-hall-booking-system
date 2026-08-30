-- Rename the existing Hotel-only enum to the shared media enum.
-- This is metadata-only: enum values and existing hotel_media rows are preserved.
ALTER TYPE "hotel_media_type" RENAME TO "media_type";

-- Provision ordering metadata without changing current Hotel Media behavior.
ALTER TABLE "hotel_media" ADD COLUMN "display_order" INTEGER;

-- Add Hall Media as a separate table with a real Hall foreign key.
CREATE TABLE "hall_media" (
    "id" UUID NOT NULL,
    "hall_id" UUID NOT NULL,
    "type" "media_type" NOT NULL,
    "storage_path" TEXT NOT NULL,
    "display_order" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "hall_media_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "idx_hall_media_hall_id" ON "hall_media"("hall_id");

ALTER TABLE "hall_media" ADD CONSTRAINT "hall_media_hall_id_fkey" FOREIGN KEY ("hall_id") REFERENCES "halls"("id") ON DELETE CASCADE ON UPDATE CASCADE;
