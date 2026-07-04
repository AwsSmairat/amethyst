import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/data/api_list_fetch.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_batches.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/catalog/presentation/widgets/vehicle_load_batch_card.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class _ProductSaleAgg {
  _ProductSaleAgg(this.name);
  final String name;
  int quantity = 0;
  double amount = 0;
}

/// تحميلات مركبة واحدة في يوم محدد (من المسار `day/yyyy-MM-dd`) مع ملخص المبيعات.
class VehicleLoadsVehicleDayPage extends StatefulWidget {
  const VehicleLoadsVehicleDayPage({
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
  State<VehicleLoadsVehicleDayPage> createState() =>
      _VehicleLoadsVehicleDayPageState();
}

class _VehicleLoadsVehicleDayPageState extends State<VehicleLoadsVehicleDayPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _loads = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _sales = <Map<String, dynamic>>[];
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _day = _parseDayKey(widget.dayKey);
    _load();
  }

  @override
  void didUpdateWidget(VehicleLoadsVehicleDayPage oldWidget) {
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
      final AmethystApi api = sl<AmethystApi>();
      final Map<String, dynamic> loadsRes = await api.listVehicleLoads(
        vehicleId: widget.vehicleId,
        dateFrom: dayStr,
        dateTo: dayStr,
        limit: 100,
      );
      if (!mounted) {
        return;
      }
      final List<Map<String, dynamic>> loadItems =
          (loadsRes['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      final List<Map<String, dynamic>> saleItems =
          await fetchAllVehicleSalesInRange(
        api,
        vehicleId: widget.vehicleId,
        dateFrom: dayStr,
        dateTo: dayStr,
      );
      setState(() {
        _loads = loadItems;
        _sales = saleItems;
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
      '${widget.shellBase}/vehicle-loads/${widget.vehicleId}/day/$newKey',
      extra: widget.vehicleRow,
    );
  }

  String _productKey(Map<String, dynamic> item) {
    final Object? p = item['product'];
    if (p is Map<String, dynamic>) {
      final String? id = p['id']?.toString();
      if (id != null && id.isNotEmpty) {
        return id;
      }
      return p['name']?.toString() ?? 'unknown';
    }
    return 'unknown';
  }

  String _productName(Map<String, dynamic> item) {
    final Object? p = item['product'];
    if (p is Map<String, dynamic>) {
      final String? raw = p['name']?.toString();
      if (raw == null || raw.trim().isEmpty) {
        return '—';
      }
      return catalogProductArabicDisplayLabel(raw);
    }
    return '—';
  }

  Map<String, _ProductSaleAgg> _aggregateSales() {
    final Map<String, _ProductSaleAgg> map = <String, _ProductSaleAgg>{};
    for (final Map<String, dynamic> item in _sales) {
      final String key = _productKey(item);
      final String name = _productName(item);
      final int q = int.tryParse(item['quantity']?.toString() ?? '') ?? 0;
      final double amt = parseDynamicDouble(item['totalAmount']) ?? 0;
      final _ProductSaleAgg agg =
          map.putIfAbsent(key, () => _ProductSaleAgg(name));
      agg.quantity += q;
      agg.amount += amt;
    }
    return map;
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

  Widget _salesSummaryCard(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    final Map<String, _ProductSaleAgg> agg = _aggregateSales();
    final List<_ProductSaleAgg> rows = agg.values.toList()
      ..sort(
        (_ProductSaleAgg a, _ProductSaleAgg b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    final NumberFormat money = NumberFormat.decimalPattern(locale);
    double grand = 0;
    for (final _ProductSaleAgg r in rows) {
      grand += r.amount;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.vehicleLoadsSalesSummaryTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                Text(
                  l10n.nothingHereYet,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                )
              else ...<Widget>[
                for (int i = 0; i < rows.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          rows[i].name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${rows[i].quantity}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        money.format(rows[i].amount),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Text(
                  l10n.vehicleLoadsGrandTotalSales(money.format(grand)),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryText,
                      ),
                ),
              ],
            ],
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
    final List<VehicleLoadBatch> batches =
        groupVehicleLoadsIntoBatches(_loads);

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
              : ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    _dateCard(context, l10n),
                    _salesSummaryCard(context, l10n, locale),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          batches.isEmpty
                              ? l10n.vehicleLoadsLoadsSectionTitle
                              : l10n.vehicleLoadsBatchesSectionTitle(
                                  '${batches.length}',
                                ),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText,
                                  ),
                        ),
                      ),
                    ),
                    if (batches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: Center(child: Text(l10n.nothingHereYet)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        child: Column(
                          children: List<Widget>.generate(batches.length, (int i) {
                            return VehicleLoadBatchCard(
                              batch: batches[i],
                              batchNumber: batches.length - i,
                              initiallyExpanded: i == 0,
                            );
                          }),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}
