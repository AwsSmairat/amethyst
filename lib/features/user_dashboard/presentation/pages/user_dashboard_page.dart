import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_cubit.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_state.dart';
import 'package:amethyst/features/user_dashboard/presentation/widgets/quick_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserDashboardCubit>(
      create: (_) => sl<UserDashboardCubit>(),
      child: const _DriverDashboardLoader(),
    );
  }
}

class _DriverDashboardLoader extends StatefulWidget {
  const _DriverDashboardLoader();

  @override
  State<_DriverDashboardLoader> createState() => _DriverDashboardLoaderState();
}

class _DriverDashboardLoaderState extends State<_DriverDashboardLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final AuthState auth = context.read<AuthCubit>().state;
      final String name =
          auth is AuthAuthenticated ? auth.user.fullName : context.l10n.driver;
      context.read<UserDashboardCubit>().load(driverDisplayName: name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _UserDashboardView();
  }
}

class _UserDashboardView extends StatelessWidget {
  const _UserDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<UserDashboardCubit, UserDashboardState>(
          builder: (context, state) {
            if (state is UserDashboardLoading || state is UserDashboardInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is UserDashboardError) {
              return Center(child: Text(state.message));
            }

            final dashboard = (state as UserDashboardLoaded).dashboard;
            return CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(<Widget>[
                      _QuickActionsRow(),
                      const SizedBox(height: 22),
                      _InventorySection(items: dashboard.inventory),
                      const SizedBox(height: 16),
                      _ExpenseAndNotesRow(
                        expensesTotal: dashboard.expensesTotal,
                        expenseNote: dashboard.expenseNote,
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: QuickActionButton(
            icon: Icons.add_shopping_cart,
            label: context.l10n.quickAddSale,
            tint: AppColors.success,
            onTap: () => context.go('/driver/sales'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuickActionButton(
            icon: Icons.payments,
            label: context.l10n.quickAddExpense,
            tint: AppColors.error,
            onTap: () => context.go('/driver/expenses'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuickActionButton(
            icon: Icons.assignment_return,
            label: context.l10n.quickLogReturn,
            tint: AppColors.primary,
            onTap: () => context.go('/driver/loads'),
          ),
        ),
      ],
    );
  }
}

class _InventorySection extends StatefulWidget {
  const _InventorySection({required this.items});

  final List<InventoryItem> items;

  @override
  State<_InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<_InventorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.todaysInventory,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.updatedAgo,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded) ...<Widget>[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                _HeaderCell(l10n.itemHeader, flex: 3, align: TextAlign.left),
                _HeaderCell(l10n.loaded, flex: 2),
                _HeaderCell(l10n.sold, flex: 2),
                _HeaderCell(l10n.left, flex: 2),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color.fromRGBO(10, 37, 64, 0.06),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: widget.items
                    .map(
                      (InventoryItem e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _InventoryRow(item: e),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.text, {
    required this.flex,
    this.align = TextAlign.center,
  });

  final String text;
  final int flex;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.60),
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.item});

  final InventoryItem item;

  IconData _iconForKey(String key) {
    return switch (key) {
      'eco' => Icons.eco,
      'inventory_2' => Icons.inventory_2,
      'water_drop' => Icons.water_drop,
      _ => Icons.category,
    };
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconForKey(item.iconKey);
    return Row(
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.tertiary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${item.loaded}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${item.sold}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.center,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '${item.left}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpenseAndNotesRow extends StatelessWidget {
  const _ExpenseAndNotesRow({
    required this.expensesTotal,
    required this.expenseNote,
  });

  final double expensesTotal;
  final String expenseNote;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.06),
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color.fromRGBO(10, 37, 64, 0.06),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.local_gas_station,
                          color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.expensesSectionUpper,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${expensesTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    expenseNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/driver/notes'),
              borderRadius: BorderRadius.circular(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.30),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.edit_note,
                            color: AppColors.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.dailyNotesUpper,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.noCriticalUpdatesToday,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.add_circle,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
