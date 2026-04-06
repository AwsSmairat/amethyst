import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// قائمة المركبات؛ الضغط يفتح تحميلات تلك المركبة لليوم المحدد.
class VehicleLoadsHubPage extends StatelessWidget {
  const VehicleLoadsHubPage({
    super.key,
    required this.shellBase,
    this.fab,
  });

  /// `/super-admin` أو `/admin`
  final String shellBase;

  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          JsonListCubit(() => sl<AmethystApi>().listVehicles())..load(),
      child: _VehicleLoadsHubBody(shellBase: shellBase, fab: fab),
    );
  }
}

class _VehicleLoadsHubBody extends StatelessWidget {
  const _VehicleLoadsHubBody({
    required this.shellBase,
    this.fab,
  });

  final String shellBase;
  final Widget? fab;

  String? _driverSubtitle(BuildContext context, Map<String, dynamic> v) {
    final l10n = context.l10n;
    final Object? driver = v['driver'];
    if (driver is Map<String, dynamic>) {
      final String n = driver['fullName']?.toString() ?? '';
      if (n.isNotEmpty) {
        return '${l10n.driverAssigned}: $n';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double bottomPad = fab != null ? 88 : 24;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleVehicleLoads),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.read<JsonListCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: fab,
      body: BlocBuilder<JsonListCubit, ListLoadState>(
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
                      onPressed: () => context.read<JsonListCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final List<Map<String, dynamic>> items =
              (state as ListLoadLoaded).items;
          if (items.isEmpty) {
            return Center(child: Text(l10n.nothingHereYet));
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPad),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  l10n.vehicleLoadsChooseVehicleHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              ...List<Widget>.generate(items.length, (int i) {
                final Map<String, dynamic> v = items[i];
                final String id = v['id']?.toString() ?? '';
                final String title =
                    v['vehicleNumber']?.toString().trim().isNotEmpty == true
                        ? v['vehicleNumber'].toString().trim()
                        : id;
                final String? sub = _driverSubtitle(context, v);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: sub != null && sub.isNotEmpty
                        ? Text(sub)
                        : null,
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      if (id.isEmpty) {
                        return;
                      }
                      context.push('$shellBase/vehicle-loads/$id', extra: v);
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
