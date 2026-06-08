import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sale_payment_method.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_api_product_names.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_stock_rules.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_validation.dart';
import 'package:amethyst/features/admin/presentation/station_sale/cubit/station_sale_form_state.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef StationSaleLine = ({
  String productId,
  int quantity,
  double unitPrice,
  /// في شاشة التعبئة: ٠ جالون، ١ قارورة، ٢ مهدي، ٣–٥ دفاتر كوبون (١٢ / ٢٤ / ٥٠).
  int columnIndex,
  /// بيع تعبئة مع زر كوبون للعمود ٠ أو ١ — تُحفظ في سجل المبيعات.
  String? note,
});

typedef _LineBuild = ({
  List<StationSaleLine>? lines,
  StationSaleValidationError? err,
});

/// ملاحظة تُخزَّن مع بيع التعبئة عند تفعيل «كوبون» على جالون/قارورة.
const String kFillingCouponSaleNote = 'كوبون';

/// تُستبدَل في الواجهة برسالة `stationSaleSubmitInsufficientStock`.
const String kStationSaleInsufficientStockSubmitMarker =
    'STATION_SALE_INSUFFICIENT_STOCK';

const String kStationSalePaymentMethodRequiredMarker =
    'STATION_SALE_PAYMENT_METHOD_REQUIRED';

final class StationSaleFormCubit extends Cubit<StationSaleFormState> {
  StationSaleFormCubit({
    required StationSaleEntryKind entryKind,
    required ListProductItemsUseCase listProductItems,
    required CreateStationSaleUseCase createStationSale,
  })  : _listProductItems = listProductItems,
        _createStationSale = createStationSale,
        super(StationSaleFormState.initial(entryKind)) {
    _loadProducts();
  }

