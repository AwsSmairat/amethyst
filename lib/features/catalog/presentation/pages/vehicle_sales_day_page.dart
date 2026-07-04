import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/data/api_list_fetch.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sale_payment_method.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_list_refresh.dart';
import 'package:amethyst/core/utils/parse_api_datetime.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/catalog/presentation/widgets/product_sales_day_summary.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// مبيعات مركبة واحدة في يوم محدد (`day/yyyy-MM-dd`) مع ملخص كمبيعات المحطة.
class VehicleSalesDayPage extends StatefulWidget {
  const VehicleSalesDayPage({
    super.key,
    required this.vehicleId,
    required this.dayKey,
    required this.shellBase,
    this.vehicleRow,
  });

  final String vehicleId;
  final String dayKey;
  final String shellBase;
  final Map<String, dynamic>? vehicleRow;

  @override
  State<VehicleSalesDayPage> createState() => _VehicleSalesDayPageState();
}

class _VehicleSalesDayPageState extends State<VehicleSalesDayPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _debtItems = <Map<String, dynamic>>[];
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _day = _parseDayKey(widget.dayKey);
    VehicleSalesListRefresh.onRefreshRequested = _load;
    _load();
  }

  @override
  void dispose() {
    if (VehicleSalesListRefresh.onRefreshRequested == _load) {
      VehicleSalesListRefresh.onRefreshRequested = null;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(VehicleSalesDayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dayKey != widget.dayKey) {
      _day = _parseDayKey(widget.dayKey);
      _load();
    }
  }

  DateTime _parseDayKey(String s) {
    final List<String> parts = s.split('-');
    if (parts.length != 3) {
      final DateTime n = DateTime.now();
      return DateTime(n.year, n.month, n.day);
    }
    final int y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final int m = int.tryParse(parts[1]) ?? 1;
    final int d = int.tryParse(parts[2]) ?? 1;
    return DateTime(y, m, d);
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final String dayStr = _ymd(_day);
    try {
      final List<Map<String, dynamic>> list =
          await fetchAllVehicleSalesInRange(
        sl<AmethystApi>(),
        vehicleId: widget.vehicleId,
        dateFrom: dayStr,
        dateTo: dayStr,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = list
            .where(isVehicleSaleVisibleInSalesList)
            .toList(growable: false);
        _debtItems = list
            .where((Map<String, dynamic> r) => r['isDebt'] == true)
            .toList(growable: false);
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

  Future<void> _pickDay() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) {
      return;
    }
    final String newKey = _ymd(DateTime(picked.year, picked.month, picked.day));
    context.go(
      '${widget.shellBase}/vehicle-sales/${widget.vehicleId}/day/$newKey',
      extra: widget.vehicleRow,
    );
  }

  Widget _dateCard(BuildContext context, AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final String primary = DateFormat.EEEE(locale).format(_day);
    final String secondary = DateFormat.yMMMd(locale).format(_day);
    final DateTime now = DateTime.now();
    final bool isToday = now.year == _day.year &&
        now.month == _day.month &&
        now.day == _day.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _pickDay,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 12,
              end: 8,
              top: 12,
              bottom: 12,
            ),
            child: Row(
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
                        primary,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondary,
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
                Icon(Icons.expand_more, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String locale = Localizations.localeOf(context).toString();
    final String dateLabel = DateFormat.yMMMd(locale).format(_day);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.vehicleSalesVehicleDayTitle(
            _vehicleLabel(),
            dateLabel,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.vehicleSalesPickDay,
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : _items.isEmpty && _debtItems.isEmpty
                  ? Center(child: Text(l10n.nothingHereYet))
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        _dateCard(context, l10n),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ProductSalesDaySummary(
                            sales: _items,
                            debtSales: _debtItems,
                          ),
                        ),
                        if (_items.isNotEmpty) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              l10n.vehicleSalesLinesSectionTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText,
                                  ),
                            ),
                          ),
                        ),
                        ...List<Widget>.generate(_items.length, (int i) {
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              i < _items.length - 1 ? 10 : 0,
                            ),
                            child: _VehicleSaleLineTile(item: _items[i]),
                          );
                        }),
                        const SizedBox(height: 24),
                        ],
                      ],
                    ),
    );
  }
}

