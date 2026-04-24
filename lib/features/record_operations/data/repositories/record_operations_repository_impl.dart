import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/features/record_operations/domain/repositories/record_operations_repository.dart';
import 'dart:typed_data';

final class RecordOperationsRepositoryImpl implements RecordOperationsRepository {
  RecordOperationsRepositoryImpl(this._api);

  final AmethystApi _api;

  @override
  Future<List<Map<String, dynamic>>> listProductItems() async {
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    var page = 1;
    const int limit = 100;
    while (true) {
      final Map<String, dynamic> p =
          await _api.listProducts(page: page, limit: limit);
      final List<Map<String, dynamic>> items =
          (p['items'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      all.addAll(items);
      final int total = switch (p['total']) {
        final int t => t,
        final num t => t.toInt(),
        _ => all.length,
      };
      if (items.length < limit || all.length >= total) {
        break;
      }
      page++;
    }
    return all;
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
  }) =>
      _api.createVehicleSale(
        vehicleId: vehicleId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
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
  }) =>
      _api.createVehicleLoad(
        vehicleId: vehicleId,
        driverId: driverId,
        productId: productId,
        quantityLoaded: quantityLoaded,
        loadDate: loadDate,
      );
}
