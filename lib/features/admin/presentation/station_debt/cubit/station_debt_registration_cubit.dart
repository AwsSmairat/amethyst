import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_api_error.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_api_product_names.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_stock_rules.dart';
import 'package:amethyst/features/admin/presentation/station_debt/cubit/station_debt_registration_state.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_vehicle_place.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kStationDebtNeedName = 'STATION_DEBT_NEED_NAME';
const String kStationDebtNeedLine = 'STATION_DEBT_NEED_LINE';
const String kStationDebtMissingProduct = 'STATION_DEBT_MISSING_PRODUCT';

/// مطابقة [add_vehicle_sale_sheet.dart] — أسماء أعمدة الدين من المركبة.
const List<String> _kVehicleDebtHomeCatalogNames = <String>[
  'Water Gallon',
  'Water Bottle',
  'Water Carton',
  'Coupon',
];

const List<String> _kVehicleDebtStoreCatalogNames = <String>[
  'جالون متجر',
  'قاروره متجر',
  'مهدي متجر',
];

final class StationDebtRegistrationCubit extends Cubit<StationDebtRegistrationState> {
  StationDebtRegistrationCubit({
    required ListProductItemsUseCase listProductItems,
    required CreateStationDebtEntriesUseCase createStationDebtEntries,
    this.vehiclePlace,
    AmethystApi? api,
    CreateVehicleSaleUseCase? createVehicleSale,
    PatchProductStationStockUseCase? patchProductStationStock,
  })  : _listProductItems = listProductItems,
        _createStationDebtEntries = createStationDebtEntries,
        _api = api,
        _createVehicleSale = createVehicleSale,
        _patchProductStationStock = patchProductStationStock,
        super(
          StationDebtRegistrationState.initial(
            columnCount: vehiclePlace == null
                ? StationDebtRegistrationState.adminColumnCount
                : vehiclePlace == StationDebtVehiclePlace.home
                    ? _kVehicleDebtHomeCatalogNames.length
                    : _kVehicleDebtStoreCatalogNames.length,
            useVehicleProductLabels: vehiclePlace != null,
          ),
        ) {
    _loadProducts();
  }

  final ListProductItemsUseCase _listProductItems;
  final CreateStationDebtEntriesUseCase _createStationDebtEntries;
  final StationDebtVehiclePlace? vehiclePlace;
  final AmethystApi? _api;
  final CreateVehicleSaleUseCase? _createVehicleSale;
  final PatchProductStationStockUseCase? _patchProductStationStock;

  String? _vehicleId;
  Map<String, int> _vehicleRemainingByNormalizedName = <String, int>{};

