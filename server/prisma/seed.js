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

  await ensureAllAmethystProducts();

  console.log('[seed] done (password for all test users: 123456)');
}

/**
 * كل المنتجات التي يتوقعها تطبيق Flutter (رصيد المحطة، بيع المحطة، بيع/تحميل المركبة).
 * الأسماء الإنجليزية مطابقة لـ `StationBalanceProductLookup` و`StationSaleApiProductNames`.
 * عند البيع يخصم الخادم `stationStock` تلقائياً طالما الـ productId صحيح.
 */
async function ensureAllAmethystProducts() {
  const specs = [
    // صفوف رصيد المحطة 0–10 (ك مهدي … ج ارضية)
    { name: 'Water Carton', unitType: 'carton' },
    { name: 'Carton Yafa', unitType: 'carton' },
    { name: 'Shanta Large', unitType: 'carton' },
    { name: 'Shanta Medium', unitType: 'carton' },
    { name: 'Shanta Small', unitType: 'carton' },
    { name: 'Saudi Bottle', unitType: 'bottle' },
    { name: 'Jordanian Bottle', unitType: 'bottle' },
    { name: 'Empty Gallon', unitType: 'gallon' },
    { name: 'Bottle 10 Liter', unitType: 'bottle' },
    { name: 'Ground Bottle', unitType: 'bottle' },
    { name: 'Ground Gallon', unitType: 'gallon' },
    // كوبون ١٢ / ٢٤ / ٥٠ — بيع المحطة (تعبئة) + رصيد المحطة + تحميل
    { name: 'Coupon', unitType: 'coupon' },
    { name: 'Coupon 2', unitType: 'coupon' },
    { name: 'Coupon 3', unitType: 'coupon' },
    // تحميل المركبة + بيع «منزل» من السيارة
    { name: 'Water Gallon', unitType: 'gallon' },
    { name: 'Water Bottle', unitType: 'bottle' },
    // بيع «متجر» من المركبة (أسماء عربية)
    { name: 'جالون متجر', unitType: 'gallon' },
    { name: 'قاروره متجر', unitType: 'bottle' },
    { name: 'مهدي متجر', unitType: 'carton' },
  ];
  for (const s of specs) {
    const existing = await prisma.product.findFirst({
      where: { name: s.name },
    });
    if (existing) {
      console.log(`[seed] skip product (exists): ${s.name}`);
      continue;
    }
    await prisma.product.create({
      data: {
        name: s.name,
        unitType: s.unitType,
        price: 0,
        stationStock: 0,
        isActive: true,
      },
    });
    console.log(`[seed] created product: ${s.name}`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
