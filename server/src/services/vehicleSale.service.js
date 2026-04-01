import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';
import { parseDateRange, startOfDay, endOfDay } from '../utils/dateRange.js';
import { mapVehicleSale } from '../utils/serialize.js';

function remainingOnLoad(load) {
  return load.quantityLoaded - load.quantitySold - load.quantityReturned;
}

async function allocateSale(tx, vehicleId, productId, quantity) {
  const loads = await tx.vehicleLoad.findMany({
    where: {
      vehicleId,
      productId,
      status: 'open',
    },
    orderBy: { createdAt: 'asc' },
  });

  let remaining = quantity;
  for (const load of loads) {
    const avail = remainingOnLoad(load);
    if (avail <= 0) continue;
    const take = Math.min(avail, remaining);
    await tx.vehicleLoad.update({
      where: { id: load.id },
      data: { quantitySold: { increment: take } },
    });
    remaining -= take;
    if (remaining === 0) break;
  }

  if (remaining > 0) {
    throw new AppError(
      'Insufficient loaded stock on vehicle for this product',
      400,
      'INSUFFICIENT_STOCK'
    );
  }
}

export async function listVehicleSales(query, actor) {
  const { page, limit, skip } = parsePagination(query);
  const { sortBy, order } = parseSort(query, ['createdAt'], 'createdAt');

  const where = {};
  if (actor.role === 'driver') {
    where.driverId = actor.id;
  } else {
    if (query.driverId) where.driverId = query.driverId;
  }
  if (query.vehicleId) where.vehicleId = query.vehicleId;
  if (query.productId) where.productId = query.productId;

  const { dateFrom, dateTo } = parseDateRange(query);
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = startOfDay(dateFrom);
    if (dateTo) where.createdAt.lte = endOfDay(dateTo);
  }

  const [total, items] = await prisma.$transaction([
    prisma.vehicleSale.count({ where }),
    prisma.vehicleSale.findMany({
      where,
      include: {
        vehicle: true,
        driver: { select: { id: true, fullName: true, phone: true } },
        product: true,
      },
      orderBy: { [sortBy]: order },
      skip,
      take: limit,
    }),
  ]);

  return {
    items: items.map((s) => mapVehicleSale(s)),
    total,
    page,
    limit,
  };
}

export async function getVehicleSaleById(id, actor) {
  const sale = await prisma.vehicleSale.findUnique({
    where: { id },
    include: {
      vehicle: true,
      driver: { select: { id: true, fullName: true, phone: true } },
      product: true,
    },
  });
  if (!sale) throw new AppError('Vehicle sale not found', 404, 'NOT_FOUND');
  if (actor.role === 'driver' && sale.driverId !== actor.id) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  return mapVehicleSale(sale);
}

export async function createVehicleSale(body, actor) {
  if (actor.role !== 'driver') {
    throw new AppError('Only drivers record vehicle sales', 403, 'FORBIDDEN');
  }

  const vehicle = await prisma.vehicle.findUnique({
    where: { id: body.vehicleId },
  });
  if (!vehicle || vehicle.driverId !== actor.id) {
    throw new AppError('Vehicle not assigned to you', 403, 'FORBIDDEN');
  }

  return prisma.$transaction(async (tx) => {
    const product = await tx.product.findUnique({
      where: { id: body.productId },
    });
    if (!product || !product.isActive) {
      throw new AppError('Product not found or inactive', 404, 'NOT_FOUND');
    }

    await allocateSale(tx, body.vehicleId, body.productId, body.quantity);

    const totalAmount = body.quantity * body.unitPrice;

    const sale = await tx.vehicleSale.create({
      data: {
        vehicleId: body.vehicleId,
        driverId: actor.id,
        productId: body.productId,
        quantity: body.quantity,
        unitPrice: body.unitPrice,
        totalAmount,
      },
      include: {
        vehicle: true,
        driver: { select: { id: true, fullName: true, phone: true } },
        product: true,
      },
    });

    await auditLog({
      userId: actor.id,
      action: 'VEHICLE_SALE_CREATE',
      entityType: 'VehicleSale',
      entityId: sale.id,
      details: { quantity: body.quantity, totalAmount },
    });

    return mapVehicleSale(sale);
  });
}

export async function mySales(query, actor) {
  const { page, limit, skip } = parsePagination(query);
  const where = { driverId: actor.id };
  const { dateFrom, dateTo } = parseDateRange(query);
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = startOfDay(dateFrom);
    if (dateTo) where.createdAt.lte = endOfDay(dateTo);
  }

  const [total, items] = await prisma.$transaction([
    prisma.vehicleSale.count({ where }),
    prisma.vehicleSale.findMany({
      where,
      include: { vehicle: true, product: true },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return {
    items: items.map((s) => mapVehicleSale(s)),
    total,
    page,
    limit,
  };
}

export async function summaryDaily(query, actor) {
  if (actor.role === 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  const day = query.date ? new Date(query.date) : new Date();
  const from = startOfDay(day);
  const to = endOfDay(day);

  const where = { createdAt: { gte: from, lte: to } };
  if (query.vehicleId) where.vehicleId = query.vehicleId;
  if (query.driverId) where.driverId = query.driverId;

  const sales = await prisma.vehicleSale.findMany({ where });

  const totalAmount = sales.reduce(
    (acc, s) => acc + Number(s.totalAmount),
    0
  );
  return {
    date: from.toISOString().slice(0, 10),
    count: sales.length,
    totalQuantity: sales.reduce((a, s) => a + s.quantity, 0),
    totalAmount,
  };
}

export async function summaryMonthly(query, actor) {
  if (actor.role === 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  const year = query.year ? Number(query.year) : new Date().getFullYear();
  const month = query.month ? Number(query.month) : new Date().getMonth() + 1;
  const from = new Date(Date.UTC(year, month - 1, 1));
  const to = new Date(Date.UTC(year, month, 0, 23, 59, 59, 999));

  const where = { createdAt: { gte: from, lte: to } };
  if (query.vehicleId) where.vehicleId = query.vehicleId;
  if (query.driverId) where.driverId = query.driverId;

  const sales = await prisma.vehicleSale.findMany({ where });
  const totalAmount = sales.reduce(
    (acc, s) => acc + Number(s.totalAmount),
    0
  );

  return {
    year,
    month,
    count: sales.length,
    totalQuantity: sales.reduce((a, s) => a + s.quantity, 0),
    totalAmount,
  };
}
