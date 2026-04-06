import 'package:equatable/equatable.dart';

final class StationDebtRegistrationState extends Equatable {
  const StationDebtRegistrationState({
    required this.loadingProducts,
    this.loadError,
    required this.submitting,
    this.submitError,
    required this.submitSucceeded,
    required this.quantities,
    required this.productIds,
    required this.unitPrices,
    required this.columnSkipsStationStock,
    required this.columnStationStock,
  });

  factory StationDebtRegistrationState.initial() =>
      StationDebtRegistrationState(
        loadingProducts: true,
        submitting: false,
        submitSucceeded: false,
        quantities: List<int>.filled(colCount, 0),
        productIds: List<String?>.filled(colCount, null),
        unitPrices: List<double?>.filled(colCount, null),
        columnSkipsStationStock: List<bool>.filled(colCount, false),
        columnStationStock: List<int>.filled(colCount, 0),
      );

  static const int colCount = 6;

  final bool loadingProducts;
  final String? loadError;
  final bool submitting;
  final String? submitError;
  final bool submitSucceeded;
  final List<int> quantities;
  final List<String?> productIds;
  final List<double?> unitPrices;
  final List<bool> columnSkipsStationStock;
  final List<int> columnStationStock;

  StationDebtRegistrationState copyWith({
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
    List<bool>? columnSkipsStationStock,
    List<int>? columnStationStock,
  }) {
    return StationDebtRegistrationState(
      loadingProducts: loadingProducts ?? this.loadingProducts,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      submitting: submitting ?? this.submitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      submitSucceeded: submitSucceeded ?? this.submitSucceeded,
      quantities: quantities ?? this.quantities,
      productIds: productIds ?? this.productIds,
      unitPrices: unitPrices ?? this.unitPrices,
      columnSkipsStationStock:
          columnSkipsStationStock ?? this.columnSkipsStationStock,
      columnStationStock: columnStationStock ?? this.columnStationStock,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        loadingProducts,
        loadError,
        submitting,
        submitError,
        submitSucceeded,
        quantities,
        productIds,
        unitPrices,
        columnSkipsStationStock,
        columnStationStock,
      ];
}
