import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/record_operations/presentation/cubit/submit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class StationSaleSubmitCubit extends Cubit<SubmitState> {
  StationSaleSubmitCubit(this._useCase) : super(const SubmitIdle());

  final CreateStationSaleUseCase _useCase;

  Future<void> submit({
    required String productId,
    required int quantity,
    required double unitPrice,
  }) async {
    emit(const SubmitLoading());
    try {
      await _useCase(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
      );
      emit(const SubmitSuccess());
    } on Object catch (e) {
      emit(SubmitFailure(errorMessageFrom(e)));
    }
  }

  /// عدة منتجات — طلب Firestore واحد.
  Future<void> submitLines({
    required List<({String productId, int quantity, double unitPrice})> lines,
  }) async {
    emit(const SubmitLoading());
    try {
      await _useCase.callBatch(
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
}
