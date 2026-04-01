import { ZodSchema } from 'zod';

/**
 * @param {ZodSchema} schema
 * @param {'body'|'query'|'params'} source
 */
export function validate(schema, source = 'body') {
  return (req, res, next) => {
    const parsed = schema.safeParse(req[source]);
    if (!parsed.success) {
      return next(parsed.error);
    }
    req[source] = parsed.data;
    next();
  };
}
