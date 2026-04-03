import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/features/record_operations/domain/repositories/record_operations_repository.dart';

sealed class SaveStationBalanceOutcome {
  const SaveStationBalanceOutcome();
}

final class SaveStationBalanceSuccess extends SaveStationBalanceOutcome {
  const SaveStationBalanceSuccess();
}

final class SaveStationBalanceInvalidQuantity extends SaveStationBalanceOutcome {
  const SaveStationBalanceInvalidQuantity();
}

/// فهرس الصف (٠–١١) الذي لا يوجد له منتج مطابق في النظام.
final class SaveStationBalanceUnlinkedRow extends SaveStationBalanceOutcome {
  const SaveStationBalanceUnlinkedRow(this.rowIndex);

  final int rowIndex;
}

final class SaveStationBalanceFailure extends SaveStationBalanceOutcome {
  const SaveStationBalanceFailure(this.message);

  final String message;
}

/// يطبّق قيم نموذج رصيد المحطة على مخزون المنتجات عبر الـ API.
final class SaveStationBalanceUseCase {
  SaveStationBalanceUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<SaveStationBalanceOutcome> call(List<String> rawValues) async {
    if (rawValues.length < kStationBalanceRowCount) {
      return const SaveStationBalanceFailure('Invalid form state');
    }
    try {
      final List<Map<String, dynamic>> products =
          await _repository.listProductItems();
      for (var i = 0; i <= kStationBalanceLastFixedRowIndex; i++) {
        final ParsedStationStockInput parsed =
            parseStationStockInput(rawValues[i]);
        switch (parsed) {
          case ParsedStationStockSkip():
            continue;
          case ParsedStationStockInvalid():
            return const SaveStationBalanceInvalidQuantity();
          case final ParsedStationStockOk ok:
            final Map<String, dynamic>? match = resolveStationBalanceProduct(
              products: products,
              rowIndex: i,
            );
            if (match == null) {
              return SaveStationBalanceUnlinkedRow(i);
            }
            final String? id = match['id'] as String?;
            if (id == null || id.isEmpty) {
              return SaveStationBalanceUnlinkedRow(i);
            }
            await _repository.patchProductStationStock(
              productId: id,
              stationStock: ok.value,
            );
        }
      }
      return const SaveStationBalanceSuccess();
    } on Object catch (e) {
      return SaveStationBalanceFailure(e.toString());
    }
  }
}
