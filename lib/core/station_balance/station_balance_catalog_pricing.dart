part of 'station_balance_catalog.dart';

/// اسم بيع «متجر» للكرتون — يُخصم من مخزون «ك مهدي» وليس من منتج مستقل.
const String kStoreMahdiProductApiName = 'مهدي متجر';

/// بيع متجر — سعر مستقل؛ الخصم من حمولة السيارة (جالون/قارورة ٢٠ لتر).
const String kStoreGallonProductApiName = 'جالون متجر';
const String kStoreBottleProductApiName = 'قاروره متجر';

/// تعبئة المحطة — أعمدة ٠–١؛ سعر مستقل بدون خصم مخزون.
const String kFillingGallonProductApiName = 'Water Gallon';
const String kFillingBottleProductApiName = 'Water Bottle';

/// جالون/قارورة صغير (تعبئة + سيارة) — **ليس** «ج/ق صغير فارغ» في رصيد المحطة.
const String kWaterSmallGallonProductApiName = 'جالون صغير';
const String kWaterSmallBottleProductApiName = 'قاروره صغير';

/// صفوف تسعير إضافية في سوبر أدمن (ليست صفوف رصيد المحطة).
const int kSuperAdminStoreMahdiPricingExtraSlot = -100;
const int kSuperAdminStoreGallonPricingExtraSlot = -101;
const int kSuperAdminStoreBottlePricingExtraSlot = -102;
const int kSuperAdminFillingGallonPricingExtraSlot = -110;
const int kSuperAdminFillingBottlePricingExtraSlot = -111;
const int kSuperAdminFillingSmallGallonPricingExtraSlot = -112;
const int kSuperAdminFillingSmallBottlePricingExtraSlot = -113;

/// ترتيب صفوف تسعير تعبئة + صغير (منزل/تعبئة).
const List<int> kSuperAdminFillingSalePricingExtraSlots = <int>[
  kSuperAdminFillingGallonPricingExtraSlot,
  kSuperAdminFillingBottlePricingExtraSlot,
  kSuperAdminFillingSmallGallonPricingExtraSlot,
  kSuperAdminFillingSmallBottlePricingExtraSlot,
];

/// بيع فارغ — زر «مع تعبئة» تحت المنتجات ١–٣ (أعمدة ٠–٢).
const String kEmptySaleWithFillingRow1ProductApiName = 'مع تعبئة — منتجات ١–٣';
const String kEmptySaleWithFillingRow2ProductApiName = 'مع تعبئة — منتجات ٤–٥';

const int kSuperAdminEmptySaleWithFillingRow1PricingExtraSlot = -120;
const int kSuperAdminEmptySaleWithFillingRow2PricingExtraSlot = -121;

const List<int> kSuperAdminEmptySaleWithFillingPricingExtraSlots = <int>[
  kSuperAdminEmptySaleWithFillingRow1PricingExtraSlot,
  kSuperAdminEmptySaleWithFillingRow2PricingExtraSlot,
];

/// آخر عمود يشمله زر «مع تعبئة» للصف الأول (بيع فارغ).
const int kStationEmptySaleWithFillingRow1LastColumn = 2;

/// أول عمود يشمله زر «مع تعبئة» للصف الثاني (بيع فارغ).
const int kStationEmptySaleWithFillingRow2FirstColumn = 3;

/// ترتيب صفوف تسعير بيع المتجر في شاشة الأسعار.
const List<int> kSuperAdminStoreSalePricingExtraSlots = <int>[
  kSuperAdminStoreGallonPricingExtraSlot,
  kSuperAdminStoreBottlePricingExtraSlot,
  kSuperAdminStoreMahdiPricingExtraSlot,
];

/// أسماء مخزون الكرتون الكنسي (بدون «مهدي متجر»).
const List<String> kMahdiCartonStockNameCandidates = <String>[
  'Water Carton',
  'Carton Mahdi',
  'ك مهدي',
  'مهدي (كرتون)',
];

bool isStoreMahdiProductName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return false;
  }
  final String n = normalizeStationBalanceProductName(name);
  if (n == normalizeStationBalanceProductName(kStoreMahdiProductApiName)) {
    return true;
  }
  return n.contains('مهدي') && n.contains('متجر');
}

