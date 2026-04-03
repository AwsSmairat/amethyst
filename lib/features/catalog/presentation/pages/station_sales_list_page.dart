import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// مبيعات المحطة مجمّعة حسب **يوم تاريخ العملية** (`createdAt`) — نفس أسلوب تحميلات المركبات.
class StationSalesListPage extends StatelessWidget {
  const StationSalesListPage({
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
          final List<_StationSalesDayGroup> groups =
              _groupBySaleDay(items);
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
            itemCount: groups.length,
            itemBuilder: (BuildContext context, int i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StationSalesDayCard(group: groups[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _StationSalesDayGroup {
  const _StationSalesDayGroup({required this.day, required this.sales});

  final DateTime? day;
  final List<Map<String, dynamic>> sales;
}

List<_StationSalesDayGroup> _groupBySaleDay(
  List<Map<String, dynamic>> items,
) {
  final Map<DateTime, List<Map<String, dynamic>>> byDay =
      <DateTime, List<Map<String, dynamic>>>{};
  final List<Map<String, dynamic>> unknown = <Map<String, dynamic>>[];

  for (final Map<String, dynamic> item in items) {
    final DateTime? d = _parseDate(item['createdAt']);
    if (d == null) {
      unknown.add(item);
      continue;
    }
    final DateTime day = DateTime(d.year, d.month, d.day);
    byDay.putIfAbsent(day, () => <Map<String, dynamic>>[]).add(item);
  }

  final List<_StationSalesDayGroup> out = byDay.entries
      .map(
        (MapEntry<DateTime, List<Map<String, dynamic>>> e) =>
            _StationSalesDayGroup(day: e.key, sales: e.value),
      )
      .toList()
    ..sort(
      (_StationSalesDayGroup a, _StationSalesDayGroup b) =>
          b.day!.compareTo(a.day!),
    );

  if (unknown.isNotEmpty) {
    out.add(_StationSalesDayGroup(day: null, sales: unknown));
  }
  return out;
}

class _StationSalesDayCard extends StatelessWidget {
  const _StationSalesDayCard({required this.group});

  final _StationSalesDayGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final DateTime? day = group.day;
    final bool isToday = day != null && _isSameDay(day, DateTime.now());

    final String headerPrimary;
    final String headerSecondary;
    if (day != null) {
      headerPrimary = DateFormat.EEEE(locale).format(day);
      headerSecondary = DateFormat.yMMMd(locale).format(day);
    } else {
      headerPrimary = l10n.operationDateLabel;
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
          children: _interleavedSaleLines(context, group.sales),
        ),
      ),
    );
  }
}

List<Widget> _interleavedSaleLines(
  BuildContext context,
  List<Map<String, dynamic>> sales,
) {
  final List<Widget> w = <Widget>[];
  for (var i = 0; i < sales.length; i++) {
    w.add(_StationSaleLine(item: sales[i]));
    if (i < sales.length - 1) {
      w.add(const Divider(height: 24));
    }
  }
  return w;
}

class _StationSaleLine extends StatelessWidget {
  const _StationSaleLine({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final String productTitle = _nestedString(item['product'], 'name');
    final String seller = _nestedString(item['soldBy'], 'fullName');
    final dynamic qty = item['quantity'];
    final String unitStr = _formatMoney(item['unitPrice']);
    final String totalStr = _formatMoney(item['totalAmount']);
    String note = item['note']?.toString().trim() ?? '';
    if (note.isEmpty) {
      final double? up = _parseMoneyAmount(item['unitPrice']);
      if (up != null && up == 0) {
        note = context.l10n.couponButton;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                productTitle.isNotEmpty ? productTitle : l10n.product,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            if (note.isNotEmpty) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                note,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        if (seller.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            '${l10n.sellerLabel}: $seller',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                '${l10n.quantity}: $qty',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${l10n.unitPrice}: $unitStr',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${l10n.totalAmountLabel}: $totalStr',
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
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

String _formatMoney(dynamic v) {
  if (v == null) return '—';
  if (v is num) return v.toStringAsFixed(2);
  final double? d = double.tryParse(v.toString());
  return d != null ? d.toStringAsFixed(2) : v.toString();
}

double? _parseMoneyAmount(dynamic v) {
  if (v == null) {
    return null;
  }
  if (v is num) {
    return v.toDouble();
  }
  return double.tryParse(v.toString());
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
