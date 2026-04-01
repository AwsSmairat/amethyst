import { z } from 'zod';

export const createVehicleLoadSchema = z.object({
  vehicleId: z.string().uuid(),
  driverId: z.string().uuid(),
  productId: z.string().uuid(),
  quantityLoaded: z.coerce.number().int().positive(),
  loadDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

export const updateVehicleLoadSchema = z.object({
  quantityLoaded: z.coerce.number().int().positive().optional(),
  loadDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});
