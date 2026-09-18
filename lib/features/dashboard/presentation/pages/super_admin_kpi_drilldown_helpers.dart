part of 'super_admin_kpi_drilldown_page.dart';

Future<Map<String, dynamic>> _fetchAllExpensesInRange(
  AmethystApi api, {
  required String dateFrom,
  required String dateTo,
}) async {
  const int limit = 100;
  int page = 1;
  final List<dynamic> all = <dynamic>[];
  while (true) {
    final Map<String, dynamic> data = await api.listExpenses(
      page: page,
      limit: limit,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    final List<dynamic> batch = data['items'] is List<dynamic>
        ? data['items'] as List<dynamic>
        : <dynamic>[];
    all.addAll(batch);
    if (batch.length < limit) {
      break;
    }
    page += 1;
    if (page > 100) {
      break;
    }
  }
  return <String, dynamic>{'items': all};
}

String _drilldownYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

double _toDouble(dynamic v) {
  if (v == null) {
    return 0;
  }
  if (v is num) {
    return v.toDouble();
  }
  return double.tryParse(v.toString()) ?? 0;
}

Map<String, dynamic>? _tryCoerceMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  return null;
}

List<Map<String, dynamic>> _coerceMapRows(Object? raw) {
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final Object? item in raw) {
    final Map<String, dynamic>? map = _tryCoerceMap(item);
    if (map != null) {
      out.add(map);
    }
  }
  return out;
}

Map<String, dynamic> _profitDayFallbackPayload(Map<String, dynamic> data) {
  final Map<String, dynamic>? today = _tryCoerceMap(data['today']);
  if (today != null) {
    return today;
  }
  if (data.containsKey('stationSales') ||
      data.containsKey('total') ||
      data.containsKey('vehicles')) {
    return data;
  }
  return data;
}

Map<String, dynamic> _profitMonthFallbackPayload(Map<String, dynamic> data) {
  final Map<String, dynamic>? current = _tryCoerceMap(data['current']);
  if (current != null) {
    return current;
  }
  if (data.containsKey('stationSales') ||
      data.containsKey('total') ||
      data.containsKey('vehicles')) {
    return data;
  }
  return data;
}

/// الشهر التقويمي الذي يسبق [year]/[month].
({int y, int m}) _calendarPreviousMonth(int year, int month) {
  if (month == 1) {
    return (y: year - 1, m: 12);
  }
  return (y: year, m: month - 1);
}

/// يُظهر: الشهر الحالي، والشهر السابق دائماً، وأي شهر أقدم له بيانات فقط.
List<Map<String, dynamic>> _filterSalesMonthsForDisplay(
  List<Map<String, dynamic>> raw,
  DateTime now,
) {
  final ({int y, int m}) prev = _calendarPreviousMonth(now.year, now.month);
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final Map<String, dynamic> row in raw) {
    final int y = (row['year'] as num?)?.toInt() ?? 0;
    final int m = (row['month'] as num?)?.toInt() ?? 0;
    if (y == now.year && m == now.month) {
      out.add(row);
      continue;
    }
    if (y == prev.y && m == prev.m) {
      out.add(row);
      continue;
    }
    final Map<String, dynamic>? totals =
        _tryCoerceMap(row['totals']);
    final double station = _toDouble(totals?['stationAmount']);
    final double vehicle = _toDouble(totals?['vehicleAmount']);
    final List<dynamic> st = row['stationSales'] is List<dynamic>
        ? row['stationSales'] as List<dynamic>
        : <dynamic>[];
    final List<dynamic> vt = row['vehicleSales'] is List<dynamic>
        ? row['vehicleSales'] as List<dynamic>
        : <dynamic>[];
    if (station + vehicle > 0 || st.isNotEmpty || vt.isNotEmpty) {
      out.add(row);
    }
  }
  return out;
}

String? _expenseItemLocalYmd(Map<String, dynamic> m) {
  final String? created = m['createdAt']?.toString();
  if (created == null) {
    return null;
  }
  DateTime? at;
  try {
    at = DateTime.parse(created);
  } on Object {
    return null;
  }
  final DateTime local = at.toLocal();
  return _drilldownYmd(DateTime(local.year, local.month, local.day));
}

