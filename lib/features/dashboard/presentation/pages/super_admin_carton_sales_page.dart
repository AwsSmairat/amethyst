import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_carton_sales_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// تفاصيل الكراتين: مخزون المحطة، السعر المرجعي، مبيعات الشهر (متجر / منزل).
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
          return RefreshIndicator(
            onRefresh: () =>
                context.read<SuperAdminCartonSalesCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                _InfoCard(
                  rows: <_InfoRow>[
                    _InfoRow(
                      label: l10n.cartonStockLabel,
                      value: _formatInt(d['cartonStock']),
                      icon: Icons.warehouse_outlined,
                    ),
                    _InfoRow(
                      label: l10n.cartonPriceLabel,
                      value: _formatPrice(d['cartonUnitPrice']),
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
