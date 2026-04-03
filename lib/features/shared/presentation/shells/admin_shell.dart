import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/brand_mark.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.scaffoldSoftGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const BrandMarkSmall(size: 32),
              const SizedBox(width: 10),
              Text(context.l10n.admin),
            ],
          ),
          actions: <Widget>[
            IconButton(
              tooltip: context.l10n.profileTooltip,
              onPressed: () => context.go('/admin/profile'),
              icon: const Icon(Icons.person_outline),
            ),
            IconButton(
              tooltip: context.l10n.signOutTooltip,
              onPressed: () => context.read<AuthCubit>().logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const BrandMarkSmall(size: 56),
                    const SizedBox(height: 12),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final name = state is AuthAuthenticated
                            ? state.user.fullName
                            : context.l10n.adminDrawerFallback;
                        return Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _tile(
                context,
                path,
                '/admin/dashboard',
                Icons.dashboard,
                context.l10n.dashboard,
              ),
              _tile(
                context,
                path,
                '/admin/vehicle-loads',
                Icons.upload,
                context.l10n.vehicleLoads,
              ),
              _tile(
                context,
                path,
                '/admin/station-sales',
                Icons.storefront,
                context.l10n.stationSales,
              ),
              _tile(
                context,
                path,
                '/admin/vehicle-sales',
                Icons.receipt_long,
                context.l10n.vehicleSales,
              ),
              _tile(
                context,
                path,
                '/admin/station-balance',
                Icons.table_chart_outlined,
                context.l10n.stationBalanceTitle,
              ),
              _tile(
                context,
                path,
                '/admin/returns',
                Icons.assignment_return,
                context.l10n.returns,
              ),
              _tile(
                context,
                path,
                '/admin/expenses',
                Icons.payments,
                context.l10n.expenses,
              ),
            ],
          ),
        ),
        body: child,
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String current,
    String route,
    IconData icon,
    String label,
  ) {
    final selected = current == route || current.startsWith('$route/');
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : null),
      title: Text(label),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }
}
