import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardCubit(sl<AmethystApi>())..load(),
      child: const _AdminDashboardBody(),
    );
  }
}

class _AdminDashboardBody extends StatelessWidget {
  const _AdminDashboardBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, DashboardLoadState>(
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
                  onPressed: () => context.read<AdminDashboardCubit>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final d = (state as DashboardLoadSuccess).data;
        final totalSales = _n(d['totalSalesToday']);
        final station = _n(d['stationSalesToday']);
        final vehicle = _n(d['vehicleSalesToday']);
        final returns = _n(d['returnedQuantitiesToday']);
        final monthly = _n(d['totalMonthlySales']);
        return RefreshIndicator(
          onRefresh: () => context.read<AdminDashboardCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                'Operations',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _chip(context, 'Sales today', totalSales.toStringAsFixed(0)),
                  _chip(context, 'Station', station.toStringAsFixed(0)),
                  _chip(context, 'Vehicle', vehicle.toStringAsFixed(0)),
                  _chip(context, 'Returns (qty)', returns.toStringAsFixed(0)),
                  _chip(context, 'Monthly sales', monthly.toStringAsFixed(0)),
                  _chip(
                    context,
                    'Active drivers',
                    '${d['activeDrivers'] ?? 0}',
                  ),
                  _chip(
                    context,
                    'Loads today',
                    '${d['vehiclesLoadedToday'] ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Remaining stock',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Station: ${_n(d['remainingStationStock']).toStringAsFixed(0)} · '
                'On vehicles: ${_n(d['remainingOnVehicles']).toStringAsFixed(0)}',
              ),
            ],
          ),
        );
      },
    );
  }

  double _n(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Widget _chip(BuildContext context, String label, String value) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
