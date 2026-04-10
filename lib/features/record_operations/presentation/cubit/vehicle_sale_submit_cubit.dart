import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef VehicleSaleLineInput = ({
  String productId,
  int quantity,
  double unitPrice,
  bool deductStationStock,
  int stationStockSnapshot,
});

final class VehicleSaleSubmitCubit extends Cubit<SubmitState> {
  VehicleSaleSubmitCubit(
    this._useCase,
    this._patchStationStock,
  ) : super(const SubmitIdle());

  final CreateVehicleSaleUseCase _useCase;
  final PatchProductStationStockUseCase _patchStationStock;

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
      emit(SubmitFailure(e.toString()));
    }
  }

  Future<void> submitLines({
    required String vehicleId,
    required List<({String productId, int quantity, double unitPrice})> lines,
    String saleDestination = 'home',
  }) async {
    emit(const SubmitLoading());
    try {
      for (final line in lines) {
        await _useCase(
          vehicleId: vehicleId,
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          saleDestination: saleDestination,
        );
      }
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(e.toString()));
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
  }) async {
    emit(const SubmitLoading());
    try {
      for (final line in lines) {
        await _useCase(
          vehicleId: vehicleId,
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          saleDestination: saleDestination,
        );
        if (line.deductStationStock) {
          final int next = (line.stationStockSnapshot - line.quantity);
          await _patchStationStock(
            productId: line.productId,
            stationStock: next < 0 ? 0 : next,
          );
        }
      }
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(e.toString()));
    }
  }
}
