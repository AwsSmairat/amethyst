import 'package:amethyst/features/admin/presentation/station_sale/station_sale_api_product_names.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_validation.dart';
import 'package:amethyst/features/admin/presentation/station_sale/cubit/station_sale_form_state.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef StationSaleLine = ({
  String productId,
  int quantity,
  double unitPrice,
  /// في شاشة التعبئة: ٠ = جالون، ١ = قارورة، ٢ = مهدي، ٣ = كوبون.
  int columnIndex,
});

typedef _LineBuild = ({
  List<StationSaleLine>? lines,
  StationSaleValidationError? err,
});

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
        final String name = i < apiNames.length ? apiNames[i] : '';
        final Map<String, dynamic>? match =
            name.isNotEmpty ? byName[name] : null;
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
      emit(
        state.copyWith(
          loadingProducts: false,
          productIds: ids,
          unitPrices: prices,
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
    emit(
      state.copyWith(
        quantities: nextQty,
        couponLine1On: c1,
        couponLine2On: c2,
      ),
    );
  }

  void toggleWithFilling() {
    emit(state.copyWith(withFilling: !state.withFilling));
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
      final double? unit = state.unitPrices[i];
      if (pid == null) {
        return (
          lines: null,
          err: StationSaleValidationError.invalidRow,
        );
      }
      if (unit == null || unit < 0) {
        return (
          lines: null,
          err: StationSaleValidationError.checkPrice,
        );
      }
      lines.add(
        (
          productId: pid,
          quantity: q,
          unitPrice: unit,
          columnIndex: i,
        ),
      );
    }
    if (lines.isEmpty) {
      return (
        lines: null,
        err: StationSaleValidationError.needLine,
      );
    }
    return (lines: lines, err: null);
  }

  /// للتحقق من الواجهة قبل استدعاء [submit].
  StationSaleValidationError? validate() {
    return _buildLines().err;
  }

  Future<void> submit() async {
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
      for (final StationSaleLine line in lines) {
        await _createStationSale(
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          fillingSale: fillingSale,
          fillingLineSlot: fillingSale ? line.columnIndex : null,
        );
      }
      emit(
        state.copyWith(
          submitting: false,
          submitSucceeded: true,
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

String? _unitTypeFromProductJson(Map<String, dynamic> pr) {
  final Object? u = pr['unitType'] ?? pr['type'];
  final String? s = u?.toString();
  if (s == null || s.isEmpty) {
    return null;
  }
  return s;
}

/// يطابق أعمدة الشاشة مع `ProductUnitType` في الـ API عندما لا يطابق الاسم الإنجليزي الثابت.
String? _unitTypeForStationSaleSlot(StationSaleEntryKind kind, int index) {
  if (kind == StationSaleEntryKind.emptySale) {
    return switch (index) {
      0 => 'gallon',
      1 => 'bottle',
      _ => null,
    };
  }
  return switch (index) {
    0 => 'gallon',
    1 => 'bottle',
    2 => 'carton',
    3 => 'coupon',
    _ => null,
  };
}
