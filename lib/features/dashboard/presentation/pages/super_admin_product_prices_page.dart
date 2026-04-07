import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_product_prices_cubit.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/add_super_admin_product_sheet.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SuperAdminProductPricesPage extends StatelessWidget {
  const SuperAdminProductPricesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuperAdminProductPricesCubit(sl<AmethystApi>())..load(),
      child: const _SuperAdminProductPricesBody(),
    );
  }
}

class _SuperAdminProductPricesBody extends StatelessWidget {
  const _SuperAdminProductPricesBody();

  String _formatPrice(dynamic v) {
    if (v == null) {
      return '—';
    }
    final double? n = v is num ? v.toDouble() : double.tryParse(v.toString());
    if (n == null) {
      return v.toString();
    }
    return NumberFormat.decimalPattern('ar').format(n);
  }

  Future<void> _editPrice(
    BuildContext context,
    SuperAdminProductPricesCubit cubit,
    Map<String, dynamic> product,
  ) async {
    final l10n = context.l10n;
    final String? id = product['id']?.toString();
    final String name = product['name']?.toString() ?? id ?? '';
    if (id == null) {
      return;
    }
    final dynamic rawPrice = product['price'];
    final double? current = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '');
    final TextEditingController ctrl = TextEditingController(
      text: current != null ? current.toString() : '',
    );
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.editProductPriceTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              name,
              textAlign: TextAlign.right,
              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.productPriceFieldLabel,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      ctrl.dispose();
      return;
    }
    final String normalized = ctrl.text.trim().replaceAll(',', '.');
    final double? parsed = double.tryParse(normalized);
    ctrl.dispose();
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidPrice)),
      );
      return;
    }
    final String? err = await cubit.updatePrice(id, parsed);
    if (!context.mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.priceUpdated)),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SuperAdminProductPricesCubit cubit,
    Map<String, dynamic> product,
  ) async {
    final l10n = context.l10n;
    final String? id = product['id']?.toString();
    final String name = product['name']?.toString() ?? id ?? '';
    if (id == null) {
      return;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.deleteProductConfirmTitle),
        content: Text(l10n.deleteProductConfirmBody(name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteProduct),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final String? err = await cubit.deleteProduct(id);
    if (!context.mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productDeleted)),
      );
    }
  }

  Future<void> _addStationProductWithPrice(
    BuildContext context,
    SuperAdminProductPricesCubit cubit,
    int rowIndex,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final ({String name, String unitType}) spec =
        stationBalanceSeedSpecForRow(rowIndex);
    final TextEditingController ctrl = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(stationBalanceRowLabel(l10n, rowIndex)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.apiProductNameHint(spec.name),
              textAlign: TextAlign.right,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.productPriceFieldLabel,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      ctrl.dispose();
      return;
    }
    final String normalized = ctrl.text.trim().replaceAll(',', '.');
    final double? parsed = double.tryParse(normalized);
    ctrl.dispose();
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidPrice)),
      );
      return;
    }
    final String? err = await cubit.createProduct(
      name: spec.name,
      unitType: spec.unitType,
      price: parsed,
    );
    if (!context.mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.productCreated)),
      );
    }
  }

  List<Widget> _stationPricingSection(
    BuildContext context,
    SuperAdminProductPricesCubit cubit,
    List<Map<String, dynamic>> items,
  ) {
    final AppLocalizations l10n = context.l10n;
    final List<Widget> out = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Text(
          l10n.stationStockPricingSection,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    ];
    for (var i = 0; i < kStationPricingBalanceRowIndices.length; i++) {
      final int idx = kStationPricingBalanceRowIndices[i];
      final Map<String, dynamic>? match =
          resolveStationBalanceProduct(products: items, rowIndex: idx);
      final String rowTitle = stationBalanceRowLabel(l10n, idx);
      out.add(
        ListTile(
          title: Text(rowTitle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                match != null
                    ? '${l10n.productPriceFieldLabel}: ${_formatPrice(match['price'])}'
                    : l10n.stationProductNotInCatalog,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              if (match == null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () =>
                        _addStationProductWithPrice(context, cubit, idx),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: Text(l10n.addStationProductWithPrice),
                  ),
                ),
            ],
          ),
          isThreeLine: match == null,
          trailing: match != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      tooltip: l10n.editProductPriceTitle,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _editPrice(context, cubit, match),
                    ),
                    IconButton(
                      tooltip: l10n.deleteProduct,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _confirmDelete(context, cubit, match),
                    ),
                  ],
                )
              : null,
        ),
      );
      if (i < kStationPricingBalanceRowIndices.length - 1) {
        out.add(const Divider(height: 1));
      }
    }
    return out;
  }

  Widget _productTile(
    BuildContext context,
    SuperAdminProductPricesCubit cubit,
    Map<String, dynamic> p,
  ) {
    final AppLocalizations l10n = context.l10n;
    final String title = p['name']?.toString() ?? '';
    final String unit =
        p['unitType']?.toString() ?? p['type']?.toString() ?? '';
    final String sub =
        '${l10n.productPriceFieldLabel}: ${_formatPrice(p['price'])}'
        '${unit.isNotEmpty ? ' · $unit' : ''}';
    return ListTile(
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        sub,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: l10n.editProductPriceTitle,
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _editPrice(context, cubit, p),
          ),
          IconButton(
            tooltip: l10n.deleteProduct,
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _confirmDelete(context, cubit, p),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleProductPrices),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.retry,
            onPressed: () =>
                context.read<SuperAdminProductPricesCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddSuperAdminProductSheet(context),
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: Text(l10n.addProduct),
      ),
      body: BlocBuilder<SuperAdminProductPricesCubit, ListLoadState>(
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
                          context.read<SuperAdminProductPricesCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final List<Map<String, dynamic>> items =
              (state as ListLoadLoaded).items;
          final SuperAdminProductPricesCubit cubit =
              context.read<SuperAdminProductPricesCubit>();
          final Set<String> pinnedIds = <String>{};
          for (final int idx in kStationPricingBalanceRowIndices) {
            final Map<String, dynamic>? m =
                resolveStationBalanceProduct(products: items, rowIndex: idx);
            final String? id = m?['id']?.toString();
            if (id != null) {
              pinnedIds.add(id);
            }
          }
          final List<Map<String, dynamic>> rest = items
              .where(
                (Map<String, dynamic> p) =>
                    !pinnedIds.contains(p['id']?.toString()),
              )
              .toList(growable: false);

          final List<Widget> children = <Widget>[
            ..._stationPricingSection(context, cubit, items),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
              child: Text(
                l10n.allProductsSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ];
          if (rest.isEmpty) {
            children.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      l10n.productPricesEmptyHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => showAddSuperAdminProductSheet(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addProduct),
                    ),
                  ],
                ),
              ),
            );
          } else {
            for (var i = 0; i < rest.length; i++) {
              children.add(_productTile(context, cubit, rest[i]));
              if (i < rest.length - 1) {
                children.add(const Divider(height: 1));
              }
            }
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
            children: children,
          );
        },
      ),
    );
  }
}
