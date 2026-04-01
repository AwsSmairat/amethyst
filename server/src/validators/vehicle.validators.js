import { z } from 'zod';

export const createVehicleSchema = z.object({
  vehicleNumber: z.string().min(1).max(50),
  driverId: z.string().uuid().nullable().optional(),
  notes: z.string().max(2000).nullable().optional(),
  isActive: z.boolean().optional(),
});

export const updateVehicleSchema = z.object({
  vehicleNumber: z.string().min(1).max(50).optional(),
  notes: z.string().max(2000).nullable().optional(),
  isActive: z.boolean().optional(),
});

export const assignDriverSchema = z.object({
  driverId: z.string().uuid().nullable(),
});
