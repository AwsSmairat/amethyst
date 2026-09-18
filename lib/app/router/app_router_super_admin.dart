part of 'app_router.dart';

GoRoute _superAdminRoute() {
  return GoRoute(
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
                path: 'carton-sales',
                builder: (_, __) => const SuperAdminCartonSalesPage(),
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
                path: 'station-balance',
                builder: (_, __) => const AdminStationBalancePage(
                  shellBase: '/super-admin',
                ),
              ),
              GoRoute(
                path: 'station-cash-balance',
                builder: (_, __) => const StationCashBalancePage(),
              ),
              GoRoute(
                path: 'station-debt-registration',
                builder: buildStationDebtRegistrationRoute,
              ),
              GoRoute(
                path: 'station-debt-list',
                builder: (_, __) =>
                    const StationDebtListPage(shellBase: '/super-admin'),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'debtor',
                    builder: (BuildContext context, GoRouterState state) {
                      final Object? extra = state.extra;
                      if (extra is! Map<String, dynamic>) {
                        return Scaffold(
                          appBar: AppBar(
                            title: Text(context.l10n.titleStationDebtList),
                          ),
                          body: Center(child: Text(context.l10n.nothingHereYet)),
                        );
                      }
                      final String debtorName =
                          extra['debtorName'] as String? ?? '';
                      final List<dynamic>? raw =
                          extra['entries'] as List<dynamic>?;
                      final List<Map<String, dynamic>> entries = raw
                              ?.whereType<Map<String, dynamic>>()
                              .toList(growable: false) ??
                          <Map<String, dynamic>>[];
                      return StationDebtorDetailPage(
                        debtorName: debtorName,
                        entries: entries,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'vehicles',
                builder: (_, __) => const SuperAdminVehiclesPage(),
              ),
              GoRoute(
                path: 'vehicle-loads',
                builder: (BuildContext context, _) =>
                    const VehicleLoadsHubPage(shellBase: '/super-admin'),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':vehicleId',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['vehicleId'] ?? '';
                      final Object? extra = state.extra;
                      final Map<String, dynamic>? row =
                          extra is Map<String, dynamic> ? extra : null;
                      return VehicleLoadsVehicleDaysListPage(
                        vehicleId: id,
                        shellBase: '/super-admin',
                        vehicleRow: row,
                      );
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'day/:dayKey',
                        builder: (BuildContext context, GoRouterState state) {
                          final String vehicleId =
                              state.pathParameters['vehicleId'] ?? '';
                          final String dayKey =
                              state.pathParameters['dayKey'] ?? '';
                          final Object? extra = state.extra;
                          final Map<String, dynamic>? row =
                              extra is Map<String, dynamic> ? extra : null;
                          return VehicleLoadsVehicleDayPage(
                            vehicleId: vehicleId,
                            dayKey: dayKey,
                            shellBase: '/super-admin',
                            vehicleRow: row,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'station-sales',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) => StationSalesListCubit()..load(),
                  child: StationSalesListPage(
                    title: context.l10n.titleStationSales,
                  ),
                ),
              ),
              GoRoute(
                path: 'vehicle-sales',
                builder: (BuildContext context, _) =>
                    const VehicleSalesHubPage(shellBase: '/super-admin'),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':vehicleId',
                    builder: (BuildContext context, GoRouterState state) {
                      final String id = state.pathParameters['vehicleId'] ?? '';
                      final Object? extra = state.extra;
                      final Map<String, dynamic>? row =
                          extra is Map<String, dynamic> ? extra : null;
                      return VehicleSalesVehicleDaysListPage(
                        vehicleId: id,
                        shellBase: '/super-admin',
                        vehicleRow: row,
                      );
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'day/:dayKey',
                        builder: (BuildContext context, GoRouterState state) {
                          final String vehicleId =
                              state.pathParameters['vehicleId'] ?? '';
                          final String dayKey =
                              state.pathParameters['dayKey'] ?? '';
                          final Object? extra = state.extra;
                          final Map<String, dynamic>? row =
                              extra is Map<String, dynamic> ? extra : null;
                          return VehicleSalesDayPage(
                            vehicleId: vehicleId,
                            dayKey: dayKey,
                            shellBase: '/super-admin',
                            vehicleRow: row,
                          );
                        },
                      ),
                    ],
                  ),
                ],
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
            ],
          ),
        ],
      );
}
