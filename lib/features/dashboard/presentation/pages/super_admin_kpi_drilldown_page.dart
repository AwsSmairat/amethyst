import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// الخادم يرفض `limit` أكبر من 100 ([listQuerySchema]). نجمع الصفحات هنا.
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
        row['totals'] is Map<String, dynamic>
            ? row['totals'] as Map<String, dynamic>
            : null;
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
    final Map<String, dynamic> m = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
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
      final Map<String, dynamic> map = e is Map<String, dynamic>
          ? e
          : Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
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
  expensesToday,
  expensesMonth,
  salesMonth;

  static SuperAdminKpiDrilldown? tryParse(String pathSegment) {
    switch (pathSegment) {
      case 'profit-today':
        return SuperAdminKpiDrilldown.profitToday;
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
      case SuperAdminKpiDrilldown.expensesToday:
        return context.l10n.expensesTodayDetail;
      case SuperAdminKpiDrilldown.expensesMonth:
        return context.l10n.monthlyExpensesDetail;
      case SuperAdminKpiDrilldown.salesMonth:
        return context.l10n.monthlySalesDetail;
    }
  }
}

class SuperAdminKpiDrilldownPage extends StatefulWidget {
  const SuperAdminKpiDrilldownPage({super.key, required this.kind});

  final SuperAdminKpiDrilldown kind;

  @override
  State<SuperAdminKpiDrilldownPage> createState() =>
      _SuperAdminKpiDrilldownPageState();
}

class _SuperAdminKpiDrilldownPageState extends State<SuperAdminKpiDrilldownPage> {
  late Future<Map<String, dynamic>> _load;

  Future<Map<String, dynamic>> _fetch() {
    final AmethystApi api = sl<AmethystApi>();
    final DateTime now = DateTime.now();
    final String todayYmd = _ymd(now);
    switch (widget.kind) {
      case SuperAdminKpiDrilldown.profitToday:
        return api.reportsProfitLoss(dateFrom: todayYmd, dateTo: todayYmd);
      case SuperAdminKpiDrilldown.expensesToday:
        return _fetchExpensesGroupedByRecentDays(api);
      case SuperAdminKpiDrilldown.expensesMonth:
        return _fetchLast12MonthsExpenses(api);
      case SuperAdminKpiDrilldown.salesMonth:
        return _fetchLast12MonthsSales(api);
    }
  }

  static String _ymd(DateTime d) => _drilldownYmd(d);

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kind.localizedTitle(context)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorBody(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _load = _fetch();
                });
              },
            );
          }
          final Map<String, dynamic> data = snapshot.data ?? <String, dynamic>{};
          switch (widget.kind) {
            case SuperAdminKpiDrilldown.profitToday:
              return _ProfitBody(data: data);
            case SuperAdminKpiDrilldown.expensesToday:
              return RefreshIndicator(
                onRefresh: () async {
                  final Future<Map<String, dynamic>> f = _fetch();
                  setState(() {
                    _load = f;
                  });
                  await f;
                },
                child: _DailyExpensesBody(data: data),
              );
            case SuperAdminKpiDrilldown.expensesMonth:
              return RefreshIndicator(
                onRefresh: () async {
                  final Future<Map<String, dynamic>> f = _fetch();
                  setState(() {
                    _load = f;
                  });
                  await f;
                },
                child: _MonthlyExpensesBody(data: data),
              );
            case SuperAdminKpiDrilldown.salesMonth:
              return RefreshIndicator(
                onRefresh: () async {
                  final Future<Map<String, dynamic>> f = _fetch();
                  setState(() {
                    _load = f;
                  });
                  await f;
                },
                child: _MonthlySalesBody(data: data),
              );
          }
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _ProfitBody extends StatelessWidget {
  const _ProfitBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final double revenue = _toDouble(data['revenue']);
    final double expenses = _toDouble(data['expenses']);
    final double net = _toDouble(data['net']);
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _ProfitMetricCard(
          label: l.revenue,
          value: revenue,
          icon: Icons.trending_up_outlined,
        ),
        const SizedBox(height: 12),
        _ProfitMetricCard(
          label: l.expenses,
          value: expenses,
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 12),
        _ProfitMetricCard(
          label: l.netProfit,
          value: net,
          icon: Icons.savings_outlined,
          emphasize: true,
        ),
      ],
    );
  }
}