  Future<void> _loadProducts() async {
    emit(state.copyWith(loadingProducts: true, clearLoadError: true));
    try {
      final List<Map<String, dynamic>> items = await _listProductItems();
      final int n = state.columnCount;
      if (vehiclePlace != null) {
        // لقطة حمولة السائق الحالية للتحقق/الخصم عند تسجيل دين من المركبة.
        final AmethystApi api = _api!;
        final Map<String, dynamic> currentLoad = await api.driverCurrentLoad();
        final Map<String, dynamic>? veh =
            currentLoad['vehicle'] as Map<String, dynamic>?;
        final List<Map<String, dynamic>> loads =
            (currentLoad['loads'] as List<dynamic>? ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
        _vehicleId = veh?['id']?.toString();
        _vehicleRemainingByNormalizedName = <String, int>{
          for (final Map<String, dynamic> l in loads)
            normalizeStationBalanceProductName(
              (l['product'] as Map<String, dynamic>?)?['name']?.toString() ??
                  '',
            ): (l['remaining'] as int?) ?? 0,
        }..removeWhere((k, _) => k.trim().isEmpty);

        final List<String> catalogNames = vehiclePlace == StationDebtVehiclePlace.home
            ? _kVehicleDebtHomeCatalogNames
            : _kVehicleDebtStoreCatalogNames;
        final List<String?> ids = List<String?>.filled(n, null, growable: false);
        final List<double?> prices =
            List<double?>.filled(n, null, growable: false);
        final List<String> namesOut =
            List<String>.filled(n, '', growable: false);
        for (var i = 0; i < n; i++) {
          final String name = catalogNames[i];
          final Map<String, dynamic>? match =
              _matchCatalogProduct(name, items);
          ids[i] = match?['id'] as String?;
          prices[i] = parseDynamicDouble(match?['price']);
          final String? dn = match?['name']?.toString().trim();
          namesOut[i] =
              (dn != null && dn.isNotEmpty) ? dn : name;
        }
        final List<bool> skipStock =
            List<bool>.filled(n, false, growable: false);
        final List<int> stocks = List<int>.filled(n, 0, growable: false);
        final List<int> vehicleRemaining =
            List<int>.filled(n, 0, growable: false);
        for (var i = 0; i < n; i++) {
          Map<String, dynamic>? row;
          final String? id = ids[i];
          if (id != null) {
            for (final Map<String, dynamic> pr in items) {
              if (pr['id']?.toString() == id) {
                row = pr;
                break;
              }
            }
          }
          stocks[i] = stationStockFromProductJson(row ?? <String, dynamic>{});
          skipStock[i] = stationSaleColumnSkipsStationStock(
            entryKind: StationSaleEntryKind.filling,
            columnIndex: i,
            product: row,
          );
          final String loadName = _vehicleLoadNameForDebtColumn(
            place: vehiclePlace!,
            columnIndex: i,
          );
          vehicleRemaining[i] = _vehicleRemainingByNormalizedName[
                  normalizeStationBalanceProductName(loadName)] ??
              0;
        }
        emit(
          state.copyWith(
            loadingProducts: false,
            productIds: ids,
            unitPrices: prices,
            columnSkipsStationStock: skipStock,
            columnStationStock: stocks,
            columnVehicleRemaining: vehicleRemaining,
            columnProductNames: namesOut,
          ),
        );
        return;
      }

      final Map<String, Map<String, dynamic>> byName =
          <String, Map<String, dynamic>>{};
      for (final Map<String, dynamic> pr in items) {
        if (pr['isActive'] == false) {
          continue;
        }
        final String? n0 = pr['name']?.toString();
        if (n0 != null) {
          byName[n0] = pr;
        }
      }
      const StationSaleEntryKind kind = StationSaleEntryKind.filling;
      final List<String> apiNames = StationSaleApiProductNames.filling;
      final List<String?> ids =
          List<String?>.filled(n, null, growable: false);
      final List<double?> prices =
          List<double?>.filled(n, null, growable: false);
      for (var i = 0; i < n; i++) {
        Map<String, dynamic>? match;
        final String name = i < apiNames.length ? apiNames[i] : '';
        match = name.isNotEmpty ? byName[name] : null;
        ids[i] = match?['id'] as String?;
        prices[i] = parseDynamicDouble(match?['price']);
      }
      for (var i = 0; i < n; i++) {
        if (ids[i] != null) {
          continue;
        }
        final String? want = _unitTypeForStationSaleSlot(kind, i);
        if (want == null) {
          continue;
        }
        for (final Map<String, dynamic> pr in items) {
          if (pr['isActive'] == false) {
            continue;
          }
          if (_unitTypeFromProductJson(pr) == want) {
            ids[i] = pr['id'] as String?;
            prices[i] = parseDynamicDouble(pr['price']);
            break;
          }
        }
      }
      final List<bool> skipStock =
          List<bool>.filled(n, false, growable: false);
      final List<int> stocks = List<int>.filled(n, 0, growable: false);
      final List<String> namesOut =
          List<String>.filled(n, '', growable: false);
      for (var i = 0; i < n; i++) {
        Map<String, dynamic>? row;
        final String? id = ids[i];
        if (id != null) {
          for (final Map<String, dynamic> pr in items) {
            if (pr['id']?.toString() == id) {
              row = pr;
              break;
            }
          }
        }
        stocks[i] = stationStockFromProductJson(row ?? <String, dynamic>{});
        skipStock[i] = stationSaleColumnSkipsStationStock(
          entryKind: StationSaleEntryKind.filling,
          columnIndex: i,
          product: row,
        );
        namesOut[i] = row?['name']?.toString().trim() ?? '';
      }
      emit(
        state.copyWith(
          loadingProducts: false,
          productIds: ids,
          unitPrices: prices,
          columnSkipsStationStock: skipStock,
          columnStationStock: stocks,
          columnProductNames: namesOut,
        ),
      );
    } on Object catch (e) {
      emit(
        state.copyWith(
          loadingProducts: false,
          loadError: e.toString(),
        ),
      );
    }
  }

  void adjustQuantity(int index, int delta) {
    if (index < 0 || index >= state.columnCount) {
      return;
    }
    if (delta > 0 &&
        index < state.columnSkipsStationStock.length &&
        index < state.columnStationStock.length &&
        !state.columnSkipsStationStock[index] &&
        state.quantities[index] >= state.columnStationStock[index]) {
      return;
    }
    final List<int> nextQty = List<int>.from(state.quantities);
    final int v = nextQty[index] + delta;
    nextQty[index] = v < 0 ? 0 : v;
    emit(state.copyWith(quantities: nextQty));
  }

  String? validateBeforeSubmit(String debtorNameRaw) {
    final String debtor = debtorNameRaw.trim();
    if (debtor.isEmpty) {
      return kStationDebtNeedName;
    }
    var any = false;
    for (var i = 0; i < state.columnCount; i++) {
      if (state.quantities[i] > 0) {
        any = true;
        break;
      }
    }
    if (!any) {
      return kStationDebtNeedLine;
    }
    for (var i = 0; i < state.columnCount; i++) {
      final int q = state.quantities[i];
      if (q <= 0) {
        continue;
      }
      if (state.productIds[i] == null || state.unitPrices[i] == null) {
        return kStationDebtMissingProduct;
      }
    }
    return null;
  }

  Future<void> submit(String debtorNameRaw) async {
    final String? v = validateBeforeSubmit(debtorNameRaw);
    if (v != null) {
      emit(state.copyWith(submitError: v));
      return;
    }
    final String debtor = debtorNameRaw.trim();
    final List<Map<String, dynamic>> lines = <Map<String, dynamic>>[];
    final List<({int columnIndex, String productId, int quantity, double unitPrice})>
        vehicleLines = <({int columnIndex, String productId, int quantity, double unitPrice})>[];
    for (var i = 0; i < state.columnCount; i++) {
      final int q = state.quantities[i];
      if (q <= 0) {
        continue;
      }
      final String pid = state.productIds[i]!;
      final double price = state.unitPrices[i]!;
      lines.add(<String, dynamic>{
        'productId': pid,
        'quantity': q,
        'unitPrice': price,
      });
      vehicleLines.add(
        (columnIndex: i, productId: pid, quantity: q, unitPrice: price),
      );
    }
    emit(
      state.copyWith(
        submitting: true,
        clearSubmitError: true,
        submitSucceeded: false,
      ),
    );
    try {
      // تسجيل دين من المركبة: تحقق من حمولة السيارة قبل الإرسال.
      if (vehiclePlace != null) {
        final StationDebtVehiclePlace place = vehiclePlace!;
        for (final line in vehicleLines) {
          final String loadName = _vehicleLoadNameForDebtColumn(
            place: place,
            columnIndex: line.columnIndex,
          );
          final String key = normalizeStationBalanceProductName(loadName);
          final int rem = _vehicleRemainingByNormalizedName[key] ?? 0;
          if (line.quantity > rem) {
            emit(
              state.copyWith(
                submitting: false,
                submitError: kStationDebtInsufficientStockSubmitMarker,
              ),
            );
            return;
          }
        }
      }

      await _createStationDebtEntries(debtorName: debtor, lines: lines);

      // بعد تسجيل الدين: خصم من حمولة السيارة (وخصم من المحطة لبعض المنتجات).
      if (vehiclePlace != null) {
        final String? vehicleId = _vehicleId;
        if (vehicleId == null || vehicleId.trim().isEmpty) {
          throw StateError('missing vehicle id for vehicle debt');
        }
        final StationDebtVehiclePlace place = vehiclePlace!;
        final String destination = place == StationDebtVehiclePlace.store
            ? 'store'
            : 'home';
        final CreateVehicleSaleUseCase createVehicleSale = _createVehicleSale!;
        final PatchProductStationStockUseCase patchStock =
            _patchProductStationStock!;

        for (final line in vehicleLines) {
          await createVehicleSale(
            vehicleId: vehicleId,
            productId: line.productId,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            saleDestination: destination,
          );

          final bool deductStationStock = place == StationDebtVehiclePlace.home
              ? line.columnIndex >= 2
              : line.columnIndex == 2;
          if (deductStationStock) {
            final int snapshot = line.columnIndex < state.columnStationStock.length
                ? state.columnStationStock[line.columnIndex]
                : 0;
            final int next = snapshot - line.quantity;
            await patchStock(
              productId: line.productId,
              stationStock: next < 0 ? 0 : next,
            );
          }
        }
      }

      emit(
        state.copyWith(
          submitting: false,
          submitSucceeded: true,
          quantities: List<int>.filled(state.columnCount, 0),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          submitError: mapStationDebtApiException(e),
        ),
      );
    } on Object catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          submitError: e.toString(),
        ),
      );
    }
  }

  void clearSubmitSucceeded() {
    emit(state.copyWith(submitSucceeded: false));
  }
}

