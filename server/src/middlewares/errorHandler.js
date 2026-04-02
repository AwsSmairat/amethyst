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
