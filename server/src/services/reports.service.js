import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { startOfDay, endOfDay } from '../utils/dateRange.js';
import { mapProduct } from '../utils/serialize.js';

function requireStaff(actor) {
  if (actor.role === 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
}

export async function salesDaily(query, actor) {
  requireStaff(actor);
  const day = query.date ? new Date(query.date) : new Date();
  const from = startOfDay(day);
  const to = endOfDay(day);

  const [station, vehicle] = await Promise.all([
    prisma.stationSale.findMany({
      where: { createdAt: { gte: from, lte: to } },
      include: { product: true, soldBy: { select: { fullName: true } } },
    }),
    prisma.vehicleSale.findMany({
      where: { createdAt: { gte: from, lte: to } },
      include: {
        product: true,
        vehicle: true,
        driver: { select: { fullName: true } },
      },
    }),
  ]);

  const stationTotal = station.reduce((a, s) => a + Number(s.totalAmount), 0);
  const vehicleTotal = vehicle.reduce((a, s) => a + Number(s.totalAmount), 0);

  return {
    date: from.toISOString().slice(0, 10),
    stationSales: station,
    vehicleSales: vehicle,
    totals: {
      stationAmount: stationTotal,
      vehicleAmount: vehicleTotal,
      combined: stationTotal + vehicleTotal,
    },
  };
}

export async function salesMonthly(query, actor) {
  requireStaff(actor);
  const year = query.year ? Number(query.year) : new Date().getFullYear();
  const month = query.month ? Number(query.month) : new Date().getMonth() + 1;
  const from = new Date(Date.UTC(year, month - 1, 1));
  const to = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));

  const [station, vehicle] = await Promise.all([
    prisma.stationSale.findMany({
      where: { createdAt: { gte: from, lte: to } },
      include: { product: true },
    }),
    prisma.vehicleSale.findMany({
      where: { createdAt: { gte: from, lte: to } },
      include: { product: true, vehicle: true },
    }),
  ]);

  return {
    year,
    month,
    stationSales: station,
    vehicleSales: vehicle,
    totals: {
      stationAmount: station.reduce((a, s) => a + Number(s.totalAmount), 0),
      vehicleAmount: vehicle.reduce((a, s) => a + Number(s.totalAmount), 0),
    },
  };
}

/** Calendar days that have at least one station or vehicle sale (days with sales activity). */
export async function salesWorkingDays(actor) {
  requireStaff(actor);
  const rows = await prisma.$queryRaw`
    SELECT COALESCE(s.day, v.day)::text AS work_date,
           (COALESCE(s.sum_station, 0) + COALESCE(v.sum_vehicle, 0))::float AS combined
    FROM (
      SELECT DATE(created_at) AS day, SUM(total_amount) AS sum_station
      FROM station_sales
      GROUP BY DATE(created_at)
    ) s
    FULL OUTER JOIN (
      SELECT DATE(created_at) AS day, SUM(total_amount) AS sum_vehicle
      FROM vehicle_sales
      GROUP BY DATE(created_at)
    ) v ON s.day = v.day
    ORDER BY COALESCE(s.day, v.day) DESC
  `;
  return {
    days: rows.map((r) => ({
      date: r.work_date,
      combined: Number(r.combined),
    })),
  };
}

export async function vehiclesReport(query, actor) {
  requireStaff(actor);
  const vehicles = await prisma.vehicle.findMany({
    include: {
      driver: { select: { id: true, fullName: true, phone: true } },
    },
  });

  const from = query.dateFrom
    ? startOfDay(new Date(query.dateFrom))
    : startOfDay(new Date());
  const to = query.dateTo ? endOfDay(new Date(query.dateTo)) : endOfDay(new Date());

  const sales = await prisma.vehicleSale.groupBy({
    by: ['vehicleId'],
    where: {
      createdAt: { gte: from, lte: to },
    },
    _sum: { totalAmount: true, quantity: true },
  });

  const map = new Map(sales.map((s) => [s.vehicleId, s]));

  return vehicles.map((v) => ({
    vehicle: v,
    periodSalesAmount: Number(map.get(v.id)?._sum.totalAmount ?? 0),
    periodQuantitySold: map.get(v.id)?._sum.quantity ?? 0,
  }));
}

