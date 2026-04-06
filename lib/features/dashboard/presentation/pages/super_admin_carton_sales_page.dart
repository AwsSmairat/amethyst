import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_carton_sales_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// تفاصيل الكراتين: منزل = محطة+كل مبيعات الكراتين من السيارة؛ متجر = من السيارة للمتاجر فقط.
class SuperAdminCartonSalesPage extends StatelessWidget {
  const SuperAdminCartonSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SuperAdminCartonSalesCubit(sl<AmethystApi>())..load(),
      child: const _SuperAdminCartonSalesBody(),
    );
  }
}

class _SuperAdminCartonSalesBody extends StatelessWidget {
  const _SuperAdminCartonSalesBody();

  static bool _isViewingCurrentMonth(DateTime selectedMonth) {
    final DateTime n = DateTime.now();
    return selectedMonth.year == n.year && selectedMonth.month == n.month;
  }

  static bool _isViewingPreviousCalendarMonth(DateTime selectedMonth) {
    final DateTime n = DateTime.now();
    final DateTime prev = DateTime(n.year, n.month - 1);
    return selectedMonth.year == prev.year && selectedMonth.month == prev.month;
  }

  static Future<void> _pickCalendarMonth(BuildContext context) async {
    final SuperAdminCartonSalesCubit cubit =
        context.read<SuperAdminCartonSalesCubit>();
    final DateTime initial = cubit.selectedMonth;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month),
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      locale: const Locale('ar'),
    );
    if (picked == null || !context.mounted) return;
    await cubit.selectCalendarMonth(DateTime(picked.year, picked.month));
  }

  static DateTime _selectedMonthFrom(Map<String, dynamic> d) {
    final Object? y = d['_selectedYear'];
    final Object? m = d['_selectedMonth'];
    final int? year = y is int ? y : int.tryParse(y?.toString() ?? '');
    final int? month = m is int ? m : int.tryParse(m?.toString() ?? '');
    if (year != null && month != null && month >= 1 && month <= 12) {
      return DateTime(year, month);
    }
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month);
  }

  static String _formatInt(dynamic v) {
    final double n = _toDouble(v);
    return NumberFormat.decimalPattern('ar').format(n.round());
  }

  static String _formatPrice(dynamic v) {
    final double n = _toDouble(v);
    return NumberFormat.decimalPattern('ar').format(n);
  }

  static double _toDouble(dynamic v) {
    if (v == null) {
      return 0;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cartonSalesMonthly)),
      body: BlocBuilder<SuperAdminCartonSalesCubit, DashboardLoadState>(
        builder: (context, state) {
          if (state is DashboardLoadLoading || state is DashboardLoadInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardLoadFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<SuperAdminCartonSalesCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final Map<String, dynamic> d =
              (state as DashboardLoadSuccess).data;
          final DateTime selectedMonth = _selectedMonthFrom(d);
          final String monthLabel =
              DateFormat.yMMMM('ar').format(selectedMonth);
          return RefreshIndicator(
            onRefresh: () =>
                context.read<SuperAdminCartonSalesCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    InkWell(
                      onTap: () => _pickCalendarMonth(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${l10n.monthYearPeriodLabel}: $monthLabel',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.brandPrimary,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilterChip(
                          label: Text(l10n.currentCalendarMonthChip),
                          selected: _isViewingCurrentMonth(selectedMonth),
                          onSelected: (_) => context
                              .read<SuperAdminCartonSalesCubit>()
                              .selectCurrentMonth(),
                        ),
                        FilterChip(
                          label: Text(l10n.previousCalendarMonthChip),
                          selected: _isViewingPreviousCalendarMonth(
                            selectedMonth,
                          ),
                          onSelected: (_) => context
                              .read<SuperAdminCartonSalesCubit>()
                              .selectPreviousMonth(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  rows: <_InfoRow>[
                    _InfoRow(
                      label: l10n.cartonStockLabel,
                      value: _formatInt(d['cartonStock']),
                      icon: Icons.warehouse_outlined,
                    ),
                    _InfoRow(
                      label: '${l10n.cartonMonthlyExpensesLabel} ($monthLabel)',
                      value: _formatPrice(d['monthlyCartonExpensesTotalAmount']),
                      icon: Icons.receipt_long_outlined,
                    ),
                    _InfoRow(
                      label: '${l10n.cartonPriceLabel} ($monthLabel)',
                      value: _formatPrice(d['monthlyCartonSalesTotalAmount']),
                      icon: Icons.payments_outlined,
                    ),
                    _InfoRow(
                      label: l10n.cartonSalesHomeLabel,
                      value: _formatInt(d['monthlyCartonSalesHomeQty']),
                      icon: Icons.home_work_outlined,
                    ),
                    _InfoRow(
                      label: l10n.cartonSalesStoreLabel,
                      value: _formatInt(d['monthlyCartonSalesStoreQty']),
                      icon: Icons.storefront_outlined,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: <Widget>[
                  Icon(rows[i].icon, color: AppColors.brandPrimary, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
