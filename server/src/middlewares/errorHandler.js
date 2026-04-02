import { Prisma } from '@prisma/client';
import { AppError } from '../utils/AppError.js';
import { ZodError } from 'zod';

export function errorHandler(err, req, res, _next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      code: 'VALIDATION_ERROR',
      errors: err.issues.map((e) => ({
        path: e.path.join('.'),
        message: e.message,
      })),
    });
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      code: err.code,
    });
  }

  if (err.code === 'P2002') {
    return res.status(409).json({
      success: false,
      message: 'A record with this value already exists',
      code: 'CONFLICT',
    });
  }

  if (err.code === 'P2025') {
    return res.status(404).json({
      success: false,
      message: 'Record not found',
      code: 'NOT_FOUND',
    });
  }

  // Prisma: connection / availability (common on misconfigured DATABASE_URL or cold DB).
  const prismaConnectionCodes = new Set([
    'P1000',
    'P1001',
    'P1002',
    'P1003',
    'P1017',
    'P2024',
  ]);
  if (
    err.name === 'PrismaClientInitializationError' ||
    prismaConnectionCodes.has(err.code)
  ) {
    console.error('[prisma]', err);
    return res.status(503).json({
      success: false,
      message:
        'Database is unavailable. Check DATABASE_URL on the server and that migrations ran.',
      code: 'DATABASE_UNAVAILABLE',
    });
  }

  // Any other Prisma "known" error (e.g. P2021 table missing) — avoid silent 500.
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    console.error('[prisma known]', err.code, err.meta, err.message);
    const message =
      err.code === 'P2021' || err.code === 'P2010'
        ? 'Database schema is out of sync. Run prisma migrate deploy on the server.'
        : `Database error (${err.code}).`;
    return res.status(503).json({
      success: false,
      message,
      code: err.code,
    });
  }

  if (err instanceof Prisma.PrismaClientUnknownRequestError) {
    console.error('[prisma unknown]', err.message);
    return res.status(503).json({
      success: false,
      message: 'Database request failed. Check DATABASE_URL and server logs.',
      code: 'DATABASE_REQUEST_FAILED',
    });
  }

  // res.json() failed (e.g. BigInt / circular structure) — log real cause in server logs.
  const msg = err?.message ?? '';
  if (
    err instanceof TypeError &&
    (msg.includes('JSON') ||
      msg.includes('BigInt') ||
      msg.includes('circular') ||
      msg.includes('Converting circular'))
  ) {
    console.error('[response]', err);
    return res.status(500).json({
      success: false,
      message: 'Response serialization failed',
      code: 'SERIALIZATION_ERROR',
    });
  }

  console.error(err);
  return res.status(500).json({
    success: false,
    message:
      process.env.NODE_ENV === 'production'
        ? 'Internal server error'
        : err.message,
    code: 'INTERNAL_ERROR',
  });
}
