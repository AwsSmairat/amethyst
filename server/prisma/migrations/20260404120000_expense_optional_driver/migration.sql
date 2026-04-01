-- Station expenses: recorded by admin without a driver.
ALTER TABLE "expenses" ALTER COLUMN "driver_id" DROP NOT NULL;
