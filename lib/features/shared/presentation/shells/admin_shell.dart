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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            BrandMarkSmall(size: 32),
            SizedBox(width: 10),
            Text('Admin'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go('/admin/profile'),
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
                      final name =
                          state is AuthAuthenticated ? state.user.fullName : 'Admin';
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
            _tile(context, path, '/admin/dashboard', Icons.dashboard, 'Dashboard'),
            _tile(context, path, '/admin/vehicle-loads', Icons.upload, 'Vehicle loads'),
            _tile(context, path, '/admin/station-sales', Icons.storefront, 'Station sales'),
            _tile(context, path, '/admin/vehicle-sales', Icons.receipt_long, 'Vehicle sales'),
            _tile(context, path, '/admin/products', Icons.inventory_2, 'Inventory'),
            _tile(context, path, '/admin/returns', Icons.assignment_return, 'Returns'),
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
