import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';
import { parseDateRange, startOfDay, endOfDay } from '../utils/dateRange.js';
import { mapStationSale } from '../utils/serialize.js';

export async function listStationSales(query, actor) {
  if (actor.role === 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  const { page, limit, skip } = parsePagination(query);
  const { sortBy, order } = parseSort(query, ['createdAt'], 'createdAt');

  const where = {};
  if (query.productId) where.productId = query.productId;
  const { dateFrom, dateTo } = parseDateRange(query);
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = startOfDay(dateFrom);
    if (dateTo) where.createdAt.lte = endOfDay(dateTo);
  }

  const [total, items] = await prisma.$transaction([
    prisma.stationSale.count({ where }),
    prisma.stationSale.findMany({
      where,
      include: {
        product: true,
        soldBy: { select: { id: true, fullName: true } },
      },
      orderBy: { [sortBy]: order },
      skip,
      take: limit,
    }),
  ]);

  return {
    items: items.map((s) => mapStationSale(s)),
    total,
    page,
    limit,
  };
}

export async function getStationSaleById(id, actor) {
  if (actor.role === 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  const sale = await prisma.stationSale.findUnique({
    where: { id },
    include: {
      product: true,
      soldBy: { select: { id: true, fullName: true } },
    },
  });
  if (!sale) throw new AppError('Station sale not found', 404, 'NOT_FOUND');
  return mapStationSale(sale);
}

export async function createStationSale(body, actor) {
  return prisma.$transaction(async (tx) => {
    const product = await tx.product.findUnique({
      where: { id: body.productId },
    });
    if (!product || !product.isActive) {
      throw new AppError('Product not found or inactive', 404, 'NOT_FOUND');
    }
    if (product.stationStock < body.quantity) {
      throw new AppError(
        'Insufficient station stock',
        400,
        'INSUFFICIENT_STOCK'
      );
    }

    const totalAmount = body.quantity * body.unitPrice;

    await tx.product.update({
      where: { id: body.productId },
      data: { stationStock: { decrement: body.quantity } },
    });

    const sale = await tx.stationSale.create({
      data: {
        productId: body.productId,
        quantity: body.quantity,
        unitPrice: body.unitPrice,
        totalAmount,
        soldById: actor.id,
      },
      include: {
        product: true,
        soldBy: { select: { id: true, fullName: true } },
      },
    });

    await auditLog({
      userId: actor.id,
      action: 'STATION_SALE_CREATE',
      entityType: 'StationSale',
      entityId: sale.id,
      details: { quantity: body.quantity, totalAmount },
    });

    return mapStationSale(sale);
  });
}

export async function summaryDaily(query, actor) {
  if (actor.role === 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  const day = query.date ? new Date(query.date) : new Date();
  const from = startOfDay(day);
  const to = endOfDay(day);

  const sales = await prisma.stationSale.findMany({
    where: { createdAt: { gte: from, lte: to } },
  });

  const totalAmount = sales.reduce(
    (acc, s) => acc + Number(s.totalAmount),
    0
  );
  const totalQuantity = sales.reduce((acc, s) => acc + s.quantity, 0);

  return {
    date: from.toISOString().slice(0, 10),
    count: sales.length,
    totalQuantity,
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

  const sales = await prisma.stationSale.findMany({
    where: { createdAt: { gte: from, lte: to } },
  });

  const totalAmount = sales.reduce(
    (acc, s) => acc + Number(s.totalAmount),
    0
  );
  const totalQuantity = sales.reduce((acc, s) => acc + s.quantity, 0);

  return {
    year,
    month,
    count: sales.length,
    totalQuantity,
    totalAmount,
  };
}
