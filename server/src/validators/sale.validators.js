import { z } from 'zod';

export const stationSaleCreateSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.coerce.number().int().positive(),
  unitPrice: z.coerce.number().nonnegative(),
  /** بيع «تعبئة»: جالون وقارورة لا يخصمان من مخزون المحطة (يُحدَّد من التطبيق). */
  fillingSale: z.preprocess(
    (val) => {
      if (val === undefined || val === null) {
        return undefined;
      }
      if (val === true || val === 1 || val === '1') {
        return true;
      }
      if (val === false || val === 0 || val === '0') {
        return false;
      }
      if (typeof val === 'string') {
        const s = val.trim().toLowerCase();
        if (s === 'true') {
          return true;
        }
        if (s === 'false') {
          return false;
        }
      }
      return val;
    },
    z.boolean().optional()
  ),
  /** تعبئة: ٠ جالون، ١ قارورة — تخطي خصم مخزون المحطة لهذين العمودين فقط. */
  fillingLineSlot: z.preprocess(
    (val) => {
      if (val === undefined || val === null) {
        return undefined;
      }
      const n = Number(val);
      if (!Number.isFinite(n)) {
        return undefined;
      }
      return Math.trunc(n);
    },
    z.number().int().min(0).max(3).optional()
  ),
  filling_slot: z.preprocess(
    (val) => {
      if (val === undefined || val === null) {
        return undefined;
      }
      const n = Number(val);
      if (!Number.isFinite(n)) {
        return undefined;
      }
      return Math.trunc(n);
    },
    z.number().int().min(0).max(3).optional()
  ),
}).transform((d) => {
  const slot = d.fillingLineSlot ?? d.filling_slot;
  const { filling_slot: _, ...rest } = d;
  return { ...rest, fillingLineSlot: slot };
});

export const vehicleSaleCreateSchema = z.object({
  vehicleId: z.string().uuid(),
  productId: z.string().uuid(),
  quantity: z.coerce.number().int().positive(),
  unitPrice: z.coerce.number().nonnegative(),
});
