import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class ReturnSubmitCubit extends Cubit<SubmitState> {
  ReturnSubmitCubit(this._useCase) : super(const SubmitIdle());

  final CreateReturnUseCase _useCase;

  Future<void> submit({
    required String vehicleLoadId,
    required int quantityReturned,
  }) async {
    emit(const SubmitLoading());
    try {
      await _useCase(
        vehicleLoadId: vehicleLoadId,
        quantityReturned: quantityReturned,
      );
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(e.toString()));
    }
  }
}
