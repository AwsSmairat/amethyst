import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_sections.dart';
import 'package:flutter/material.dart';

class StationBalanceSummaryCard extends StatelessWidget {
  const StationBalanceSummaryCard({
    super.key,
    required this.summary,
  });

  final StationBalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.stationBalanceTotalUnits,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.totalUnits}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricChip(
                  label: l10n.stationBalanceItemsWithStock,
                  value: '${summary.itemsWithStock}/${summary.trackedRowCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(
                  label: l10n.stationBalanceLowStock,
                  value: '${summary.lowStockCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(
                  label: l10n.stationBalanceUnlinked,
                  value: '${summary.unlinkedCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
