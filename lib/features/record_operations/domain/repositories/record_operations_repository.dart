import 'dart:typed_data';

abstract class RecordOperationsRepository {
  /// عناصر المنتجات من الـ API (قائمة خرائط خام).
  Future<List<Map<String, dynamic>>> listProductItems();

  /// تحديث مخزون المحطة لمنتج (PATCH /products/:id/stock).
  Future<void> patchProductStationStock({
    required String productId,
    required int stationStock,
  });

  Future<void> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  });

  /// دين محطة — منفصل عن مبيعات المحطة.
  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  });

  Future<void> createVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    /// `store` = بيع من السيارة للمتاجر؛ `home` = للمنازل (الافتراضي).
    String saleDestination = 'home',
  });

  Future<void> createExpense({
    String? vehicleId,
    required double amount,
    String? note,
    Uint8List? receiptBytes,
    String? receiptFilename,
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
