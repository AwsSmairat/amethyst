import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { mapStationDebtEntry, mapStationSale } from '../utils/serialize.js';
import { shouldSkipStationStockForDebtProduct } from '../utils/stationStockSkip.js';

/**
 * تسجيل دين: لا يُنشأ StationSale ولا يُحتسب في مبيعات اليوم.
 * يُخصم مخزون المحطة إلا لمنتجات الجالون/القارورة (نفس استثناء بيع التعبئة).
 */
export async function createStationDebtEntries(body, actor) {
  const debtorName = String(body.debtorName ?? '').trim();
  if (!debtorName || debtorName.length > 200) {
    throw new AppError('Invalid debtor name', 400, 'VALIDATION');
  }
  const lines = body.lines;
  if (!Array.isArray(lines) || lines.length === 0) {
    throw new AppError('At least one line is required', 400, 'VALIDATION');
  }

  return prisma.$transaction(async (tx) => {
    const created = [];
    for (const line of lines) {
      const qty = Number(line.quantity);
      const unitPriceNum = Number(line.unitPrice);
      const productId = line.productId;
      if (!productId || typeof productId !== 'string') {
        throw new AppError('Invalid product', 400, 'VALIDATION');
      }
      if (!Number.isInteger(qty) || qty <= 0) {
        throw new AppError('Invalid quantity', 400, 'VALIDATION');
      }
      if (!Number.isFinite(unitPriceNum) || unitPriceNum < 0) {
        throw new AppError('Invalid unit price', 400, 'VALIDATION');
      }

      const product = await tx.product.findUnique({
        where: { id: productId },
      });
      if (!product || !product.isActive) {
        throw new AppError('Product not found or inactive', 404, 'NOT_FOUND');
      }

      const skipStationStock = shouldSkipStationStockForDebtProduct(product);
      if (!skipStationStock) {
        if (product.stationStock < qty) {
          throw new AppError(
            'Insufficient station stock',
            400,
            'INSUFFICIENT_STOCK'
          );
        }
        await tx.product.update({
          where: { id: productId },
          data: { stationStock: { decrement: qty } },
        });
      }

      const totalAmount = qty * unitPriceNum;

      const row = await tx.stationDebtEntry.create({
        data: {
          debtorName,
          productId,
          quantity: qty,
          unitPrice: unitPriceNum,
          totalAmount,
          recordedById: actor.id,
        },
        include: {
          product: true,
          recordedBy: { select: { id: true, fullName: true } },
        },
      });
      created.push(row);
    }

    await auditLog({
      userId: actor.id,
      action: 'STATION_DEBT_ENTRIES_CREATE',
      entityType: 'StationDebtEntry',
      entityId: created[0]?.id ?? null,
      details: {
        debtorName,
        lineCount: created.length,
      },
    });

    return { items: created.map((r) => mapStationDebtEntry(r)) };
  });
}

/**
 * سداد دين لمدين: إنشاء سجلات مبيعات محطة (بدون خصم مخزون — مُخصم سابقاً عند تسجيل الدين)
 * ليُحتسب في مبيعات اليوم والإجمالي؛ وتحديد repaidAt على السجلات.
 */
export async function repayStationDebtForDebtor(body, actor) {
  const debtorName = String(body.debtorName ?? '').trim();
  if (!debtorName || debtorName.length > 200) {
    throw new AppError('Invalid debtor name', 400, 'VALIDATION');
  }

  return prisma.$transaction(async (tx) => {
    const entries = await tx.stationDebtEntry.findMany({
      where: { debtorName, repaidAt: null },
    });
    if (entries.length === 0) {
      throw new AppError('No unpaid debt for this person', 404, 'NOT_FOUND');
    }

    const now = new Date();
    const sales = [];
    for (const entry of entries) {
      const sale = await tx.stationSale.create({
        data: {
          productId: entry.productId,
          quantity: entry.quantity,
          unitPrice: entry.unitPrice,
          totalAmount: entry.totalAmount,
          soldById: actor.id,
          note: `سداد دين — ${debtorName}`.slice(0, 500),
        },
        include: {
          product: true,
          soldBy: { select: { id: true, fullName: true } },
        },
      });
      sales.push(sale);
      await tx.stationDebtEntry.update({
        where: { id: entry.id },
        data: { repaidAt: now },
      });
    }

    await auditLog({
      userId: actor.id,
      action: 'STATION_DEBT_REPAY',
      entityType: 'StationDebtEntry',
      entityId: entries[0]?.id ?? null,
      details: {
        debtorName,
        entryCount: entries.length,
        saleCount: sales.length,
      },
    });

    return {
      debtorName,
      repaidEntryCount: entries.length,
      sales: sales.map((s) => mapStationSale(s)),
    };
  });
}

export async function listStationDebtEntries(query, actor) {
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(query.limit) || 50));
  const skip = (page - 1) * limit;

  const where = { repaidAt: null };

  const [total, items] = await prisma.$transaction([
    prisma.stationDebtEntry.count({ where }),
    prisma.stationDebtEntry.findMany({
      where,
      include: {
        product: true,
        recordedBy: { select: { id: true, fullName: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return {
    items: items.map((s) => mapStationDebtEntry(s)),
    total,
    page,
    limit,
  };
}
