import { z } from 'zod';

export const uuidParam = z.object({
  id: z.string().uuid(),
});

export const paginationQuery = z.object({
  page: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().positive().max(100).optional(),
  sort: z.string().optional(),
  order: z.enum(['asc', 'desc']).optional(),
  dateFrom: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  dateTo: z.string().datetime().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/)).optional(),
  vehicleId: z.string().uuid().optional(),
  driverId: z.string().uuid().optional(),
  productId: z.string().uuid().optional(),
});

/**
 * Shared list query: pagination, sort, common filters.
 * Unknown keys are preserved for resource-specific filters.
 */
export const listQuerySchema = z
  .object({
    page: z.coerce.number().int().positive().optional(),
    limit: z.coerce.number().int().positive().max(100).optional(),
    sort: z.string().optional(),
    order: z.enum(['asc', 'desc']).optional(),
    dateFrom: z.string().optional(),
    dateTo: z.string().optional(),
    vehicleId: z.string().uuid().optional(),
    driverId: z.string().uuid().optional(),
    productId: z.string().uuid().optional(),
    status: z.enum(['open', 'closed']).optional(),
    isActive: z.preprocess((val) => {
      if (val === undefined || val === '') return undefined;
      if (val === true || val === 'true' || val === '1') return true;
      if (val === false || val === 'false' || val === '0') return false;
      return undefined;
    }, z.boolean().optional()),
  })
  .passthrough();

export const userRoleEnum = z.enum(['super_admin', 'admin', 'driver']);
