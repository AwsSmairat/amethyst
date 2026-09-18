part of 'add_vehicle_sale_sheet.dart';

class _VehicleSaleProductsGrid extends StatelessWidget {
  const _VehicleSaleProductsGrid({
    required this.columnCount,
    required this.columnBuilder,
  });

  final int columnCount;
  final Widget Function(BuildContext context, int index) columnBuilder;

  static const int _kColumnsPerRow = 3;
  static const double _kColumnGap = 8;

  @override
  Widget build(BuildContext context) {
    if (columnCount <= 0) {
      return const SizedBox.shrink();
    }
    final List<Widget> rows = <Widget>[];
    for (var start = 0; start < columnCount; start += _kColumnsPerRow) {
      final int end = start + _kColumnsPerRow > columnCount
          ? columnCount
          : start + _kColumnsPerRow;
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: _kColumnGap));
      }
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var i = start; i < end; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: i == start ? 0 : _kColumnGap / 2,
                    end: i == end - 1 ? 0 : _kColumnGap / 2,
                  ),
                  child: columnBuilder(context, i),
                ),
              ),
            for (var i = end; i < start + _kColumnsPerRow; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: _kColumnGap / 2,
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _VehicleSaleColumn extends StatelessWidget {
  const _VehicleSaleColumn({
    required this.index,
    required this.badgeLabel,
    required this.productLabel,
    required this.vehicleRemaining,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.busy,
    this.showHomeCouponButton = false,
    this.homeCouponActive = false,
    this.onHomeCouponToggle,
  });

  final int index;
  final String badgeLabel;
  final String productLabel;
  final int vehicleRemaining;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool busy;
  final bool showHomeCouponButton;
  final bool homeCouponActive;
  final VoidCallback? onHomeCouponToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasStock = vehicleRemaining > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Text(
                    badgeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              productLabel.isNotEmpty ? productLabel : '—',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: hasStock
                    ? AppColors.success.withValues(alpha: 0.12)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: hasStock
                          ? AppColors.success
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.left}: $vehicleRemaining',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                            color: hasStock
                                ? AppColors.success
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.quantity,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: <Widget>[
                    _QuantityStepButton(
                      icon: Icons.remove,
                      onPressed: busy || quantity <= 0 ? null : onDecrement,
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
                    _QuantityStepButton(
                      icon: Icons.add,
                      onPressed: busy ? null : onIncrement,
                    ),
                  ],
                ),
              ),
            ),
            if (showHomeCouponButton && onHomeCouponToggle != null) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy ? null : onHomeCouponToggle,
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      homeCouponActive ? AppColors.success : Colors.transparent,
                  foregroundColor: homeCouponActive
                      ? Colors.white
                      : scheme.primary,
                  side: BorderSide(
                    color: homeCouponActive
                        ? AppColors.success
                        : AppColors.outlineVariant,
                    width: homeCouponActive ? 2 : 1,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.couponButton,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.1)
          : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? scheme.primary : AppColors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.primary : AppColors.primaryText,
                ),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepButton extends StatelessWidget {
  const _QuantityStepButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      iconSize: 18,
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        minimumSize: const Size(36, 36),
        fixedSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
