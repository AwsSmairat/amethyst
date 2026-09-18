part of 'super_admin_kpi_drilldown_page.dart';


class _MonthlySalesBody extends StatelessWidget {
  const _MonthlySalesBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> months = _coerceMapRows(data['months']);
    if (months.isNotEmpty) {
      final DateTime n = DateTime.now();
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (BuildContext context, int i) {
          final Map<String, dynamic> row = months[i];
          final int y = (row['year'] as num?)?.toInt() ?? n.year;
          final int m = (row['month'] as num?)?.toInt() ?? n.month;
          final bool isCurrent = y == n.year && m == n.month;
          final ({int y, int m}) prev = _calendarPreviousMonth(n.year, n.month);
          final bool isImmediatePrevious =
              !isCurrent && y == prev.y && m == prev.m;
          return _MonthlySalesMonthCard(
            monthPayload: row,
            isCurrentCalendarMonth: isCurrent,
            isImmediatePreviousMonth: isImmediatePrevious,
          );
        },
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _MonthlySalesMonthCard(
          monthPayload: data,
          isCurrentCalendarMonth: true,
          isImmediatePreviousMonth: false,
        ),
      ],
    );
  }
}

class _MonthlySalesMonthCard extends StatelessWidget {
  const _MonthlySalesMonthCard({
    required this.monthPayload,
    required this.isCurrentCalendarMonth,
    required this.isImmediatePreviousMonth,
  });

  final Map<String, dynamic> monthPayload;
  final bool isCurrentCalendarMonth;
  final bool isImmediatePreviousMonth;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? totals = _tryCoerceMap(monthPayload['totals']);
    final double station = _toDouble(totals?['stationAmount']);
    final double vehicle = _toDouble(totals?['vehicleAmount']);
    final double combined = station + vehicle;
    final List<dynamic> stationRows = monthPayload['stationSales'] is List<dynamic>
        ? monthPayload['stationSales'] as List<dynamic>
        : <dynamic>[];
    final List<dynamic> vehicleRows = monthPayload['vehicleSales'] is List<dynamic>
        ? monthPayload['vehicleSales'] as List<dynamic>
        : <dynamic>[];
    final int y =
        (monthPayload['year'] as num?)?.toInt() ?? DateTime.now().year;
    final int m =
        (monthPayload['month'] as num?)?.toInt() ?? DateTime.now().month;
    final String locale = Localizations.localeOf(context).toString();
    final String periodTitle =
        DateFormat.yMMM(locale).format(DateTime(y, m, 1));
    final ThemeData theme = Theme.of(context);
    final Color fieldFill = theme.colorScheme.surface;

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: fieldFill,
          isDense: true,
        );

    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    key: ValueKey<String>('month_period_${y}_$m'),
                    readOnly: true,
                    initialValue: periodTitle,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: deco(context.l10n.monthYearPeriodLabel),
                  ),
                ),
                if (isCurrentCalendarMonth) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.currentCalendarMonthChip),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ] else if (isImmediatePreviousMonth) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.previousCalendarMonthChip),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey<String>('st_${y}_${m}_${station.toStringAsFixed(2)}'),
              readOnly: true,
              initialValue: station.toStringAsFixed(2),
              textAlign: TextAlign.end,
              decoration: deco(context.l10n.stationSales),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey<String>('vh_${y}_${m}_${vehicle.toStringAsFixed(2)}'),
              readOnly: true,
              initialValue: vehicle.toStringAsFixed(2),
              textAlign: TextAlign.end,
              decoration: deco(context.l10n.vehicleSales),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey<String>('tot_${y}_${m}_${combined.toStringAsFixed(2)}'),
              readOnly: true,
              initialValue: combined.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: deco(context.l10n.combinedTotalLabel),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.transactionsSummary(
                stationRows.length,
                vehicleRows.length,
              ),
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
