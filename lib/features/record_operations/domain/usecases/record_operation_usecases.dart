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
    String? note,
  }) =>
      _repository.createStationSale(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        fillingSale: fillingSale,
        fillingLineSlot: fillingLineSlot,
        note: note,
      );

  Future<void> callBatch({
    required List<Map<String, dynamic>> lines,
    bool fillingSale = false,
  }) =>
      _repository.createStationSalesBatch(
        lines: lines,
        fillingSale: fillingSale,
      );
}

final class CreateStationDebtEntriesUseCase {
  CreateStationDebtEntriesUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) =>
      _repository.createStationDebtEntries(
        debtorName: debtorName,
        lines: lines,
      );
}

final class RepayStationDebtUseCase {
  RepayStationDebtUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<Map<String, dynamic>> call({required String debtorName}) =>
      _repository.repayStationDebt(debtorName: debtorName);
}

final class RepayStationDebtFromVehicleUseCase {
  RepayStationDebtFromVehicleUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<Map<String, dynamic>> call({required String debtorName}) =>
      _repository.repayStationDebtFromVehicle(debtorName: debtorName);
}

final class CreateVehicleSaleUseCase {
  CreateVehicleSaleUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String saleDestination = 'home',
    String? stockProductId,
    String? debtorName,
    bool isDebt = false,
    bool skipLoadDeduction = false,
  }) =>
      _repository.createVehicleSale(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        saleDestination: saleDestination,
        stockProductId: stockProductId,
        debtorName: debtorName,
        isDebt: isDebt,
        skipLoadDeduction: skipLoadDeduction,
      );
}

final class CreateVehicleSalesBatchUseCase {
  CreateVehicleSalesBatchUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String vehicleId,
    required List<Map<String, dynamic>> lines,
    String saleDestination = 'home',
  }) =>
      _repository.createVehicleSalesBatch(
        vehicleId: vehicleId,
        lines: lines,
        saleDestination: saleDestination,
      );
}

final class PatchProductStationStockUseCase {
  PatchProductStationStockUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String productId,
    required int stationStock,
  }) =>
      _repository.patchProductStationStock(
        productId: productId,
        stationStock: stationStock,
      );
}

final class DeductStationStockForSaleUseCase {
  DeductStationStockForSaleUseCase(this._repository);

  final RecordOperationsRepository _repository;

  Future<void> call({
    required String productId,
    required int quantity,
  }) =>
      _repository.deductStationStockForSale(
        productId: productId,
        quantity: quantity,
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
    String? loadBatchId,
  }) =>
      _repository.createVehicleLoad(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: productId,
        quantityLoaded: quantityLoaded,
        loadDate: loadDate,
        loadBatchId: loadBatchId,
      );

  Future<void> callBatch({
    required String vehicleId,
    required String driverId,
    required String loadDate,
    required List<Map<String, dynamic>> lines,
    String? loadBatchId,
  }) =>
      _repository.createVehicleLoadsBatch(
        vehicleId: vehicleId,
        driverId: driverId,
        loadDate: loadDate,
        lines: lines,
        loadBatchId: loadBatchId,
      );
}
