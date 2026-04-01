abstract class RecordOperationsRepository {
  Future<void> createVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
  });

  Future<void> createExpense({
    String? vehicleId,
    required double amount,
    String? note,
  });

  Future<void> createReturn({
    required String vehicleLoadId,
    required int quantityReturned,
  });

  Future<void> createVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
  });
}
