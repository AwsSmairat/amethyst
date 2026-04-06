import { DateTime } from 'luxon';

export function startOfDay(d) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

export function endOfDay(d) {
  const x = new Date(d);
  x.setHours(23, 59, 59, 999);
  return x;
}

/**
 * UTC instants for the calendar day containing `now` in `timeZone` (for DB filters).
 */
export function businessDayUtcRange(now = new Date(), timeZone) {
  const z = DateTime.fromJSDate(now).setZone(timeZone);
  const start = z.startOf('day');
  const end = z.endOf('day');
  return { start: start.toJSDate(), end: end.toJSDate() };
}

/**
 * UTC instants for the calendar month containing `now` in `timeZone`.
 */
export function businessMonthUtcRange(now = new Date(), timeZone) {
  const z = DateTime.fromJSDate(now).setZone(timeZone);
  const start = z.startOf('month');
  const end = z.endOf('month');
  return { start: start.toJSDate(), end: end.toJSDate() };
}

/** UTC instants for a given calendar month (month = 1–12) in `timeZone`. */
export function businessMonthUtcRangeFor(year, month, timeZone) {
  const z = DateTime.fromObject(
    { year, month, day: 1 },
    { zone: timeZone }
  );
  const start = z.startOf('month');
  const end = z.endOf('month');
  return { start: start.toJSDate(), end: end.toJSDate() };
}

export function parseDateRange(query) {
  const dateFrom = query.dateFrom ? new Date(query.dateFrom) : null;
  const dateTo = query.dateTo ? new Date(query.dateTo) : null;
  return {
    dateFrom: dateFrom && !Number.isNaN(dateFrom.getTime()) ? dateFrom : null,
    dateTo: dateTo && !Number.isNaN(dateTo.getTime()) ? dateTo : null,
  };
}
