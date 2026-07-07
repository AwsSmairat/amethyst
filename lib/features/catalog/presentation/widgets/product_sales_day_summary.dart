import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sale_payment_method.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _ProductAgg {
  _ProductAgg(this.name);
  final String name;
  int quantity = 0;
  double amount = 0;
  int quantityCoupon = 0;
  int debtQuantity = 0;
  double debtAmount = 0;
}

bool _isSaleCouponByUnitPrice(Map<String, dynamic> item) {
  final double? up = parseDynamicDouble(item['unitPrice']);
  return up != null && up == 0;
}

Map<String, _ProductAgg> _aggregateProductSales(
  List<Map<String, dynamic>> sales, {
  List<Map<String, dynamic>> debtSales = const <Map<String, dynamic>>[],
}) {
  final Map<String, _ProductAgg> map = <String, _ProductAgg>{};
  for (final Map<String, dynamic> item in sales) {
    final String key = _saleProductKey(item);
    final String name = _saleProductName(item);
    final int q = int.tryParse(item['quantity']?.toString() ?? '') ?? 0;
    final double amt = parseDynamicDouble(item['totalAmount']) ?? 0;
    final _ProductAgg agg = map.putIfAbsent(key, () => _ProductAgg(name));
    agg.quantity += q;
    agg.amount += amt;
    if (_isSaleCouponByUnitPrice(item)) {
      agg.quantityCoupon += q;
    }
  }
  for (final Map<String, dynamic> item in debtSales) {
    final String key = _saleProductKey(item);
    final String name = _saleProductName(item);
    final int q = int.tryParse(item['quantity']?.toString() ?? '') ?? 0;
    final double amt = parseDynamicDouble(item['totalAmount']) ?? 0;
    final _ProductAgg agg = map.putIfAbsent(key, () => _ProductAgg(name));
    agg.debtQuantity += q;
    agg.debtAmount += amt;
  }
  return map;
}

