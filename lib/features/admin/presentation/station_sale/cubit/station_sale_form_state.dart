import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:equatable/equatable.dart';

final class StationSaleFormState extends Equatable {
  const StationSaleFormState({
    required this.entryKind,
    required this.loadingProducts,
    this.loadError,
    required this.submitting,
    this.submitError,
    required this.submitSucceeded,
    required this.quantities,
    required this.productIds,
    required this.unitPrices,
    required this.withFillingRow1On,
    required this.withFillingRow2On,
    required this.emptySaleWithFillingSurchargeRow1,
    required this.emptySaleWithFillingSurchargeRow2,
    required this.couponLine1On,
    required this.couponLine2On,
    required this.columnSkipsStationStock,
    required this.columnStationStock,
  });

  factory StationSaleFormState.initial(StationSaleEntryKind entryKind) {
    final int n = entryKind == StationSaleEntryKind.filling
        ? kStationFillingColumnCount
        : kStationEmptySaleColumnCount;
    return StationSaleFormState(
      entryKind: entryKind,
      loadingProducts: true,
      submitting: false,
      submitSucceeded: false,
      quantities: List<int>.filled(n, 0),
      productIds: List<String?>.filled(n, null),
      unitPrices: List<double?>.filled(n, null),
      withFillingRow1On: false,
      withFillingRow2On: false,
      emptySaleWithFillingSurchargeRow1: 0.5,
      emptySaleWithFillingSurchargeRow2: 0.5,
      couponLine1On: false,
      couponLine2On: false,
      columnSkipsStationStock: List<bool>.filled(n, false),
      columnStationStock: List<int>.filled(n, 0),
    );
  }

  final StationSaleEntryKind entryKind;
  final bool loadingProducts;
  final String? loadError;
  final bool submitting;
  final String? submitError;
  final bool submitSucceeded;
  final List<int> quantities;
  final List<String?> productIds;
  final List<double?> unitPrices;
  final bool withFillingRow1On;
  final bool withFillingRow2On;
  final double emptySaleWithFillingSurchargeRow1;
  final double emptySaleWithFillingSurchargeRow2;
  final bool couponLine1On;
  final bool couponLine2On;
  /// يُحدَّد من الخادم (تعبئة: جالون/قارورة العمودين ٠–١ وما شابه لا يُخصم).
  final List<bool> columnSkipsStationStock;
  /// لقطة مخزون المحطة عند التحميل (للأعمدة التي يُخصم منها).
  final List<int> columnStationStock;

  int get colCount => entryKind == StationSaleEntryKind.filling
      ? kStationFillingColumnCount
      : kStationEmptySaleColumnCount;

  bool get showCouponUnderProduct1And2 =>
      entryKind == StationSaleEntryKind.filling;

  /// بيع فارغ — هل يوجد كمية على أحد المنتجات ١–٣؟
  bool get hasQuantityInEmptySaleRow1 {
    if (entryKind != StationSaleEntryKind.emptySale) {
      return false;
    }
    for (var i = 0; i <= kStationEmptySaleWithFillingRow1LastColumn; i++) {
      if (i < quantities.length && quantities[i] > 0) {
        return true;
      }
    }
    return false;
  }

  /// بيع فارغ — هل يوجد كمية على أحد المنتجين ٤–٥؟
  bool get hasQuantityInEmptySaleRow2 {
    if (entryKind != StationSaleEntryKind.emptySale) {
      return false;
    }
    for (var i = kStationEmptySaleWithFillingRow2FirstColumn;
        i < kStationEmptySaleColumnCount;
        i++) {
      if (i < quantities.length && quantities[i] > 0) {
        return true;
      }
    }
    return false;
  }

  StationSaleFormState copyWith({
    bool? loadingProducts,
    String? loadError,
    bool clearLoadError = false,
    bool? submitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? submitSucceeded,
    List<int>? quantities,
    List<String?>? productIds,
    List<double?>? unitPrices,
    bool? withFillingRow1On,
    bool? withFillingRow2On,
    double? emptySaleWithFillingSurchargeRow1,
    double? emptySaleWithFillingSurchargeRow2,
    bool? couponLine1On,
    bool? couponLine2On,
    List<bool>? columnSkipsStationStock,
    List<int>? columnStationStock,
  }) {
    return StationSaleFormState(
      entryKind: entryKind,
      loadingProducts: loadingProducts ?? this.loadingProducts,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitSucceeded: submitSucceeded ?? this.submitSucceeded,
      quantities: quantities ?? this.quantities,
      productIds: productIds ?? this.productIds,
      unitPrices: unitPrices ?? this.unitPrices,
      withFillingRow1On: withFillingRow1On ?? this.withFillingRow1On,
      withFillingRow2On: withFillingRow2On ?? this.withFillingRow2On,
      emptySaleWithFillingSurchargeRow1: emptySaleWithFillingSurchargeRow1 ??
          this.emptySaleWithFillingSurchargeRow1,
      emptySaleWithFillingSurchargeRow2: emptySaleWithFillingSurchargeRow2 ??
          this.emptySaleWithFillingSurchargeRow2,
      couponLine1On: couponLine1On ?? this.couponLine1On,
      couponLine2On: couponLine2On ?? this.couponLine2On,
      columnSkipsStationStock:
          columnSkipsStationStock ?? this.columnSkipsStationStock,
      columnStationStock: columnStationStock ?? this.columnStationStock,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        entryKind,
        loadingProducts,
        loadError,
        submitting,
        submitError,
        submitSucceeded,
        quantities,
        productIds,
        unitPrices,
        withFillingRow1On,
        withFillingRow2On,
        emptySaleWithFillingSurchargeRow1,
        emptySaleWithFillingSurchargeRow2,
        couponLine1On,
        couponLine2On,
        columnSkipsStationStock,
        columnStationStock,
      ];
}
