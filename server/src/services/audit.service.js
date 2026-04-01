import { prisma } from '../utils/prisma.js';

const CRITICAL_ACTIONS = new Set([
  'USER_CREATE',
  'USER_UPDATE',
  'USER_DELETE',
  'USER_STATUS',
  'VEHICLE_CREATE',
  'VEHICLE_UPDATE',
  'VEHICLE_DELETE',
  'VEHICLE_ASSIGN_DRIVER',
  'PRODUCT_CREATE',
  'PRODUCT_UPDATE',
  'PRODUCT_DELETE',
  'PRODUCT_STOCK_ADJUST',
  'VEHICLE_LOAD_CREATE',
  'VEHICLE_LOAD_UPDATE',
  'VEHICLE_LOAD_CLOSE',
  'STATION_SALE_CREATE',
  'VEHICLE_SALE_CREATE',
  'EXPENSE_CREATE',
  'EXPENSE_UPDATE',
  'EXPENSE_DELETE',
  'RETURN_RECORD',
]);

export async function auditLog({
  userId,
  action,
  entityType,
  entityId = null,
  details = null,
}) {
  if (!CRITICAL_ACTIONS.has(action)) {
    return null;
  }
  return prisma.auditLog.create({
    data: {
      userId,
      action,
      entityType,
      entityId,
      details: details ?? undefined,
    },
  });
}
