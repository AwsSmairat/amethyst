import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';
import { env } from '../config/env.js';
import {
  businessDayUtcRange,
  parseDateRange,
  startOfDay,
  endOfDay,
} from '../utils/dateRange.js';
import { stationStockReservedOnVehicleLoad } from '../utils/vehicleStockPolicy.js';

function remainingOnLoad(load) {
  return (
    load.quantityLoaded - load.quantitySold - load.quantityReturned
  );
}

/**
 * الكراتين ودفاتر الكوبون: عند التحميل يُحجَز من `station_stock` (يُنقص) لصالح السيارة.
 * عند البيع من السيارة لا يُعاد خصم المحطة — يُستهلك من سطر التحميل فقط (`vehicleSale.service.js`).
 */

export async function listVehicleLoads(query, actor) {
  const { page, limit, skip } = parsePagination(query);
  const { sortBy, order } = parseSort(
    query,
    ['createdAt', 'loadDate'],
    'createdAt'
  );

  const where = {};
  if (actor.role === 'driver') {
    if (query.driverId && query.driverId !== actor.id) {
      throw new AppError('Forbidden', 403, 'FORBIDDEN');
    }
    where.driverId = actor.id;
  } else if (query.driverId) {
    where.driverId = query.driverId;
  }
  if (query.vehicleId) where.vehicleId = query.vehicleId;
  if (query.productId) where.productId = query.productId;
  if (query.status) where.status = query.status;

  const { dateFrom, dateTo } = parseDateRange(query);
  if (dateFrom || dateTo) {
    where.loadDate = {};
    if (dateFrom) where.loadDate.gte = startOfDay(dateFrom);
    if (dateTo) where.loadDate.lte = endOfDay(dateTo);
  }

  const [total, items] = await prisma.$transaction([
    prisma.vehicleLoad.count({ where }),
    prisma.vehicleLoad.findMany({
      where,
      include: {
        vehicle: true,
        driver: {
          select: { id: true, fullName: true, phone: true },
        },
        product: true,
        createdBy: {
          select: { id: true, fullName: true },
        },
      },
      orderBy: { [sortBy]: order },
      skip,
      take: limit,
    }),
  ]);

  return { items, total, page, limit };
}

export async function getVehicleLoadById(id, actor) {
  const load = await prisma.vehicleLoad.findUnique({
    where: { id },
    include: {
      vehicle: true,
      driver: {
        select: { id: true, fullName: true, phone: true },
      },
      product: true,
      createdBy: { select: { id: true, fullName: true } },
    },
  });
  if (!load) throw new AppError('Vehicle load not found', 404, 'NOT_FOUND');
  if (actor.role === 'driver' && load.driverId !== actor.id) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  return load;
}

export async function createVehicleLoad(body, actor) {
  const loadDate = new Date(body.loadDate + 'T00:00:00.000Z');

  return prisma.$transaction(async (tx) => {
    const vehicle = await tx.vehicle.findUnique({
      where: { id: body.vehicleId },
    });
    if (!vehicle) throw new AppError('Vehicle not found', 404, 'NOT_FOUND');
    if (vehicle.driverId !== body.driverId) {
      throw new AppError('Driver is not assigned to this vehicle', 400, 'VALIDATION_ERROR');
    }

    const product = await tx.product.findUnique({
      where: { id: body.productId },
    });
    if (!product || !product.isActive) {
      throw new AppError('Product not found or inactive', 404, 'NOT_FOUND');
    }

    const load = await tx.vehicleLoad.create({
      data: {
        vehicleId: body.vehicleId,
        driverId: body.driverId,
        productId: body.productId,
        quantityLoaded: body.quantityLoaded,
        loadDate,
        status: 'open',
        createdById: actor.id,
      },
      include: {
        vehicle: true,
        driver: { select: { id: true, fullName: true, phone: true } },
        product: true,
        createdBy: { select: { id: true, fullName: true } },
      },
    });

    if (stationStockReservedOnVehicleLoad(product)) {
      const reserved = await tx.product.updateMany({
        where: {
          id: product.id,
          stationStock: { gte: body.quantityLoaded },
        },
        data: { stationStock: { decrement: body.quantityLoaded } },
      });
      if (reserved.count !== 1) {
        throw new AppError(
          'Insufficient station stock to load this quantity',
          400,
          'INSUFFICIENT_STOCK'
        );
      }
    }

    await auditLog({
      userId: actor.id,
      action: 'VEHICLE_LOAD_CREATE',
      entityType: 'VehicleLoad',
      entityId: load.id,
      details: {
        quantityLoaded: body.quantityLoaded,
        productId: body.productId,
      },
    });

    return load;
  });
}

