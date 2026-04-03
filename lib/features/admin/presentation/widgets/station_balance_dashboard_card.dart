import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_station_balance_sheet.dart';
import 'package:flutter/material.dart';

/// بطاقة تسجيل رصيد المحطة (لوحة المدير وصفحة الرصيد).
class StationBalanceDashboardCard extends StatelessWidget {
  const StationBalanceDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.table_chart_outlined,
                  color: AppColors.brandPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.stationBalanceTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.stationBalanceSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => showAddStationBalanceSheet(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addStationBalance),
            ),
          ],
        ),
      ),
    );
  }
}
