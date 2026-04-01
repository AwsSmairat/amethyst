import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/vehicle_loads_export.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// قائمة تحميلات المركبات مجمّعة حسب **اليوم**: حقل واحد لكل يوم (عنوان: اسم اليوم + التاريخ).
class VehicleLoadsListPage extends StatelessWidget {
  const VehicleLoadsListPage({
    super.key,
    required this.title,
    this.fab,
  });

  final String title;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final double bottomPad = fab != null ? 88 : 16;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.exportVehicleLoads,
            onPressed: () async {
              final ListLoadState s = context.read<JsonListCubit>().state;
              if (s is! ListLoadLoaded) return;
              await shareTodaysVehicleLoads(context, s.items);
            },
            icon: const Icon(Icons.save_alt_outlined),
          ),
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
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final List<Map<String, dynamic>> items =
              (state as ListLoadLoaded).items;
          if (items.isEmpty) {
            return Center(child: Text(context.l10n.nothingHereYet));
          }
          final List<_DayGroup> groups = _groupByLoadDay(items);
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
            itemCount: groups.length,
            itemBuilder: (BuildContext context, int i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VehicleLoadsDayCard(group: groups[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _DayGroup {
  const _DayGroup({required this.day, required this.loads});

  /// يوم التحميل (منتصف الليل المحلي) أو `null` إن لم يُعرف التاريخ.
  final DateTime? day;
  final List<Map<String, dynamic>> loads;
}

List<_DayGroup> _groupByLoadDay(List<Map<String, dynamic>> items) {
  final Map<DateTime, List<Map<String, dynamic>>> byDay =
      <DateTime, List<Map<String, dynamic>>>{};
  final List<Map<String, dynamic>> unknown = <Map<String, dynamic>>[];

  for (final Map<String, dynamic> item in items) {
    final DateTime? d = _parseDate(item['loadDate']);
    if (d == null) {
      unknown.add(item);
      continue;
    }
    final DateTime day = DateTime(d.year, d.month, d.day);
    byDay.putIfAbsent(day, () => <Map<String, dynamic>>[]).add(item);
  }

  final List<_DayGroup> out = byDay.entries
      .map(
        (MapEntry<DateTime, List<Map<String, dynamic>>> e) =>
            _DayGroup(day: e.key, loads: e.value),
      )
      .toList()
    ..sort((_DayGroup a, _DayGroup b) => b.day!.compareTo(a.day!));

  if (unknown.isNotEmpty) {
    out.add(_DayGroup(day: null, loads: unknown));
  }
  return out;
}

class _VehicleLoadsDayCard extends StatelessWidget {
  const _VehicleLoadsDayCard({required this.group});

  final _DayGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final DateTime? day = group.day;
    final bool isToday = day != null && _isSameDay(day, DateTime.now());

    String headerPrimary;
    String? headerSecondary;
    if (day != null) {
      headerPrimary = DateFormat.EEEE(locale).format(day);
      headerSecondary = DateFormat.yMMMd(locale).format(day);
    } else {
      headerPrimary = l10n.loadDate;
      headerSecondary = '—';
    }

    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsetsDirectional.only(
            start: 12,
            end: 8,
            top: 8,
            bottom: 8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.primary,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      headerPrimary,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      headerSecondary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.sectionToday,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          children: _interleavedLines(context, group.loads),
        ),
      ),
    );
  }
}

List<Widget> _interleavedLines(
  BuildContext context,
  List<Map<String, dynamic>> loads,
) {
  final List<Widget> w = <Widget>[];
  for (var i = 0; i < loads.length; i++) {
    w.add(_VehicleLoadLine(item: loads[i]));
    if (i < loads.length - 1) {
      w.add(const Divider(height: 24));
    }
  }
  return w;
}

/// صف منتج واحد داخل مجموعة اليوم (بدون تكرار التاريخ).
class _VehicleLoadLine extends StatelessWidget {
  const _VehicleLoadLine({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final String productTitle = _nestedString(item['product'], 'name');
    final String vehicleNo = _nestedString(item['vehicle'], 'vehicleNumber');
    final String driverName = _nestedString(item['driver'], 'fullName');
    final String statusRaw = item['status']?.toString() ?? '';
    final String statusAr = _statusLabel(context, statusRaw);
    final dynamic qty = item['quantityLoaded'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          productTitle.isNotEmpty ? productTitle : l10n.product,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        if (vehicleNo.isNotEmpty || driverName.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            <String>[
              if (vehicleNo.isNotEmpty) l10n.vehicleWithNumber(vehicleNo),
              if (driverName.isNotEmpty) driverName,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _StatusChip(label: statusAr),
            const Spacer(),
            Text(
              '${l10n.quantity}: $qty',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

String _nestedString(dynamic obj, String key) {
  if (obj is Map<String, dynamic>) {
    return obj[key]?.toString() ?? '';
  }
  if (obj is Map) {
    return obj[key]?.toString() ?? '';
  }
  return '';
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _statusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status.toLowerCase()) {
    case 'open':
      return l10n.loadStatusOpen;
    case 'closed':
      return l10n.loadStatusClosed;
    default:
      return status;
  }
}