export async function driversReport(query, actor) {
  requireStaff(actor);
  const drivers = await prisma.user.findMany({
    where: { role: 'driver' },
    select: { id: true, fullName: true, phone: true, isActive: true },
  });

  const from = query.dateFrom
    ? startOfDay(new Date(query.dateFrom))
    : startOfDay(new Date());
  const to = query.dateTo ? endOfDay(new Date(query.dateTo)) : endOfDay(new Date());

  const sales = await prisma.vehicleSale.groupBy({
    by: ['driverId'],
    where: { createdAt: { gte: from, lte: to } },
    _sum: { totalAmount: true, quantity: true },
  });

  const exp = await prisma.expense.groupBy({
    by: ['driverId'],
    where: { createdAt: { gte: from, lte: to } },
    _sum: { amount: true },
  });

  const saleMap = new Map(sales.map((s) => [s.driverId, s]));
  const expMap = new Map(exp.map((e) => [e.driverId, e]));

  return drivers.map((d) => ({
    driver: d,
    vehicleSalesAmount: Number(saleMap.get(d.id)?._sum.totalAmount ?? 0),
    quantitySold: saleMap.get(d.id)?._sum.quantity ?? 0,
    expensesAmount: Number(expMap.get(d.id)?._sum.amount ?? 0),
  }));
}

export async function inventoryReport(actor) {
  requireStaff(actor);
  const products = await prisma.product.findMany({ orderBy: { name: 'asc' } });
  const loads = await prisma.vehicleLoad.findMany({
    where: { status: 'open' },
    include: { product: true, vehicle: true },
  });

  const onVehicles = loads.reduce((acc, l) => {
    const rem = l.quantityLoaded - l.quantitySold - l.quantityReturned;
    return acc + (rem > 0 ? rem : 0);
  }, 0);

  return {
    stationProducts: products.map(mapProduct),
    openLoadLines: loads.length,
    estimatedUnitsOnVehicles: onVehicles,
  };
}

export async function expensesReport(query, actor) {
  requireStaff(actor);
  const from = query.dateFrom
    ? startOfDay(new Date(query.dateFrom))
    : startOfDay(new Date());
  const to = query.dateTo ? endOfDay(new Date(query.dateTo)) : endOfDay(new Date());

  const items = await prisma.expense.findMany({
    where: { createdAt: { gte: from, lte: to } },
    include: {
      driver: { select: { fullName: true } },
      vehicle: true,
    },
    orderBy: { createdAt: 'desc' },
  });

  const total = items.reduce((a, e) => a + Number(e.amount), 0);

  return { from, to, total, items };
}

export async function profitLossReport(query, actor) {
  requireStaff(actor);
  const from = query.dateFrom
    ? startOfDay(new Date(query.dateFrom))
    : startOfDay(new Date());
  const to = query.dateTo ? endOfDay(new Date(query.dateTo)) : endOfDay(new Date());

  const [stationSales, vehicleSales, expenses] = await Promise.all([
    prisma.stationSale.findMany({
      where: { createdAt: { gte: from, lte: to } },
    }),
    prisma.vehicleSale.findMany({
      where: { createdAt: { gte: from, lte: to } },
    }),
    prisma.expense.findMany({
      where: { createdAt: { gte: from, lte: to } },
    }),
  ]);

  const revenue =
    stationSales.reduce((a, s) => a + Number(s.totalAmount), 0) +
    vehicleSales.reduce((a, s) => a + Number(s.totalAmount), 0);
  const expenseTotal = expenses.reduce((a, e) => a + Number(e.amount), 0);

  return {
    from,
    to,
    revenue,
    expenses: expenseTotal,
    net: revenue - expenseTotal,
  };
}
