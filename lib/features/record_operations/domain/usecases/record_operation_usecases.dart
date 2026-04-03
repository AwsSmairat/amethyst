import 'package:amethyst/features/record_operations/domain/repositories/record_operations_repository.dart';
import 'dart:typed_data';

final class ListProductItemsUseCase {
  ListProductItemsUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<List<Map<String, dynamic>>> call() => _repository.listProductItems();
}

final class CreateStationSaleUseCase {
  CreateStationSaleUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
  }) =>
      _repository.createStationSale(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        fillingSale: fillingSale,
        fillingLineSlot: fillingLineSlot,
      );
}

final class CreateVehicleSaleUseCase {
  CreateVehicleSaleUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
  }) =>
      _repository.createVehicleSale(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
      );
}

final class CreateExpenseUseCase {
  CreateExpenseUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    String? vehicleId,
    required double amount,
    String? note,
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) =>
      _repository.createExpense(
        vehicleId: vehicleId,
        amount: amount,
        note: note,
        receiptBytes: receiptBytes,
        receiptFilename: receiptFilename,
      );
}

final class CreateReturnUseCase {
  CreateReturnUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String vehicleLoadId,
    required int quantityReturned,
  }) =>
      _repository.createReturn(
        vehicleLoadId: vehicleLoadId,
        quantityReturned: quantityReturned,
      );
}

final class CreateVehicleLoadUseCase {
  CreateVehicleLoadUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
  }) =>
      _repository.createVehicleLoad(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: productId,
        quantityLoaded: quantityLoaded,
        loadDate: loadDate,
      );
}
