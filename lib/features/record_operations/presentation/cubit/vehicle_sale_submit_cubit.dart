import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class VehicleSaleSubmitCubit extends Cubit<SubmitState> {
  VehicleSaleSubmitCubit(this._useCase) : super(const SubmitIdle());

  final CreateVehicleSaleUseCase _useCase;

  Future<void> submit({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
  }) async {
    emit(const SubmitLoading());
    try {
      await _useCase(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
      );
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(e.toString()));
    }
  }

  Future<void> submitLines({
    required String vehicleId,
    required List<({String productId, int quantity, double unitPrice})> lines,
  }) async {
    emit(const SubmitLoading());
    try {
      for (final line in lines) {
        await _useCase(
          vehicleId: vehicleId,
          productId: line.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
        );
      }
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(e.toString()));
    }
  }
}