String _vehicleSaleDestinationLabel(AppLocalizations l10n, String? raw) {
  final String? d = raw?.trim().toLowerCase();
  if (d == 'home') {
    return l10n.vehicleSaleDestinationHome;
  }
  if (d == 'store') {
    return l10n.vehicleSaleDestinationStore;
  }
  if (d != null && d.isNotEmpty) {
    return raw!.trim();
  }
  return '—';
}

class _VehicleSaleBadge extends StatelessWidget {
  const _VehicleSaleBadge({
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

class _VehicleSaleLineTile extends StatelessWidget {
  const _VehicleSaleLineTile({required this.item});

  final Map<String, dynamic> item;

  static TextSpan _labelSpan(ThemeData theme, String text) {
    return TextSpan(
      text: text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
  }

  static TextSpan _valueSpan(ThemeData theme, String text) {
    return TextSpan(
      text: text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
        height: 1.25,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat money = NumberFormat.decimalPattern(locale);

    final Object? p = item['product'];
    String productName = '—';
    if (p is Map<String, dynamic>) {
      final String? raw = p['name']?.toString();
      productName = raw == null || raw.trim().isEmpty
          ? '—'
          : catalogProductArabicDisplayLabel(raw);
    }
    final String qty = item['quantity']?.toString() ?? '';
    final String title = '$productName × $qty';

    final double? total = parseDynamicDouble(item['totalAmount']);
    final String totalStr =
        total != null ? money.format(total) : (item['totalAmount']?.toString() ?? '—');

    final double? unit = parseDynamicDouble(item['unitPrice']);
    final String unitStr =
        unit != null ? money.format(unit) : (item['unitPrice']?.toString() ?? '—');

    final bool debtRepayment = isVehicleDebtRepaymentSale(item);
    final String? paymentLabel = debtRepayment
        ? null
        : vehicleSalePaymentMethodLabel(
            l10n,
            item['paymentMethod']?.toString(),
          );
    final bool coupon = shouldShowVehicleSaleCouponBadge(
      item,
      displayProductName: productName,
    );
    final String? debtorName = item['debtorName']?.toString().trim();

    final String destRaw = item['saleDestination']?.toString().trim().toLowerCase() ?? '';
    final String destLabel =
        _vehicleSaleDestinationLabel(l10n, item['saleDestination']?.toString());

    IconData destIcon = Icons.place_outlined;
    if (destRaw == 'store') {
      destIcon = Icons.storefront_outlined;
    } else if (destRaw == 'home') {
      destIcon = Icons.home_outlined;
    }

    String timePart = '';
    final DateTime? dt = parseApiDateTime(item['createdAt']);
    if (dt != null) {
      timePart = DateFormat.jm(locale).format(dt.toLocal());
    }

    return Material(
      color: AppColors.surfaceLowest,
      elevation: 0,
      shadowColor: AppColors.deepNavy.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        height: 1.25,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  if (debtRepayment) ...<Widget>[
                    const SizedBox(width: 8),
                    _VehicleSaleBadge(
                      label: l10n.vehicleSaleDebtRepaymentBadge,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  if (paymentLabel != null) ...<Widget>[
                    const SizedBox(width: 8),
                    _VehicleSaleBadge(
                      label: paymentLabel,
                      color: item['paymentMethod']?.toString().trim().toLowerCase() ==
                              'cliq'
                          ? AppColors.brandPrimary
                          : AppColors.success,
                    ),
                  ],
                  if (coupon) ...<Widget>[
                    const SizedBox(width: 8),
                    _VehicleSaleBadge(
                      label: l10n.couponButton,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    destIcon,
                    size: 18,
                    color: AppColors.softGreyText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      <String>[
                        if (debtRepayment &&
                            debtorName != null &&
                            debtorName.isNotEmpty)
                          '$debtorName · ',
                        if (timePart.isNotEmpty) '$destLabel · $timePart' else destLabel,
                      ].join(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            _labelSpan(theme, '${l10n.unitPrice}: '),
                            _valueSpan(theme, unitStr),
                          ],
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '·',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
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
              ),
            ],
          ),
        ),
    );
  }
}
