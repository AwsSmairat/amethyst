import { AppError } from '../utils/AppError.js';

/** @param {unknown} role */
function normalizeRole(role) {
  if (role == null) {
    return '';
  }
  return String(role).trim().toLowerCase();
}

/** @param {string[]} roles */
export function authorize(...roles) {
  return (req, res, next) => {
    try {
      if (!req.user) {
        throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
      }
      const userRole = normalizeRole(req.user.role);
      const allowed = roles.map((r) => normalizeRole(r));
      if (!allowed.includes(userRole)) {
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
