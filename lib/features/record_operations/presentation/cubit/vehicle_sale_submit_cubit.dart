import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef VehicleSaleLineInput = ({
  String productId,
  int quantity,
  double unitPrice,
  bool deductStationStock,
  int stationStockSnapshot,
  /// معرّف مخزون الحمولة/المحطة عند اختلافه عن [productId] (مهدي متجر ← ك مهدي).
  String? stockProductId,
});

final class VehicleSaleSubmitCubit extends Cubit<SubmitState> {
  VehicleSaleSubmitCubit(
    this._useCase,
    this._batchUseCase,
  ) : super(const SubmitIdle());

  final CreateVehicleSaleUseCase _useCase;
  final CreateVehicleSalesBatchUseCase _batchUseCase;

  Future<void> submit({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String saleDestination = 'home',
  }) async {
    emit(const SubmitLoading());
    try {
      await _useCase(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        saleDestination: saleDestination,
      );
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(errorMessageFrom(e)));
    }
  }

  Future<void> submitLines({
    required String vehicleId,
    required List<({String productId, int quantity, double unitPrice})> lines,
    String saleDestination = 'home',
  }) async {
    emit(const SubmitLoading());
    try {
      await _batchUseCase(
        vehicleId: vehicleId,
        saleDestination: saleDestination,
        lines: lines
            .map(
              (({String productId, int quantity, double unitPrice}) line) =>
                  <String, dynamic>{
                'productId': line.productId,
                'quantity': line.quantity,
                'unitPrice': line.unitPrice,
              },
            )
            .toList(growable: false),
      );
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(errorMessageFrom(e)));
    }
  }

  /// يسجل البيع ثم يخصم من مخزون المحطة لبعض السطور (حسب [deductStationStock]).
  ///
  /// [stationStockSnapshot] مطلوب لأن واجهة السائق لا تحمل لقطة مخزون متزامنة
  /// بعد كل عملية — نخصم من اللقطة التي عُرضت/تحقّقنا منها عند الإدخال.
  Future<void> submitLinesAndDeductStationStock({
    required String vehicleId,
    required List<VehicleSaleLineInput> lines,
    String saleDestination = 'home',
    String? paymentMethod,
  }) async {
    emit(const SubmitLoading());
    try {
      await _batchUseCase(
        vehicleId: vehicleId,
        saleDestination: saleDestination,
        paymentMethod: paymentMethod,
        lines: lines
            .map(
              (VehicleSaleLineInput line) => <String, dynamic>{
                'productId': line.productId,
                'quantity': line.quantity,
                'unitPrice': line.unitPrice,
                if (line.stockProductId != null)
                  'stockProductId': line.stockProductId,
                'deductStationStock': line.deductStationStock,
              },
            )
            .toList(growable: false),
      );
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(errorMessageFrom(e)));
    }
  }
}
