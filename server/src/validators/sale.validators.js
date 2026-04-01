import { z } from 'zod';

export const stationSaleCreateSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.coerce.number().int().positive(),
  unitPrice: z.coerce.number().positive(),
});

export const vehicleSaleCreateSchema = z.object({
  vehicleId: z.string().uuid(),
  productId: z.string().uuid(),
  quantity: z.coerce.number().int().positive(),
  unitPrice: z.coerce.number().positive(),
});
