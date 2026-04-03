import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_product_prices_cubit.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/add_super_admin_product_sheet.dart';
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
          final items = (state as ListLoadLoaded).items;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.productPricesEmptyHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => showAddSuperAdminProductSheet(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addProduct),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              final Map<String, dynamic> p = items[i];
              final String title = p['name']?.toString() ?? '';
              final String unit =
                  p['unitType']?.toString() ?? p['type']?.toString() ?? '';
              final String sub =
                  '${l10n.productPriceFieldLabel}: ${_formatPrice(p['price'])}'
                  '${unit.isNotEmpty ? ' · $unit' : ''}';
              final cubit = context.read<SuperAdminProductPricesCubit>();
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
            },
          );
        },
      ),
    );
  }
}
