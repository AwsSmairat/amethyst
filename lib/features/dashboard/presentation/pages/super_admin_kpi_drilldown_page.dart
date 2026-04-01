import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        return api.listExpenses(
          dateFrom: todayYmd,
          dateTo: todayYmd,
          limit: 200,
        );
      case SuperAdminKpiDrilldown.expensesMonth:
        final DateTime start = DateTime(now.year, now.month, 1);
        final DateTime end = DateTime(now.year, now.month + 1, 0);
        return api.listExpenses(
          dateFrom: _ymd(start),
          dateTo: _ymd(end),
          limit: 500,
        );
      case SuperAdminKpiDrilldown.salesMonth:
        return api.reportsSalesMonthly();
    }
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
            case SuperAdminKpiDrilldown.expensesMonth:
              return _ExpensesListBody(data: data);
            case SuperAdminKpiDrilldown.salesMonth:
              return _MonthlySalesBody(data: data);
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
        _metricRow(context, l.revenue, revenue),
        _metricRow(context, l.expenses, expenses),
        _metricRow(context, l.netProfit, net, emphasize: true),
      ],
    );
  }

  Widget _metricRow(
    BuildContext context,
    String label,
    double value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '$label: ${value.toStringAsFixed(2)}',
        style: (emphasize ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.bodyLarge)
            ?.copyWith(fontWeight: emphasize ? FontWeight.w800 : null),
      ),
    );
  }
}

class _ExpensesListBody extends StatelessWidget {
  const _ExpensesListBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> raw = data['items'] is List<dynamic>
        ? data['items'] as List<dynamic>
        : <dynamic>[];
    if (raw.isEmpty) {
      return Center(child: Text(context.l10n.noExpensesPeriod));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: raw.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final dynamic item = raw[i];
        final Map<String, dynamic> m = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
        final double amount = _toDouble(m['amount']);
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
        return ListTile(
          title: Text(amount.toStringAsFixed(2)),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        );
      },
    );
  }
}

class _MonthlySalesBody extends StatelessWidget {
  const _MonthlySalesBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? totals =
        data['totals'] is Map<String, dynamic> ? data['totals'] as Map<String, dynamic> : null;
    final double station = _toDouble(totals?['stationAmount']);
    final double vehicle = _toDouble(totals?['vehicleAmount']);
    final double combined = station + vehicle;
    final List<dynamic> stationRows = data['stationSales'] is List<dynamic>
        ? data['stationSales'] as List<dynamic>
        : <dynamic>[];
    final List<dynamic> vehicleRows = data['vehicleSales'] is List<dynamic>
        ? data['vehicleSales'] as List<dynamic>
        : <dynamic>[];
    final int y = data['year'] is int ? data['year'] as int : DateTime.now().year;
    final int m = data['month'] is int ? data['month'] as int : DateTime.now().month;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(
          '$y-${m.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.stationSalesAmount(station.toStringAsFixed(2))),
        Text(context.l10n.vehicleSalesAmount(vehicle.toStringAsFixed(2))),
        Text(
          context.l10n.combinedSales(combined.toStringAsFixed(2)),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.transactionsSummary(stationRows.length, vehicleRows.length),
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
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
