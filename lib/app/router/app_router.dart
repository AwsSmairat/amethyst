import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_vehicle_load_sheet.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/auth/presentation/pages/login_page.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:amethyst/features/catalog/presentation/pages/expenses_hub_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/expense_category_report_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/json_list_page.dart';
import 'package:amethyst/features/admin/presentation/widgets/add_station_sale_sheet.dart';
import 'package:amethyst/features/catalog/presentation/pages/station_sales_list_page.dart';
import 'package:amethyst/features/catalog/presentation/pages/vehicle_loads_list_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/admin_station_balance_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/reports_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/sales_working_days_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_dashboard_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_users_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_drivers_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_kpi_drilldown_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_product_prices_page.dart';
import 'package:amethyst/features/dashboard/presentation/pages/super_admin_vehicles_page.dart';
import 'package:amethyst/features/driver/presentation/pages/driver_expenses_page.dart';
import 'package:amethyst/features/driver/presentation/pages/driver_loads_page.dart';
import 'package:amethyst/features/driver/presentation/pages/driver_notes_page.dart';
import 'package:amethyst/features/driver/presentation/pages/driver_sales_page.dart';
import 'package:amethyst/features/profile/presentation/pages/profile_page.dart';
import 'package:amethyst/features/shared/presentation/shells/admin_shell.dart';
import 'package:amethyst/features/shared/presentation/shells/driver_shell_page.dart';
import 'package:amethyst/features/shared/presentation/shells/super_admin_shell.dart';
import 'package:amethyst/app/router/go_router_refresh.dart';
import 'package:amethyst/features/user_dashboard/presentation/pages/user_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
      GoRoute(
        path: '/super-admin',
        redirect: (BuildContext context, GoRouterState state) {
          if (state.uri.path == '/super-admin') {
            return '/super-admin/dashboard';
          }
          return null;
        },
        routes: <RouteBase>[
          ShellRoute(
            builder:
                (BuildContext context, GoRouterState state, Widget child) {
              return SuperAdminShell(child: child);
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'dashboard',
                builder: (_, __) => const SuperAdminDashboardPage(),
              ),
              GoRoute(
                path: 'sales-working-days',
                builder: (_, __) => const SalesWorkingDaysPage(),
              ),
              GoRoute(
                path: 'kpi/:kind',
                builder: (BuildContext context, GoRouterState state) {
                  final SuperAdminKpiDrilldown? kind =
                      SuperAdminKpiDrilldown.tryParse(
                    state.pathParameters['kind'] ?? '',
                  );
                  if (kind == null) {
                    return Scaffold(
                      appBar: AppBar(title: Text(context.l10n.notFound)),
                      body: Center(child: Text(context.l10n.unknownReport)),
                    );
                  }
                  return SuperAdminKpiDrilldownPage(kind: kind);
                },
              ),
              GoRoute(
                path: 'users',
                builder: (_, __) => const SuperAdminUsersPage(),
              ),
              GoRoute(
                path: 'drivers',
                builder: (_, __) => const SuperAdminDriversPage(),
              ),
              GoRoute(
                path: 'admins',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(() => sl<AmethystApi>().listUsers())
                        ..load(),
                  child: JsonListPage(
                    title: context.l10n.titleAdmins,
                    where: _isAdminRole,
                    subtitleBuilder: _userSubtitle,
                  ),
                ),
              ),
              GoRoute(
                path: 'product-prices',
                builder: (_, __) => const SuperAdminProductPricesPage(),
              ),
              GoRoute(
                path: 'products',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(() => sl<AmethystApi>().listProducts())
                        ..load(),
                  child: JsonListPage(title: context.l10n.titleProducts),
                ),
              ),
              GoRoute(
                path: 'vehicles',
                builder: (_, __) => const SuperAdminVehiclesPage(),
              ),
              GoRoute(
                path: 'vehicle-loads',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(() => sl<AmethystApi>().listVehicleLoads())
                        ..load(),
                  child: VehicleLoadsListPage(
                    title: context.l10n.titleVehicleLoads,
                  ),
                ),
              ),
              GoRoute(
                path: 'station-sales',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(
                        () => sl<AmethystApi>().listStationSales(),
                      )..load(),
                  child: StationSalesListPage(
                    title: context.l10n.titleStationSales,
                  ),
                ),
              ),
              GoRoute(
                path: 'vehicle-sales',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(
                        () => sl<AmethystApi>().listVehicleSales(),
                      )..load(),
                  child: JsonListPage(title: context.l10n.titleVehicleSales),
                ),
              ),
              GoRoute(
                path: 'expenses/report/:category',
                builder: (BuildContext context, GoRouterState state) =>
                    ExpenseCategoryReportPage(
                  categoryKey: state.pathParameters['category'] ?? '',
                ),
              ),
              GoRoute(
                path: 'expenses',
                builder: (BuildContext context, _) =>
                    const ExpensesHubPage(basePath: '/super-admin'),
              ),
              GoRoute(
                path: 'reports',
                builder: (_, __) => const ReportsPage(),
              ),
              GoRoute(
                path: 'profile',
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        redirect: (BuildContext context, GoRouterState state) {
          if (state.uri.path == '/admin') {
            return '/admin/dashboard';
          }
          return null;
        },
        routes: <RouteBase>[
          ShellRoute(
            builder:
                (BuildContext context, GoRouterState state, Widget child) {
              return AdminShell(child: child);
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'dashboard',
                builder: (_, __) => const AdminDashboardPage(),
              ),
              GoRoute(
                path: 'vehicle-loads',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(
                        () => sl<AmethystApi>().listVehicleLoads(),
                      )..load(),
                  child: VehicleLoadsListPage(
                    title: context.l10n.titleVehicleLoads,
                    fab: Builder(
                      builder: (BuildContext context) {
                        return FloatingActionButton.extended(
                          onPressed: () => showAddVehicleLoadSheet(context),
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.addLoad),
                        );
                      },
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: 'station-sales',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(
                        () => sl<AmethystApi>().listStationSales(),
                      )..load(),
                  child: StationSalesListPage(
                    title: context.l10n.titleStationSales,
                    fab: Builder(
                      builder: (BuildContext context) {
                        return FloatingActionButton.extended(
                          onPressed: () => showAddStationSaleSheet(context),
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.addStationSale),
                        );
                      },
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: 'vehicle-sales',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(
                        () => sl<AmethystApi>().listVehicleSales(),
                      )..load(),
                  child: JsonListPage(title: context.l10n.titleVehicleSales),
                ),
              ),
              GoRoute(
                path: 'station-balance',
                builder: (_, __) => const AdminStationBalancePage(),
              ),
              GoRoute(
                path: 'products',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(() => sl<AmethystApi>().listProducts())
                        ..load(),
                  child: JsonListPage(title: context.l10n.titleInventoryProducts),
                ),
              ),
              GoRoute(
                path: 'returns',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(() => sl<AmethystApi>().listReturns())
                        ..load(),
                  child: JsonListPage(title: context.l10n.titleReturns),
                ),
              ),
              GoRoute(
                path: 'expenses/report/:category',
                builder: (BuildContext context, GoRouterState state) =>
                    ExpenseCategoryReportPage(
                  categoryKey: state.pathParameters['category'] ?? '',
                ),
              ),
              GoRoute(
                path: 'expenses',
                builder: (BuildContext context, _) =>
                    const ExpensesHubPage(basePath: '/admin'),
              ),
              GoRoute(
                path: 'profile',
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/driver',
        redirect: (BuildContext context, GoRouterState state) {
          if (state.uri.path == '/driver') {
            return '/driver/dashboard';
          }
          return null;
        },
        routes: <RouteBase>[
          StatefulShellRoute.indexedStack(
            builder: (BuildContext context, GoRouterState state,
                StatefulNavigationShell navigationShell) {
              return DriverShellPage(navigationShell: navigationShell);
            },
            branches: <StatefulShellBranch>[
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: 'dashboard',
                    builder: (_, __) => const DriverDashboardPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: 'sales',
                    builder: (_, __) => const DriverSalesPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: 'expenses',
                    builder: (_, __) => const DriverExpensesPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: 'loads',
                    builder: (_, __) => const DriverLoadsPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: 'notes',
                    builder: (_, __) => const DriverNotesPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: 'profile',
                    builder: (_, __) => const ProfilePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String _userSubtitle(BuildContext context, Map<String, dynamic> m) =>
    '${m['role'] ?? ''} · ${m['email'] ?? ''}';

bool _isAdminRole(Map<String, dynamic> m) => m['role'] == 'admin';
