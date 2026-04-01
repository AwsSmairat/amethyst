import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const BCRYPT_ROUNDS = 12;

async function hash(pw) {
  return bcrypt.hash(pw, BCRYPT_ROUNDS);
}

/** يزيل السيارة V-002 والسائق الثاني من قواعد بيانات قديمة بعد تغيير الـ seed. */
async function removeSecondVehicleAndDriver() {
  const driver2 = await prisma.user.findUnique({
    where: { email: 'driver2@amethyst.local' },
  });
  const v2 = await prisma.vehicle.findUnique({
    where: { vehicleNumber: 'V-002' },
  });

  if (v2) {
    await prisma.vehicleLoad.deleteMany({ where: { vehicleId: v2.id } });
    await prisma.vehicleSale.deleteMany({ where: { vehicleId: v2.id } });
    await prisma.expense.deleteMany({ where: { vehicleId: v2.id } });
    await prisma.vehicle.delete({ where: { id: v2.id } });
  }

  if (driver2) {
    await prisma.vehicleLoad.deleteMany({
      where: {
        OR: [{ driverId: driver2.id }, { createdById: driver2.id }],
      },
    });
    await prisma.vehicleSale.deleteMany({ where: { driverId: driver2.id } });
    await prisma.stationSale.deleteMany({ where: { soldById: driver2.id } });
    await prisma.expense.deleteMany({ where: { driverId: driver2.id } });
    await prisma.auditLog.deleteMany({ where: { userId: driver2.id } });
    await prisma.vehicle.updateMany({
      where: { driverId: driver2.id },
      data: { driverId: null },
    });
    await prisma.user.delete({ where: { id: driver2.id } });
  }
}

async function main() {
  await removeSecondVehicleAndDriver();

  const passwordSuper = await hash('sohaib123');
  const passwordAdmin = await hash('Admin123!');
  const passwordDriver = await hash('Driver123!');

  await prisma.user.deleteMany({ where: { email: 'super@amethyst.local' } });

  const superAdmin = await prisma.user.upsert({
    where: { email: 'sohaib@amethyst.local' },
    update: {
      fullName: 'Sohaib',
      passwordHash: passwordSuper,
      role: 'super_admin',
      isActive: true,
    },
    create: {
      fullName: 'Sohaib',
      phone: '+10000000001',
      email: 'sohaib@amethyst.local',
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

  console.log('Seed complete:', {
    superAdmin: superAdmin.email,
    admin: admin.email,
    drivers: [driver1.email],
    products: [bottle.name, carton.name, gallon.name],
    vehicles: [v1.vehicleNumber],
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
