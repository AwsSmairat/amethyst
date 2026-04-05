-- CreateEnum
CREATE TYPE "VehicleSaleDestination" AS ENUM ('home', 'store');

-- AlterTable
ALTER TABLE "vehicle_sales" ADD COLUMN "sale_destination" "VehicleSaleDestination" NOT NULL DEFAULT 'home';
