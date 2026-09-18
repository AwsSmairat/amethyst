import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/expenses/expense_category_match.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/vehicle/vehicle_kind_match.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'super_admin_kpi_drilldown_helpers.dart';
part 'super_admin_kpi_drilldown_profit.dart';
part 'super_admin_kpi_drilldown_expenses.dart';
part 'super_admin_kpi_drilldown_sales.dart';


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
    switch (widget.kind) {
      case SuperAdminKpiDrilldown.profitToday:
        return _fetchProfitGroupedByRecentDays(api);
      case SuperAdminKpiDrilldown.profitMonth:
        return api.reportsProfitLossMonthly();
      case SuperAdminKpiDrilldown.expensesToday:
        return _fetchExpensesGroupedByRecentDays(api);
      case SuperAdminKpiDrilldown.expensesMonth:
        return _fetchLast12MonthsExpenses(api);
      case SuperAdminKpiDrilldown.salesMonth:
        return _fetchLast12MonthsSales(api);
    }
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
              return RefreshIndicator(
                onRefresh: () async {
                  final Future<Map<String, dynamic>> f = _fetch();
                  setState(() {
                    _load = f;
                  });
                  await f;
                },
                child: _ProfitDaysBody(data: data),
              );
            case SuperAdminKpiDrilldown.profitMonth:
              return RefreshIndicator(
                onRefresh: () async {
                  final Future<Map<String, dynamic>> f = _fetch();
                  setState(() {
                    _load = f;
                  });
                  await f;
                },
                child: _ProfitMonthsBody(data: data),
              );
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