String _saleProductKey(Map<String, dynamic> item) {
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

String _saleProductName(Map<String, dynamic> item) {
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

const double _kSummaryAmountCol = 56;
const double _kSummaryQtyCol = 40;
const double _kSummaryCouponCol = 40;
const double _kSummaryDebtCol = 44;

enum _CoreVolumeBucket { gallon, bottle, storeGallon, storeBottle }

class _CoreVolumeQtyTotals {
  int gallon = 0;
  int bottle = 0;
  int storeGallon = 0;
  int storeBottle = 0;

  bool get hasAny =>
      gallon > 0 || bottle > 0 || storeGallon > 0 || storeBottle > 0;

  int get total => gallon + bottle + storeGallon + storeBottle;
}

_CoreVolumeBucket? _coreVolumeBucketForItem(Map<String, dynamic> item) {
  final String label = _saleProductName(item);
  return switch (label) {
    'جالون' => _CoreVolumeBucket.gallon,
    'قاروره' => _CoreVolumeBucket.bottle,
    'جالون متجر' => _CoreVolumeBucket.storeGallon,
    'قاروره متجر' => _CoreVolumeBucket.storeBottle,
    _ => null,
  };
}

void _addCoreVolumeQty(_CoreVolumeQtyTotals totals, Map<String, dynamic> item) {
  final _CoreVolumeBucket? bucket = _coreVolumeBucketForItem(item);
  if (bucket == null) {
    return;
  }
  final int q = int.tryParse(item['quantity']?.toString() ?? '') ?? 0;
  switch (bucket) {
    case _CoreVolumeBucket.gallon:
      totals.gallon += q;
    case _CoreVolumeBucket.bottle:
      totals.bottle += q;
    case _CoreVolumeBucket.storeGallon:
      totals.storeGallon += q;
    case _CoreVolumeBucket.storeBottle:
      totals.storeBottle += q;
  }
}

_CoreVolumeQtyTotals _aggregateCoreVolumeQuantities({
  required List<Map<String, dynamic>> sales,
  required List<Map<String, dynamic>> debtSales,
}) {
  final _CoreVolumeQtyTotals totals = _CoreVolumeQtyTotals();
  for (final Map<String, dynamic> item in sales) {
    _addCoreVolumeQty(totals, item);
  }
  for (final Map<String, dynamic> item in debtSales) {
    _addCoreVolumeQty(totals, item);
  }
  return totals;
}

TextStyle? _summaryTotalTextStyle(ThemeData theme) {
  return theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );
}

/// ملخص مبيعات ليوم واحد حسب المنتج (محطة أو مركبة) — نفس أعمدة مبيعات المحطة.
class ProductSalesDaySummary extends StatelessWidget {
  const ProductSalesDaySummary({
    super.key,
    required this.sales,
    this.debtSales = const <Map<String, dynamic>>[],
  });

  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> debtSales;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat money = NumberFormat.decimalPattern(locale);
    final Map<String, _ProductAgg> agg = _aggregateProductSales(
      sales,
      debtSales: debtSales,
    );
    final List<_ProductAgg> rows = agg.values.toList()
      ..sort(
        (_ProductAgg a, _ProductAgg b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    double grand = 0;
    int grandCouponQty = 0;
    int grandDebtQty = 0;
    double grandDebtAmount = 0;
    for (final _ProductAgg r in rows) {
      grand += r.amount;
      grandCouponQty += r.quantityCoupon;
      grandDebtQty += r.debtQuantity;
      grandDebtAmount += r.debtAmount;
    }
    final bool showDebtTotal =
        debtSales.isNotEmpty || grandDebtQty > 0 || grandDebtAmount > 0;
    final _CoreVolumeQtyTotals volumeTotals = _aggregateCoreVolumeQuantities(
      sales: sales,
      debtSales: debtSales,
    );
    final SalePaymentMethodAmountTotals paymentTotals =
        sumSalePaymentMethodAmounts(sales);
    final double debtRepaymentTotal = sumDebtRepaymentAmounts(sales);

    final TextStyle? headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.vehicleLoadsSalesSummaryTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            const Expanded(child: SizedBox.shrink()),
            SizedBox(
              width: _kSummaryAmountCol,
              child: Text(
                l10n.stationSalesSummaryHeaderAmount,
                textAlign: TextAlign.end,
                style: headerStyle,
              ),
            ),
            SizedBox(
              width: _kSummaryQtyCol,
              child: Text(
                l10n.stationSalesSummaryHeaderQuantity,
                textAlign: TextAlign.end,
                style: headerStyle,
              ),
            ),
            SizedBox(
              width: _kSummaryCouponCol,
              child: Text(
                l10n.stationSalesSummaryHeaderCoupon,
                textAlign: TextAlign.end,
                style: headerStyle,
              ),
            ),
            SizedBox(
              width: _kSummaryDebtCol,
              child: Text(
                l10n.vehicleSalesSummaryHeaderDebt,
                textAlign: TextAlign.end,
                style: headerStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < rows.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  rows[i].name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _kSummaryAmountCol,
                child: Text(
                  money.format(rows[i].amount),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              SizedBox(
                width: _kSummaryQtyCol,
                child: Text(
                  '${rows[i].quantity}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: _kSummaryCouponCol,
                child: Text(
                  '${rows[i].quantityCoupon}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: _kSummaryDebtCol,
                child: Text(
                  '${rows[i].debtQuantity}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.vehicleLoadsGrandTotalSales(money.format(grand)),
                textAlign: TextAlign.start,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.stationSalesGrandTotalCoupon('$grandCouponQty'),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
        if (showDebtTotal) ...<Widget>[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.vehicleSalesGrandTotalDebt(money.format(grandDebtAmount)),
              textAlign: TextAlign.start,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ],
        if (paymentTotals.hasAny) ...<Widget>[
          if (paymentTotals.cash != 0) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.salesSummaryTotalCashAmount(
                  money.format(paymentTotals.cash),
                ),
                textAlign: TextAlign.start,
                style: _summaryTotalTextStyle(theme),
              ),
            ),
          ],
          if (paymentTotals.cliq != 0) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.salesSummaryTotalCliqAmount(
                  money.format(paymentTotals.cliq),
                ),
                textAlign: TextAlign.start,
                style: _summaryTotalTextStyle(theme),
              ),
            ),
          ],
        ],
        if (debtRepaymentTotal > 0) ...<Widget>[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.salesSummaryTotalDebtRepayment(
                money.format(debtRepaymentTotal),
              ),
              textAlign: TextAlign.start,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ],
        if (volumeTotals.hasAny) ...<Widget>[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.salesSummaryTotalCoreVolumeQty('${volumeTotals.total}'),
              textAlign: TextAlign.start,
              style: _summaryTotalTextStyle(theme),
            ),
          ),
        ],
      ],
    );
  }
}
