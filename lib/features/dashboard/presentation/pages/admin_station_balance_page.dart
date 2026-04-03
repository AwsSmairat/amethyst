import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_station_balance_sheet.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// شاشة رصيد المحطة: نفس بنود نموذج التسجيل مع عرض الكمية من مخزون المحطة.
class AdminStationBalancePage extends StatelessWidget {
  const AdminStationBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          JsonListCubit(() => sl<AmethystApi>().listProducts())..load(),
      child: const _AdminStationBalanceBody(),
    );
  }
}

class _AdminStationBalanceBody extends StatelessWidget {
  const _AdminStationBalanceBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.stationBalanceTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.addStationBalance,
                      onPressed: () => showAddStationBalanceSheet(
                        context,
                        onSuccess: () =>
                            context.read<JsonListCubit>().load(),
                      ),
                      icon: const Icon(Icons.post_add_outlined),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(context)
                          .refreshIndicatorSemanticLabel,
                      onPressed: () => context.read<JsonListCubit>().load(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                Text(
                  l10n.stationBalanceSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<JsonListCubit, ListLoadState>(
              builder: (BuildContext context, ListLoadState state) {
                if (state is ListLoadLoading || state is ListLoadInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ListLoadFailure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                context.read<JsonListCubit>().load(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final List<Map<String, dynamic>> products =
                    (state as ListLoadLoaded).items;
                return RefreshIndicator(
                  onRefresh: () => context.read<JsonListCubit>().load(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: kStationBalanceRowCount,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int i) {
                      final String rowLabel = stationBalanceRowLabel(l10n, i);
                      if (i > kStationBalanceLastFixedRowIndex) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          title: Text(
                            rowLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '—',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final Map<String, dynamic>? match =
                          resolveStationBalanceProduct(
                        products: products,
                        rowIndex: i,
                      );
                      final int? stock = match == null
                          ? null
                          : stationStockFromProductJson(match);
                      final String? apiName =
                          match?['name']?.toString();
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        title: Text(
                          rowLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: apiName != null &&
                                apiName.trim().isNotEmpty &&
                                apiName.trim() != rowLabel.trim()
                            ? Text(
                                apiName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              )
                            : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              l10n.quantity,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              stock == null ? '—' : stock.toString(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: stock == null
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
