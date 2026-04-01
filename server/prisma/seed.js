import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const BCRYPT_ROUNDS = 12;

async function hash(pw) {
  return bcrypt.hash(pw, BCRYPT_ROUNDS);
}

async function main() {
  const passwordSuper = await hash('SuperAdmin123!');
  const passwordAdmin = await hash('Admin123!');
  const passwordDriver = await hash('Driver123!');

  const superAdmin = await prisma.user.upsert({
    where: { email: 'super@amethyst.local' },
    update: {},
    create: {
      fullName: 'Super Admin',
      phone: '+10000000001',
      email: 'super@amethyst.local',
      passwordHash: passwordSuper,
      role: 'super_admin',
      isActive: true,
    },
  });

  const admin = await prisma.user.upsert({
    where: { email: 'admin@amethyst.local' },
    update: {},
    create: {
      fullName: 'Station Admin',
      phone: '+10000000002',
      email: 'admin@amethyst.local',
      passwordHash: passwordAdmin,
      role: 'admin',
      isActive: true,
    },
  });

  const driver1 = await prisma.user.upsert({
    where: { email: 'driver1@amethyst.local' },
    update: {},
    create: {
      fullName: 'Driver One',
      phone: '+10000000003',
      email: 'driver1@amethyst.local',
      passwordHash: passwordDriver,
      role: 'driver',
      isActive: true,
    },
  });

  const driver2 = await prisma.user.upsert({
    where: { email: 'driver2@amethyst.local' },
    update: {},
    create: {
      fullName: 'Driver Two',
      phone: '+10000000004',
      email: 'driver2@amethyst.local',
      passwordHash: passwordDriver,
      role: 'driver',
      isActive: true,
    },
  });

  async function ensureProduct(data) {
    const existing = await prisma.product.findFirst({
      where: { name: data.name },
    });
    if (existing) return existing;
    return prisma.product.create({ data });
  }

  const bottle = await ensureProduct({
    name: 'Water Bottle',
    unitType: 'bottle',
    price: 1.5,
    stationStock: 500,
    isActive: true,
  });

  const carton = await ensureProduct({
    name: 'Water Carton',
    unitType: 'carton',
    price: 8.0,
    stationStock: 120,
    isActive: true,
  });

  const gallon = await ensureProduct({
    name: 'Water Gallon',
    unitType: 'gallon',
    price: 3.25,
    stationStock: 80,
    isActive: true,
  });

  const v1 = await prisma.vehicle.upsert({
    where: { vehicleNumber: 'V-001' },
    update: { driverId: driver1.id },
    create: {
      vehicleNumber: 'V-001',
      driverId: driver1.id,
      notes: 'Downtown route',
      isActive: true,
    },
  });

  const v2 = await prisma.vehicle.upsert({
    where: { vehicleNumber: 'V-002' },
    update: { driverId: driver2.id },
    create: {
      vehicleNumber: 'V-002',
      driverId: driver2.id,
      notes: 'Suburbs route',
      isActive: true,
    },
  });

  console.log('Seed complete:', {
    superAdmin: superAdmin.email,
    admin: admin.email,
    drivers: [driver1.email, driver2.email],
    products: [bottle.name, carton.name, gallon.name],
    vehicles: [v1.vehicleNumber, v2.vehicleNumber],
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
