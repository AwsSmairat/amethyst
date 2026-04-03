import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SuperAdminDashboardPage extends StatelessWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuperAdminDashboardCubit(sl<AmethystApi>())..load(),
      child: const _SuperAdminDashboardBody(),
    );
  }
}

class _SuperAdminDashboardBody extends StatelessWidget {
  const _SuperAdminDashboardBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuperAdminDashboardCubit, DashboardLoadState>(
      builder: (context, state) {
        if (state is DashboardLoadLoading || state is DashboardLoadInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardLoadFailure) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      context.read<SuperAdminDashboardCubit>().load(),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          );
        }
        final d = (state as DashboardLoadSuccess).data;
        final salesToday = _num(d['totalSalesToday']);
        final profit = _num(d['totalProfitToday']);
        final expenses = _num(d['totalExpensesToday']);
        final monthlyExpenses = _num(d['totalMonthlyExpenses']);
        final monthly = _num(d['totalMonthlySales']);
        final l10n = context.l10n;
        return RefreshIndicator(
          onRefresh: () => context.read<SuperAdminDashboardCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                l10n.overview,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              _KpiGrid(
                children: <Widget>[
                  _KpiCard(
                    label: l10n.kpiUsers,
                    value: '${d['totalUsers'] ?? 0}',
                    icon: Icons.people,
                    onTap: () => context.push('/super-admin/users'),
                  ),
                  _KpiCard(
                    label: l10n.kpiAdmins,
                    value: '${d['totalAdmins'] ?? 0}',
                    icon: Icons.admin_panel_settings,
                  ),
                  _KpiCard(
                    label: l10n.kpiProductPrices,
                    value:
                        '${d['productsWithPrice'] ?? d['totalProducts'] ?? 0}',
                    icon: Icons.price_change_outlined,
                    onTap: () => context.push('/super-admin/product-prices'),
                  ),
                  _KpiCard(
                    label: l10n.kpiDrivers,
                    value: '${d['totalDrivers'] ?? 0}',
                    icon: Icons.drive_eta,
                    onTap: () => context.push('/super-admin/drivers'),
                  ),
                  _KpiCard(
                    label: l10n.kpiVehicles,
                    value: '${d['totalVehicles'] ?? 0}',
                    icon: Icons.local_shipping,
                    onTap: () => context.push('/super-admin/vehicles'),
                  ),
                  _KpiCard(
                    label: l10n.salesToday,
                    value: salesToday.toStringAsFixed(0),
                    icon: Icons.trending_up,
                    onTap: () =>
                        context.push('/super-admin/sales-working-days'),
                  ),
                  _KpiCard(
                    label: l10n.profitToday,
                    value: profit.toStringAsFixed(0),
                    icon: Icons.savings,
                    onTap: () => context.push('/super-admin/kpi/profit-today'),
                  ),
                  _KpiCard(
                    label: l10n.expensesToday,
                    value: expenses.toStringAsFixed(0),
                    icon: Icons.payments,
                    onTap: () =>
                        context.push('/super-admin/kpi/expenses-today'),
                  ),
                  _KpiCard(
                    label: l10n.monthlyExpenses,
                    value: monthlyExpenses.toStringAsFixed(0),
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () =>
                        context.push('/super-admin/kpi/expenses-month'),
                  ),
                  _KpiCard(
                    label: l10n.monthlySales,
                    value: monthly.toStringAsFixed(0),
                    icon: Icons.calendar_month,
                    onTap: () => context.push('/super-admin/kpi/sales-month'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.stockSnapshot,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.stockLine(
                  _num(d['remainingStationStock']).toStringAsFixed(0),
                  _num(d['remainingOnVehicles']).toStringAsFixed(0),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        );
      },
    );
  }

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cross = w > 900 ? 4 : (w > 600 ? 2 : 1);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map(
                (c) =>
                    SizedBox(width: (w - 12 * (cross - 1)) / cross, child: c),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.brandPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
        ],
      ),
    );
    return Card(
      clipBehavior: onTap != null ? Clip.antiAlias : Clip.none,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
