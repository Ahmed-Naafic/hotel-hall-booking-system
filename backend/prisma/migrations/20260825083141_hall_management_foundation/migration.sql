-- CreateTable
CREATE TABLE "halls" (
    "id" UUID NOT NULL,
    "hotel_id" UUID NOT NULL,
    "profile_data" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "halls_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_halls_hotel_id" ON "halls"("hotel_id");

-- AddForeignKey
ALTER TABLE "halls" ADD CONSTRAINT "halls_hotel_id_fkey" FOREIGN KEY ("hotel_id") REFERENCES "hotels"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