/// بطاقة واحدة لكل مؤشر — الإيرادات والمصاريف وصافي الربح منفصلين بصرياً.
class _ProfitMetricCard extends StatelessWidget {
  const _ProfitMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              color: AppColors.brandPrimary,
              size: emphasize ? 32 : 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.8,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.toStringAsFixed(2),
                    style: (emphasize
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _expenseLineSubtitle(Map<String, dynamic> m) {
  final Map<String, dynamic>? driver = m['driver'] is Map<String, dynamic>
      ? m['driver'] as Map<String, dynamic>
      : null;
  final String driverName = driver?['fullName']?.toString() ?? '—';
  final String? note = m['note']?.toString();
  final String? created = m['createdAt']?.toString();
  DateTime? at;
  if (created != null) {
    try {
      at = DateTime.parse(created);
    } on Object {
      at = null;
    }
  }
  String subtitle = driverName;
  if (note != null && note.isNotEmpty) {
    subtitle = '$subtitle · $note';
  }
  if (at != null) {
    subtitle = '$subtitle · ${DateFormat.Hm().format(at)}';
  }
  return subtitle;
}

class _DailyExpensesBody extends StatelessWidget {
  const _DailyExpensesBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? days = data['expenseDays'] as List<dynamic>?;
    if (days == null || days.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(context.l10n.noExpensesPeriod)),
          ),
        ],
      );
    }
    final DateTime n = DateTime.now();
    final DateTime todayDate = DateTime(n.year, n.month, n.day);
    final String todayYmd = _drilldownYmd(todayDate);
    final String yesterdayYmd =
        _drilldownYmd(todayDate.subtract(const Duration(days: 1)));

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int i) {
        final Map<String, dynamic> row = days[i] is Map<String, dynamic>
            ? days[i] as Map<String, dynamic>
            : Map<String, dynamic>.from(days[i] as Map<dynamic, dynamic>);
        final String dateStr = row['date']?.toString() ?? '';
        final List<dynamic> items = row['items'] is List<dynamic>
            ? row['items'] as List<dynamic>
            : <dynamic>[];
        final bool isToday = dateStr == todayYmd;
        final bool isYesterday = dateStr == yesterdayYmd;
        return _DailyExpensesDayCard(
          dateYmd: dateStr,
          items: items,
          isToday: isToday,
          isYesterday: isYesterday,
        );
      },
    );
  }
}

class _DailyExpensesDayCard extends StatelessWidget {
  const _DailyExpensesDayCard({
    required this.dateYmd,
    required this.items,
    required this.isToday,
    required this.isYesterday,
  });