Map<String, List<Map<String, dynamic>>> _groupExpensesByLocalDay(
  List<dynamic> items,
) {
  final Map<String, List<Map<String, dynamic>>> map =
      <String, List<Map<String, dynamic>>>{};
  for (final dynamic raw in items) {
    final Map<String, dynamic>? m = _tryCoerceMap(raw);
    if (m == null) {
      continue;
    }
    final String? key = _expenseItemLocalYmd(m);
    if (key == null || key.isEmpty) {
      continue;
    }
    map.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(m);
  }
  for (final List<Map<String, dynamic>> list in map.values) {
    list.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime ta = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime tb = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
  }
  return map;
}

/// اليوم والأمس دائماً؛ أيام أقدم تظهر فقط إن فيها مصاريف.
List<Map<String, dynamic>> _buildExpenseDayCardsPayload(
  Map<String, List<Map<String, dynamic>>> byDay,
  DateTime now,
) {
  final DateTime todayDate = DateTime(now.year, now.month, now.day);
  final String todayYmd = _drilldownYmd(todayDate);
  final DateTime yesterdayDate = todayDate.subtract(const Duration(days: 1));
  final String yesterdayYmd = _drilldownYmd(yesterdayDate);

  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[
    <String, dynamic>{
      'date': todayYmd,
      'items': byDay[todayYmd] ?? <Map<String, dynamic>>[],
    },
    <String, dynamic>{
      'date': yesterdayYmd,
      'items': byDay[yesterdayYmd] ?? <Map<String, dynamic>>[],
    },
  ];

  final List<String> keys = byDay.keys.toList()..sort((String a, String b) => b.compareTo(a));
  for (final String k in keys) {
    if (k == todayYmd || k == yesterdayYmd) {
      continue;
    }
    final List<Map<String, dynamic>> list = byDay[k]!;
    if (list.isNotEmpty) {
      out.add(<String, dynamic>{'date': k, 'items': list});
    }
  }
  return out;
}

Future<Map<String, dynamic>> _fetchExpensesGroupedByRecentDays(
  AmethystApi api,
) async {
  final DateTime now = DateTime.now();
  final DateTime todayStart = DateTime(now.year, now.month, now.day);
  final DateTime rangeStart = todayStart.subtract(const Duration(days: 59));
  final Map<String, dynamic> chunk = await _fetchAllExpensesInRange(
    api,
    dateFrom: _drilldownYmd(rangeStart),
    dateTo: _drilldownYmd(now),
  );
  final List<dynamic> items = chunk['items'] is List<dynamic>
      ? chunk['items'] as List<dynamic>
      : <dynamic>[];
  final Map<String, List<Map<String, dynamic>>> grouped =
      _groupExpensesByLocalDay(items);
  final List<Map<String, dynamic>> days =
      _buildExpenseDayCardsPayload(grouped, now);
  return <String, dynamic>{'expenseDays': days};
}

Future<Map<String, dynamic>> _fetchProfitGroupedByRecentDays(
  AmethystApi api,
) async {
  final DateTime now = DateTime.now();
  final DateTime todayStart = DateTime(now.year, now.month, now.day);
  final DateTime rangeStart = todayStart.subtract(const Duration(days: 59));
  return api.reportsProfitLoss(
    dateFrom: _drilldownYmd(rangeStart),
    dateTo: _drilldownYmd(now),
  );
}

List<Map<String, dynamic>> _filterExpenseMonthsForDisplay(
  List<Map<String, dynamic>> raw,
  DateTime now,
) {
  final ({int y, int m}) prev = _calendarPreviousMonth(now.year, now.month);
  final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
  for (final Map<String, dynamic> row in raw) {
    final int y = (row['year'] as num?)?.toInt() ?? 0;
    final int m = (row['month'] as num?)?.toInt() ?? 0;
    if (y == now.year && m == now.month) {
      out.add(row);
      continue;
    }
    if (y == prev.y && m == prev.m) {
      out.add(row);
      continue;
    }
    final List<dynamic> items = row['items'] is List<dynamic>
        ? row['items'] as List<dynamic>
        : <dynamic>[];
    double total = 0;
    for (final dynamic e in items) {
      final Map<String, dynamic>? map = _tryCoerceMap(e);
      if (map == null) {
        continue;
      }
      total += _toDouble(map['amount']);
    }
    if (items.isNotEmpty || total > 0) {
      out.add(row);
    }
  }
  return out;
}

