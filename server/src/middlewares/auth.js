import { verifyToken } from '../utils/jwt.js';
import { AppError } from '../utils/AppError.js';
import { prisma } from '../utils/prisma.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const authenticate = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
  }
  const token = header.slice(7);
  try {
    const decoded = verifyToken(token);
    const user = await prisma.user.findUnique({
      where: { id: decoded.sub },
      select: {
        id: true,
        email: true,
        role: true,
        isActive: true,
        fullName: true,
        phone: true,
      },
    });
    if (!user || !user.isActive) {
      throw new AppError('Invalid or inactive account', 401, 'UNAUTHORIZED');
    }
    req.user = user;
    next();
  } catch (e) {
    if (e instanceof AppError) throw e;
    throw new AppError('Invalid or expired token', 401, 'UNAUTHORIZED');
  }
});

/** Alias for `authenticate` — production naming convention. */
export const authMiddleware = authenticate;
