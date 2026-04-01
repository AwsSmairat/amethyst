import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class ExpenseSubmitCubit extends Cubit<SubmitState> {
  ExpenseSubmitCubit(this._useCase) : super(const SubmitIdle());

  final CreateExpenseUseCase _useCase;

  Future<void> submit({
    String? vehicleId,
    required double amount,
    String? note,
  }) async {
    emit(const SubmitLoading());
    try {
      await _useCase(vehicleId: vehicleId, amount: amount, note: note);
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(e.toString()));
    }
  }
}