  final ListProductItemsUseCase _listProductItems;
  final CreateStationSaleUseCase _createStationSale;

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
      final List<String> apiNames = state.entryKind ==
              StationSaleEntryKind.filling
          ? StationSaleApiProductNames.filling
          : StationSaleApiProductNames.emptySale;
      final List<String?> ids =
          List<String?>.filled(state.colCount, null, growable: false);
      final List<double?> prices =
          List<double?>.filled(state.colCount, null, growable: false);
      for (var i = 0; i < state.colCount; i++) {
        Map<String, dynamic>? match;
        if (state.entryKind == StationSaleEntryKind.emptySale &&
            i < kStationEmptySaleBalanceRowIndices.length) {
          match = resolveStationBalanceProduct(
            products: items,
            rowIndex: kStationEmptySaleBalanceRowIndices[i],
          );
        }
        if (state.entryKind == StationSaleEntryKind.filling &&
            i < kStationFillingBalanceRowByColumn.length) {
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
          match = name.isNotEmpty ? byName[name] : null;
        }
        ids[i] = match?['id'] as String?;
        prices[i] = parseDynamicDouble(match?['price']);
      }
      for (var i = 0; i < state.colCount; i++) {
        if (ids[i] != null) {
          continue;
        }
        final String? want =
            _unitTypeForStationSaleSlot(state.entryKind, i);
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
          List<bool>.filled(state.colCount, false, growable: false);
      final List<int> stocks =
          List<int>.filled(state.colCount, 0, growable: false);
      for (var i = 0; i < state.colCount; i++) {
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
        if (state.entryKind == StationSaleEntryKind.filling && i == 4) {
          final String? canonical =
              resolveMahdiCartonStockProductId(products: items);
          if (canonical != null && canonical.isNotEmpty) {
            id = canonicalProductIdForMahdiStoreSale(
              productId: id ?? canonical,
              products: items,
            );
            ids[i] = id;
            for (final Map<String, dynamic> pr in items) {
              if (pr['id']?.toString() == id) {
                row = pr;
                break;
              }
            }
          }
          final double? mahdiPrice =
              stationMahdiFillingAndHomeUnitPrice(products: items);
          if (mahdiPrice != null) {
            prices[i] = mahdiPrice;
          }
          stocks[i] = aggregateStationStockForBalanceRow(
            products: items,
            rowIndex: 0,
          );
          skipStock[i] = false;
        } else if (state.entryKind == StationSaleEntryKind.emptySale &&
            i < kStationEmptySaleBalanceRowIndices.length) {
          stocks[i] = stationStockForBalanceRow(
            products: items,
            rowIndex: kStationEmptySaleBalanceRowIndices[i],
          );
          skipStock[i] = stationSaleColumnSkipsStationStock(
            entryKind: state.entryKind,
            columnIndex: i,
            product: row,
          );
        } else {
          stocks[i] = stationStockFromProductJson(row ?? <String, dynamic>{});
          skipStock[i] = stationSaleColumnSkipsStationStock(
            entryKind: state.entryKind,
            columnIndex: i,
            product: row,
          );
        }
      }
      double surchargeRow1 = state.emptySaleWithFillingSurchargeRow1;
      double surchargeRow2 = state.emptySaleWithFillingSurchargeRow2;
      if (state.entryKind == StationSaleEntryKind.emptySale) {
        final Map<String, dynamic>? row1Product =
            resolveEmptySaleWithFillingRow1Product(products: items);
        final Map<String, dynamic>? row2Product =
            resolveEmptySaleWithFillingRow2Product(products: items);
        surchargeRow1 =
            parseDynamicDouble(row1Product?['price']) ?? surchargeRow1;
        surchargeRow2 =
            parseDynamicDouble(row2Product?['price']) ?? surchargeRow2;
      }
      emit(
        state.copyWith(
          loadingProducts: false,
          productIds: ids,
          unitPrices: prices,
          columnSkipsStationStock: skipStock,
          columnStationStock: stocks,
          emptySaleWithFillingSurchargeRow1: surchargeRow1,
          emptySaleWithFillingSurchargeRow2: surchargeRow2,
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
    if (index < 0 || index >= state.colCount) {
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
    bool c1 = state.couponLine1On;
    bool c2 = state.couponLine2On;
    if (nextQty[index] == 0 && (index == 0 || index == 1)) {
      if (index == 0) {
        c1 = false;
      } else {
        c2 = false;
      }
    }
    var withFillingRow1On = state.withFillingRow1On;
    var withFillingRow2On = state.withFillingRow2On;
    if (withFillingRow1On && !_hasQuantityInRange(nextQty, 0, 3)) {
      withFillingRow1On = false;
    }
    if (withFillingRow2On && !_hasQuantityInRange(nextQty, 3, 5)) {
      withFillingRow2On = false;
    }
    emit(
      state.copyWith(
        quantities: nextQty,
        couponLine1On: c1,
        couponLine2On: c2,
        withFillingRow1On: withFillingRow1On,
        withFillingRow2On: withFillingRow2On,
      ),
    );
  }

  void toggleWithFillingRow1() {
    if (!state.withFillingRow1On && !state.hasQuantityInEmptySaleRow1) {
      return;
    }
    emit(state.copyWith(withFillingRow1On: !state.withFillingRow1On));
  }

  void toggleWithFillingRow2() {
    if (!state.withFillingRow2On && !state.hasQuantityInEmptySaleRow2) {
      return;
    }
    emit(state.copyWith(withFillingRow2On: !state.withFillingRow2On));
  }

  void setPaymentMethod(VehicleSalePaymentMethod method) {
    emit(state.copyWith(paymentMethod: method));
  }

  void toggleCouponLine(int productIndex) {
    if (productIndex == 0) {
      emit(state.copyWith(couponLine1On: !state.couponLine1On));
    } else if (productIndex == 1) {
      emit(state.copyWith(couponLine2On: !state.couponLine2On));
    }
  }

  _LineBuild _buildLines() {
    final List<StationSaleLine> lines = <StationSaleLine>[];
    for (var i = 0; i < state.colCount; i++) {
      final int q = state.quantities[i];
      if (q <= 0) {
        continue;
      }
      final String? pid = state.productIds[i];
      final double? catalogUnit = state.unitPrices[i];
      final bool couponPriceZero =
          state.entryKind == StationSaleEntryKind.filling &&
              ((i == 0 && state.couponLine1On) ||
                  (i == 1 && state.couponLine2On));
      if (pid == null) {
        return (
          lines: null,
          err: StationSaleValidationError.invalidRow,
        );
      }
      if (!couponPriceZero && (catalogUnit == null || catalogUnit < 0)) {
        return (
          lines: null,
          err: StationSaleValidationError.checkPrice,
        );
      }
      final double unit = couponPriceZero ? 0.0 : catalogUnit!;
      lines.add(
        (
          productId: pid,
          quantity: q,
          unitPrice: unit,
          columnIndex: i,
          note: couponPriceZero ? kFillingCouponSaleNote : null,
        ),
      );
    }
    if (lines.isEmpty) {
      return (
        lines: null,
        err: StationSaleValidationError.needLine,
      );
    }
    final Map<String, int> demand = <String, int>{};
    for (final StationSaleLine line in lines) {
      if (line.columnIndex < state.columnSkipsStationStock.length &&
          !state.columnSkipsStationStock[line.columnIndex]) {
        demand[line.productId] =
            (demand[line.productId] ?? 0) + line.quantity;
      }
    }
    for (final MapEntry<String, int> e in demand.entries) {
      if (e.value >
          _stationStockForProductId(
            state,
            e.key,
          )) {
        return (
          lines: null,
          err: StationSaleValidationError.insufficientStock,
        );
      }
    }
    return (lines: lines, err: null);
  }

  /// للتحقق من الواجهة قبل استدعاء [submit].
  StationSaleValidationError? validate() {
    return _buildLines().err;
  }

  Future<void> submit() async {
    if (state.paymentMethod == null) {
      emit(
        state.copyWith(
          submitError: kStationSalePaymentMethodRequiredMarker,
        ),
      );
      return;
    }
    final _LineBuild built = _buildLines();
    if (built.err != null) {
      return;
    }
    final List<StationSaleLine> lines = built.lines!;
    emit(
      state.copyWith(
        submitting: true,
        clearSubmitError: true,
        submitSucceeded: false,
      ),
    );
    try {
      final bool fillingSale =
          state.entryKind == StationSaleEntryKind.filling;
      final Map<String, ({int quantity, double unitPrice, int? columnIndex, String? note})>
          mergedByProduct = <String,
              ({int quantity, double unitPrice, int? columnIndex, String? note})>{};
      for (final StationSaleLine line in lines) {
        final double unitOut = line.unitPrice +
            emptySaleWithFillingSurchargeForColumn(
              columnIndex: line.columnIndex,
              row1On: state.withFillingRow1On,
              row2On: state.withFillingRow2On,
              row1Surcharge: state.emptySaleWithFillingSurchargeRow1,
              row2Surcharge: state.emptySaleWithFillingSurchargeRow2,
            );
        final String pid = line.productId;
        final ({int quantity, double unitPrice, int? columnIndex, String? note})?
            existing = mergedByProduct[pid];
        if (existing != null) {
          mergedByProduct[pid] = (
            quantity: existing.quantity + line.quantity,
            unitPrice: existing.unitPrice,
            columnIndex: existing.columnIndex,
            note: existing.note,
          );
        } else {
          mergedByProduct[pid] = (
            quantity: line.quantity,
            unitPrice: unitOut,
            columnIndex: line.columnIndex,
            note: line.note,
          );
        }
      }
      final List<Map<String, dynamic>> batchLines =
          mergedByProduct.entries
              .map(
                (MapEntry<String,
                        ({int quantity, double unitPrice, int? columnIndex, String? note})>
                    entry) => <String, dynamic>{
                  'productId': entry.key,
                  'quantity': entry.value.quantity,
                  'unitPrice': entry.value.unitPrice,
                  if (fillingSale) 'fillingLineSlot': entry.value.columnIndex,
                  if (entry.value.note != null) 'note': entry.value.note,
                },
              )
              .toList(growable: false);
      await _createStationSale.callBatch(
        lines: batchLines,
        fillingSale: fillingSale,
        paymentMethod: state.paymentMethod!.firestoreValue,
      );
      emit(
        state.copyWith(
          submitting: false,
          submitSucceeded: true,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          submitError: e.code == 'INSUFFICIENT_STOCK'
              ? kStationSaleInsufficientStockSubmitMarker
              : e.message,
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
}

int _stationStockForProductId(StationSaleFormState state, String productId) {
  for (var i = 0; i < state.colCount; i++) {
    if (state.productIds[i] == productId &&
        i < state.columnSkipsStationStock.length &&
        !state.columnSkipsStationStock[i]) {
      return i < state.columnStationStock.length
          ? state.columnStationStock[i]
          : 0;
    }
  }
  return 0;
}

String? _unitTypeFromProductJson(Map<String, dynamic> pr) {
  final Object? u = pr['unitType'] ?? pr['type'];
  final String? s = u?.toString();
  if (s == null || s.isEmpty) {
    return null;
  }
  return s;
}

/// يطابق أعمدة الشاشة مع `ProductUnitType` في الـ API عندما لا يطابق الاسم الإنجليزي الثابت.
///
/// بيع فارغ: ق سعودي / ق اردني / ج فارغ / ق صغير فارغ / ج صغير فارغ — بالاسم أو صف الرصيد.
/// حتى لا يُختار نفس منتج [bottle] مرتين عند التراجع عن التطابق بالاسم.
bool _hasQuantityInRange(List<int> quantities, int start, int end) {
  for (var i = start; i < end && i < quantities.length; i++) {
    if (quantities[i] > 0) {
      return true;
    }
  }
  return false;
}

String? _unitTypeForStationSaleSlot(StationSaleEntryKind kind, int index) {
  if (kind == StationSaleEntryKind.emptySale) {
    return null;
  }
  return switch (index) {
    0 || 2 => 'gallon',
    1 || 3 => 'bottle',
    4 => 'carton',
    5 || 6 || 7 => 'coupon',
    _ => null,
  };
}
