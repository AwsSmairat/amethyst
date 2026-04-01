import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { startOfDay, endOfDay } from '../utils/dateRange.js';
import { mapProduct } from '../utils/serialize.js';

const LOW_STOCK_THRESHOLD = 50;

async function sumStationSales(from, to) {
  const rows = await prisma.stationSale.findMany({
    where: { createdAt: { gte: from, lte: to } },
  });
  return rows.reduce((a, r) => a + Number(r.totalAmount), 0);
}

async function sumVehicleSales(from, to) {
  const rows = await prisma.vehicleSale.findMany({
    where: { createdAt: { gte: from, lte: to } },
  });
  return rows.reduce((a, r) => a + Number(r.totalAmount), 0);
}

async function sumExpenses(from, to) {
  const rows = await prisma.expense.findMany({
    where: { createdAt: { gte: from, lte: to } },
  });
  return rows.reduce((a, r) => a + Number(r.amount), 0);
}

/** Units still at the station + units still on vehicles (open loads). */
async function remainingStockSnapshot() {
  const stockAgg = await prisma.product.aggregate({
    _sum: { stationStock: true },
  });
  const openLoads = await prisma.vehicleLoad.findMany({
    where: { status: 'open' },
    select: {
      quantityLoaded: true,
      quantitySold: true,
      quantityReturned: true,
    },
  });
  const remainingOnVehicles = openLoads.reduce((acc, l) => {
    const rem =
      l.quantityLoaded - l.quantitySold - l.quantityReturned;
    return acc + (rem > 0 ? rem : 0);
  }, 0);
  return {
    remainingStationStock: stockAgg._sum.stationStock ?? 0,
    remainingOnVehicles,
  };
}

export async function superAdminDashboard() {
  const now = new Date();
  const dayStart = startOfDay(now);
  const dayEnd = endOfDay(now);
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(
    now.getFullYear(),
    now.getMonth() + 1,
    0,
    23,
    59,
    59,
    999
  );

  const [
    totalUsers,
    totalAdmins,
    totalDrivers,
    totalVehicles,
    stationToday,
    vehicleToday,
    expensesToday,
    monthlyStation,
    monthlyVehicle,
    monthlyExpenses,
    lowStock,
    recentAudit,
    stockSnapshot,
  ] = await Promise.all([
    prisma.user.count(),
    prisma.user.count({ where: { role: 'admin' } }),
    prisma.user.count({ where: { role: 'driver' } }),
    prisma.vehicle.count(),
    sumStationSales(dayStart, dayEnd),
    sumVehicleSales(dayStart, dayEnd),
    sumExpenses(dayStart, dayEnd),
    sumStationSales(monthStart, monthEnd),
    sumVehicleSales(monthStart, monthEnd),
    sumExpenses(monthStart, monthEnd),
    prisma.product.findMany({
      where: { stationStock: { lt: LOW_STOCK_THRESHOLD }, isActive: true },
      orderBy: { stationStock: 'asc' },
      take: 10,
    }),
    prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: 15,
      include: {
        user: { select: { id: true, fullName: true, role: true } },
      },
    }),
    remainingStockSnapshot(),
  ]);

  const totalMonthlySales = monthlyStation + monthlyVehicle;
  const totalProfitToday = stationToday + vehicleToday - expensesToday;
  const totalSalesToday = stationToday + vehicleToday;

  return {
    totalUsers,
    totalAdmins,
    totalDrivers,
    totalVehicles,
    totalSalesToday,
    stationSalesToday: stationToday,
    vehicleSalesToday: vehicleToday,
    totalExpensesToday: expensesToday,
    totalMonthlyExpenses: monthlyExpenses,
    totalProfitToday,
    totalMonthlySales,
    remainingStationStock: stockSnapshot.remainingStationStock,
    remainingOnVehicles: stockSnapshot.remainingOnVehicles,
    lowStockProducts: lowStock.map(mapProduct),
    recentActivities: recentAudit,
  };
}

