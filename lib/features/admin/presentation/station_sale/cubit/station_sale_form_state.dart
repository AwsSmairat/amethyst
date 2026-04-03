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
    required this.withFilling,
    required this.couponLine1On,
    required this.couponLine2On,
  });

  factory StationSaleFormState.initial(StationSaleEntryKind entryKind) {
    final int n = entryKind == StationSaleEntryKind.filling ? 4 : 2;
    return StationSaleFormState(
      entryKind: entryKind,
      loadingProducts: true,
      submitting: false,
      submitSucceeded: false,
      quantities: List<int>.filled(n, 0),
      productIds: List<String?>.filled(n, null),
      unitPrices: List<double?>.filled(n, null),
      withFilling: false,
      couponLine1On: false,
      couponLine2On: false,
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
  final bool withFilling;
  final bool couponLine1On;
  final bool couponLine2On;

  int get colCount =>
      entryKind == StationSaleEntryKind.filling ? 4 : 2;

  bool get showCouponUnderProduct1And2 =>
      entryKind == StationSaleEntryKind.filling ||
      entryKind == StationSaleEntryKind.emptySale;

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
    bool? withFilling,
    bool? couponLine1On,
    bool? couponLine2On,
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
      withFilling: withFilling ?? this.withFilling,
      couponLine1On: couponLine1On ?? this.couponLine1On,
      couponLine2On: couponLine2On ?? this.couponLine2On,
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
        withFilling,
        couponLine1On,
        couponLine2On,
      ];
}