/// منتج مخزون «ك مهدي» الفعلي في الكتالوج (للخصم عند بيع «مهدي متجر»).
Map<String, dynamic>? resolveMahdiCartonStockProduct({
  required List<Map<String, dynamic>> products,
}) {
  final List<Map<String, dynamic>> active = products
      .where((Map<String, dynamic> p) => p['isActive'] != false)
      .toList(growable: false);
  for (final String c in kMahdiCartonStockNameCandidates) {
    final Map<String, dynamic>? match = _resolveStationBalanceProductFromPool(
      pool: active,
      candidates: <String>[c],
    );
    if (match != null && !isStoreMahdiProductName(match['name']?.toString())) {
      return match;
    }
  }
  for (final Map<String, dynamic> p in active) {
    if (isStoreMahdiProductName(p['name']?.toString())) {
      continue;
    }
    final String ut =
        (p['unitType'] ?? p['type'])?.toString().trim().toLowerCase() ?? '';
    if (ut == 'carton') {
      final String raw = p['name']?.toString() ?? '';
      if (raw.contains('مهدي') || raw.toLowerCase().contains('mahdi')) {
        return p;
      }
    }
  }
  return resolveStationBalanceProduct(products: products, rowIndex: 0);
}

String? resolveMahdiCartonStockProductId({
  required List<Map<String, dynamic>> products,
}) =>
    resolveMahdiCartonStockProduct(products: products)?['id']?.toString();

Map<String, dynamic>? resolveStoreGallonSaleProduct({
  required List<Map<String, dynamic>> products,
}) =>
    resolveProductByNameCandidates(
      products: products,
      candidates: <String>[kStoreGallonProductApiName],
    );

Map<String, dynamic>? resolveStoreBottleSaleProduct({
  required List<Map<String, dynamic>> products,
}) =>
    resolveProductByNameCandidates(
      products: products,
      candidates: <String>[kStoreBottleProductApiName],
    );

Map<String, dynamic>? resolveFillingGallonProduct({
  required List<Map<String, dynamic>> products,
}) =>
    resolveProductByNameCandidates(
      products: products,
      candidates: <String>[
        kFillingGallonProductApiName,
        'جالون ٢٠ لتر',
        'جالون',
      ],
    );

Map<String, dynamic>? resolveFillingBottleProduct({
  required List<Map<String, dynamic>> products,
}) =>
    resolveProductByNameCandidates(
      products: products,
      candidates: <String>[
        kFillingBottleProductApiName,
        'قاروره ٢٠ لتر',
        'قاروره',
      ],
    );

Map<String, dynamic>? resolveWaterSmallGallonProduct({
  required List<Map<String, dynamic>> products,
}) =>
    resolveProductByNameCandidates(
      products: products,
      candidates: <String>[
        kWaterSmallGallonProductApiName,
        'Water Small Gallon',
      ],
    );

Map<String, dynamic>? resolveWaterSmallBottleProduct({
  required List<Map<String, dynamic>> products,
}) =>
    resolveProductByNameCandidates(
      products: products,
      candidates: <String>[
        kWaterSmallBottleProductApiName,
        'Water Small Bottle',
      ],
    );

String superAdminStorePricingRowLabel(int rowIndex) {
  return switch (rowIndex) {
    kSuperAdminStoreGallonPricingExtraSlot => kStoreGallonProductApiName,
    kSuperAdminStoreBottlePricingExtraSlot => kStoreBottleProductApiName,
    kSuperAdminStoreMahdiPricingExtraSlot => kStoreMahdiProductApiName,
    _ => '',
  };
}

String superAdminEmptySaleWithFillingPricingRowLabel(int rowIndex) {
  return switch (rowIndex) {
    kSuperAdminEmptySaleWithFillingRow1PricingExtraSlot =>
      kEmptySaleWithFillingRow1ProductApiName,
    kSuperAdminEmptySaleWithFillingRow2PricingExtraSlot =>
      kEmptySaleWithFillingRow2ProductApiName,
    _ => '',
  };
}

Map<String, dynamic>? resolveEmptySaleWithFillingRow1Product({
  required List<Map<String, dynamic>> products,
}) =>
    resolveProductByNameCandidates(
      products: products,
      candidates: <String>[kEmptySaleWithFillingRow1ProductApiName],
    );

Map<String, dynamic>? resolveEmptySaleWithFillingRow2Product({
  required List<Map<String, dynamic>> products,
}) =>
    resolveProductByNameCandidates(
      products: products,
      candidates: <String>[kEmptySaleWithFillingRow2ProductApiName],
    );

