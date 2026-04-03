import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_vehicles_cubit.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/add_super_admin_vehicle_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SuperAdminVehiclesPage extends StatelessWidget {
  const SuperAdminVehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuperAdminVehiclesCubit(sl<AmethystApi>())..load(),
      child: const _SuperAdminVehiclesBody(),
    );
  }
}

class _SuperAdminVehiclesBody extends StatelessWidget {
  const _SuperAdminVehiclesBody();

  Future<void> _confirmDelete(
    BuildContext context,
    SuperAdminVehiclesCubit cubit,
    Map<String, dynamic> v,
  ) async {
    final l10n = context.l10n;
    final String? id = v['id']?.toString();
    final String name =
        v['vehicleNumber']?.toString() ?? id ?? '';
    if (id == null) {
      return;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.deleteVehicleConfirmTitle),
        content: Text(l10n.deleteVehicleConfirmBody(name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteVehicle),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final String? err = await cubit.deleteVehicle(id);
    if (!context.mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.vehicleDeleted)),
      );
    }
  }

  String _subtitle(BuildContext context, Map<String, dynamic> v) {
    final l10n = context.l10n;
    final Object? driver = v['driver'];
    if (driver is Map<String, dynamic>) {
      final String n = driver['fullName']?.toString() ?? '';
      if (n.isNotEmpty) {
        return '${l10n.driverAssigned}: $n';
      }
    }
    return l10n.noDriver;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleVehicles),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => context.read<SuperAdminVehiclesCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddSuperAdminVehicleSheet(context),
        icon: const Icon(Icons.add_road),
        label: Text(l10n.addVehicle),
      ),
      body: BlocBuilder<SuperAdminVehiclesCubit, ListLoadState>(
        builder: (BuildContext context, ListLoadState state) {
          if (state is ListLoadLoading || state is ListLoadInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ListLoadFailure) {
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
                          context.read<SuperAdminVehiclesCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = (state as ListLoadLoaded).items;
          if (items.isEmpty) {
            return Center(child: Text(l10n.nothingHereYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              final Map<String, dynamic> v = items[i];
              final String title =
                  v['vehicleNumber']?.toString() ?? v['id']?.toString() ?? '';
              return ListTile(
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _subtitle(context, v),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                trailing: IconButton(
                  tooltip: l10n.deleteVehicle,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _confirmDelete(
                    context,
                    context.read<SuperAdminVehiclesCubit>(),
                    v,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
