const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

export function parsePagination(query) {
  const page = Math.max(1, parseInt(String(query.page || '1'), 10) || 1);
  let limit = parseInt(String(query.limit || String(DEFAULT_LIMIT)), 10) || DEFAULT_LIMIT;
  limit = Math.min(Math.max(1, limit), MAX_LIMIT);
  const skip = (page - 1) * limit;
  return { page, limit, skip };
}

export function parseSort(query, allowedFields, defaultField = 'createdAt') {
  const sortBy = allowedFields.includes(query.sort) ? query.sort : defaultField;
  const order = String(query.order || 'desc').toLowerCase() === 'asc' ? 'asc' : 'desc';
  return { sortBy, order };
}
