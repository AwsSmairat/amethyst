part of 'app_router.dart';

GoRoute _adminRoute() {
  return GoRoute(
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
                path: 'product-prices',
                builder: (_, __) => const SuperAdminProductPricesPage(
                  allowAddProduct: false,
                ),
              ),
              GoRoute(
                path: 'station-debt-registration',
                builder: buildStationDebtRegistrationRoute,
              ),
              GoRoute(
                path: 'station-debt-list',
                builder: (_, __) => const StationDebtListPage(),
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
                path: 'vehicle-loads',
                builder: (BuildContext context, _) => const VehicleLoadsHubPage(
                  shellBase: '/admin',
                  showAddLoadFab: true,
                ),
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
                        shellBase: '/admin',
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
                            shellBase: '/admin',
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
                    fab: Builder(
                      builder: (BuildContext context) {
                        return FloatingActionButton.extended(
                          heroTag: FabHeroTags.adminStationSales,
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
                builder: (BuildContext context, _) =>
                    const VehicleSalesHubPage(shellBase: '/admin'),
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
                        shellBase: '/admin',
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
                            shellBase: '/admin',
                            vehicleRow: row,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'printer-settings',
                builder: (_, __) => const PrinterSettingsScreen(),
              ),
              GoRoute(
                path: 'station-balance',
                builder: (_, __) => const AdminStationBalancePage(
                  shellBase: '/admin',
                ),
              ),
              GoRoute(
                path: 'station-cash-balance',
                builder: (_, __) => const StationCashBalancePage(),
              ),
              GoRoute(
                path: 'products',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(() => sl<AmethystApi>().listProducts())
                        ..load(),
                  child: JsonListPage(
                    title: context.l10n.titleInventoryProducts,
                    subtitleBuilder: (_, Map<String, dynamic> item) =>
                        productUnitTypeArabicLabel(
                          item['unitType']?.toString() ?? item['type']?.toString(),
                        ),
                  ),
                ),
              ),
              GoRoute(
                path: 'returns',
                builder: (BuildContext context, _) => BlocProvider(
                  create: (_) =>
                      JsonListCubit(() => sl<AmethystApi>().listReturns())
                        ..load(),
                  child: const ReturnsListPage(),
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
            ],
          ),
        ],
      );
}

GoRoute _driverRoute() {
  return GoRoute(
        path: '/driver',
        redirect: (BuildContext context, GoRouterState state) {
          if (state.uri.path == '/driver') {
            return '/driver/dashboard';
          }
          return null;
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'printer-settings',
            builder: (_, __) => const PrinterSettingsScreen(),
          ),
          GoRoute(
            path: 'receipt-style',
            builder: (_, __) => const ReceiptStyleSettingsScreen(),
          ),
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
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'station-debt-registration',
                        builder:
                            (BuildContext context, GoRouterState state) {
                          StationDebtVehiclePlace place =
                              StationDebtVehiclePlace.home;
                          final Object? extra = state.extra;
                          if (extra is Map<String, dynamic>) {
                            final String? raw =
                                extra['vehiclePlace']?.toString();
                            if (raw == 'store') {
                              place = StationDebtVehiclePlace.store;
                            } else if (raw == 'home') {
                              place = StationDebtVehiclePlace.home;
                            }
                          }
                          return BlocProvider<StationDebtRegistrationCubit>(
                            create: (_) => StationDebtRegistrationCubit(
                              listProductItems:
                                  sl<ListProductItemsUseCase>(),
                              createStationDebtEntries:
                                  sl<CreateStationDebtEntriesUseCase>(),
                              vehiclePlace: place,
                              api: sl<AmethystApi>(),
                              createVehicleSalesBatch:
                                  sl<CreateVehicleSalesBatchUseCase>(),
                            ),
                            child: const StationDebtRegistrationPage(),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'station-debt-list',
                        builder: (_, __) => const StationDebtListPage(
                          shellBase: '/driver/dashboard',
                        ),
                        routes: <RouteBase>[
                          GoRoute(
                            path: 'debtor',
                            builder:
                                (BuildContext context, GoRouterState state) {
                              final Object? extra = state.extra;
                              if (extra is! Map<String, dynamic>) {
                                return Scaffold(
                                  appBar: AppBar(
                                    title: Text(
                                      context.l10n.titleStationDebtList,
                                    ),
                                  ),
                                  body: Center(
                                    child: Text(context.l10n.nothingHereYet),
                                  ),
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
                    ],
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
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'report/:category',
                        builder: (BuildContext context, GoRouterState state) {
                          final AuthState auth =
                              context.read<AuthCubit>().state;
                          final String? driverId = auth is AuthAuthenticated
                              ? auth.user.id
                              : null;
                          return ExpenseCategoryReportPage(
                            categoryKey:
                                state.pathParameters['category'] ?? '',
                            driverIdFilter: driverId,
                          );
                        },
                      ),
                    ],
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
            ],
          ),
        ],
      );
}
