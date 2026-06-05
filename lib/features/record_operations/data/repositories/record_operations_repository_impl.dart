import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/data/api_list_fetch.dart';
import 'package:amethyst/features/record_operations/domain/repositories/record_operations_repository.dart';
import 'dart:typed_data';

final class RecordOperationsRepositoryImpl implements RecordOperationsRepository {
  RecordOperationsRepositoryImpl(this._api);

  final AmethystApi _api;

  @override
  Future<List<Map<String, dynamic>>> listProductItems() =>
      fetchAllProducts(_api);

  @override
  Future<void> patchProductStationStock({
    required String productId,
    required int stationStock,
  }) =>
      _api.patchProductStationStock(
        id: productId,
        stationStock: stationStock,
      );

  @override
  Future<void> deductStationStockForSale({
    required String productId,
    required int quantity,
  }) =>
      _api.deductStationStockForSale(
        productId: productId,
        quantity: quantity,
      );

  @override
  Future<void> upsertStationBalanceRowStock({
    required int rowIndex,
    required int stationStock,
  }) =>
      _api.upsertStationBalanceRowStock(
        rowIndex: rowIndex,
        stationStock: stationStock,
      );

  @override
  Future<void> saveStationBalanceRows({
    required List<Map<String, dynamic>> rows,
  }) =>
      _api.saveStationBalanceRows(rows: rows);

  @override
  Future<void> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  }) =>
      _api.createStationSale(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        fillingSale: fillingSale,
        fillingLineSlot: fillingLineSlot,
        note: note,
      );

  @override
  Future<void> createStationSalesBatch({
    required List<Map<String, dynamic>> lines,
    bool fillingSale = false,
  }) =>
      _api.createStationSalesBatch(lines: lines, fillingSale: fillingSale);

  @override
  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) =>
      _api.createStationDebtEntries(
        debtorName: debtorName,
        lines: lines,
      );

  @override
  Future<Map<String, dynamic>> repayStationDebt({
    required String debtorName,
  }) =>
      _api.repayStationDebt(debtorName: debtorName);

  @override
  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
  }) =>
      _api.repayStationDebtFromVehicle(debtorName: debtorName);

  @override
  Future<void> createVehicleSale({
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
      _api.createVehicleSale(
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

  @override
  Future<void> createVehicleSalesBatch({
    required String vehicleId,
    required List<Map<String, dynamic>> lines,
    String saleDestination = 'home',
  }) =>
      _api.createVehicleSalesBatch(
        vehicleId: vehicleId,
        lines: lines,
        saleDestination: saleDestination,
      );

  @override
  Future<void> createExpense({
    String? vehicleId,
    required double amount,
    String? note,
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) =>
      _api.createExpense(
        vehicleId: vehicleId,
        amount: amount,
        note: note,
        receiptBytes: receiptBytes,
        receiptFilename: receiptFilename,
      );

  @override
  Future<void> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  }) =>
      _api.createReturn(
        vehicleLoadId: vehicleLoadId,
        quantityReturned: quantityReturned,
      );

  @override
  Future<void> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
    String? loadBatchId,
  }) =>
      _api.createVehicleLoad(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: productId,
        quantityLoaded: quantityLoaded,
        loadDate: loadDate,
        loadBatchId: loadBatchId,
      );

  @override
  Future<void> createVehicleLoadsBatch({
    required String vehicleId,
    required String driverId,
    required String loadDate,
    required List<Map<String, dynamic>> lines,
    String? loadBatchId,
  }) =>
      _api.createVehicleLoadsBatch(
        vehicleId: vehicleId,
        driverId: driverId,
        loadDate: loadDate,
        lines: lines,
        loadBatchId: loadBatchId,
      );
}
