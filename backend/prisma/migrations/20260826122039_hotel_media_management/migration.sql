-- CreateEnum
CREATE TYPE "hotel_media_type" AS ENUM ('LOGO', 'PHOTO');

-- CreateTable
CREATE TABLE "hotel_media" (
    "id" UUID NOT NULL,
    "hotel_id" UUID NOT NULL,
    "type" "hotel_media_type" NOT NULL,
    "storage_path" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "hotel_media_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_hotel_media_hotel_id" ON "hotel_media"("hotel_id");

-- AddForeignKey
ALTER TABLE "hotel_media" ADD CONSTRAINT "hotel_media_hotel_id_fkey" FOREIGN KEY ("hotel_id") REFERENCES "hotels"("id") ON DELETE CASCADE ON UPDATE CASCADE;
