import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/station_balance/station_balance_list_refresh.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_sections.dart';
import 'package:amethyst/features/admin/presentation/station_balance/widgets/station_balance_item_card.dart';
import 'package:amethyst/features/admin/presentation/station_balance/widgets/station_balance_summary_card.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_station_balance_sheet.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// شاشة رصيد المحطة — أدمن وسوبر أدمن.
class AdminStationBalancePage extends StatelessWidget {
  const AdminStationBalancePage({
    super.key,
    this.shellBase = '/admin',
  });

  /// `/admin` أو `/super-admin`
  final String shellBase;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          JsonListCubit(() => sl<AmethystApi>().listProducts())..load(),
      child: _AdminStationBalanceBody(shellBase: shellBase),
    );
  }
}

class _AdminStationBalanceBody extends StatefulWidget {
  const _AdminStationBalanceBody({required this.shellBase});

  final String shellBase;

  @override
  State<_AdminStationBalanceBody> createState() =>
      _AdminStationBalanceBodyState();
}

class _AdminStationBalanceBodyState extends State<_AdminStationBalanceBody> {
  @override
  void initState() {
    super.initState();
    StationBalanceListRefresh.onRefreshRequested = _reloadProducts;
  }

  @override
  void dispose() {
    if (StationBalanceListRefresh.onRefreshRequested == _reloadProducts) {
      StationBalanceListRefresh.onRefreshRequested = null;
    }
    super.dispose();
  }

  void _reloadProducts() {
    if (!mounted) {
      return;
    }
    context.read<JsonListCubit>().load();
  }

  void _openEditSheet(BuildContext context) {
    showAddStationBalanceSheet(
      context,
      onSuccess: () => context.read<JsonListCubit>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final List<StationBalanceSection> sections = stationBalanceSections(l10n);
    final String shellBase = widget.shellBase;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditSheet(context),
        icon: const Icon(Icons.edit_note),
        label: Text(l10n.addStationBalance),
        backgroundColor: AppColors.brandPrimary,
      ),
      body: BlocBuilder<JsonListCubit, ListLoadState>(
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
                      onPressed: () => context.read<JsonListCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<Map<String, dynamic>> products =
              (state as ListLoadLoaded).items;
          final StationBalanceSummary summary =
              computeStationBalanceSummary(products: products);

          return RefreshIndicator(
            onRefresh: () => context.read<JsonListCubit>().load(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                l10n.stationBalanceTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.stationBalancePageHint,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .refreshIndicatorSemanticLabel,
                          onPressed: () =>
                              context.read<JsonListCubit>().load(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Material(
                      color: AppColors.tertiaryFixed.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push(
                          '$shellBase/product-prices',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.price_change_outlined,
                                color: AppColors.brandPrimary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.stationBalancePricingHint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_left,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StationBalanceSummaryCard(summary: summary),
                ),
                ..._buildSectionSlivers(
                  context: context,
                  sections: sections,
                  products: products,
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSectionSlivers({
    required BuildContext context,
    required List<StationBalanceSection> sections,
    required List<Map<String, dynamic>> products,
  }) {
    final l10n = context.l10n;
    final List<Widget> out = <Widget>[];

    for (final StationBalanceSection section in sections) {
      var sectionStock = 0;
      var visibleItems = 0;

      for (final int rowIndex in section.rowIndices) {
        final bool isOptional = rowIndex > kStationBalanceLastFixedRowIndex;
        if (isOptional) {
          visibleItems++;
          continue;
        }
        final Map<String, dynamic>? match = resolveStationBalanceProduct(
          products: products,
          rowIndex: rowIndex,
        );
        if (match != null) {
          sectionStock += stationStockForBalanceRow(
            products: products,
            rowIndex: rowIndex,
          );
        }
        visibleItems++;
      }

      out.add(
        SliverToBoxAdapter(
          child: StationBalanceSectionHeader(
            section: section,
            itemsCount: visibleItems,
            sectionStock: sectionStock,
          ),
        ),
      );

      for (final int rowIndex in section.rowIndices) {
        final String rowLabel = stationBalanceRowLabel(l10n, rowIndex);
        final bool isOptional = rowIndex > kStationBalanceLastFixedRowIndex;

        if (isOptional) {
          out.add(
            SliverToBoxAdapter(
              child: StationBalanceItemCard(
                rowIndex: rowIndex,
                rowLabel: rowLabel,
                isOptionalRow: true,
              ),
            ),
          );
          continue;
        }

        final Map<String, dynamic>? match = resolveStationBalanceProduct(
          products: products,
          rowIndex: rowIndex,
        );
        final int? stock = match == null
            ? null
            : stationStockForBalanceRow(
                products: products,
                rowIndex: rowIndex,
              );
        final String? apiName = match?['name']?.toString();

        out.add(
          SliverToBoxAdapter(
            child: StationBalanceItemCard(
              rowIndex: rowIndex,
              rowLabel: rowLabel,
              apiName: apiName,
              stock: stock,
            ),
          ),
        );
      }
    }

    return out;
  }
}
