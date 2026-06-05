import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_debt/cubit/station_debt_registration_cubit.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_registration_page.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_vehicle_place.dart';
import 'package:amethyst/features/admin/presentation/station_debt/widgets/station_debt_kind_picker.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

const String kStationDebtExtraEntryKind = 'entryKind';

Map<String, dynamic> stationDebtRegistrationExtra({
  required StationSaleEntryKind entryKind,
  String? vehiclePlace,
}) {
  return <String, dynamic>{
    kStationDebtExtraEntryKind: entryKind == StationSaleEntryKind.emptySale
        ? 'emptySale'
        : 'filling',
    if (vehiclePlace != null && vehiclePlace.isNotEmpty)
      'vehiclePlace': vehiclePlace,
  };
}

StationSaleEntryKind stationDebtEntryKindFromExtra(Object? extra) {
  if (extra is! Map<String, dynamic>) {
    return StationSaleEntryKind.filling;
  }
  final String? raw = extra[kStationDebtExtraEntryKind]?.toString();
  if (raw == 'emptySale') {
    return StationSaleEntryKind.emptySale;
  }
  return StationSaleEntryKind.filling;
}

Future<StationSaleEntryKind?> showStationDebtEntryKindPicker(
  BuildContext context,
) {
  return showModalBottomSheet<StationSaleEntryKind>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext ctx) => const StationDebtKindPicker(),
  );
}

Future<void> openAdminStationDebtRegistration(
  BuildContext context, {
  required String registrationPath,
}) async {
  final StationSaleEntryKind? kind =
      await showStationDebtEntryKindPicker(context);
  if (!context.mounted || kind == null) {
    return;
  }
  await context.push(
    registrationPath,
    extra: stationDebtRegistrationExtra(entryKind: kind),
  );
}

List<({int start, int end})> stationDebtAdminLayoutBands({
  required StationSaleEntryKind entryKind,
  required int columnCount,
}) {
  if (entryKind == StationSaleEntryKind.emptySale) {
    return <({int start, int end})>[
      (start: 0, end: 2),
      (start: 2, end: 3),
      (start: 3, end: columnCount),
    ];
  }
  return <({int start, int end})>[
    (start: 0, end: 2),
    (start: 2, end: 4),
    (start: 4, end: 6),
    (start: 6, end: columnCount),
  ];
}

Widget buildStationDebtRegistrationRoute(
  BuildContext context,
  GoRouterState state,
) {
  StationDebtVehiclePlace? place;
  final Object? extra = state.extra;
  if (extra is Map<String, dynamic>) {
    final String? raw = extra['vehiclePlace']?.toString();
    if (raw == 'store') {
      place = StationDebtVehiclePlace.store;
    } else if (raw == 'home') {
      place = StationDebtVehiclePlace.home;
    }
  }
  final StationSaleEntryKind entryKind = stationDebtEntryKindFromExtra(extra);
  return BlocProvider<StationDebtRegistrationCubit>(
    create: (_) => StationDebtRegistrationCubit(
      listProductItems: sl<ListProductItemsUseCase>(),
      createStationDebtEntries: sl<CreateStationDebtEntriesUseCase>(),
      vehiclePlace: place,
      stationEntryKind: place == null ? entryKind : StationSaleEntryKind.filling,
      api: place != null ? sl<AmethystApi>() : null,
      createVehicleSale:
          place != null ? sl<CreateVehicleSaleUseCase>() : null,
      deductStationStockForSale: sl<DeductStationStockForSaleUseCase>(),
    ),
    child: const StationDebtRegistrationPage(),
  );
}
