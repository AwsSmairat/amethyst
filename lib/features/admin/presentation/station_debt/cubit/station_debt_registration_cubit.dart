import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
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

VehicleProductColumnPlace _vehicleColumnPlace(StationDebtVehiclePlace place) =>
    place == StationDebtVehiclePlace.home
        ? VehicleProductColumnPlace.home
        : VehicleProductColumnPlace.store;

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
                : vehicleProductColumnCount(
                    _vehicleColumnPlace(vehiclePlace),
                  ),
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
  List<Map<String, dynamic>> _driverLoadLines = <Map<String, dynamic>>[];
  List<String?> _stockProductIds = <String?>[];

  int _vehicleRemainingForDebtColumn({
    required StationDebtVehiclePlace place,
    required int columnIndex,
  }) {
    if (_driverLoadLines.isEmpty) {
      return 0;
    }
    final VehicleProductColumnPlace columnPlace = _vehicleColumnPlace(place);
    final String? stockId = columnIndex < _stockProductIds.length
        ? _stockProductIds[columnIndex]
        : null;
    final String? saleId = columnIndex < state.productIds.length
        ? state.productIds[columnIndex]
        : null;
    return vehicleRemainingFromDriverLoad(
      loadLines: _driverLoadLines,
      place: columnPlace,
      columnIndex: columnIndex,
      stockProductId: stockId,
      saleProductId: saleId,
    );
  }

  Future<void> _loadProducts() async {
    emit(state.copyWith(loadingProducts: true, clearLoadError: true));
    try {
      final List<Map<String, dynamic>> items = await _listProductItems();
      final int n = state.columnCount;
      if (vehiclePlace != null) {
        final VehicleProductColumnPlace columnPlace =
            _vehicleColumnPlace(vehiclePlace!);

        final AmethystApi api = _api!;
        final Map<String, dynamic> currentLoad = await api.driverCurrentLoad();
        final Map<String, dynamic>? veh =
            currentLoad['vehicle'] as Map<String, dynamic>?;
        _driverLoadLines =
            (currentLoad['loads'] as List<dynamic>? ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList(growable: false);
        _vehicleId = veh?['id']?.toString();

        final List<String?> ids = List<String?>.filled(n, null, growable: false);
        final List<double?> prices =
            List<double?>.filled(n, null, growable: false);
        final List<String> namesOut =
            List<String>.filled(n, '', growable: false);
        _stockProductIds = List<String?>.filled(n, null, growable: false);

        for (var i = 0; i < n; i++) {
          final VehicleProductColumnBinding binding =
              bindVehicleProductColumn(
            place: columnPlace,
            columnIndex: i,
            products: items,
          );
          ids[i] = binding.saleProductId;
          _stockProductIds[i] = binding.stockProductId;
          prices[i] = binding.unitPrice;
          namesOut[i] = binding.displayLabel;
        }

        final List<bool> skipStock = List<bool>.generate(
          n,
          (int i) => vehicleProductColumnSkipsStationStock(columnPlace, i),
          growable: false,
        );
        final List<int> stocks = List<int>.filled(n, 0, growable: false);
        final List<int> vehicleRemaining =
            List<int>.filled(n, 0, growable: false);
        for (var i = 0; i < n; i++) {
          final VehicleProductColumnBinding binding =
              bindVehicleProductColumn(
            place: columnPlace,
            columnIndex: i,
            products: items,
          );
          stocks[i] = binding.stationStock;
          vehicleRemaining[i] = vehicleRemainingFromDriverLoad(
            loadLines: _driverLoadLines,
            place: columnPlace,
            columnIndex: i,
            stockProductId: _stockProductIds[i],
            saleProductId: ids[i],
          );
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
    if (delta > 0) {
      // دين المركبة: سقف الكمية من متبقي الحمولة (ومخزون المحطة إن وُجد).
      if (vehiclePlace != null) {
        final VehicleProductColumnPlace columnPlace =
            _vehicleColumnPlace(vehiclePlace!);
        final bool usesVehicleLoad =
            vehicleDebtColumnUsesVehicleLoad(columnPlace, index);
        final bool deductStationStock =
            vehicleProductColumnDeductsStationStock(columnPlace, index);
        if ((usesVehicleLoad || deductStationStock) &&
            index < state.columnVehicleRemaining.length) {
          int cap = state.columnVehicleRemaining[index];
          if (deductStationStock &&
              index < state.columnStationStock.length &&
              index < state.columnSkipsStationStock.length &&
              !state.columnSkipsStationStock[index]) {
            final int station = state.columnStationStock[index];
            cap = cap < station ? cap : station;
          }
          if (state.quantities[index] >= cap) {
            return;
          }
        }
      } else if (index < state.columnSkipsStationStock.length &&
          index < state.columnStationStock.length &&
          !state.columnSkipsStationStock[index] &&
          state.quantities[index] >= state.columnStationStock[index]) {
        // وضع الإدارة: سقف = مخزون المحطة (للأعمدة التي يُخصم منها).
        return;
      }
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
      if (state.productIds[i] == null || state.productIds[i]!.isEmpty) {
        return kStationDebtMissingProduct;
      }
      if (state.unitPrices[i] == null) {
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
    final List<Map<String, dynamic>> catalog = await _listProductItems();
    final List<Map<String, dynamic>> lines = <Map<String, dynamic>>[];
    final List<
        ({
          int columnIndex,
          String productId,
          String? stockProductId,
          int quantity,
          double unitPrice,
        })> vehicleLines = <({
      int columnIndex,
      String productId,
      String? stockProductId,
      int quantity,
      double unitPrice,
    })>[];
    for (var i = 0; i < state.columnCount; i++) {
      final int q = state.quantities[i];
      if (q <= 0) {
        continue;
      }
      final String pid = canonicalProductIdForMahdiStoreSale(
        productId: state.productIds[i]!,
        products: catalog,
      );
      final double price = state.unitPrices[i]!;
      lines.add(<String, dynamic>{
        'productId': pid,
        'quantity': q,
        'unitPrice': price,
      });
      final String? stockId = i < _stockProductIds.length
          ? _stockProductIds[i]
          : null;
      vehicleLines.add(
        (
          columnIndex: i,
          productId: pid,
          stockProductId: vehiclePlace != null &&
                  stockId != null &&
                  stockId.isNotEmpty
              ? stockId
              : null,
          quantity: q,
          unitPrice: price,
        ),
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
        final VehicleProductColumnPlace columnPlace = _vehicleColumnPlace(place);
        for (final line in vehicleLines) {
          if (!vehicleDebtColumnUsesVehicleLoad(
                columnPlace,
                line.columnIndex,
              ) &&
              !vehicleProductColumnDeductsStationStock(
                columnPlace,
                line.columnIndex,
              )) {
            continue;
          }
          final int vehicleRem = _vehicleRemainingForDebtColumn(
            place: place,
            columnIndex: line.columnIndex,
          );
          var cap = vehicleRem;
          if (vehicleProductColumnDeductsStationStock(
            columnPlace,
            line.columnIndex,
          )) {
            final int station = line.columnIndex < state.columnStationStock.length
                ? state.columnStationStock[line.columnIndex]
                : 0;
            cap = cap < station ? cap : station;
          }
          if (line.quantity > cap) {
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

      if (vehiclePlace != null) {
        // دين المركبة = مبيعات سيارة (isDebt) وليس سجل دين محطة منفصل.
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

        final VehicleProductColumnPlace columnPlace = _vehicleColumnPlace(place);
        for (final line in vehicleLines) {
          await createVehicleSale(
            vehicleId: vehicleId,
            productId: line.productId,
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            saleDestination: destination,
            stockProductId: line.stockProductId,
            debtorName: debtor,
            isDebt: true,
            skipLoadDeduction: false,
          );
          final bool deductStationStock = vehicleProductColumnDeductsStationStock(
            columnPlace,
            line.columnIndex,
          );
          if (deductStationStock) {
            final int snapshot = line.columnIndex < state.columnStationStock.length
                ? state.columnStationStock[line.columnIndex]
                : 0;
            final int next = snapshot - line.quantity;
            final String stockPatchId =
                line.stockProductId ?? line.productId;
            await patchStock(
              productId: stockPatchId,
              stationStock: next < 0 ? 0 : next,
            );
          }
        }
      } else {
        await _createStationDebtEntries(debtorName: debtor, lines: lines);
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
