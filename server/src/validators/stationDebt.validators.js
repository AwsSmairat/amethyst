import { z } from 'zod';

export const stationDebtRepaySchema = z.object({
  debtorName: z.string().trim().min(1).max(200),
});

export const stationDebtCreateBatchSchema = z.object({
  debtorName: z.string().trim().min(1).max(200),
  lines: z
    .array(
      z.object({
        productId: z.string().uuid(),
        quantity: z.coerce.number().int().positive(),
        unitPrice: z.coerce.number().nonnegative(),
      })
    )
    .min(1),
});
