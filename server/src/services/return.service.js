import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';
import { parseDateRange, startOfDay, endOfDay } from '../utils/dateRange.js';

function remainingPhysical(load) {
  return load.quantityLoaded - load.quantitySold - load.quantityReturned;
}

export async function listReturns(query, actor) {
  if (actor.role === 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  const { page, limit, skip } = parsePagination(query);
  const { sortBy, order } = parseSort(query, ['updatedAt'], 'updatedAt');

  const where = { quantityReturned: { gt: 0 } };
  if (query.vehicleId) where.vehicleId = query.vehicleId;
  if (query.driverId) where.driverId = query.driverId;
  if (query.productId) where.productId = query.productId;

  const { dateFrom, dateTo } = parseDateRange(query);
  if (dateFrom || dateTo) {
    where.updatedAt = {};
    if (dateFrom) where.updatedAt.gte = startOfDay(dateFrom);
    if (dateTo) where.updatedAt.lte = endOfDay(dateTo);
  }

  const [total, items] = await prisma.$transaction([
    prisma.vehicleLoad.count({ where }),
    prisma.vehicleLoad.findMany({
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

  return { items, total, page, limit };
}

export async function getReturnById(id, actor) {
  if (actor.role === 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  const load = await prisma.vehicleLoad.findUnique({
    where: { id },
    include: {
      vehicle: true,
      driver: { select: { id: true, fullName: true, phone: true } },
      product: true,
    },
  });
  if (!load) throw new AppError('Return record not found', 404, 'NOT_FOUND');
  return load;
}

/**
 * Record additional returned quantity for a vehicle load line.
 * Restores station stock by the returned amount.
 */
export async function recordReturn(body, actor) {
  return prisma.$transaction(async (tx) => {
    const load = await tx.vehicleLoad.findUnique({
      where: { id: body.vehicleLoadId },
      include: { product: true },
    });
    if (!load) throw new AppError('Vehicle load not found', 404, 'NOT_FOUND');

    if (actor.role === 'driver') {
      if (load.driverId !== actor.id) {
        throw new AppError('Forbidden', 403, 'FORBIDDEN');
      }
    }
    if (load.status === 'closed' && actor.role === 'driver') {
      throw new AppError('Cannot return on a closed load', 400, 'VALIDATION_ERROR');
    }

    const avail = remainingPhysical(load);
    if (body.quantityReturned > avail) {
      throw new AppError(
        'Return quantity exceeds remaining on-vehicle stock',
        400,
        'VALIDATION_ERROR'
      );
    }

    const updated = await tx.vehicleLoad.update({
      where: { id: load.id },
      data: {
        quantityReturned: { increment: body.quantityReturned },
      },
      include: {
        vehicle: true,
        driver: { select: { id: true, fullName: true, phone: true } },
        product: true,
      },
    });

    await tx.product.update({
      where: { id: load.productId },
      data: { stationStock: { increment: body.quantityReturned } },
    });

    await auditLog({
      userId: actor.id,
      action: 'RETURN_RECORD',
      entityType: 'VehicleLoad',
      entityId: load.id,
      details: { quantityReturned: body.quantityReturned },
    });

    return updated;
  });
}
