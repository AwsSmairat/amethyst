import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_product_prices_cubit.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/add_super_admin_product_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          return ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                child: Text(
                  l10n.allProductsSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
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
            ],
          );
        },
      ),
    );
  }
}
