-- CreateEnum
CREATE TYPE "StationDebtRecordingSource" AS ENUM ('station', 'vehicle');

-- AlterTable
ALTER TABLE "station_debt_entries" ADD COLUMN "recording_source" "StationDebtRecordingSource" NOT NULL DEFAULT 'station';

-- CreateIndex
CREATE INDEX "station_debt_entries_recording_source_recorded_by_id_idx" ON "station_debt_entries"("recording_source", "recorded_by_id");
