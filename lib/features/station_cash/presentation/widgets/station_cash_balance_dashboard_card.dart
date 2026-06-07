import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/station_cash/station_cash_list_refresh.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/format_money.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/station_cash/domain/entities/station_cash_balance_snapshot.dart';
import 'package:amethyst/features/station_cash/domain/usecases/get_station_cash_snapshot_usecase.dart';
import 'package:amethyst/features/station_cash/presentation/widgets/register_station_cash_sheet.dart';
import 'package:flutter/material.dart';

/// بطاقة رصيد الأموال في لوحة الأدمن.
class StationCashBalanceDashboardCard extends StatefulWidget {
  const StationCashBalanceDashboardCard({super.key});

  @override
  State<StationCashBalanceDashboardCard> createState() =>
      _StationCashBalanceDashboardCardState();
}

class _StationCashBalanceDashboardCardState
    extends State<StationCashBalanceDashboardCard> {
  bool _loading = true;
  String? _error;
  StationCashBalanceSnapshot _snapshot =
      const StationCashBalanceSnapshot(todayAmount: 0, yesterdayAmount: 0);

  @override
  void initState() {
    super.initState();
    StationCashListRefresh.onRefreshRequested = _load;
    _load();
  }

  @override
  void dispose() {
    if (StationCashListRefresh.onRefreshRequested == _load) {
      StationCashListRefresh.onRefreshRequested = null;
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final StationCashBalanceSnapshot snapshot =
          await sl<GetStationCashSnapshotUseCase>()();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
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

  Future<void> _openRegisterSheet() async {
    await showRegisterStationCashSheet(context);
    await _load();
  }

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
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.brandPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.stationCashBalanceTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: _load,
                      child: Text(l10n.retry),
                    ),
                  ),
                ],
              )
            else ...<Widget>[
              _BalanceLine(
                label: l10n.stationCashBalanceYesterdayLabel,
                value: formatMoneyAmount(_snapshot.yesterdayAmount),
                icon: Icons.history_outlined,
              ),
              const SizedBox(height: 12),
              _BalanceLine(
                label: l10n.stationCashBalanceTodayLabel,
                value: formatMoneyAmount(_snapshot.todayAmount),
                icon: Icons.payments_outlined,
                highlighted: true,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openRegisterSheet,
              icon: const Icon(Icons.add),
              label: Text(l10n.addStationCashBalance),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine({
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, color: AppColors.brandPrimary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: highlighted ? AppColors.brandPrimary : AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
