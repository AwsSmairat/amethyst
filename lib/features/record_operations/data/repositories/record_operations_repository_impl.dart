import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/features/record_operations/domain/repositories/record_operations_repository.dart';

final class RecordOperationsRepositoryImpl implements RecordOperationsRepository {
  RecordOperationsRepositoryImpl(this._api);

  final AmethystApi _api;

  @override
  Future<void> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
  }) =>
      _api.createStationSale(
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
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
  }) =>
      _api.createExpense(vehicleId: vehicleId, amount: amount, note: note);

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