String _vehicleLoadNameForDebtColumn({
  required StationDebtVehiclePlace place,
  required int columnIndex,
}) {
  if (place == StationDebtVehiclePlace.home) {
    // ٠..٣ مطابق للأسماء الثابتة في شاشة دين المركبة (منزل).
    if (columnIndex >= 0 && columnIndex < _kVehicleDebtHomeCatalogNames.length) {
      return _kVehicleDebtHomeCatalogNames[columnIndex];
    }
    return '';
  }
  // "متجر": 0/1/2 تستهلك من Water Gallon/Bottle/Carton في حمولة السيارة.
  return switch (columnIndex) {
    0 => 'Water Gallon',
    1 => 'Water Bottle',
    2 => 'Water Carton',
    _ => '',
  };
}

Map<String, dynamic>? _matchCatalogProduct(
  String requestedName,
  List<Map<String, dynamic>> items,
) {
  final String want = requestedName.trim();
  if (want.isEmpty) {
    return null;
  }
  for (final Map<String, dynamic> pr in items) {
    if (pr['isActive'] == false) {
      continue;
    }
    final String? n = pr['name']?.toString().trim();
    if (n != null && n == want) {
      return pr;
    }
  }
  final String wantLower = want.toLowerCase();
  for (final Map<String, dynamic> pr in items) {
    if (pr['isActive'] == false) {
      continue;
    }
    final String? n = pr['name']?.toString().trim();
    if (n != null && n.toLowerCase() == wantLower) {
      return pr;
    }
  }
  return null;
}

String? _unitTypeFromProductJson(Map<String, dynamic> pr) {
  final Object? u = pr['unitType'] ?? pr['type'];
  final String? s = u?.toString();
  if (s == null || s.isEmpty) {
    return null;
  }
  return s;
}

String? _unitTypeForStationSaleSlot(StationSaleEntryKind kind, int index) {
  if (kind == StationSaleEntryKind.emptySale) {
    return null;
  }
  return switch (index) {
    0 => 'gallon',
    1 => 'bottle',
    2 => 'carton',
    3 || 4 || 5 => 'coupon',
    _ => null,
  };
}
