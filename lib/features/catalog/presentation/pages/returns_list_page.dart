import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:amethyst/features/catalog/presentation/widgets/return_entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// قائمة المرتجعات للإدارة — عرض تفصيلي بدل معرّفات خام.
class ReturnsListPage extends StatelessWidget {
  const ReturnsListPage({super.key});

  DateTime? _parseDate(Object? v) {
    if (v == null) {
      return null;
    }
    if (v is DateTime) {
      return v;
    }
    return DateTime.tryParse(v.toString());
  }

  DateTime? _dayKey(DateTime? dt) {
    if (dt == null) {
      return null;
    }
    return DateTime(dt.year, dt.month, dt.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleReturns),
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
              List<Map<String, dynamic>>.from(
            (state as ListLoadLoaded).items,
          );
          if (items.isEmpty) {
            return Center(child: Text(l10n.nothingHereYet));
          }

          items.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
            final DateTime? da = _parseDate(a['createdAt']);
            final DateTime? db = _parseDate(b['createdAt']);
            if (da == null && db == null) {
              return 0;
            }
            if (da == null) {
              return 1;
            }
            if (db == null) {
              return -1;
            }
            return db.compareTo(da);
          });

          final String locale = Localizations.localeOf(context).toString();
          final DateFormat dateFmt = DateFormat.yMMMMd(locale);
          final Map<DateTime?, List<Map<String, dynamic>>> grouped =
              <DateTime?, List<Map<String, dynamic>>>{};
          for (final Map<String, dynamic> row in items) {
            final DateTime? key = _dayKey(_parseDate(row['createdAt']));
            (grouped[key] ??= <Map<String, dynamic>>[]).add(row);
          }
          final List<DateTime?> keys = grouped.keys.toList(growable: false)
            ..sort((DateTime? a, DateTime? b) {
              if (a == null && b == null) {
                return 0;
              }
              if (a == null) {
                return 1;
              }
              if (b == null) {
                return -1;
              }
              return b.compareTo(a);
            });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (BuildContext context, int sectionIndex) {
              final DateTime? day = keys[sectionIndex];
              final String dayLabel = day == null ? '—' : dateFmt.format(day);
              final List<Map<String, dynamic>> dayItems =
                  grouped[day] ?? const <Map<String, dynamic>>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 8),
                    child: Text(
                      dayLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandPrimary,
                          ),
                    ),
                  ),
                  ...dayItems.map(
                    (Map<String, dynamic> row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReturnEntryTile(item: row),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
