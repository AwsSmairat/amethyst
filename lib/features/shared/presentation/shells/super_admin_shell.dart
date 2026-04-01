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
            tooltip: 'Profile',
            onPressed: () => context.go('/super-admin/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Sign out',
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
                          : 'Super Admin';
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
            _tile(context, path, '/super-admin/dashboard', Icons.dashboard, 'Dashboard'),
            _tile(context, path, '/super-admin/users', Icons.people, 'Users'),
            _tile(context, path, '/super-admin/admins', Icons.admin_panel_settings, 'Admins'),
            _tile(context, path, '/super-admin/products', Icons.inventory_2, 'Products'),
            _tile(context, path, '/super-admin/vehicles', Icons.local_shipping, 'Vehicles'),
            _tile(context, path, '/super-admin/vehicle-loads', Icons.upload, 'Vehicle loads'),
            _tile(context, path, '/super-admin/station-sales', Icons.storefront, 'Station sales'),
            _tile(context, path, '/super-admin/vehicle-sales', Icons.receipt_long, 'Vehicle sales'),
            _tile(context, path, '/super-admin/expenses', Icons.payments, 'Expenses'),
            _tile(context, path, '/super-admin/reports', Icons.analytics, 'Reports'),
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
