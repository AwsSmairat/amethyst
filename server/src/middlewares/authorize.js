import { AppError } from '../utils/AppError.js';

/** @param {string[]} roles */
export function authorize(...roles) {
  return (req, res, next) => {
    try {
      if (!req.user) {
        throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
      }
      if (!roles.includes(req.user.role)) {
        throw new AppError('Forbidden', 403, 'FORBIDDEN');
      }
      next();
    } catch (err) {
      next(err);
    }
  };
}

/** Alias for `authorize` — production naming convention. */
export const roleMiddleware = authorize;
