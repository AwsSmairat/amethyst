import { z } from 'zod';

const unitType = z.enum(['bottle', 'carton', 'gallon', 'coupon']);

export const createProductSchema = z
  .object({
    name: z.string().min(1).max(200),
    unitType: unitType.optional(),
    type: unitType.optional(),
    price: z.coerce.number().positive(),
    stationStock: z.coerce.number().int().min(0).optional(),
    stock: z.coerce.number().int().min(0).optional(),
    isActive: z.boolean().optional(),
  })
  .transform((d) => ({
    name: d.name,
    unitType: d.unitType ?? d.type,
    price: d.price,
    stationStock: d.stationStock ?? d.stock ?? 0,
    isActive: d.isActive,
  }))
  .refine((d) => d.unitType != null, {
    message: 'Provide unitType or type (bottle | carton | gallon | coupon)',
    path: ['unitType'],
  });

export const updateProductSchema = z
  .object({
    name: z.string().min(1).max(200).optional(),
    unitType: unitType.optional(),
    type: unitType.optional(),
    price: z.coerce.number().positive().optional(),
    stationStock: z.coerce.number().int().min(0).optional(),
    stock: z.coerce.number().int().min(0).optional(),
    isActive: z.boolean().optional(),
  })
  .refine(
    (d) =>
      d.name !== undefined ||
      d.unitType !== undefined ||
      d.type !== undefined ||
      d.price !== undefined ||
      d.stationStock !== undefined ||
      d.stock !== undefined ||
      d.isActive !== undefined,
    { message: 'At least one field must be provided' }
  )
  .transform((d) => ({
    name: d.name,
    unitType: d.unitType ?? d.type,
    price: d.price,
    stationStock: d.stationStock ?? d.stock,
    isActive: d.isActive,
  }));

export const patchStockSchema = z
  .object({
    stationStock: z.coerce.number().int().min(0).optional(),
    stock: z.coerce.number().int().min(0).optional(),
  })
  .transform((d) => ({
    stationStock: d.stationStock ?? d.stock,
  }))
  .refine((d) => d.stationStock !== undefined && d.stationStock !== null, {
    message: 'Provide stationStock or stock',
    path: ['stationStock'],
  });
