import { prisma } from '../utils/prisma.js';
import { AppError } from '../utils/AppError.js';
import { auditLog } from './audit.service.js';
import { parsePagination, parseSort } from '../utils/pagination.js';
import { parseDateRange, startOfDay, endOfDay } from '../utils/dateRange.js';
import { mapExpense } from '../utils/serialize.js';

export async function listExpenses(query, actor) {
  const { page, limit, skip } = parsePagination(query);
  const { sortBy, order } = parseSort(query, ['createdAt', 'amount'], 'createdAt');

  const where = {};
  if (actor.role === 'driver') {
    where.driverId = actor.id;
  } else if (query.driverId) {
    where.driverId = query.driverId;
  }
  if (query.vehicleId) where.vehicleId = query.vehicleId;

  const { dateFrom, dateTo } = parseDateRange(query);
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = startOfDay(dateFrom);
    if (dateTo) where.createdAt.lte = endOfDay(dateTo);
  }

  const [total, items] = await prisma.$transaction([
    prisma.expense.count({ where }),
    prisma.expense.findMany({
      where,
      include: {
        vehicle: true,
        driver: { select: { id: true, fullName: true, phone: true } },
      },
      orderBy: { [sortBy]: order },
      skip,
      take: limit,
    }),
  ]);

  return {
    items: items.map((e) => mapExpense(e)),
    total,
    page,
    limit,
  };
}

export async function getExpenseById(id, actor) {
  const expense = await prisma.expense.findUnique({
    where: { id },
    include: {
      vehicle: true,
      driver: { select: { id: true, fullName: true, phone: true } },
    },
  });
  if (!expense) throw new AppError('Expense not found', 404, 'NOT_FOUND');
  if (actor.role === 'driver' && expense.driverId !== actor.id) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  return mapExpense(expense);
}

export async function createExpense(body, actor) {
  if (actor.role === 'admin' || actor.role === 'super_admin') {
    const expense = await prisma.expense.create({
      data: {
        driverId: null,
        vehicleId: null,
        amount: body.amount,
        note: body.note?.trim() || null,
      },
      include: {
        vehicle: true,
        driver: { select: { id: true, fullName: true, phone: true } },
      },
    });

    await auditLog({
      userId: actor.id,
      action: 'EXPENSE_CREATE',
      entityType: 'Expense',
      entityId: expense.id,
      details: { amount: Number(expense.amount), station: true },
    });

    return mapExpense(expense);
  }

  if (actor.role !== 'driver') {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }
  if (body.vehicleId) {
    const v = await prisma.vehicle.findUnique({ where: { id: body.vehicleId } });
    if (!v || v.driverId !== actor.id) {
      throw new AppError('Invalid vehicle for this driver', 400, 'VALIDATION_ERROR');
    }
  }

  const expense = await prisma.expense.create({
    data: {
      driverId: actor.id,
      vehicleId: body.vehicleId ?? null,
      amount: body.amount,
      note: body.note ?? null,
    },
    include: {
      vehicle: true,
      driver: { select: { id: true, fullName: true, phone: true } },
    },
  });

  await auditLog({
    userId: actor.id,
    action: 'EXPENSE_CREATE',
    entityType: 'Expense',
    entityId: expense.id,
    details: { amount: Number(expense.amount) },
  });

  return mapExpense(expense);
}

export async function updateExpense(id, body, actor) {
  const existing = await prisma.expense.findUnique({ where: { id } });
  if (!existing) throw new AppError('Expense not found', 404, 'NOT_FOUND');
  if (actor.role !== 'driver' || existing.driverId !== actor.id) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }

  if (body.vehicleId) {
    const v = await prisma.vehicle.findUnique({ where: { id: body.vehicleId } });
    if (!v || v.driverId !== actor.id) {
      throw new AppError('Invalid vehicle for this driver', 400, 'VALIDATION_ERROR');
    }
  }

  const expense = await prisma.expense.update({
    where: { id },
    data: {
      ...(body.amount !== undefined && { amount: body.amount }),
      ...(body.note !== undefined && { note: body.note }),
      ...(body.vehicleId !== undefined && { vehicleId: body.vehicleId }),
    },
    include: {
      vehicle: true,
      driver: { select: { id: true, fullName: true, phone: true } },
    },
  });

  await auditLog({
    userId: actor.id,
    action: 'EXPENSE_UPDATE',
    entityType: 'Expense',
    entityId: id,
  });

  return mapExpense(expense);
}

export async function deleteExpense(id, actor) {
  const existing = await prisma.expense.findUnique({ where: { id } });
  if (!existing) throw new AppError('Expense not found', 404, 'NOT_FOUND');
  if (actor.role !== 'driver' || existing.driverId !== actor.id) {
    throw new AppError('Forbidden', 403, 'FORBIDDEN');
  }

  await prisma.expense.delete({ where: { id } });

  await auditLog({
    userId: actor.id,
    action: 'EXPENSE_DELETE',
    entityType: 'Expense',
    entityId: id,
  });

  return { deleted: true };
}

export async function myExpenses(query, actor) {
  const { page, limit, skip } = parsePagination(query);
  const where = { driverId: actor.id };
  const { dateFrom, dateTo } = parseDateRange(query);
  if (dateFrom || dateTo) {
    where.createdAt = {};
    if (dateFrom) where.createdAt.gte = startOfDay(dateFrom);
    if (dateTo) where.createdAt.lte = endOfDay(dateTo);
  }

  const [total, items] = await prisma.$transaction([
    prisma.expense.count({ where }),
    prisma.expense.findMany({
      where,
      include: { vehicle: true },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
    }),
  ]);

  return {
    items: items.map((e) => mapExpense(e)),
    total,
    page,
    limit,
  };
}
