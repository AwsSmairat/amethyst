import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/format_money.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_cubit.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_state.dart';
import 'package:amethyst/features/user_dashboard/presentation/widgets/quick_action_button.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_vehicle_place_picker.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_vehicle_sale_sheet.dart';
import 'package:amethyst/features/driver_cash/presentation/widgets/driver_cash_balance_dashboard_card.dart';
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

            return CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(<Widget>[
                      const DriverCashBalanceDashboardCard(),
                      const SizedBox(height: 12),
                      const _QuickActionsRow(),
                      const SizedBox(height: 12),
                      const _DriverDebtActionsRow(),
                      const SizedBox(height: 12),
                      const _DriverDailySalesTotalCard(),
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
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: QuickActionButton(
            icon: Icons.add_shopping_cart,
            label: context.l10n.quickAddSale,
            tint: AppColors.success,
            onTap: () async {
              await showAddVehicleSaleSheet(context);
              if (!context.mounted) {
                return;
              }
              final AuthState auth = context.read<AuthCubit>().state;
              final String name = auth is AuthAuthenticated
                  ? auth.user.fullName
                  : context.l10n.driver;
              await context.read<UserDashboardCubit>().load(
                    driverDisplayName: name,
                  );
            },
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

class _DriverDebtActionsRow extends StatelessWidget {
  const _DriverDebtActionsRow();

  static void _showVehicleDebtPlacePicker(BuildContext context) {
    showVehicleDebtPlacePicker(
      context,
      registrationPath: '/driver/dashboard/station-debt-registration',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: QuickActionButton(
                icon: Icons.receipt_long_outlined,
                label: l10n.driverQuickDebt,
                tint: AppColors.brandPrimary,
                onTap: () =>
                    context.push('/driver/dashboard/station-debt-list'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: Icons.paid_outlined,
                label: l10n.driverQuickRepayment,
                tint: AppColors.brandPrimary,
                onTap: () => context.push('/driver/dashboard/station-debt-list'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: QuickActionButton(
                icon: Icons.drive_eta_outlined,
                label: l10n.driverRegisterVehicleDebt,
                tint: AppColors.brandPrimary,
                onTap: () => _showVehicleDebtPlacePicker(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DriverDailySalesTotalCard extends StatelessWidget {
  const _DriverDailySalesTotalCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserDashboardCubit>().state;
    if (state is! UserDashboardLoaded) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final double total = state.dashboard.dailySalesTotal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.point_of_sale_outlined,
              color: AppColors.brandPrimary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.driverDashboardDailySalesTotal,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              formatMoneyAmount(total),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.brandPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
