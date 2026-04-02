import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const BCRYPT_ROUNDS = 12;

async function hashPassword(plain) {
  return bcrypt.hash(plain, BCRYPT_ROUNDS);
}

/**
 * Inserts a user only if no row exists with the same email.
 * Avoids phone collisions with older seeded rows (phone is unique).
 */
async function createUserIfMissing({
  email,
  password,
  fullName,
  role,
  phone,
}) {
  const normalizedEmail = email.toLowerCase();
  const existingByEmail = await prisma.user.findUnique({
    where: { email: normalizedEmail },
  });
  if (existingByEmail) {
    console.log(`[seed] skip (exists): ${normalizedEmail}`);
    return existingByEmail;
  }

  const existingByPhone = await prisma.user.findUnique({
    where: { phone },
  });
  if (existingByPhone) {
    console.log(
      `[seed] skip (phone ${phone} already used by ${existingByPhone.email}): ${normalizedEmail}`,
    );
    return existingByPhone;
  }

  const passwordHash = await hashPassword(password);
  const user = await prisma.user.create({
    data: {
      email: normalizedEmail,
      fullName,
      phone,
      passwordHash,
      role,
      isActive: true,
    },
  });
  console.log(`[seed] created: ${normalizedEmail} (${role})`);
  return user;
}

async function main() {
  // Reserved range so we do not collide with legacy seed phones (+1000000000x).
  await createUserIfMissing({
    email: 'super@test.com',
    password: '123456',
    fullName: 'Super Admin',
    role: 'super_admin',
    phone: '+10000090001',
  });

  await createUserIfMissing({
    email: 'admin@test.com',
    password: '123456',
    fullName: 'Admin',
    role: 'admin',
    phone: '+10000090002',
  });

  await createUserIfMissing({
    email: 'driver@test.com',
    password: '123456',
    fullName: 'Driver',
    role: 'driver',
    phone: '+10000090003',
  });

  console.log('[seed] done (password for all test users: 123456)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
