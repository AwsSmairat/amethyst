import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class VehicleLoadSubmitCubit extends Cubit<SubmitState> {
  VehicleLoadSubmitCubit(this._useCase) : super(const SubmitIdle());

  final CreateVehicleLoadUseCase _useCase;

  Future<void> submit({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
  }) async {
    emit(const SubmitLoading());
    try {
      await _useCase(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: productId,
        quantityLoaded: quantityLoaded,
        loadDate: loadDate,
      );
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(errorMessageFrom(e)));
    }
  }

  /// عدة منتجات في نفس التاريخ والمركبة والسائق (طلب API لكل سطر).
  Future<void> submitLines({
    required String vehicleId,
    required String driverId,
    required String loadDate,
    required List<({String productId, int quantityLoaded})> lines,
  }) async {
    emit(const SubmitLoading());
    try {
      final String batchId =
          'batch_${DateTime.now().millisecondsSinceEpoch}';
      for (final line in lines) {
        await _useCase(
          vehicleId: vehicleId,
          driverId: driverId,
          productId: line.productId,
          quantityLoaded: line.quantityLoaded,
          loadDate: loadDate,
          loadBatchId: batchId,
        );
      }
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(errorMessageFrom(e)));
    }
  }
}
