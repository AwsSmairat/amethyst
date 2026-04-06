import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_api_error.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_api_product_names.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_stock_rules.dart';
import 'package:amethyst/features/admin/presentation/station_debt/cubit/station_debt_registration_state.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String kStationDebtNeedName = 'STATION_DEBT_NEED_NAME';
const String kStationDebtNeedLine = 'STATION_DEBT_NEED_LINE';
const String kStationDebtMissingProduct = 'STATION_DEBT_MISSING_PRODUCT';

final class StationDebtRegistrationCubit extends Cubit<StationDebtRegistrationState> {
  StationDebtRegistrationCubit({
    required ListProductItemsUseCase listProductItems,
    required CreateStationDebtEntriesUseCase createStationDebtEntries,
  })  : _listProductItems = listProductItems,
        _createStationDebtEntries = createStationDebtEntries,
        super(StationDebtRegistrationState.initial()) {
    _loadProducts();
  }

  final ListProductItemsUseCase _listProductItems;
  final CreateStationDebtEntriesUseCase _createStationDebtEntries;

  Future<void> _loadProducts() async {
    emit(state.copyWith(loadingProducts: true, clearLoadError: true));
    try {
      final List<Map<String, dynamic>> items = await _listProductItems();
      final Map<String, Map<String, dynamic>> byName =
          <String, Map<String, dynamic>>{};
      for (final Map<String, dynamic> pr in items) {
        if (pr['isActive'] == false) {
          continue;
        }
        final String? n = pr['name']?.toString();
        if (n != null) {
          byName[n] = pr;
        }
      }
      const StationSaleEntryKind kind = StationSaleEntryKind.filling;
      const int colCount = StationDebtRegistrationState.colCount;
      final List<String> apiNames = StationSaleApiProductNames.filling;
      final List<String?> ids =
          List<String?>.filled(colCount, null, growable: false);
      final List<double?> prices =
          List<double?>.filled(colCount, null, growable: false);
      for (var i = 0; i < colCount; i++) {
        Map<String, dynamic>? match;
        final String name = i < apiNames.length ? apiNames[i] : '';
        match = name.isNotEmpty ? byName[name] : null;
        ids[i] = match?['id'] as String?;
        prices[i] = parseDynamicDouble(match?['price']);
      }
      for (var i = 0; i < colCount; i++) {
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
          List<bool>.filled(colCount, false, growable: false);
      final List<int> stocks =
          List<int>.filled(colCount, 0, growable: false);
      for (var i = 0; i < colCount; i++) {
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
      }
      emit(
        state.copyWith(
          loadingProducts: false,
          productIds: ids,
          unitPrices: prices,
          columnSkipsStationStock: skipStock,
          columnStationStock: stocks,
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
    if (index < 0 || index >= StationDebtRegistrationState.colCount) {
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
    for (var i = 0; i < StationDebtRegistrationState.colCount; i++) {
      if (state.quantities[i] > 0) {
        any = true;
        break;
      }
    }
    if (!any) {
      return kStationDebtNeedLine;
    }
    for (var i = 0; i < StationDebtRegistrationState.colCount; i++) {
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
    for (var i = 0; i < StationDebtRegistrationState.colCount; i++) {
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
    }
    emit(
      state.copyWith(
        submitting: true,
        clearSubmitError: true,
        submitSucceeded: false,
      ),
    );
    try {
      await _createStationDebtEntries(debtorName: debtor, lines: lines);
      emit(
        state.copyWith(
          submitting: false,
          submitSucceeded: true,
          quantities: List<int>.filled(StationDebtRegistrationState.colCount, 0),
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
