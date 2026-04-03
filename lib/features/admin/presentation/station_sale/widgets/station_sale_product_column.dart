import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class StationSaleProductColumn extends StatelessWidget {
  const StationSaleProductColumn({
    super.key,
    required this.index,
    required this.productLabel,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.busy,
    this.showCouponButton = false,
    this.couponActive = false,
    this.onCouponToggle,
    this.stationStockAvailable,
  });

  final int index;
  final String productLabel;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool busy;
  final bool showCouponButton;
  final bool couponActive;
  final VoidCallback? onCouponToggle;
  /// `null` = لا يُعرض (مثلاً تعبئة بدون خصم مخزون). غير ذلك يُظهر مخزون المحطة الحالي.
  final int? stationStockAvailable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.productRow(index + 1),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          productLabel.isNotEmpty ? productLabel : '—',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.quantity,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton.filledTonal(
              onPressed: busy || quantity <= 0 ? null : onDecrement,
              icon: const Icon(Icons.remove, size: 16),
              iconSize: 16,
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(26, 26),
                fixedSize: const Size(26, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Expanded(
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: busy ? null : onIncrement,
              icon: const Icon(Icons.add, size: 16),
              iconSize: 16,
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(26, 26),
                fixedSize: const Size(26, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (stationStockAvailable != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            l10n.stationSaleStockAvailable(stationStockAvailable!),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        if (showCouponButton &&
            quantity > 0 &&
            onCouponToggle != null) ...<Widget>[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onCouponToggle,
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    couponActive ? AppColors.success : Colors.transparent,
                foregroundColor: couponActive
                    ? Colors.white
                    : theme.colorScheme.primary,
                side: BorderSide(
                  color: couponActive
                      ? AppColors.success
                      : AppColors.outlineVariant,
                  width: couponActive ? 2 : 1,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.couponButton,
                style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