export async function updateVehicleLoad(id, body, actor) {
  const existing = await prisma.vehicleLoad.findUnique({
    where: { id },
    include: { product: true },
  });
  if (!existing) throw new AppError('Vehicle load not found', 404, 'NOT_FOUND');
  if (existing.status === 'closed') {
    throw new AppError('Cannot update a closed load', 400, 'VALIDATION_ERROR');
  }

  return prisma.$transaction(async (tx) => {
    if (body.quantityLoaded !== undefined && body.quantityLoaded !== existing.quantityLoaded) {
      const newLoaded = body.quantityLoaded;
      const committed =
        existing.quantitySold + existing.quantityReturned;
      if (newLoaded < committed) {
        throw new AppError(
          'quantityLoaded cannot be less than sold + returned quantities',
          400,
          'VALIDATION_ERROR'
        );
      }
    }

    const loadDate =
      body.loadDate !== undefined
        ? new Date(body.loadDate + 'T00:00:00.000Z')
        : undefined;

    if (
      existing.product &&
      stationStockReservedOnVehicleLoad(existing.product) &&
      body.quantityLoaded !== undefined &&
      body.quantityLoaded !== existing.quantityLoaded
    ) {
      const delta = body.quantityLoaded - existing.quantityLoaded;
      if (delta > 0) {
        const ok = await tx.product.updateMany({
          where: {
            id: existing.productId,
            stationStock: { gte: delta },
          },
          data: { stationStock: { decrement: delta } },
        });
        if (ok.count !== 1) {
          throw new AppError(
            'Insufficient station stock to increase loaded quantity',
            400,
            'INSUFFICIENT_STOCK'
          );
        }
      } else if (delta < 0) {
        await tx.product.update({
          where: { id: existing.productId },
          data: { stationStock: { increment: -delta } },
        });
      }
    }

    const load = await tx.vehicleLoad.update({
      where: { id },
      data: {
        ...(body.quantityLoaded !== undefined && {
          quantityLoaded: body.quantityLoaded,
        }),
        ...(loadDate !== undefined && { loadDate }),
      },
      include: {
        vehicle: true,
        driver: { select: { id: true, fullName: true, phone: true } },
        product: true,
        createdBy: { select: { id: true, fullName: true } },
      },
    });

    await auditLog({
      userId: actor.id,
      action: 'VEHICLE_LOAD_UPDATE',
      entityType: 'VehicleLoad',
      entityId: id,
    });

    return load;
  });
}

export async function closeVehicleLoad(id, actor) {
  const load = await prisma.vehicleLoad.update({
    where: { id },
    data: { status: 'closed' },
    include: {
      vehicle: true,
      driver: { select: { id: true, fullName: true, phone: true } },
      product: true,
    },
  });
  await auditLog({
    userId: actor.id,
    action: 'VEHICLE_LOAD_CLOSE',
    entityType: 'VehicleLoad',
    entityId: id,
  });
  return load;
}

/** Open loads for the driver's assigned vehicle for the current calendar day only. */
export async function getDriverCurrentLoads(actor) {
  if (actor.role !== 'driver') {
    throw new AppError('Drivers only', 403, 'FORBIDDEN');
  }
  const vehicle = await prisma.vehicle.findFirst({
    where: { driverId: actor.id, isActive: true },
  });
  if (!vehicle) {
    return { vehicle: null, loads: [] };
  }

  const now = new Date();
  const { start: dayStart, end: dayEnd } = businessDayUtcRange(
    now,
    env.businessTimeZone
  );

  const loads = await prisma.vehicleLoad.findMany({
    where: {
      vehicleId: vehicle.id,
      driverId: actor.id,
      status: 'open',
      loadDate: {
        gte: dayStart,
        lte: dayEnd,
      },
    },
    include: { product: true },
    orderBy: { createdAt: 'asc' },
  });

  return {
    vehicle,
    loads: loads.map((l) => ({
      ...l,
      remaining: remainingOnLoad(l),
    })),
  };
}