  final String dateYmd;
  final List<dynamic> items;
  final bool isToday;
  final bool isYesterday;

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final dynamic e in items) {
      final Map<String, dynamic> m = e is Map<String, dynamic>
          ? e
          : Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      total += _toDouble(m['amount']);
    }
    final DateTime? parsed = _parseYmdLocal(dateYmd);
    final String locale = Localizations.localeOf(context).toString();
    final String periodTitle = parsed != null
        ? DateFormat.yMMMEd(locale).format(parsed)
        : dateYmd;
    final ThemeData theme = Theme.of(context);
    final Color fieldFill = theme.colorScheme.surface;

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fieldFill,
          isDense: true,
        );

    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: ValueKey<String>('exp_day_$dateYmd'),
                    readOnly: true,
                    initialValue: periodTitle,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: deco(context.l10n.expenseDayDateLabel),
                  ),
                ),
                if (isToday) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.sectionToday),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ] else if (isYesterday) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.yesterdayChip),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey<String>('exp_day_tot_${dateYmd}_${total.toStringAsFixed(2)}'),
              readOnly: true,
              initialValue: total.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: deco(context.l10n.expenseDayTotalLabel),
            ),
            if (items.isEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                context.l10n.noExpensesThisDay,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 16),
              Text(
                context.l10n.expenseLinesSection,
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...List<Widget>.generate(items.length, (int i) {
                final dynamic raw = items[i];
                final Map<String, dynamic> m = raw is Map<String, dynamic>
                    ? raw
                    : Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
                final double amount = _toDouble(m['amount']);
                final String id =
                    m['id']?.toString() ?? '${dateYmd}_$i';
                final String label = _expenseLineSubtitle(m);
                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                  child: TextFormField(
                    key: ValueKey<String>('exp_day_line_${id}_$amount'),
                    readOnly: true,
                    initialValue: amount.toStringAsFixed(2),
                    textAlign: TextAlign.end,
                    decoration: deco(label),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

DateTime? _parseYmdLocal(String ymd) {
  final List<String> p = ymd.split('-');
  if (p.length != 3) {
    return null;
  }
  final int? y = int.tryParse(p[0]);
  final int? m = int.tryParse(p[1]);
  final int? d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) {
    return null;
  }
  return DateTime(y, m, d);
}

class _MonthlyExpensesBody extends StatelessWidget {
  const _MonthlyExpensesBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? months = data['expenseMonths'] as List<dynamic>?;
    if (months == null || months.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[SizedBox(height: 1)],
      );
    }
    final DateTime n = DateTime.now();
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: months.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int i) {
        final Map<String, dynamic> row = months[i] is Map<String, dynamic>
            ? months[i] as Map<String, dynamic>
            : Map<String, dynamic>.from(months[i] as Map<dynamic, dynamic>);
        final int y = (row['year'] as num?)?.toInt() ?? n.year;
        final int m = (row['month'] as num?)?.toInt() ?? n.month;
        final bool isCurrent = y == n.year && m == n.month;
        final ({int y, int m}) prev = _calendarPreviousMonth(n.year, n.month);
        final bool isImmediatePrevious =
            !isCurrent && y == prev.y && m == prev.m;
        final List<dynamic> items = row['items'] is List<dynamic>
            ? row['items'] as List<dynamic>
            : <dynamic>[];
        return _MonthlyExpensesMonthCard(
          year: y,
          month: m,
          items: items,
          isCurrentCalendarMonth: isCurrent,
          isImmediatePreviousMonth: isImmediatePrevious,
        );
      },
    );
  }
}

class _MonthlyExpensesMonthCard extends StatelessWidget {
  const _MonthlyExpensesMonthCard({
    required this.year,
    required this.month,
    required this.items,
    required this.isCurrentCalendarMonth,
    required this.isImmediatePreviousMonth,
  });

