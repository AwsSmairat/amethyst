import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Lists calendar days that had station and/or vehicle sales (tap target from Sales today KPI).
class SalesWorkingDaysPage extends StatefulWidget {
  const SalesWorkingDaysPage({super.key});

  @override
  State<SalesWorkingDaysPage> createState() => _SalesWorkingDaysPageState();
}

class _SalesWorkingDaysPageState extends State<SalesWorkingDaysPage> {
  late Future<Map<String, dynamic>> _load;

  Future<Map<String, dynamic>> _fetch() =>
      sl<AmethystApi>().reportsSalesWorkingDays();

  /// يطابق تاريخ السيرفر (YYYY-MM-DD…) مع اليوم المحلي للجهاز.
  static String _ymdPrefix(String apiDate) {
    final String t = apiDate.trim();
    if (t.length >= 10) {
      return t.substring(0, 10);
    }
    return t;
  }

  static String _todayYmdLocal() {
    final DateTime n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// يضمن صفّاً لـ **اليوم** دائماً (حتى 0.00)؛ أي يوم جديد يظهر حقلُه فوراً.
  /// بقية الأيام كما رجعت من الـ API (بدون تكرار لتاريخ اليوم).
  List<Map<String, dynamic>> _daysWithTodayRow(List<dynamic> raw) {
    final String todayYmd = _todayYmdLocal();
    double todayCombined = 0;
    final List<Map<String, dynamic>> others = <Map<String, dynamic>>[];
    for (final dynamic item in raw) {
      final Map<String, dynamic> row = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
      final String key = _ymdPrefix(row['date']?.toString() ?? '');
      if (key == todayYmd) {
        todayCombined = _toDouble(row['combined']);
        continue;
      }
      if (key.isNotEmpty) {
        others.add(row);
      }
    }
    return <Map<String, dynamic>>[
      <String, dynamic>{'date': todayYmd, 'combined': todayCombined},
      ...others,
    ];
  }

  DateTime? _parseRowDate(String dateStr) {
    final String ymd = _ymdPrefix(dateStr);
    final List<String> p = ymd.split('-');
    if (p.length != 3) {
      try {
        return DateTime.parse(dateStr);
      } on Object {
        return null;
      }
    }
    final int? y = int.tryParse(p[0]);
    final int? m = int.tryParse(p[1]);
    final int? d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) {
      return null;
    }
    return DateTime(y, m, d);
  }

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.daysWithSales),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _load = _fetch();
                        });
                      },
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data ?? <String, dynamic>{};
          final raw = data['days'];
          final List<dynamic> fromApi =
              raw is List<dynamic> ? raw : <dynamic>[];
          final List<Map<String, dynamic>> days = _daysWithTodayRow(fromApi);
          final String todayYmd = _todayYmdLocal();
          return RefreshIndicator(
            onRefresh: () async {
              final Future<Map<String, dynamic>> f = _fetch();
              setState(() {
                _load = f;
              });
              await f;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: days.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final Map<String, dynamic> row = days[i];
                final String dateStr = row['date']?.toString() ?? '';
                final DateTime? parsed = _parseRowDate(dateStr);
                final locale = Localizations.localeOf(context).toString();
                final String title = parsed != null
                    ? DateFormat.yMMMEd(locale).format(parsed)
                    : dateStr;
                final double combined = _toDouble(row['combined']);
                final bool isToday = _ymdPrefix(dateStr) == todayYmd;
                final ThemeData theme = Theme.of(context);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isToday)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 8,
                              ),
                              child: Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(context.l10n.sectionToday),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: ValueKey<String>(
                          '${_ymdPrefix(dateStr)}_${combined.toStringAsFixed(2)}',
                        ),
                        readOnly: true,
                        initialValue: combined.toStringAsFixed(2),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n.totalSalesAmountLabel,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.surfaceLowest,
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  double _toDouble(dynamic v) {
    if (v == null) {
      return 0;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString()) ?? 0;
  }
}
