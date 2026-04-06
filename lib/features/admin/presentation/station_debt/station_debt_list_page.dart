import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_api_error.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// قائمة أسماء المدينين؛ الضغط يفتح تفاصيل المنتجات لكل اسم.
class StationDebtListPage extends StatelessWidget {
  const StationDebtListPage({super.key});

  static const String _extraDebtorName = 'debtorName';
  static const String _extraEntries = 'entries';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider<JsonListCubit>(
      create: (_) => JsonListCubit(
        () => sl<AmethystApi>().listStationDebtEntries(),
        mapLoadError: mapStationDebtListLoadError,
      )..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.titleStationDebtList),
          actions: <Widget>[
            IconButton(
              onPressed: () => context.read<JsonListCubit>().load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: BlocBuilder<JsonListCubit, ListLoadState>(
          builder: (BuildContext context, ListLoadState state) {
            if (state is ListLoadLoading || state is ListLoadInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ListLoadFailure) {
              final String raw = state.message;
              final String display = _failureDisplayMessage(context, raw);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(display, textAlign: TextAlign.center),
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
            final List<_DebtorGroup> groups = _groupByDebtorName(items);
            if (groups.isEmpty) {
              return Center(child: Text(l10n.nothingHereYet));
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int i) {
                final _DebtorGroup g = groups[i];
                return ListTile(
                  title: Text(
                    g.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    l10n.stationDebtDebtorLineCount(g.entries.length),
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () async {
                    final bool? done = await context.push<bool>(
                      '/admin/station-debt-list/debtor',
                      extra: <String, dynamic>{
                        _extraDebtorName: g.name,
                        _extraEntries: g.entries,
                      },
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (done == true) {
                      context.read<JsonListCubit>().load();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _failureDisplayMessage(BuildContext context, String raw) {
    if (raw == kStationDebtApiRouteMissingMarker) {
      return context.l10n.stationDebtErrorApiRouteMissing;
    }
    if (raw == kStationDebtInsufficientStockSubmitMarker) {
      return context.l10n.stationSaleSubmitInsufficientStock;
    }
    return raw;
  }
}

final class _DebtorGroup {
  const _DebtorGroup({
    required this.name,
    required this.entries,
    this.latestAt,
  });

  final String name;
  final List<Map<String, dynamic>> entries;
  final DateTime? latestAt;
}

List<_DebtorGroup> _groupByDebtorName(List<Map<String, dynamic>> items) {
  final Map<String, List<Map<String, dynamic>>> byName =
      <String, List<Map<String, dynamic>>>{};
  for (final Map<String, dynamic> e in items) {
    final String key = (e['debtorName']?.toString() ?? '').trim();
    if (key.isEmpty) {
      continue;
    }
    byName.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(e);
  }
  final List<_DebtorGroup> groups = byName.entries.map((
    MapEntry<String, List<Map<String, dynamic>>> entry,
  ) {
    DateTime? latest;
    for (final Map<String, dynamic> x in entry.value) {
      final DateTime? d = DateTime.tryParse(x['createdAt']?.toString() ?? '');
      if (d != null && (latest == null || d.isAfter(latest))) {
        latest = d;
      }
    }
    return _DebtorGroup(
      name: entry.key,
      entries: entry.value,
      latestAt: latest,
    );
  }).toList();
  groups.sort((_DebtorGroup a, _DebtorGroup b) {
    if (a.latestAt == null && b.latestAt == null) {
      return a.name.compareTo(b.name);
    }
    if (a.latestAt == null) {
      return 1;
    }
    if (b.latestAt == null) {
      return -1;
    }
    return b.latestAt!.compareTo(a.latestAt!);
  });
  return groups;
}