  final int year;
  final int month;
  final List<dynamic> items;
  final bool isCurrentCalendarMonth;
  final bool isImmediatePreviousMonth;

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final dynamic e in items) {
      final Map<String, dynamic> m = e is Map<String, dynamic>
          ? e
          : Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      total += _toDouble(m['amount']);
    }
    final String locale = Localizations.localeOf(context).toString();
    final String periodTitle =
        DateFormat.yMMM(locale).format(DateTime(year, month, 1));
    final ThemeData theme = Theme.of(context);
    final Color fieldFill = theme.colorScheme.surface;

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fieldFill,
          isDense: true,
        );

    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: ValueKey<String>('exp_month_period_${year}_$month'),
                    readOnly: true,
                    initialValue: periodTitle,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: deco(context.l10n.monthYearPeriodLabel),
                  ),
                ),
                if (isCurrentCalendarMonth) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.currentCalendarMonthChip),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ] else if (isImmediatePreviousMonth) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.previousCalendarMonthChip),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey<String>(
                'exp_month_tot_${year}_${month}_${total.toStringAsFixed(2)}',
              ),
              readOnly: true,
              initialValue: total.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: deco(context.l10n.monthlyExpensesTotalLabel),
            ),
            if (items.isEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                context.l10n.noExpensesThisMonth,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 16),
              Text(
                context.l10n.expenseLinesSection,
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...List<Widget>.generate(items.length, (int i) {
                final dynamic raw = items[i];
                final Map<String, dynamic> m = raw is Map<String, dynamic>
                    ? raw
                    : Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
                final double amount = _toDouble(m['amount']);
                final String id =
                    m['id']?.toString() ?? '${year}_${month}_$i';
                final String label = _expenseLineSubtitle(m);
                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                  child: TextFormField(
                    key: ValueKey<String>('exp_line_${id}_$amount'),
                    readOnly: true,
                    initialValue: amount.toStringAsFixed(2),
                    textAlign: TextAlign.end,
                    decoration: deco(label),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthlySalesBody extends StatelessWidget {
  const _MonthlySalesBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? months = data['months'] as List<dynamic>?;
    if (months != null && months.isNotEmpty) {
      final DateTime n = DateTime.now();
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext context, int i) {
          final Map<String, dynamic> row = months[i] is Map<String, dynamic>
              ? months[i] as Map<String, dynamic>
              : Map<String, dynamic>.from(months[i] as Map<dynamic, dynamic>);
          final int y = (row['year'] as num?)?.toInt() ?? n.year;
          final int m = (row['month'] as num?)?.toInt() ?? n.month;
          final bool isCurrent = y == n.year && m == n.month;
          final ({int y, int m}) prev = _calendarPreviousMonth(n.year, n.month);
          final bool isImmediatePrevious =
              !isCurrent && y == prev.y && m == prev.m;
          return _MonthlySalesMonthCard(
            monthPayload: row,
            isCurrentCalendarMonth: isCurrent,
            isImmediatePreviousMonth: isImmediatePrevious,
          );
        },
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _MonthlySalesMonthCard(
          monthPayload: data,
          isCurrentCalendarMonth: true,
          isImmediatePreviousMonth: false,
        ),
      ],
    );
  }
}

class _MonthlySalesMonthCard extends StatelessWidget {
  const _MonthlySalesMonthCard({
    required this.monthPayload,
    required this.isCurrentCalendarMonth,
    required this.isImmediatePreviousMonth,
  });

  final Map<String, dynamic> monthPayload;
  final bool isCurrentCalendarMonth;
  final bool isImmediatePreviousMonth;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? totals = monthPayload['totals'] is Map<String, dynamic>
        ? monthPayload['totals'] as Map<String, dynamic>
        : null;
    final double station = _toDouble(totals?['stationAmount']);
    final double vehicle = _toDouble(totals?['vehicleAmount']);
    final double combined = station + vehicle;
    final List<dynamic> stationRows = monthPayload['stationSales'] is List<dynamic>
        ? monthPayload['stationSales'] as List<dynamic>
        : <dynamic>[];
    final List<dynamic> vehicleRows = monthPayload['vehicleSales'] is List<dynamic>
        ? monthPayload['vehicleSales'] as List<dynamic>
        : <dynamic>[];
    final int y =
        (monthPayload['year'] as num?)?.toInt() ?? DateTime.now().year;
    final int m =
        (monthPayload['month'] as num?)?.toInt() ?? DateTime.now().month;
    final String locale = Localizations.localeOf(context).toString();
    final String periodTitle =
        DateFormat.yMMM(locale).format(DateTime(y, m, 1));
    final ThemeData theme = Theme.of(context);
    final Color fieldFill = theme.colorScheme.surface;

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fieldFill,
          isDense: true,
        );

    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: ValueKey<String>('month_period_${y}_$m'),
                    readOnly: true,
                    initialValue: periodTitle,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: deco(context.l10n.monthYearPeriodLabel),
                  ),
                ),
                if (isCurrentCalendarMonth) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.currentCalendarMonthChip),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ] else if (isImmediatePreviousMonth) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.previousCalendarMonthChip),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey<String>('st_${y}_${m}_${station.toStringAsFixed(2)}'),
              readOnly: true,
              initialValue: station.toStringAsFixed(2),
              textAlign: TextAlign.end,
              decoration: deco(context.l10n.stationSales),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey<String>('vh_${y}_${m}_${vehicle.toStringAsFixed(2)}'),
              readOnly: true,
              initialValue: vehicle.toStringAsFixed(2),
              textAlign: TextAlign.end,
              decoration: deco(context.l10n.vehicleSales),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey<String>('tot_${y}_${m}_${combined.toStringAsFixed(2)}'),
              readOnly: true,
              initialValue: combined.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: deco(context.l10n.combinedTotalLabel),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.transactionsSummary(
                stationRows.length,
                vehicleRows.length,
              ),
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
