import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
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
    this.stationEntryKind = StationSaleEntryKind.filling,
    AmethystApi? api,
    CreateVehicleSalesBatchUseCase? createVehicleSalesBatch,
  })  : _listProductItems = listProductItems,
        _createStationDebtEntries = createStationDebtEntries,
        _api = api,
        _createVehicleSalesBatch = createVehicleSalesBatch,
        super(
          StationDebtRegistrationState.initial(
            columnCount: vehiclePlace == null
                ? _adminColumnCount(stationEntryKind)
                : vehicleProductColumnCount(
                    _vehicleColumnPlace(vehiclePlace),
                  ),
            useVehicleProductLabels: vehiclePlace != null,
          ),
        ) {
    _loadProducts();
  }

  static int _adminColumnCount(StationSaleEntryKind kind) =>
      kind == StationSaleEntryKind.emptySale
          ? kStationEmptySaleColumnCount
          : kStationFillingColumnCount;

  final ListProductItemsUseCase _listProductItems;
  final CreateStationDebtEntriesUseCase _createStationDebtEntries;
  final StationDebtVehiclePlace? vehiclePlace;
  final StationSaleEntryKind stationEntryKind;
  final AmethystApi? _api;
  final CreateVehicleSalesBatchUseCase? _createVehicleSalesBatch;

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
            (currentLoad['loadLines'] as List<dynamic>? ??
                    currentLoad['loads'] as List<dynamic>? ??
                    <dynamic>[])
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
      final bool emptySale =
          stationEntryKind == StationSaleEntryKind.emptySale;
      final List<String> apiNames = emptySale
          ? StationSaleApiProductNames.emptySale
          : StationSaleApiProductNames.filling;
      final List<String?> ids =
          List<String?>.filled(n, null, growable: false);
      final List<double?> prices =
          List<double?>.filled(n, null, growable: false);
      for (var i = 0; i < n; i++) {
        Map<String, dynamic>? match;
        if (emptySale && i < kStationEmptySaleBalanceRowIndices.length) {
          match = resolveStationBalanceProduct(
            products: items,
            rowIndex: kStationEmptySaleBalanceRowIndices[i],
          );
        } else if (!emptySale && i < kStationFillingBalanceRowByColumn.length) {
          final int? balanceRow = kStationFillingBalanceRowByColumn[i];
          if (balanceRow != null) {
            match = resolveStationBalanceProduct(
              products: items,
              rowIndex: balanceRow,
            );
          }
        }
        if (match == null) {
          final String name = i < apiNames.length ? apiNames[i] : '';
          if (name.isNotEmpty) {
            match = byName[name];
          }
        }
        if (!emptySale) {
          match ??=
              _resolveStationDebtFillingProduct(items: items, columnIndex: i);
        }
        ids[i] = match?['id'] as String?;
        prices[i] = parseDynamicDouble(match?['price']);
      }
      if (!emptySale && n > 4) {
        final String? mahdiId =
            resolveMahdiCartonStockProductId(products: items);
        if (mahdiId != null && mahdiId.isNotEmpty) {
          ids[4] = canonicalProductIdForMahdiStoreSale(
            productId: ids[4] ?? mahdiId,
            products: items,
          );
        }
        final double? mahdiPrice =
            stationMahdiFillingAndHomeUnitPrice(products: items);
        if (mahdiPrice != null) {
          prices[4] = mahdiPrice;
        }
      }
      final List<bool> skipStock =
          List<bool>.filled(n, false, growable: false);
      final List<int> stocks = List<int>.filled(n, 0, growable: false);
      final List<String> namesOut =
          List<String>.filled(n, '', growable: false);
      for (var i = 0; i < n; i++) {
        Map<String, dynamic>? row;
        String? id = ids[i];
        if (id != null) {
          for (final Map<String, dynamic> pr in items) {
            if (pr['id']?.toString() == id) {
              row = pr;
              break;
            }
          }
        }
        if (!emptySale && i == 4) {
          stocks[i] = aggregateStationStockForBalanceRow(
            products: items,
            rowIndex: 0,
          );
          skipStock[i] = false;
        } else if (emptySale &&
            i < kStationEmptySaleBalanceRowIndices.length) {
          stocks[i] = stationStockForBalanceRow(
            products: items,
            rowIndex: kStationEmptySaleBalanceRowIndices[i],
          );
          skipStock[i] = stationSaleColumnSkipsStationStock(
            entryKind: StationSaleEntryKind.emptySale,
            columnIndex: i,
            product: row,
          );
        } else {
          stocks[i] = stationStockFromProductJson(row ?? <String, dynamic>{});
          skipStock[i] = stationSaleColumnSkipsStationStock(
            entryKind: StationSaleEntryKind.filling,
            columnIndex: i,
            product: row,
          );
        }
        namesOut[i] = catalogProductArabicDisplayLabel(
          row?['name']?.toString(),
        );
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

  int _vehicleDebtQuantityCap(int index) {
    final VehicleProductColumnPlace columnPlace =
        _vehicleColumnPlace(vehiclePlace!);
    final int vehicle = index < state.columnVehicleRemaining.length
        ? state.columnVehicleRemaining[index]
        : 0;
    final int station = index < state.columnStationStock.length
        ? state.columnStationStock[index]
        : 0;
    return vehicleDebtMaxSellableQuantity(
      place: columnPlace,
      columnIndex: index,
      vehicleRemaining: vehicle,
      stationStock: station,
    );
  }

  void adjustQuantity(int index, int delta) {
    if (index < 0 || index >= state.columnCount) {
      return;
    }
    if (delta > 0) {
      // دين المركبة: سقف الكمية = متبقي الحمولة و/أو مخزون المحطة (مطابق شاشة البيع).
      if (vehiclePlace != null) {
        final VehicleProductColumnPlace columnPlace =
            _vehicleColumnPlace(vehiclePlace!);
        final bool capped = vehicleDebtColumnUsesVehicleLoad(columnPlace, index) ||
            vehicleProductColumnDeductsStationStock(columnPlace, index);
        if (capped) {
          final int cap = _vehicleDebtQuantityCap(index);
          if (cap < 999999 && state.quantities[index] >= cap) {
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
    emit(
      state.copyWith(
        submitting: true,
        clearSubmitError: true,
        submitSucceeded: false,
      ),
    );
    try {
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
          final int station = line.columnIndex < state.columnStationStock.length
              ? state.columnStationStock[line.columnIndex]
              : 0;
          final int cap = vehicleDebtMaxSellableQuantity(
            place: columnPlace,
            columnIndex: line.columnIndex,
            vehicleRemaining: _vehicleRemainingForDebtColumn(
              place: place,
              columnIndex: line.columnIndex,
            ),
            stationStock: station,
          );
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
        final CreateVehicleSalesBatchUseCase createVehicleSalesBatch =
            _createVehicleSalesBatch!;
        final VehicleProductColumnPlace columnPlace = _vehicleColumnPlace(place);
        final List<Map<String, dynamic>> batchLines =
            <Map<String, dynamic>>[];
        for (final ({
              int columnIndex,
              String productId,
              String? stockProductId,
              int quantity,
              double unitPrice,
            }) line in vehicleLines) {
          batchLines.add(<String, dynamic>{
            'productId': line.productId,
            'quantity': line.quantity,
            'unitPrice': line.unitPrice,
            if (line.stockProductId != null)
              'stockProductId': line.stockProductId,
            'debtorName': debtor,
            'isDebt': true,
            'deductStationStock': vehicleProductColumnDeductsStationStock(
              columnPlace,
              line.columnIndex,
            ),
          });
        }
        await createVehicleSalesBatch(
          vehicleId: vehicleId,
          saleDestination: destination,
          lines: batchLines,
        );
      } else {
        for (var i = 0; i < state.columnCount; i++) {
          final int q = state.quantities[i];
          if (q <= 0) {
            continue;
          }
          if (i < state.columnSkipsStationStock.length &&
              state.columnSkipsStationStock[i]) {
            continue;
          }
          final int available = i < state.columnStationStock.length
              ? state.columnStationStock[i]
              : 0;
          if (q > available) {
            emit(
              state.copyWith(
                submitting: false,
                submitError: kStationDebtInsufficientStockSubmitMarker,
              ),
            );
            return;
          }
        }
        // Firebase backend يخصم المخزون داخل createStationDebtEntries.
        await _createStationDebtEntries(debtorName: debtor, lines: lines);
      }

      emit(
        state.copyWith(
          submitting: false,
          submitSucceeded: true,
          quantities: List<int>.filled(state.columnCount, 0),
        ),
      );
    } on Object catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          submitError: mapStationDebtSubmitError(e),
        ),
      );
    }
  }

  void clearSubmitSucceeded() {
    emit(state.copyWith(submitSucceeded: false));
  }
}

Map<String, dynamic>? _resolveStationDebtFillingProduct({
  required List<Map<String, dynamic>> items,
  required int columnIndex,
}) {
  return switch (columnIndex) {
    0 => resolveFillingGallonProduct(products: items),
    1 => resolveFillingBottleProduct(products: items),
    2 => resolveWaterSmallGallonProduct(products: items),
    3 => resolveWaterSmallBottleProduct(products: items),
    4 => resolveMahdiCartonStockProduct(products: items),
    5 => resolveStationBalanceProduct(
        products: items,
        rowIndex: kStationBalanceFirstCouponRowIndex,
      ),
    6 => resolveStationBalanceProduct(
        products: items,
        rowIndex: kStationBalanceFirstCouponRowIndex + 1,
      ),
    7 => resolveStationBalanceProduct(
        products: items,
        rowIndex: kStationBalanceFirstCouponRowIndex + 2,
      ),
    _ => null,
  };
}
