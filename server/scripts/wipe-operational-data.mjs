/**
 * Amethyst — wipe operational tables; keep `users` and Prisma migration history.
 *
 * Safety: set CONFIRM_WIPE=YES (otherwise exits).
 * Loads server/.env for DATABASE_URL via Prisma.
 *
 * Keep TRUNCATE list in sync with: scripts/wipe-operational-data.sql
 */
import { config } from 'dotenv';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PrismaClient } from '@prisma/client';

const __dirname = dirname(fileURLToPath(import.meta.url));
config({ path: resolve(__dirname, '../.env') });

const TRUNCATE_SQL = `
TRUNCATE TABLE
  "audit_logs",
  "expenses",
  "vehicle_sales",
  "station_debt_entries",
  "station_sales",
  "vehicle_loads",
  "vehicles",
  "products"
RESTART IDENTITY CASCADE;
`;

async function main() {
  if (process.env.CONFIRM_WIPE !== 'YES') {
    console.error(
      'Refusing to run: set CONFIRM_WIPE=YES to truncate operational tables (users are never touched).',
    );
    process.exit(1);
  }

  const prisma = new PrismaClient();
  try {
    await prisma.$transaction(async (tx) => {
      await tx.$executeRawUnsafe(TRUNCATE_SQL);
    });
    console.log('OK: operational tables truncated; users and _prisma_migrations unchanged.');
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
