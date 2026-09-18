import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/widgets/fab_hero_tags.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/auth/presentation/pages/login_page.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:amethyst/features/catalog/presentation/cubit/station_sales_list_cubit.dart';
import 'package:amethyst/features/catalog/presentation/pages/expenses_hub_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/expense_category_report_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/json_list_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/returns_list_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/vehicle_loads_hub_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/vehicle_loads_vehicle_day_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/vehicle_loads_vehicle_days_list_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/vehicle_sales_day_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/vehicle_sales_vehicle_days_list_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/vehicle_sales_hub_page.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_station_sale_sheet.dart';
import 'package:amethyst/features/catalog/presentation/pages/station_sales_list_page.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_list_page.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debtor_detail_page.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_registration_nav.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_vehicle_place.dart';
import 'package:amethyst/features/admin/presentation/station_debt/cubit/station_debt_registration_cubit.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_registration_page.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/admin_station_balance_page.dart';
import 'package:amethyst/features/station_cash/presentation/pages/station_cash_balance_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/sales_working_days_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_carton_sales_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_dashboard_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_users_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_drivers_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_kpi_drilldown_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_product_prices_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_vehicles_page.dart';
import 'package:amethyst/features/driver/presentation/pages/driver_expenses_page.dart';
import 'package:amethyst/features/driver/presentation/pages/driver_loads_page.dart';
import 'package:amethyst/features/driver/presentation/pages/printer_settings_screen.dart';
import 'package:amethyst/features/driver/presentation/pages/receipt_style_settings_screen.dart';
import 'package:amethyst/features/driver/presentation/pages/driver_sales_page.dart';
import 'package:amethyst/features/shared/presentation/shells/admin_shell.dart';
import 'package:amethyst/features/shared/presentation/shells/driver_shell_page.dart';
import 'package:amethyst/features/shared/presentation/shells/super_admin_shell.dart';
import 'package:amethyst/app/router/go_router_refresh.dart';
import 'package:amethyst/features/user_dashboard/presentation/pages/user_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'app_router_super_admin.dart';
part 'app_router_staff.dart';

String homeForRole(String role) {
  switch (role) {
    case 'super_admin':
      return '/super-admin/dashboard';
    case 'admin':
      return '/admin/dashboard';
    case 'driver':
      return '/driver/dashboard';
    default:
      return '/login';
  }
}

GoRouter createAppRouter(AuthCubit authCubit) {
  final AuthState s = authCubit.state;
  final String initial = s is AuthAuthenticated
      ? homeForRole(s.user.role)
      : '/login';

  return GoRouter(
    initialLocation: initial,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = authCubit.state;
      final String loc = state.matchedLocation;

      if (auth is AuthUnauthenticated) {
        return loc == '/login' ? null : '/login';
      }
      if (auth is AuthAuthenticated) {
        final String role = auth.user.role;
        if (loc == '/login') {
          return homeForRole(role);
        }
        if (role == 'super_admin' && !loc.startsWith('/super-admin')) {
          return '/super-admin/dashboard';
        }
        if (role == 'admin' && !loc.startsWith('/admin')) {
          return '/admin/dashboard';
        }
        if (role == 'driver' && !loc.startsWith('/driver')) {
          return '/driver/dashboard';
        }
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      _superAdminRoute(),
      _adminRoute(),
      _driverRoute(),
    ],
  );
}

String _userSubtitle(BuildContext context, Map<String, dynamic> m) =>
    '${m['role'] ?? ''} · ${m['email'] ?? ''}';

bool _isAdminRole(Map<String, dynamic> m) => m['role'] == 'admin';
