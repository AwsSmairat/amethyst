import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';

export async function listVehicles(query, actor) {
  const { page, limit, skip } = parsePagination(query);
  const { sortBy, order } = parseSort(query, ['createdAt', 'vehicleNumber'], 'createdAt');

  const where = {};
  if (actor.role === 'driver') {
    where.driverId = actor.id;
  }

  const [total, items] = await prisma.$transaction([
    prisma.vehicle.count({ where }),
    prisma.vehicle.findMany({
      where,
      include: {
        driver: {
          select: { id: true, fullName: true, phone: true, email: true },
        },
      },
      orderBy: { [sortBy]: order },
      skip,
      take: limit,
    }),
  ]);

  return { items, total, page, limit };
}

export async function getVehicleById(id, actor) {
  const vehicle = await prisma.vehicle.findUnique({
    where: { id },
    include: {
      driver: {
        select: { id: true, fullName: true, phone: true, email: true },
      },
    },
  });
  if (!vehicle) throw new AppError('Vehicle not found', 404, 'NOT_FOUND');
  if (actor.role === 'driver' && vehicle.driverId !== actor.id) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  return vehicle;
}

export async function createVehicle(body, actor) {
  if (body.driverId) {
    const driver = await prisma.user.findUnique({
      where: { id: body.driverId },
    });
    if (!driver || driver.role !== 'driver') {
      throw new AppError('Invalid driver', 400, 'VALIDATION_ERROR');
    }
  }
  const vehicle = await prisma.vehicle.create({
    data: {
      vehicleNumber: body.vehicleNumber,
      driverId: body.driverId ?? null,
      notes: body.notes ?? null,
      isActive: body.isActive ?? true,
    },
    include: {
      driver: {
        select: { id: true, fullName: true, phone: true, email: true },
      },
    },
  });
  await auditLog({
    userId: actor.id,
    action: 'VEHICLE_CREATE',
    entityType: 'Vehicle',
    entityId: vehicle.id,
  });
  return vehicle;
}

export async function updateVehicle(id, body, actor) {
  const existing = await prisma.vehicle.findUnique({ where: { id } });
  if (!existing) throw new AppError('Vehicle not found', 404, 'NOT_FOUND');

  const vehicle = await prisma.vehicle.update({
    where: { id },
    data: {
      ...(body.vehicleNumber !== undefined && { vehicleNumber: body.vehicleNumber }),
      ...(body.notes !== undefined && { notes: body.notes }),
      ...(body.isActive !== undefined && { isActive: body.isActive }),
    },
    include: {
      driver: {
        select: { id: true, fullName: true, phone: true, email: true },
      },
    },
  });
  await auditLog({
    userId: actor.id,
    action: 'VEHICLE_UPDATE',
    entityType: 'Vehicle',
    entityId: id,
  });
  return vehicle;
}

export async function deleteVehicle(id, actor) {
  await prisma.vehicle.delete({ where: { id } }).catch(() => {
    throw new AppError('Vehicle not found', 404, 'NOT_FOUND');
  });
  await auditLog({
    userId: actor.id,
    action: 'VEHICLE_DELETE',
    entityType: 'Vehicle',
    entityId: id,
  });
  return { deleted: true };
}

export async function assignDriver(id, driverId, actor) {
  if (driverId) {
    const driver = await prisma.user.findUnique({ where: { id: driverId } });
    if (!driver || driver.role !== 'driver') {
      throw new AppError('Invalid driver', 400, 'VALIDATION_ERROR');
    }
  }
  const vehicle = await prisma.vehicle.update({
    where: { id },
    data: { driverId },
    include: {
      driver: {
        select: { id: true, fullName: true, phone: true, email: true },
      },
    },
  });
  await auditLog({
    userId: actor.id,
    action: 'VEHICLE_ASSIGN_DRIVER',
    entityType: 'Vehicle',
    entityId: id,
    details: { driverId },
  });
  return vehicle;
}
