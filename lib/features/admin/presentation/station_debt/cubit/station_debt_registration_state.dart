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
    required this.columnVehicleRemaining,
    required this.columnProductNames,
    required this.useVehicleProductLabels,
  });

  factory StationDebtRegistrationState.initial({
    int columnCount = 6,
    bool useVehicleProductLabels = false,
  }) =>
      StationDebtRegistrationState(
        loadingProducts: true,
        submitting: false,
        submitSucceeded: false,
        quantities: List<int>.filled(columnCount, 0),
        productIds: List<String?>.filled(columnCount, null),
        unitPrices: List<double?>.filled(columnCount, null),
        columnSkipsStationStock: List<bool>.filled(columnCount, false),
        columnStationStock: List<int>.filled(columnCount, 0),
        columnVehicleRemaining: List<int>.filled(columnCount, 0),
        columnProductNames: List<String>.filled(columnCount, ''),
        useVehicleProductLabels: useVehicleProductLabels,
      );

  /// أقصى عدد أعمدة (وضع المحطة).
  static const int adminColumnCount = 6;

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
  /// لقطة المتبقي على المركبة لكل عمود عند وضع السائق (٠ عند عدم توفرها).
  final List<int> columnVehicleRemaining;
  /// اسم العرض لكل عمود (من كتالوج الـ API) عند وضع المركبة؛ أو فارغ لاستخدام تسميات التعبئة.
  final List<String> columnProductNames;
  final bool useVehicleProductLabels;

  int get columnCount => quantities.length;

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
    List<int>? columnVehicleRemaining,
    List<String>? columnProductNames,
    bool? useVehicleProductLabels,
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
      columnVehicleRemaining:
          columnVehicleRemaining ?? this.columnVehicleRemaining,
      columnProductNames: columnProductNames ?? this.columnProductNames,
      useVehicleProductLabels:
          useVehicleProductLabels ?? this.useVehicleProductLabels,
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
        columnVehicleRemaining,
        columnProductNames,
        useVehicleProductLabels,
      ];
}