/// زيادة سعر الوحدة عند «مع تعبئة» في بيع فارغ حسب العمود والصف المفعّل.
double emptySaleWithFillingSurchargeForColumn({
  required int columnIndex,
  required bool row1On,
  required bool row2On,
  required double row1Surcharge,
  required double row2Surcharge,
}) {
  if (columnIndex >= 0 &&
      columnIndex <= kStationEmptySaleWithFillingRow1LastColumn &&
      row1On) {
    return row1Surcharge;
  }
  if (columnIndex >= kStationEmptySaleWithFillingRow2FirstColumn &&
      columnIndex < kStationEmptySaleColumnCount &&
      row2On) {
    return row2Surcharge;
  }
  return 0;
}

/// منتج بيع «مهدي متجر» (سعر مستقل في التسعير؛ المخزون من «ك مهدي»).
Map<String, dynamic>? resolveStoreMahdiSaleProduct({
  required List<Map<String, dynamic>> products,
}) {
  final List<Map<String, dynamic>> active = products
      .where((Map<String, dynamic> p) => p['isActive'] != false)
      .toList(growable: false);
  for (final Map<String, dynamic> p in active) {
    if (isStoreMahdiProductName(p['name']?.toString())) {
      return p;
    }
  }
  return resolveProductByNameCandidates(
    products: products,
    candidates: <String>[kStoreMahdiProductApiName],
  );
}

String? resolveStoreMahdiSaleProductId({
  required List<Map<String, dynamic>> products,
}) =>
    resolveStoreMahdiSaleProduct(products: products)?['id']?.toString();

/// سعر موحّد: «مهدي» (تعبئة المحطة) و«ك مهدي» (منزل/حمولة) — من منتج مخزون الكرتون.
double? stationMahdiFillingAndHomeUnitPrice({
  required List<Map<String, dynamic>> products,
}) {
  final double? fromStock = parseDynamicDouble(
    resolveMahdiCartonStockProduct(products: products)?['price'],
  );
  if (fromStock != null) {
    return fromStock;
  }
  return parseDynamicDouble(
    resolveStationBalanceProduct(products: products, rowIndex: 0)?['price'],
  );
}

/// سعر «مهدي متجر» فقط (بيع متجر من السيارة).
double? storeMahdiSaleUnitPrice({
  required List<Map<String, dynamic>> products,
}) =>
    parseDynamicDouble(
      resolveStoreMahdiSaleProduct(products: products)?['price'],
    );

/// عند البيع باسم «مهدي متجر» يُرسل معرّف مخزون «ك مهدي» للخصم من المحطة.
String canonicalProductIdForMahdiStoreSale({
  required String productId,
  required List<Map<String, dynamic>> products,
}) {
  final String? canonical = resolveMahdiCartonStockProductId(products: products);
  if (canonical == null || canonical.isEmpty) {
    return productId;
  }
  for (final Map<String, dynamic> p in products) {
    if (p['id']?.toString() != productId) {
      continue;
    }
    if (isStoreMahdiProductName(p['name']?.toString())) {
      return canonical;
    }
    break;
  }
  return productId;
}

int stationStockFromProductJson(Map<String, dynamic> item) {
  final Object? v = item['stationStock'] ?? item['stock'];
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  final String t = v?.toString().trim() ?? '';
  if (t.isEmpty) {
    return 0;
  }
  final num? n = num.tryParse(t.replaceAll(',', ''));
  if (n != null) {
    return n.round();
  }
  return int.tryParse(t) ?? 0;
}

/// صف رصيد المحطة الذي يطابق [productId]، أو `null`.
int? balanceRowIndexForProductId({
  required List<Map<String, dynamic>> products,
  required String productId,
}) {
  final String id = productId.trim();
  if (id.isEmpty) {
    return null;
  }
  Map<String, dynamic>? product;
  for (final Map<String, dynamic> p in products) {
    if (p['id']?.toString() == id) {
      product = p;
      break;
    }
  }
  if (product == null) {
    return null;
  }
  final String name = product['name']?.toString() ?? '';
  int? bestRow;
  var bestScore = 0;
  for (var row = 0; row <= kStationBalanceLastFixedRowIndex; row++) {
    if (row >= StationBalanceProductLookup.nameCandidates.length) {
      continue;
    }
    for (final String c in StationBalanceProductLookup.nameCandidates[row]) {
      final int score = _stationBalanceMatchScore(name, c);
      if (score > bestScore) {
        bestScore = score;
        bestRow = row;
      }
    }
  }
  return bestRow;
}

