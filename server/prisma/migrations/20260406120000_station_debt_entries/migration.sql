-- CreateTable
CREATE TABLE "station_debt_entries" (
    "id" TEXT NOT NULL,
    "debtor_name" VARCHAR(200) NOT NULL,
    "product_id" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unit_price" DECIMAL(12,2) NOT NULL,
    "total_amount" DECIMAL(14,2) NOT NULL,
    "recorded_by_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "station_debt_entries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "station_debt_entries_created_at_idx" ON "station_debt_entries"("created_at");

-- CreateIndex
CREATE INDEX "station_debt_entries_debtor_name_idx" ON "station_debt_entries"("debtor_name");

-- AddForeignKey
ALTER TABLE "station_debt_entries" ADD CONSTRAINT "station_debt_entries_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "station_debt_entries" ADD CONSTRAINT "station_debt_entries_recorded_by_id_fkey" FOREIGN KEY ("recorded_by_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
