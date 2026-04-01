/**
 * Central entry for auth / RBAC middleware.
 * Existing routes may import from `auth.js` / `authorize.js` directly.
 */
export { authenticate, authMiddleware } from './auth.js';
export { authorize, roleMiddleware } from './authorize.js';
export { validate } from './validate.js';
export { errorHandler } from './errorHandler.js';
