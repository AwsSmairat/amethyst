-- AlterTable
ALTER TABLE "station_debt_entries" ADD COLUMN "repaid_at" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "station_debt_entries_repaid_at_idx" ON "station_debt_entries"("repaid_at");
