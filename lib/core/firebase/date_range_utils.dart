DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

({DateTime start, DateTime end}) businessDayRange(DateTime anchor) {
  final DateTime start = startOfDay(anchor);
  return (start: start, end: endOfDay(anchor));
}

({DateTime start, DateTime end}) businessMonthRange(DateTime anchor) {
  final DateTime start = DateTime(anchor.year, anchor.month, 1);
  final DateTime end = DateTime(anchor.year, anchor.month + 1, 0, 23, 59, 59, 999);
  return (start: start, end: end);
}

({DateTime start, DateTime end}) businessMonthRangeFor(int year, int month) {
  final DateTime start = DateTime(year, month, 1);
  final DateTime end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
  return (start: start, end: end);
}

bool isInRange(DateTime? value, DateTime start, DateTime end) {
  if (value == null) {
    return false;
  }
  return !value.isBefore(start) && !value.isAfter(end);
}

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseYmd(String? s) {
  if (s == null || s.isEmpty) {
    return null;
  }
  final List<String> p = s.split('-');
  if (p.length != 3) {
    return null;
  }
  final int? y = int.tryParse(p[0]);
  final int? m = int.tryParse(p[1]);
  final int? day = int.tryParse(p[2]);
  if (y == null || m == null || day == null) {
    return null;
  }
  return DateTime(y, m, day);
}
