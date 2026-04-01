import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/glass_container.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_cubit.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_state.dart';
import 'package:amethyst/features/user_dashboard/presentation/widgets/primary_gradient_card.dart';
import 'package:amethyst/features/user_dashboard/presentation/widgets/quick_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserDashboardCubit>(
      create: (_) => sl<UserDashboardCubit>()..load(),
      child: const _UserDashboardView(),
    );
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
                SliverToBoxAdapter(
                  child: _TopAppBar(title: dashboard.title),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(<Widget>[
                      _DriverStatusCard(dashboard: dashboard),
                      const SizedBox(height: 14),
                      _QuickActionsRow(),
                      const SizedBox(height: 22),
                      _InventorySection(items: dashboard.inventory),
                      const SizedBox(height: 16),
                      _ExpenseAndNotesRow(
                        expensesTotal: dashboard.expensesTotal,
                        expenseNote: dashboard.expenseNote,
                      ),
                      const SizedBox(height: 16),
                      _RouteMapCard(),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryContainer, width: 2),
                color: AppColors.surfaceContainerHigh,
              ),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverStatusCard extends StatelessWidget {
  const _DriverStatusCard({required this.dashboard});

  final DriverDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.80),
          letterSpacing: 1.2,
        );
    return PrimaryGradientCard(
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -10,
            bottom: -14,
            child: Icon(
              Icons.water_drop,
              size: 110,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.directions_car, size: 14),
                  const SizedBox(width: 6),
                  Text('CURRENT VEHICLE', style: labelStyle),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dashboard.vehicleLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  _MiniInfoPill(
                    title: 'Shift Time',
                    value: dashboard.shiftRemaining,
                  ),
                  const SizedBox(width: 10),
                  _MiniInfoPill(
                    title: 'Status',
                    value: dashboard.isActive ? 'Active' : 'Inactive',
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({
    required this.title,
    required this.value,
    this.leading,
  });

  final String title;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    leading!,
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            label: 'Add Sale',
            tint: AppColors.success,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuickActionButton(
            icon: Icons.payments,
            label: 'Add Expense',
            tint: AppColors.error,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: QuickActionButton(
            icon: Icons.assignment_return,
            label: 'Log Return',
            tint: AppColors.primary,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Today's Inventory",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'Updated 2m ago',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              _HeaderCell('Item', flex: 3, align: TextAlign.left),
              _HeaderCell('Loaded', flex: 2),
              _HeaderCell('Sold', flex: 2),
              _HeaderCell('Left', flex: 2),
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
              children: items
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _InventoryRow(item: e),
                      ))
                  .toList(growable: false),
            ),
          ),
        ),
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
                        'EXPENSES',
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
                      Icon(Icons.edit_note,
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY NOTES',
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
                    'No critical updates for today yet...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.add_circle, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteMapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(10, 37, 64, 0.06),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.tertiaryFixed.withValues(alpha: 0.45),
                        AppColors.primaryContainer.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Color.fromRGBO(0, 0, 0, 0.50),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                children: <Widget>[
                  Icon(Icons.map, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'View Route Map',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      blurSigma: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _NavItem(
            label: 'Dashboard',
            icon: Icons.dashboard,
            selected: true,
          ),
          const _NavItem(label: 'Sales', icon: Icons.receipt_long),
          const _NavItem(label: 'Expenses', icon: Icons.payments),
          const _NavItem(label: 'Notes', icon: Icons.description),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color.fromRGBO(11, 111, 164, 0.20),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AppColors.onSurfaceVariant.withValues(alpha: 0.55)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

