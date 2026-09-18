part of 'super_admin_kpi_drilldown_page.dart';

String _expenseLineSubtitle(Map<String, dynamic> m, AppLocalizations l10n) {
  final Map<String, dynamic>? driver = m['driver'] is Map<String, dynamic>
      ? m['driver'] as Map<String, dynamic>
      : null;
  final String driverName = driver?['fullName']?.toString() ?? '—';
  final String? note = m['note']?.toString();
  final String? created = m['createdAt']?.toString();
  DateTime? at;
  if (created != null) {
    try {
      at = DateTime.parse(created);
    } on Object {
      at = null;
    }
  }
  String subtitle = driverName;
  if (note != null && note.isNotEmpty) {
    subtitle =
        '$subtitle · ${expenseNoteArabicDisplayLabel(note, l10n)}';
  }
  if (at != null) {
    subtitle = '$subtitle · ${DateFormat.Hm().format(at)}';
  }
  return subtitle;
}

class _DailyExpensesBody extends StatelessWidget {
  const _DailyExpensesBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> days =
        _coerceMapRows(data['expenseDays']);
    if (days.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text(context.l10n.noExpensesPeriod)),
          ),
        ],
      );
    }
    final DateTime n = DateTime.now();
    final DateTime todayDate = DateTime(n.year, n.month, n.day);
    final String todayYmd = _drilldownYmd(todayDate);
    final String yesterdayYmd =
        _drilldownYmd(todayDate.subtract(const Duration(days: 1)));

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int i) {
        final Map<String, dynamic> row = days[i];
        final String dateStr = row['date']?.toString() ?? '';
        final List<Map<String, dynamic>> items =
            _coerceMapRows(row['items']);
        final bool isToday = dateStr == todayYmd;
        final bool isYesterday = dateStr == yesterdayYmd;
        return _DailyExpensesDayCard(
          dateYmd: dateStr,
          items: items,
          isToday: isToday,
          isYesterday: isYesterday,
        );
      },
    );
  }
}

class _DailyExpensesDayCard extends StatelessWidget {
  const _DailyExpensesDayCard({
    required this.dateYmd,
    required this.items,
    required this.isToday,
    required this.isYesterday,
  });

  final String dateYmd;
  final List<Map<String, dynamic>> items;
  final bool isToday;
  final bool isYesterday;

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final Map<String, dynamic> m in items) {
      total += _toDouble(m['amount']);
    }
    final DateTime? parsed = _parseYmdLocal(dateYmd);
    final String locale = Localizations.localeOf(context).toString();
    final String periodTitle = parsed != null
        ? DateFormat.yMMMEd(locale).format(parsed)
        : dateYmd;
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
                    key: ValueKey<String>('exp_day_$dateYmd'),
                    readOnly: true,
                    initialValue: periodTitle,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: deco(context.l10n.expenseDayDateLabel),
                  ),
                ),
                if (isToday) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.sectionToday),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ] else if (isYesterday) ...<Widget>[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(context.l10n.yesterdayChip),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey<String>('exp_day_tot_${dateYmd}_${total.toStringAsFixed(2)}'),
              readOnly: true,
              initialValue: total.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: deco(context.l10n.expenseDayTotalLabel),
            ),
            if (items.isEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                context.l10n.noExpensesThisDay,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 16),
              Text(
                context.l10n.expenseLinesSection,
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...List<Widget>.generate(items.length, (int i) {
                final Map<String, dynamic> m = items[i];
                final double amount = _toDouble(m['amount']);
                final String id =
                    m['id']?.toString() ?? '${dateYmd}_$i';
                final String label = _expenseLineSubtitle(m, context.l10n);
                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                  child: TextFormField(
                    key: ValueKey<String>('exp_day_line_${id}_$amount'),
                    readOnly: true,
                    initialValue: amount.toStringAsFixed(2),
                    textAlign: TextAlign.end,
                    decoration: deco(label),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

DateTime? _parseYmdLocal(String ymd) {
  final List<String> p = ymd.split('-');
  if (p.length != 3) {
    return null;
  }
  final int? y = int.tryParse(p[0]);
  final int? m = int.tryParse(p[1]);
  final int? d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) {
    return null;
  }
  return DateTime(y, m, d);
}

class _MonthlyExpensesBody extends StatelessWidget {
  const _MonthlyExpensesBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> months =
        _coerceMapRows(data['expenseMonths']);
    if (months.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[SizedBox(height: 1)],
      );
    }
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
        final List<Map<String, dynamic>> items =
            _coerceMapRows(row['items']);
        return _MonthlyExpensesMonthCard(
          year: y,
          month: m,
          items: items,
          isCurrentCalendarMonth: isCurrent,
          isImmediatePreviousMonth: isImmediatePrevious,
        );
      },
    );
  }
}

class _MonthlyExpensesMonthCard extends StatelessWidget {
  const _MonthlyExpensesMonthCard({
    required this.year,
    required this.month,
    required this.items,
    required this.isCurrentCalendarMonth,
    required this.isImmediatePreviousMonth,
  });

  final int year;
  final int month;
  final List<Map<String, dynamic>> items;
  final bool isCurrentCalendarMonth;
  final bool isImmediatePreviousMonth;

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final Map<String, dynamic> m in items) {
      total += _toDouble(m['amount']);
    }
    final String locale = Localizations.localeOf(context).toString();
    final String periodTitle =
        DateFormat.yMMM(locale).format(DateTime(year, month, 1));
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
                    key: ValueKey<String>('exp_month_period_${year}_$month'),
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
              key: ValueKey<String>(
                'exp_month_tot_${year}_${month}_${total.toStringAsFixed(2)}',
              ),
              readOnly: true,
              initialValue: total.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: deco(context.l10n.monthlyExpensesTotalLabel),
            ),
            if (items.isEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                context.l10n.noExpensesThisMonth,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 16),
              Text(
                context.l10n.expenseLinesSection,
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...List<Widget>.generate(items.length, (int i) {
                final Map<String, dynamic> m = items[i];
                final double amount = _toDouble(m['amount']);
                final String id =
                    m['id']?.toString() ?? '${year}_${month}_$i';
                final String label = _expenseLineSubtitle(m, context.l10n);
                return Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                  child: TextFormField(
                    key: ValueKey<String>('exp_line_${id}_$amount'),
                    readOnly: true,
                    initialValue: amount.toStringAsFixed(2),
                    textAlign: TextAlign.end,
                    decoration: deco(label),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
