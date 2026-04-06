-- DropForeignKey
ALTER TABLE "expenses" DROP CONSTRAINT "expenses_driver_id_fkey";

-- AddForeignKey
ALTER TABLE "expenses" ADD CONSTRAINT "expenses_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