export async function adminDashboard() {
  const now = new Date();
  const dayStart = startOfDay(now);
  const dayEnd = endOfDay(now);
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(
    now.getFullYear(),
    now.getMonth() + 1,
    0,
    23,
    59,
    59,
    999
  );

  const products = await prisma.product.findMany({
    where: { isActive: true },
    orderBy: { name: 'asc' },
  });

  const loadsToday = await prisma.vehicleLoad.findMany({
    where: {
      loadDate: {
        gte: dayStart,
        lte: dayEnd,
      },
    },
    include: { vehicle: true },
  });

  const stationToday = await sumStationSales(dayStart, dayEnd);
  const vehicleToday = await sumVehicleSales(dayStart, dayEnd);

  const returnsTodayAgg = await prisma.vehicleLoad.aggregate({
    where: {
      updatedAt: { gte: dayStart, lte: dayEnd },
    },
    _sum: { quantityReturned: true },
  });

  const activeDrivers = await prisma.user.count({
    where: { role: 'driver', isActive: true },
  });

  const lowStock = await prisma.product.findMany({
    where: { stationStock: { lt: LOW_STOCK_THRESHOLD }, isActive: true },
    take: 10,
    orderBy: { stationStock: 'asc' },
  });

  const stockSnapshot = await remainingStockSnapshot();

  const monthlyStation = await sumStationSales(monthStart, monthEnd);
  const monthlyVehicle = await sumVehicleSales(monthStart, monthEnd);
  const totalMonthlySales = monthlyStation + monthlyVehicle;

  return {
    stationStockSummary: products.map(mapProduct),
    vehiclesLoadedToday: loadsToday.length,
    loadsToday: loadsToday.slice(0, 20),
    totalSalesToday: stationToday + vehicleToday,
    stationSalesToday: stationToday,
    vehicleSalesToday: vehicleToday,
    totalMonthlySales,
    returnedQuantitiesToday: returnsTodayAgg._sum.quantityReturned ?? 0,
    activeDrivers,
    remainingStationStock: stockSnapshot.remainingStationStock,
    remainingOnVehicles: stockSnapshot.remainingOnVehicles,
    lowStockProducts: lowStock.map(mapProduct),
  };
}

export async function driverDashboard(actor) {
  if (actor.role !== 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }

  const now = new Date();
  const dayStart = startOfDay(now);
  const dayEnd = endOfDay(now);

  const vehicle = await prisma.vehicle.findFirst({
    where: { driverId: actor.id, isActive: true },
  });

  if (!vehicle) {
    return {
      assignedVehicle: null,
      productsLoadedToday: [],
      soldQuantitiesToday: 0,
      vehicleSalesAmountToday: 0,
      remainingQuantities: [],
      remainingOnVehicle: 0,
      returnedQuantitiesToday: 0,
      totalExpensesToday: 0,
      notesSummary: [],
    };
  }

  const loadsToday = await prisma.vehicleLoad.findMany({
    where: {
      vehicleId: vehicle.id,
      driverId: actor.id,
      loadDate: { gte: dayStart, lte: dayEnd },
    },
    include: { product: true },
  });

  const vehicleSalesToday = await prisma.vehicleSale.findMany({
    where: {
      driverId: actor.id,
      createdAt: { gte: dayStart, lte: dayEnd },
    },
    include: { product: true },
  });

  const soldQty = vehicleSalesToday.reduce((a, s) => a + s.quantity, 0);
  const vehicleSalesAmountToday = vehicleSalesToday.reduce(
    (a, s) => a + Number(s.totalAmount),
    0
  );

  const remainingQuantities = loadsToday.map((l) => ({
    productId: l.productId,
    productName: l.product.name,
    remaining:
      l.quantityLoaded - l.quantitySold - l.quantityReturned,
    quantityReturned: l.quantityReturned,
    quantitySold: l.quantitySold,
  }));

  const returnedToday = loadsToday.reduce((a, l) => a + l.quantityReturned, 0);

  const expensesToday = await prisma.expense.findMany({
    where: {
      driverId: actor.id,
      createdAt: { gte: dayStart, lte: dayEnd },
    },
  });
  const totalExpensesToday = expensesToday.reduce(
    (a, e) => a + Number(e.amount),
    0
  );

  const notesSummary = expensesToday
    .filter((e) => e.note)
    .map((e) => ({ note: e.note, at: e.createdAt }));

  const vehicleRemainingUnits = remainingQuantities.reduce(
    (a, r) => a + (r.remaining > 0 ? r.remaining : 0),
    0
  );

  return {
    assignedVehicle: vehicle,
    productsLoadedToday: loadsToday,
    soldQuantitiesToday: soldQty,
    vehicleSalesAmountToday,
    remainingQuantities,
    remainingOnVehicle: vehicleRemainingUnits,
    returnedQuantitiesToday: returnedToday,
    totalExpensesToday,
    notesSummary,
  };
}
