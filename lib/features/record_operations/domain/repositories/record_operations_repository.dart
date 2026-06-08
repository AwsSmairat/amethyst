import 'dart:typed_data';

abstract class RecordOperationsRepository {
  /// عناصر المنتجات من الـ API (قائمة خرائط خام).
  Future<List<Map<String, dynamic>>> listProductItems();

  /// تحديث مخزون المحطة لمنتج (PATCH /products/:id/stock).
  Future<void> patchProductStationStock({
    required String productId,
    required int stationStock,
  });

  /// خصم كمية من مخزون المحطة بعد بيع/دين (صف رصيد قد يجمع عدة منتجات).
  Future<void> deductStationStockForSale({
    required String productId,
    required int quantity,
  });

  /// حفظ رصيد صف في نموذج المحطة (إنشاء منتج إن لم يكن مربوطاً).
  Future<void> upsertStationBalanceRowStock({
    required int rowIndex,
    required int stationStock,
  });

  /// حفظ عدة صفوف رصيد دفعة واحدة (أسرع من استدعاء [upsertStationBalanceRowStock] لكل صف).
  Future<void> saveStationBalanceRows({
    required List<Map<String, dynamic>> rows,
  });

  Future<void> createStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    bool fillingSale = false,
    int? fillingLineSlot,
    String? note,
  });

  Future<void> createStationSalesBatch({
    required List<Map<String, dynamic>> lines,
    bool fillingSale = false,
    String? paymentMethod,
  });

  /// دين محطة — منفصل عن مبيعات المحطة.
  Future<void> createStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  });

  Future<Map<String, dynamic>> repayStationDebt({
    required String debtorName,
  });

  /// سداد دين لكن يُحتسب ضمن بيع السيارة (driver only).
  Future<Map<String, dynamic>> repayStationDebtFromVehicle({
    required String debtorName,
  });

  Future<void> createVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    /// `store` = بيع من السيارة للمتاجر؛ `home` = للمنازل (الافتراضي).
    String saleDestination = 'home',
    /// عند بيع «مهدي متجر»: خصم الحمولة/المخزون من هذا المعرّف (مثلاً ك مهدي).
    String? stockProductId,
    /// دين من المركبة: يُسجَّل كمبيع سيارة مع اسم المدين.
    String? debtorName,
    bool isDebt = false,
    /// جالون/قاروره دين: لا يُخصم من حمولة السيارة.
    bool skipLoadDeduction = false,
  });

  /// عدة أسطر بيع + خصم حمولة/مخزون محطة في طلب Firestore واحد.
  Future<void> createVehicleSalesBatch({
    required String vehicleId,
    required List<Map<String, dynamic>> lines,
    String saleDestination = 'home',
    String? paymentMethod,
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
    String? loadBatchId,
  });

  /// عدة منتجات في نفس التحميل — طلب Firestore واحد.
  Future<void> createVehicleLoadsBatch({
    required String vehicleId,
    required String driverId,
    required String loadDate,
    required List<Map<String, dynamic>> lines,
    String? loadBatchId,
  });
}
