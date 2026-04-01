import { z } from 'zod';

export const expenseCreateSchema = z.object({
  vehicleId: z.string().uuid().nullable().optional(),
  amount: z.coerce.number().positive(),
  note: z.string().max(2000).nullable().optional(),
});

export const expenseUpdateSchema = z.object({
  vehicleId: z.string().uuid().nullable().optional(),
  amount: z.coerce.number().positive().optional(),
  note: z.string().max(2000).nullable().optional(),
});
