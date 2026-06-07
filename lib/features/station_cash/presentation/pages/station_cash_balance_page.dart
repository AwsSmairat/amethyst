import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/station_cash/station_cash_list_refresh.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/format_money.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/station_cash/domain/usecases/get_station_cash_snapshot_usecase.dart';
import 'package:amethyst/features/station_cash/domain/usecases/list_station_cash_entries_usecase.dart';
import 'package:amethyst/features/station_cash/domain/usecases/set_station_cash_balance_usecase.dart';
import 'package:amethyst/features/station_cash/presentation/cubit/station_cash_balance_cubit.dart';
import 'package:amethyst/features/station_cash/presentation/cubit/station_cash_balance_state.dart';
import 'package:amethyst/features/station_cash/presentation/widgets/register_station_cash_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class StationCashBalancePage extends StatelessWidget {
  const StationCashBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StationCashBalanceCubit(
        getSnapshot: sl<GetStationCashSnapshotUseCase>(),
        listEntries: sl<ListStationCashEntriesUseCase>(),
        setBalance: sl<SetStationCashBalanceUseCase>(),
      )..load(),
      child: const _StationCashBalanceBody(),
    );
  }
}

class _StationCashBalanceBody extends StatefulWidget {
  const _StationCashBalanceBody();

  @override
  State<_StationCashBalanceBody> createState() =>
      _StationCashBalanceBodyState();
}

class _StationCashBalanceBodyState extends State<_StationCashBalanceBody> {
  @override
  void initState() {
    super.initState();
    StationCashListRefresh.onRefreshRequested = _reload;
  }

  @override
  void dispose() {
    if (StationCashListRefresh.onRefreshRequested == _reload) {
      StationCashListRefresh.onRefreshRequested = null;
    }
    super.dispose();
  }

  void _reload() {
    if (!mounted) {
      return;
    }
    context.read<StationCashBalanceCubit>().load();
  }

  Future<void> _openRegisterSheet() async {
    await showRegisterStationCashSheet(context);
    if (!mounted) {
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stationCashBalanceTitle),
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegisterSheet,
        icon: const Icon(Icons.edit_note),
        label: Text(l10n.addStationCashBalance),
        backgroundColor: AppColors.brandPrimary,
      ),
      body: BlocBuilder<StationCashBalanceCubit, StationCashBalanceState>(
        builder: (BuildContext context, StationCashBalanceState state) {
          if (state is StationCashBalanceLoading ||
              state is StationCashBalanceInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StationCashBalanceFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final double amount = switch (state) {
            StationCashBalanceLoaded s => s.amount,
            StationCashBalanceSubmitting s => s.amount,
            _ => 0.0,
          };
          final double yesterdayAmount = switch (state) {
            StationCashBalanceLoaded s => s.yesterdayAmount,
            StationCashBalanceSubmitting s => s.yesterdayAmount,
            _ => 0.0,
          };
          final List<Map<String, dynamic>> entries = switch (state) {
            StationCashBalanceLoaded s => s.entries,
            StationCashBalanceSubmitting s => s.entries,
            _ => const <Map<String, dynamic>>[],
          };

          return RefreshIndicator(
            onRefresh: () => context.read<StationCashBalanceCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: <Widget>[
                Text(
                  l10n.stationCashBalancePageHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _StationCashSummaryTile(
                  label: l10n.stationCashBalanceYesterdayLabel,
                  value: formatMoneyAmount(yesterdayAmount),
                  icon: Icons.history_outlined,
                ),
                const SizedBox(height: 12),
                _StationCashSummaryTile(
                  label: l10n.stationCashBalanceTodayLabel,
                  value: formatMoneyAmount(amount),
                  icon: Icons.account_balance_wallet_outlined,
                  highlighted: true,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.stationCashBalanceHistoryTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l10n.nothingHereYet,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...entries.map(
                    (Map<String, dynamic> entry) => Card(
                      child: ListTile(
                        title: Text(
                          formatMoneyAmount(entry['amount']),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          _entrySubtitle(context, entry),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.brandPrimary.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

}

class _StationCashSummaryTile extends StatelessWidget {
  const _StationCashSummaryTile({
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
    final ThemeData theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.brandPrimary),
        ),
        title: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: highlighted ? AppColors.brandPrimary : AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

extension on _StationCashBalanceBodyState {
  String _entrySubtitle(BuildContext context, Map<String, dynamic> entry) {
    final l10n = context.l10n;
    final Object? created = entry['createdAt'];
    final String? note = entry['note']?.toString();
    final String when = created is DateTime
        ? DateFormat.yMMMd('ar').add_jm().format(created)
        : '';
    final String previous =
        formatMoneyAmount(entry['previousAmount']);
    final String line = l10n.stationCashBalanceEntryLine(previous, when);
    if (note != null && note.isNotEmpty) {
      return '$line\n$note';
    }
    return line;
  }
}
