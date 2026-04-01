export function success(res, data = null, message = 'OK', status = 200) {
  return res.status(status).json({
    success: true,
    message,
    data,
  });
}

export function paginated(res, { items, total, page, limit }, message = 'OK') {
  return res.status(200).json({
    success: true,
    message,
    data: {
      items,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit) || 0,
      },
    },
  });
}
