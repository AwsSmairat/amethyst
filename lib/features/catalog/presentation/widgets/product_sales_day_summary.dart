import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _ProductAgg {
  _ProductAgg(this.name);
  final String name;
  int quantity = 0;
  double amount = 0;
  int quantityCoupon = 0;
}

bool _isSaleCouponByUnitPrice(Map<String, dynamic> item) {
  final double? up = parseDynamicDouble(item['unitPrice']);
  return up != null && up == 0;
}

Map<String, _ProductAgg> _aggregateProductSales(
  List<Map<String, dynamic>> sales,
) {
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
    return p['name']?.toString() ?? '—';
  }
  return '—';
}

const double _kSummaryAmountCol = 56;
const double _kSummaryQtyCol = 40;
const double _kSummaryCouponCol = 40;

/// ملخص مبيعات ليوم واحد حسب المنتج (محطة أو مركبة) — نفس أعمدة مبيعات المحطة.
class ProductSalesDaySummary extends StatelessWidget {
  const ProductSalesDaySummary({super.key, required this.sales});

  final List<Map<String, dynamic>> sales;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat money = NumberFormat.decimalPattern(locale);
    final Map<String, _ProductAgg> agg = _aggregateProductSales(sales);
    final List<_ProductAgg> rows = agg.values.toList()
      ..sort(
        (_ProductAgg a, _ProductAgg b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    double grand = 0;
    int grandCouponQty = 0;
    for (final _ProductAgg r in rows) {
      grand += r.amount;
      grandCouponQty += r.quantityCoupon;
    }

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
      ],
    );
  }
}
