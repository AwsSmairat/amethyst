import { z } from 'zod';

export const returnCreateSchema = z.object({
  vehicleLoadId: z.string().uuid(),
  quantityReturned: z.coerce.number().int().positive(),
});
