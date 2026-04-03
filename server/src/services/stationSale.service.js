import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';
import { parseDateRange, startOfDay, endOfDay } from '../utils/dateRange.js';
import { mapStationSale } from '../utils/serialize.js';

/**
 * أسماء المنتجات الافتراضية لعمودي الجالون والقارورة في وضع التعبئة (مرادفة
 * `StationSaleApiProductNames.filling` في التطبيق). تُستخدم كاحتياط إذا كان
 * `unit_type` في قاعدة البيانات غير مطابق لـ gallon/bottle.
 */
const FILLING_SKIP_STATION_STOCK_BY_NAME = new Set([
  'Water Gallon',
  'Water Bottle',
]);

/** مطابقة بدون حساسية لحالة الأحرف + أسماء شائعة بالعربي إن وُجدت في قاعدة البيانات. */
const FILLING_SKIP_STATION_STOCK_BY_NAME_LOWER = new Set(
  [...FILLING_SKIP_STATION_STOCK_BY_NAME].map((n) => n.toLowerCase())
);

function isFillingSaleRequest(v) {
  if (v === true || v === 1) {
    return true;
  }
  if (typeof v === 'string') {
    const s = v.trim().toLowerCase();
    return s === 'true' || s === '1';
  }
  return false;
}

/** بعد التحقق من Zod يكون الرقم؛ احتياطاً لقيم نصية أو BigInt. */
function fillingLineSlotAsInt(body) {
  const raw = body.fillingLineSlot;
  if (raw === undefined || raw === null || raw === '') {
    return null;
  }
  const n = Number(raw);
  if (!Number.isInteger(n) || n < 0 || n > 3) {
    return null;
  }
  return n;
}

function productNameSuggestsFillingSkipStock(name) {
  if (!name || typeof name !== 'string') {
    return false;
  }
  const t = name.trim();
  if (FILLING_SKIP_STATION_STOCK_BY_NAME.has(t)) {
    return true;
  }
  const lower = t.toLowerCase();
  if (FILLING_SKIP_STATION_STOCK_BY_NAME_LOWER.has(lower)) {
    return true;
  }
  // أسماء عربية شائعة لعمودي الجالون/القارورة عندما لا يطابق الاسم الإنجليزي.
  if (t.includes('جالون')) {
    return true;
  }
  if (t.includes('قارورة') || t.includes('قاروره')) {
    return true;
  }
  return false;
}

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

    const fillingSale = isFillingSaleRequest(body.fillingSale);
    const slot = fillingLineSlotAsInt(body);
    const skipGallonBottleColumns =
      fillingSale && slot !== null && (slot === 0 || slot === 1);
    const trimmedName =
      typeof product.name === 'string' ? product.name.trim() : '';
    const nameMatchesFillingSkip =
      trimmedName.length > 0 && productNameSuggestsFillingSkipStock(trimmedName);
    const skipStationStock =
      skipGallonBottleColumns ||
      (fillingSale &&
        (product.unitType === 'gallon' ||
          product.unitType === 'bottle' ||
          nameMatchesFillingSkip));

    const qty = Number(body.quantity);
    const unitPriceNum = Number(body.unitPrice);

    if (!skipStationStock) {
      if (product.stationStock < qty) {
        throw new AppError(
          'Insufficient station stock',
          400,
          'INSUFFICIENT_STOCK'
        );
      }
      await tx.product.update({
        where: { id: body.productId },
        data: { stationStock: { decrement: qty } },
      });
    }

    const totalAmount = qty * unitPriceNum;

    const sale = await tx.stationSale.create({
      data: {
        productId: body.productId,
        quantity: qty,
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
      details: {
        quantity: body.quantity,
        totalAmount,
        ...(skipStationStock ? { skipStationStock: true } : {}),
      },
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
