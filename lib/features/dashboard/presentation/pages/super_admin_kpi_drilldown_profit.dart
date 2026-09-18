part of 'super_admin_kpi_drilldown_page.dart';


class _ProfitDaysBody extends StatelessWidget {
  const _ProfitDaysBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> days =
        _coerceMapRows(data['profitDays']);
    if (days.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _ProfitDayCard(
            dayPayload: _profitDayFallbackPayload(data),
            isToday: true,
            isYesterday: false,
          ),
        ],
      );
    }

    final DateTime n = DateTime.now();
    final String todayYmd = _drilldownYmd(DateTime(n.year, n.month, n.day));
    final String yesterdayYmd = _drilldownYmd(
      DateTime(n.year, n.month, n.day).subtract(const Duration(days: 1)),
    );

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int i) {
        final Map<String, dynamic> row = days[i];
        final String dateStr = row['date']?.toString() ?? '';
        return _ProfitDayCard(
          dayPayload: row,
          isToday: dateStr == todayYmd,
          isYesterday: dateStr == yesterdayYmd,
        );
      },
    );
  }
}

class _ProfitDayCard extends StatelessWidget {
  const _ProfitDayCard({
    required this.dayPayload,
    required this.isToday,
    required this.isYesterday,
  });

  final Map<String, dynamic> dayPayload;
  final bool isToday;
  final bool isYesterday;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String dateStr = dayPayload['date']?.toString() ?? '';
    final DateTime? parsed = _parseYmdLocal(dateStr);
    final String locale = Localizations.localeOf(context).toString();
    final String periodTitle = parsed != null
        ? DateFormat.yMMMEd(locale).format(parsed)
        : dateStr;
    final ThemeData theme = Theme.of(context);

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
                  child: Text(
                    periodTitle,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isToday) ...<Widget>[
                  const SizedBox(width: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.success.withValues(alpha: 0.15),
                    label: Text(
                      l.sectionToday,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else if (isYesterday) ...<Widget>[
                  const SizedBox(width: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(l.yesterdayChip),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _ProfitBreakdownMetrics(
              payload: dayPayload,
              includeCashBalance: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitMonthsBody extends StatelessWidget {
  const _ProfitMonthsBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> months =
        _coerceMapRows(data['profitMonths']);
    if (months.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _ProfitMonthCard(
            monthPayload: _profitMonthFallbackPayload(data),
            isCurrentCalendarMonth: true,
            isImmediatePreviousMonth: false,
          ),
        ],
      );
    }

    final DateTime n = DateTime.now();
    final ({int y, int m}) prev = _calendarPreviousMonth(n.year, n.month);

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
        final bool isImmediatePrevious =
            !isCurrent && y == prev.y && m == prev.m;
        return _ProfitMonthCard(
          monthPayload: row,
          isCurrentCalendarMonth: isCurrent,
          isImmediatePreviousMonth: isImmediatePrevious,
        );
      },
    );
  }
}

class _ProfitMonthCard extends StatelessWidget {
  const _ProfitMonthCard({
    required this.monthPayload,
    required this.isCurrentCalendarMonth,
    required this.isImmediatePreviousMonth,
  });

  final Map<String, dynamic> monthPayload;
  final bool isCurrentCalendarMonth;
  final bool isImmediatePreviousMonth;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final int y =
        (monthPayload['year'] as num?)?.toInt() ?? DateTime.now().year;
    final int m =
        (monthPayload['month'] as num?)?.toInt() ?? DateTime.now().month;
    final String locale = Localizations.localeOf(context).toString();
    final String periodTitle =
        DateFormat.yMMM(locale).format(DateTime(y, m, 1));
    final ThemeData theme = Theme.of(context);

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
                  child: Text(
                    periodTitle,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isCurrentCalendarMonth) ...<Widget>[
                  const SizedBox(width: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.success.withValues(alpha: 0.15),
                    label: Text(
                      l.currentCalendarMonthChip,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ] else if (isImmediatePreviousMonth) ...<Widget>[
                  const SizedBox(width: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(l.previousCalendarMonthChip),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _ProfitBreakdownMetrics(
              payload: monthPayload,
              includeCashBalance: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitBreakdownMetrics extends StatelessWidget {
  const _ProfitBreakdownMetrics({
    required this.payload,
    required this.includeCashBalance,
  });

  final Map<String, dynamic> payload;
  final bool includeCashBalance;

  @override
  Widget build(BuildContext context) {
    final double stationSales = _toDouble(payload['stationSales']);
    final double stationExpenses = _toDouble(
      payload['stationExpenses'] ?? payload['expenses'],
    );
    final double stationCashBalance = _toDouble(payload['stationCashBalance']);
    final double stationNetTotal = payload['stationNetTotal'] != null
        ? _toDouble(payload['stationNetTotal'])
        : includeCashBalance
            ? stationSales - stationExpenses + stationCashBalance
            : stationSales - stationExpenses;
    final double total = _toDouble(payload['total']);
    final List<Map<String, dynamic>> vehicles =
        _profitVehicleRows(payload['vehicles']);
    final l = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProfitDetailRow(
          label: l.stationSales,
          value: stationSales,
          icon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 12),
        _ProfitDetailRow(
          label: l.profitTodayStationExpenses,
          value: stationExpenses,
          icon: Icons.payments_outlined,
        ),
        if (includeCashBalance) ...<Widget>[
          const SizedBox(height: 12),
          _ProfitDetailRow(
            label: l.profitTodayStationCashBalance,
            value: stationCashBalance,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
        const SizedBox(height: 12),
        _ProfitDetailRow(
          label: includeCashBalance
              ? l.profitTodayStationNetFormula
              : l.profitMonthStationNetFormula,
          value: stationNetTotal,
          icon: Icons.store_mall_directory_outlined,
          emphasize: true,
        ),
        for (final Map<String, dynamic> vehicle in vehicles) ...<Widget>[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _VehicleProfitBreakdown(
            vehicle: vehicle,
            includeCashBalance: includeCashBalance,
          ),
        ],
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        _ProfitDetailRow(
          label: l.profitTodayGrandTotalFormula,
          value: total,
          icon: Icons.savings_outlined,
          emphasize: true,
        ),
      ],
    );
  }
}

List<Map<String, dynamic>> _profitVehicleRows(Object? raw) =>
    _coerceMapRows(raw);

class _VehicleProfitBreakdown extends StatelessWidget {
  const _VehicleProfitBreakdown({
    required this.vehicle,
    required this.includeCashBalance,
  });

  final Map<String, dynamic> vehicle;
  final bool includeCashBalance;

  IconData _iconForVehicle(String vehicleNumber) {
    switch (vehicleSalesBucketForNumber(vehicleNumber)) {
      case VehicleSalesBucket.bus:
        return Icons.directions_bus_outlined;
      case VehicleSalesBucket.bingo:
        return Icons.local_shipping_outlined;
      case VehicleSalesBucket.other:
        return Icons.directions_car_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final String vehicleNumber = vehicle['vehicleNumber']?.toString() ?? '';
    final double sales = _toDouble(vehicle['sales']);
    final double expenses = _toDouble(vehicle['operatingExpenses']);
    final double cashBalance = _toDouble(vehicle['cashBalance']);
    final double netTotal = _toDouble(vehicle['netTotal']);
    final IconData icon = _iconForVehicle(vehicleNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProfitDetailRow(
          label: l.profitVehicleSales(vehicleNumber),
          value: sales,
          icon: icon,
        ),
        const SizedBox(height: 12),
        _ProfitDetailRow(
          label: l.profitVehicleOperatingExpenses(vehicleNumber),
          value: expenses,
          icon: Icons.payments_outlined,
        ),
        if (includeCashBalance) ...<Widget>[
          const SizedBox(height: 12),
          _ProfitDetailRow(
            label: l.profitVehicleCashBalance(vehicleNumber),
            value: cashBalance,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
        const SizedBox(height: 12),
        _ProfitDetailRow(
          label: includeCashBalance
              ? l.profitVehicleNetFormula(vehicleNumber)
              : l.profitMonthVehicleNetFormula(vehicleNumber),
          value: netTotal,
          icon: icon,
          emphasize: true,
        ),
      ],
    );
  }
}

class _ProfitDetailRow extends StatelessWidget {
  const _ProfitDetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(
          icon,
          color: AppColors.brandPrimary,
          size: emphasize ? 30 : 26,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(2),
                style: (emphasize
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