/// آخر 12 شهراً من المصاريف؛ بنفس فكرة المبيعات الشهرية (بطاقة لكل شهر).
Future<Map<String, dynamic>> _fetchLast12MonthsExpenses(AmethystApi api) async {
  final DateTime now = DateTime.now();
  final List<DateTime> firstDays = <DateTime>[];
  final List<Future<Map<String, dynamic>>> futures =
      <Future<Map<String, dynamic>>>[];
  for (var i = 0; i < 12; i++) {
    final DateTime first = DateTime(now.year, now.month - i, 1);
    final DateTime last = DateTime(first.year, first.month + 1, 0);
    firstDays.add(first);
    futures.add(
      _fetchAllExpensesInRange(
        api,
        dateFrom: _drilldownYmd(first),
        dateTo: _drilldownYmd(last),
      ),
    );
  }
  final List<Map<String, dynamic>> chunks = await Future.wait(futures);
  final List<Map<String, dynamic>> expenseMonths = <Map<String, dynamic>>[];
  for (var i = 0; i < 12; i++) {
    final DateTime first = firstDays[i];
    final List<dynamic> items = chunks[i]['items'] is List<dynamic>
        ? chunks[i]['items'] as List<dynamic>
        : <dynamic>[];
    expenseMonths.add(<String, dynamic>{
      'year': first.year,
      'month': first.month,
      'items': items,
    });
  }
  final List<Map<String, dynamic>> visible =
      _filterExpenseMonthsForDisplay(expenseMonths, now);
  return <String, dynamic>{'expenseMonths': visible};
}

/// آخر 12 شهراً؛ كل شهر في عنصر واجهة منفصل (حقل باسم الشهر والسنة).
Future<Map<String, dynamic>> _fetchLast12MonthsSales(AmethystApi api) async {
  final DateTime now = DateTime.now();
  final List<Future<Map<String, dynamic>>> futures =
      <Future<Map<String, dynamic>>>[];
  for (var i = 0; i < 12; i++) {
    final DateTime d = DateTime(now.year, now.month - i, 1);
    futures.add(api.reportsSalesMonthly(year: d.year, month: d.month));
  }
  final List<Map<String, dynamic>> months = await Future.wait(futures);
  final List<Map<String, dynamic>> visible =
      _filterSalesMonthsForDisplay(months, now);
  return <String, dynamic>{'months': visible};
}

/// Drill-down from super admin dashboard KPI tiles.
enum SuperAdminKpiDrilldown {
  profitToday,
  profitMonth,
  expensesToday,
  expensesMonth,
  salesMonth;

  static SuperAdminKpiDrilldown? tryParse(String pathSegment) {
    switch (pathSegment) {
      case 'profit-today':
        return SuperAdminKpiDrilldown.profitToday;
      case 'profit-month':
        return SuperAdminKpiDrilldown.profitMonth;
      case 'expenses-today':
        return SuperAdminKpiDrilldown.expensesToday;
      case 'expenses-month':
        return SuperAdminKpiDrilldown.expensesMonth;
      case 'sales-month':
        return SuperAdminKpiDrilldown.salesMonth;
      default:
        return null;
    }
  }
}

extension SuperAdminKpiDrilldownL10n on SuperAdminKpiDrilldown {
  String localizedTitle(BuildContext context) {
    switch (this) {
      case SuperAdminKpiDrilldown.profitToday:
        return context.l10n.profitTodayDetail;
      case SuperAdminKpiDrilldown.profitMonth:
        return context.l10n.profitMonthDetail;
      case SuperAdminKpiDrilldown.expensesToday:
        return context.l10n.expensesTodayDetail;
      case SuperAdminKpiDrilldown.expensesMonth:
        return context.l10n.monthlyExpensesDetail;
      case SuperAdminKpiDrilldown.salesMonth:
        return context.l10n.monthlySalesDetail;
    }
  }
}
