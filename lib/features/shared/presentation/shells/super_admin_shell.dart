import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/brand_mark.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SuperAdminShell extends StatelessWidget {
  const SuperAdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      appBar: AppBar(
        title: const BrandMarkSmall(size: 36),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.profileTooltip,
            onPressed: () => context.go('/super-admin/profile'),
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
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                          : context.l10n.superAdminDrawerFallback;
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
            _tile(context, path, '/super-admin/dashboard', Icons.dashboard, context.l10n.dashboard),
            _tile(context, path, '/super-admin/users', Icons.people, context.l10n.users),
            _tile(context, path, '/super-admin/drivers', Icons.drive_eta, context.l10n.titleDrivers),
            _tile(context, path, '/super-admin/admins', Icons.admin_panel_settings, context.l10n.admins),
            _tile(context, path, '/super-admin/product-prices', Icons.price_change_outlined, context.l10n.kpiProductPrices),
            _tile(context, path, '/super-admin/products', Icons.inventory_2, context.l10n.products),
            _tile(context, path, '/super-admin/vehicles', Icons.local_shipping, context.l10n.vehicles),
            _tile(context, path, '/super-admin/vehicle-loads', Icons.upload, context.l10n.vehicleLoads),
            _tile(context, path, '/super-admin/station-sales', Icons.storefront, context.l10n.stationSales),
            _tile(context, path, '/super-admin/vehicle-sales', Icons.receipt_long, context.l10n.vehicleSales),
            _tile(context, path, '/super-admin/expenses', Icons.payments, context.l10n.expenses),
            _tile(context, path, '/super-admin/reports', Icons.analytics, context.l10n.reports),
          ],
        ),
      ),
      body: child,
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
