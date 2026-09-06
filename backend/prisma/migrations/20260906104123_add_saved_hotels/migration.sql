-- CreateTable
CREATE TABLE "saved_hotels" (
    "id" UUID NOT NULL,
    "customer_user_id" UUID NOT NULL,
    "hotel_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_hotels_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "idx_saved_hotels_customer_created_at" ON "saved_hotels"("customer_user_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "saved_hotels_customer_user_id_hotel_id_key" ON "saved_hotels"("customer_user_id", "hotel_id");

-- AddForeignKey
ALTER TABLE "saved_hotels" ADD CONSTRAINT "saved_hotels_customer_user_id_fkey" FOREIGN KEY ("customer_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_hotels" ADD CONSTRAINT "saved_hotels_hotel_id_fkey" FOREIGN KEY ("hotel_id") REFERENCES "hotels"("id") ON DELETE CASCADE ON UPDATE CASCADE;