/// معرّفات المنتجات النشطة المرتبطة بصف الرصيد.
List<String> productIdsForBalanceRow({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (rowIndex < 0 ||
      rowIndex > kStationBalanceLastFixedRowIndex ||
      rowIndex >= StationBalanceProductLookup.nameCandidates.length) {
    return const <String>[];
  }
  final List<String> candidates =
      StationBalanceProductLookup.nameCandidates[rowIndex];
  final List<Map<String, dynamic>> active = products
      .where((Map<String, dynamic> p) => p['isActive'] != false)
      .toList(growable: false);
  final List<String> ids = <String>[];
  final Set<String> seen = <String>{};
  for (final Map<String, dynamic> p in active) {
    final String id = p['id']?.toString() ?? '';
    if (id.isEmpty || seen.contains(id)) {
      continue;
    }
    final String n = p['name']?.toString() ?? '';
    for (final String c in candidates) {
      if (_stationBalanceNamesMatch(n, c)) {
        seen.add(id);
        ids.add(id);
        break;
      }
    }
  }
  return ids;
}

int _deductStationStockFromProductInList({
  required List<Map<String, dynamic>> products,
  required String productId,
  required int quantity,
}) {
  if (quantity <= 0) {
    return 0;
  }
  for (final Map<String, dynamic> p in products) {
    if (p['id']?.toString() != productId) {
      continue;
    }
    final int current = stationStockFromProductJson(p);
    final int take = quantity < current ? quantity : current;
    if (take <= 0) {
      return 0;
    }
    final int next = current - take;
    p['stationStock'] = next;
    p['stock'] = next;
    return take;
  }
  return 0;
}

int _stationStockAvailableInList({
  required List<Map<String, dynamic>> products,
  required String productId,
}) {
  for (final Map<String, dynamic> p in products) {
    if (p['id']?.toString() == productId) {
      return stationStockFromProductJson(p);
    }
  }
  return 0;
}

List<String> _stationStockDeductionOrder({
  required List<Map<String, dynamic>> products,
  required String productId,
}) {
  final String pid = productId.trim();
  final int? row = balanceRowIndexForProductId(
    products: products,
    productId: pid,
  );
  if (row == null) {
    return <String>[pid];
  }
  final List<String> rowIds = productIdsForBalanceRow(
    products: products,
    rowIndex: row,
  );
  return <String>[
    pid,
    for (final String id in rowIds)
      if (id != pid) id,
  ];
}

/// يحدد كم يُخصم من كل منتج ضمن صف الرصيد (بدون تعديل القائمة).
Map<String, int> planStationStockDeduction({
  required List<Map<String, dynamic>> products,
  required String productId,
  required int quantity,
}) {
  if (quantity <= 0) {
    return const <String, int>{};
  }
  final String pid = productId.trim();
  if (pid.isEmpty) {
    throw StateError('INSUFFICIENT_STOCK');
  }
  var remaining = quantity;
  final Map<String, int> plan = <String, int>{};
  for (final String id in _stationStockDeductionOrder(
    products: products,
    productId: pid,
  )) {
    if (remaining <= 0) {
      break;
    }
    final int available = _stationStockAvailableInList(
      products: products,
      productId: id,
    );
    if (available <= 0) {
      continue;
    }
    final int take = remaining < available ? remaining : available;
    plan[id] = (plan[id] ?? 0) + take;
    remaining -= take;
  }
  if (remaining > 0) {
    throw StateError('INSUFFICIENT_STOCK');
  }
  return plan;
}

/// خصم [quantity] من مخزون المحطة بعد البيع/الدين (يُحدّث قوائم المنتجات في الذاكرة).
void applyStationStockDeductionForSale({
  required List<Map<String, dynamic>> products,
  required String productId,
  required int quantity,
}) {
  final Map<String, int> plan = planStationStockDeduction(
    products: products,
    productId: productId,
    quantity: quantity,
  );
  for (final MapEntry<String, int> entry in plan.entries) {
    _deductStationStockFromProductInList(
      products: products,
      productId: entry.key,
      quantity: entry.value,
    );
  }
}
