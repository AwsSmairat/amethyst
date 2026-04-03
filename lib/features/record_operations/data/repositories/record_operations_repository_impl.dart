import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/features/record_operations/domain/repositories/record_operations_repository.dart';
import 'dart:typed_data';

final class RecordOperationsRepositoryImpl implements RecordOperationsRepository {
  RecordOperationsRepositoryImpl(this._api);

  final AmethystApi _api;

  @override
  Future<List<Map<String, dynamic>>> listProductItems() async {
    final Map<String, dynamic> p = await _api.listProducts();
    return (p['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

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
  Future<void> createVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
  }) =>
      _api.createVehicleSale(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
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
  }) =>
      _api.createVehicleLoad(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: productId,
        quantityLoaded: quantityLoaded,
        loadDate: loadDate,
      );
}
