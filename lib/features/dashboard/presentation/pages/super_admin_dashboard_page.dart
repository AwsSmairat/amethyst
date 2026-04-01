import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                  onPressed: () => context.read<SuperAdminDashboardCubit>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final d = (state as DashboardLoadSuccess).data;
        final salesToday = _num(d['totalSalesToday']);
        final profit = _num(d['totalProfitToday']);
        final expenses = _num(d['totalExpensesToday']);
        final monthly = _num(d['totalMonthlySales']);
        return RefreshIndicator(
          onRefresh: () => context.read<SuperAdminDashboardCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
              ),
              const SizedBox(height: 16),
              _KpiGrid(
                children: <Widget>[
                  _KpiCard(
                    label: 'Users',
                    value: '${d['totalUsers'] ?? 0}',
                    icon: Icons.people,
                  ),
                  _KpiCard(
                    label: 'Admins',
                    value: '${d['totalAdmins'] ?? 0}',
                    icon: Icons.admin_panel_settings,
                  ),
                  _KpiCard(
                    label: 'Drivers',
                    value: '${d['totalDrivers'] ?? 0}',
                    icon: Icons.drive_eta,
                  ),
                  _KpiCard(
                    label: 'Vehicles',
                    value: '${d['totalVehicles'] ?? 0}',
                    icon: Icons.local_shipping,
                  ),
                  _KpiCard(
                    label: 'Sales today',
                    value: salesToday.toStringAsFixed(0),
                    icon: Icons.trending_up,
                  ),
                  _KpiCard(
                    label: 'Profit today',
                    value: profit.toStringAsFixed(0),
                    icon: Icons.savings,
                  ),
                  _KpiCard(
                    label: 'Expenses today',
                    value: expenses.toStringAsFixed(0),
                    icon: Icons.payments,
                  ),
                  _KpiCard(
                    label: 'Monthly sales',
                    value: monthly.toStringAsFixed(0),
                    icon: Icons.calendar_month,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Stock snapshot',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Station: ${_num(d['remainingStationStock']).toStringAsFixed(0)} · '
                'On vehicles: ${_num(d['remainingOnVehicles']).toStringAsFixed(0)}',
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
                (c) => SizedBox(
                  width: (w - 12 * (cross - 1)) / cross,
                  child: c,
                ),
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
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppColors.primaryContainer),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
