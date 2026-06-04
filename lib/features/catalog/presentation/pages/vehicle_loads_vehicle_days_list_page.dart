import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_aggregates.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_batches.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// بعد اختيار مركبة: قائمة الأيام التي فيها تحميل؛ الضغط يفتح تفاصيل اليوم.
class VehicleLoadsVehicleDaysListPage extends StatefulWidget {
  const VehicleLoadsVehicleDaysListPage({
    super.key,
    required this.vehicleId,
    required this.shellBase,
    this.vehicleRow,
  });

  final String vehicleId;
  final String shellBase;
  final Map<String, dynamic>? vehicleRow;

  @override
  State<VehicleLoadsVehicleDaysListPage> createState() =>
      _VehicleLoadsVehicleDaysListPageState();
}

class _VehicleLoadsVehicleDaysListPageState
    extends State<VehicleLoadsVehicleDaysListPage> {
  bool _loading = true;
  String? _error;
  List<DateTime> _days = <DateTime>[];
  Map<DateTime, int> _batchCountByDay = <DateTime, int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AmethystApi api = sl<AmethystApi>();
      final Map<String, dynamic> res = await api.listVehicleLoads(
        vehicleId: widget.vehicleId,
        limit: 100,
      );
      final List<Map<String, dynamic>> items =
          (res['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      final Set<DateTime> daySet = <DateTime>{};
      final Map<DateTime, int> batchCounts = <DateTime, int>{};
      for (final Map<String, dynamic> item in items) {
        final DateTime? d = vehicleLoadCalendarDay(item);
        if (d == null) {
          continue;
        }
        final DateTime day = DateTime(d.year, d.month, d.day);
        daySet.add(day);
      }
      for (final DateTime day in daySet) {
        batchCounts[day] = vehicleLoadBatchCountForDay(
          loads: items,
          vehicleId: widget.vehicleId,
          day: day,
        );
      }
      final List<DateTime> days = daySet.toList()
        ..sort((DateTime a, DateTime b) => b.compareTo(a));
      if (!mounted) {
        return;
      }
      setState(() {
        _days = days;
        _batchCountByDay = batchCounts;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _ymd(DateTime d) {
    final String y = d.year.toString().padLeft(4, '0');
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _vehicleLabel() {
    final Object? n = widget.vehicleRow?['vehicleNumber'];
    if (n != null && n.toString().trim().isNotEmpty) {
      return n.toString().trim();
    }
    return widget.vehicleId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.vehicleLoadsDaysListTitle(_vehicleLabel()),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context, l10n, locale),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }
    if (_days.isEmpty) {
      return Center(child: Text(l10n.nothingHereYet));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _days.length,
      itemBuilder: (BuildContext context, int i) {
        final DateTime day = _days[i];
        final String primary = DateFormat.EEEE(locale).format(day);
        final String secondary = DateFormat.yMMMd(locale).format(day);
        final String dayKey = _ymd(day);
        final DateTime now = DateTime.now();
        final bool isToday = now.year == day.year &&
            now.month == day.month &&
            now.day == day.day;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(
              Icons.event_note_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              primary,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(secondary),
                if ((_batchCountByDay[day] ?? 0) > 0) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    l10n.vehicleLoadsDayBatchCountLine(
                      '${_batchCountByDay[day]}',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ],
            ),
            isThreeLine: (_batchCountByDay[day] ?? 0) > 0,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (isToday)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                const Icon(Icons.chevron_left),
              ],
            ),
            onTap: () {
              context.push(
                '${widget.shellBase}/vehicle-loads/${widget.vehicleId}/day/$dayKey',
                extra: widget.vehicleRow,
              );
            },
          ),
        );
      },
    );
  }
}
