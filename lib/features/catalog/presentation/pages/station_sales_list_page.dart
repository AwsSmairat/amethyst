import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/expenses/expense_aggregates.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sale_payment_method.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/catalog/presentation/cubit/station_sales_list_cubit.dart';
import 'package:amethyst/features/catalog/presentation/widgets/product_sales_day_summary.dart';
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
            onPressed: () => context.read<StationSalesListCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: fab,
      body: BlocBuilder<StationSalesListCubit, ListLoadState>(
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
                          context.read<StationSalesListCubit>().load(),
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final StationSalesListLoaded loaded = state as StationSalesListLoaded;
          if (loaded.sales.isEmpty &&
              loaded.debtEntries.isEmpty &&
              !loaded.expenses.any(isStationScopedExpense)) {
            return Center(child: Text(context.l10n.nothingHereYet));
          }
          final List<_StationSalesDayGroup> groups = _groupBySaleDay(
            loaded.sales,
            loaded.debtEntries,
            loaded.expenses,
          );
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
  const _StationSalesDayGroup({
    required this.day,
    required this.sales,
    required this.debtSales,
    this.dayExpensesTotal = 0,
  });

  final DateTime? day;
  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> debtSales;
  final double dayExpensesTotal;
}

List<_StationSalesDayGroup> _groupBySaleDay(
  List<Map<String, dynamic>> salesItems,
  List<Map<String, dynamic>> debtItems,
  List<Map<String, dynamic>> expenseItems,
) {
  final Map<DateTime, List<Map<String, dynamic>>> salesByDay =
      <DateTime, List<Map<String, dynamic>>>{};
  final Map<DateTime, List<Map<String, dynamic>>> debtByDay =
      <DateTime, List<Map<String, dynamic>>>{};
  final Map<DateTime, double> expensesByDay = <DateTime, double>{};
  final List<Map<String, dynamic>> unknownSales = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> unknownDebt = <Map<String, dynamic>>[];

  for (final Map<String, dynamic> item in salesItems) {
    final DateTime? d = parseApiDateTime(item['createdAt']);
    if (d == null) {
      unknownSales.add(item);
      continue;
    }
    final DateTime day = DateTime(d.year, d.month, d.day);
    salesByDay.putIfAbsent(day, () => <Map<String, dynamic>>[]).add(item);
  }

  for (final Map<String, dynamic> item in debtItems) {
    final DateTime? d = parseApiDateTime(item['createdAt']);
    if (d == null) {
      unknownDebt.add(item);
      continue;
    }
    final DateTime day = DateTime(d.year, d.month, d.day);
    debtByDay.putIfAbsent(day, () => <Map<String, dynamic>>[]).add(item);
  }

  for (final Map<String, dynamic> item in expenseItems) {
    if (!isStationScopedExpense(item)) {
      continue;
    }
    final String? ymd = expenseRowLocalYmd(item);
    if (ymd == null) {
      continue;
    }
    final List<String> parts = ymd.split('-');
    if (parts.length != 3) {
      continue;
    }
    final int? y = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    final int? d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      continue;
    }
    final DateTime day = DateTime(y, m, d);
    final double amount = parseDynamicDouble(item['amount']) ?? 0;
    if (amount > 0) {
      expensesByDay[day] = (expensesByDay[day] ?? 0) + amount;
    }
  }

  final Set<DateTime> allDays = <DateTime>{
    ...salesByDay.keys,
    ...debtByDay.keys,
    ...expensesByDay.keys,
  };
  final List<_StationSalesDayGroup> out = allDays
      .map(
        (DateTime day) => _StationSalesDayGroup(
          day: day,
          sales: salesByDay[day] ?? <Map<String, dynamic>>[],
          debtSales: debtByDay[day] ?? <Map<String, dynamic>>[],
          dayExpensesTotal: expensesByDay[day] ?? 0,
        ),
      )
      .toList()
    ..sort(
      (_StationSalesDayGroup a, _StationSalesDayGroup b) =>
          b.day!.compareTo(a.day!),
    );

  if (unknownSales.isNotEmpty || unknownDebt.isNotEmpty) {
    out.add(
      _StationSalesDayGroup(
        day: null,
        sales: unknownSales,
        debtSales: unknownDebt,
      ),
    );
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
          children: <Widget>[
            if (group.sales.isNotEmpty ||
                group.debtSales.isNotEmpty ||
                group.dayExpensesTotal > 0) ...<Widget>[
              ProductSalesDaySummary(
                sales: group.sales,
                debtSales: group.debtSales,
                dayExpensesTotal: group.dayExpensesTotal,
              ),
              if (group.sales.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
            ],
            if (group.sales.isNotEmpty)
              ..._interleavedSaleLines(context, group.sales),
          ],
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

class _StationSalePaymentBadge extends StatelessWidget {
  const _StationSalePaymentBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StationSaleLine extends StatelessWidget {
  const _StationSaleLine({required this.item});

  final Map<String, dynamic> item;

  static TextSpan _labelSpan(ThemeData theme, String text) {
    return TextSpan(
      text: text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static TextSpan _valueSpan(ThemeData theme, String text) {
    return TextSpan(
      text: text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final String rawProductName = _nestedString(item['product'], 'name');
    final String productTitle = rawProductName.isNotEmpty
        ? catalogProductArabicDisplayLabel(rawProductName)
        : '';
    final String seller = _nestedString(item['soldBy'], 'fullName');
    final dynamic qty = item['quantity'];
    final String unitStr = _formatMoney(item['unitPrice']);
    final String totalStr = _formatMoney(item['totalAmount']);
    final bool debtRepayment = isDebtRepaymentSale(item);
    String note = item['note']?.toString().trim() ?? '';
    if (note.isEmpty) {
      final double? up = _parseMoneyAmount(item['unitPrice']);
      if (up != null && up == 0) {
        note = l10n.couponButton;
      }
    }
    final String? paymentLabel = vehicleSalePaymentMethodLabel(
      l10n,
      item['paymentMethod']?.toString(),
    );
    final String? paymentRaw = item['paymentMethod']?.toString().trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                productTitle.isNotEmpty ? productTitle : l10n.product,
                textAlign: TextAlign.start,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            if (debtRepayment) ...<Widget>[
              const SizedBox(width: 8),
              _StationSalePaymentBadge(
                label: l10n.vehicleSaleDebtRepaymentBadge,
                color: theme.colorScheme.primary,
              ),
            ],
            if (paymentLabel != null) ...<Widget>[
              const SizedBox(width: 8),
              _StationSalePaymentBadge(
                label: paymentLabel,
                color: paymentRaw == 'cliq'
                    ? AppColors.brandPrimary
                    : AppColors.success,
              ),
            ],
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
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: <TextSpan>[
                _labelSpan(theme, '${l10n.sellerLabel}: '),
                _valueSpan(theme, seller),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <TextSpan>[
                    _labelSpan(theme, '${l10n.quantity}: '),
                    _valueSpan(theme, '$qty'),
                  ],
                ),
                textAlign: TextAlign.start,
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <TextSpan>[
                    _labelSpan(theme, '${l10n.unitPrice}: '),
                    _valueSpan(theme, unitStr),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <TextSpan>[
                    _labelSpan(theme, '${l10n.totalAmountLabel}: '),
                    _valueSpan(theme, totalStr),
                  ],
                ),
                textAlign: TextAlign.end,
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

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
