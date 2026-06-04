import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_sections.dart';
import 'package:flutter/material.dart';

class StationBalanceItemCard extends StatelessWidget {
  const StationBalanceItemCard({
    super.key,
    required this.rowIndex,
    required this.rowLabel,
    this.apiName,
    this.stock,
    this.isOptionalRow = false,
  });

  final int rowIndex;
  final String rowLabel;
  final String? apiName;
  final int? stock;
  final bool isOptionalRow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final bool unlinked = !isOptionalRow && stock == null;
    final int qty = stock ?? 0;
    final bool isLow = !unlinked &&
        qty > 0 &&
        qty <= StationBalanceSummary.lowStockThreshold;
    final bool isEmpty = !unlinked && qty == 0;

    final Color qtyBg = unlinked
        ? AppColors.surfaceContainerHigh
        : isEmpty
            ? AppColors.surfaceContainerLow
            : isLow
                ? const Color(0xFFFFF3E0)
                : AppColors.lightMint.withValues(alpha: 0.55);
    final Color qtyFg = unlinked
        ? AppColors.onSurfaceVariant
        : isEmpty
            ? AppColors.onSurfaceVariant
            : isLow
                ? const Color(0xFFE65100)
                : const Color(0xFF1B5E20);

    final String? subtitle = apiName != null &&
            apiName!.trim().isNotEmpty &&
            apiName!.trim() != rowLabel.trim()
        ? apiName!.trim()
        : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.softSkyBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                stationBalanceRowIcon(rowIndex),
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    rowLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (unlinked) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      l10n.stationBalanceRowUnlinkedHint,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  l10n.quantity,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: qtyBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isOptionalRow && stock == null
                        ? '—'
                        : unlinked
                            ? '—'
                            : '$qty',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: qtyFg,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StationBalanceSectionHeader extends StatelessWidget {
  const StationBalanceSectionHeader({
    super.key,
    required this.section,
    required this.itemsCount,
    required this.sectionStock,
  });

  final StationBalanceSection section;
  final int itemsCount;
  final int sectionStock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: section.tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(section.icon, color: section.tint, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
            ),
          ),
          Text(
            l10n.stationBalanceSectionStockLine('$sectionStock', '$itemsCount'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
