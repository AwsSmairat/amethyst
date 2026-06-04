import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_aggregates.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_catalog.dart';

/// أعمدة منتجات البيع/الدين من المركبة (منزل = ٨، متجر = ٣) — مطابقة [add_vehicle_sale_sheet.dart].

const List<String> kVehicleHomeProductApiNames = kVehicleLoadFixedApiNames;

const List<String> kVehicleStoreProductApiNames = <String>[
  kStoreGallonProductApiName,
  kStoreBottleProductApiName,
  kStoreMahdiProductApiName,
];

const List<String> kVehicleStoreMahdiStockNameCandidates = <String>[
  'Water Carton',
  'Carton Mahdi',
  'ك مهدي',
  'مهدي (كرتون)',
  kStoreMahdiProductApiName,
];

enum VehicleProductColumnPlace { home, store }

int vehicleProductColumnCount(VehicleProductColumnPlace place) =>
    place == VehicleProductColumnPlace.home
        ? kVehicleHomeProductApiNames.length
        : kVehicleStoreProductApiNames.length;

/// ترتيب مطابقة أسماء المنزل: الأعمدة الأكثر تحديداً أولاً (قارورة/جالون صغير قبل الكبير).
const List<int> kVehicleHomeColumnMatchOrder = <int>[
  7,
  6,
  5,
  4,
  3,
  2,
  1,
  0,
];

Iterable<int> vehicleProductColumnMatchOrder(VehicleProductColumnPlace place) {
  final int n = vehicleProductColumnCount(place);
  if (place == VehicleProductColumnPlace.home) {
    return kVehicleHomeColumnMatchOrder.where((int i) => i < n);
  }
  return List<int>.generate(n, (int i) => i);
}

/// يحدد عمود البيع من [productId] (دين/مبيعات مركبة).
int? vehicleProductColumnIndexForSaleProductId({
  required VehicleProductColumnPlace place,
  required String productId,
  List<Map<String, dynamic>>? products,
}) {
  final String id = productId.trim();
  if (id.isEmpty) {
    return null;
  }
  final List<Map<String, dynamic>> pool = products ?? const <Map<String, dynamic>>[];
  for (final int i in vehicleProductColumnMatchOrder(place)) {
    final VehicleProductColumnBinding binding = bindVehicleProductColumn(
      place: place,
      columnIndex: i,
      products: pool,
    );
    if (binding.saleProductId == id) {
      return i;
    }
    if (place == VehicleProductColumnPlace.home &&
        i < kVehicleLoadFixedRowCount) {
      final Map<String, dynamic>? row = resolveVehicleLoadRowProduct(
        products: pool,
        rowIndex: i,
      );
      if (row?['id']?.toString() == id) {
        return i;
      }
    }
  }
  return null;
}

/// تسمية عربية من اسم المنتج في الكتالوج عبر مرشحي كل عمود (بدون التباس قارورة/قارورة صغير).
String? vehicleProductDisplayLabelByNameMatch({
  required VehicleProductColumnPlace place,
  required String productName,
}) {
  final String raw = productName.trim();
  if (raw.isEmpty) {
    return null;
  }
  for (final int i in vehicleProductColumnMatchOrder(place)) {
    for (final String candidate in vehicleProductLoadNameCandidates(place, i)) {
      if (stationBalanceProductNamesMatch(raw, candidate)) {
        return vehicleProductDisplayLabel(place, i);
      }
    }
  }
  return null;
}

/// تسمية عربية ثابتة للواجهة (منزل: صفوف التحميل؛ متجر: أسماء القالب).
String vehicleProductDisplayLabel(
  VehicleProductColumnPlace place,
  int columnIndex,
) {
  if (place == VehicleProductColumnPlace.store) {
    if (columnIndex >= 0 && columnIndex < kVehicleStoreProductApiNames.length) {
      return kVehicleStoreProductApiNames[columnIndex];
    }
    return '';
  }
  return switch (columnIndex) {
    0 => 'جالون',
    1 => 'قاروره',
    2 => 'جالون صغير',
    3 => 'قاروره صغير',
    4 => 'ك مهدي',
    5 => 'كوبون ١٢',
    6 => 'كوبون ٢٤',
    7 => 'كوبون ٥٠',
    _ => '',
  };
}

/// شارة أعلى البطاقة: دفاتر الكوبون (منزل ٣–٥) تعرض اسم النوع بدل «منتج ٤/٥/٦».
String? vehicleProductBadgeLabel(
  VehicleProductColumnPlace place,
  int columnIndex,
) {
  if (place == VehicleProductColumnPlace.home &&
      columnIndex >= kVehicleHomeFirstCouponColumnIndex &&
      columnIndex < kVehicleLoadFixedRowCount) {
    return vehicleProductDisplayLabel(place, columnIndex);
  }
  return null;
}

List<String> vehicleProductLoadNameCandidates(
  VehicleProductColumnPlace place,
  int columnIndex,
) {
  return switch (place) {
    VehicleProductColumnPlace.home => columnIndex < kVehicleLoadFixedRowCount
        ? <String>[
            kVehicleLoadFixedApiNames[columnIndex],
            ...vehicleLoadNameCandidatesForRow(columnIndex),
          ]
        : <String>[],
    VehicleProductColumnPlace.store => switch (columnIndex) {
        0 => vehicleLoadNameCandidatesForRow(0),
        1 => vehicleLoadNameCandidatesForRow(1),
        2 => <String>[
          ...kMahdiCartonStockNameCandidates,
          ...kVehicleStoreMahdiStockNameCandidates,
        ],
        _ => <String>[],
      },
  };
}

int _loadLineRemainingQty(Map<String, dynamic> line) {
  if (line['remaining'] is int) {
    return line['remaining'] as int;
  }
  return vehicleLoadRemainingQty(line);
}

/// متبقي الحمولة لعمود واحد (مطابقة منطق شاشة البيع).
int vehicleRemainingFromDriverLoad({
  required List<Map<String, dynamic>> loadLines,
  required VehicleProductColumnPlace place,
  required int columnIndex,
  String? stockProductId,
  String? saleProductId,
}) {
  if (stockProductId != null && stockProductId.isNotEmpty) {
    var fromStockId = 0;
    for (final Map<String, dynamic> line in loadLines) {
      if (line['productId']?.toString() == stockProductId) {
        fromStockId += _loadLineRemainingQty(line);
      }
    }
    if (fromStockId > 0) {
      return fromStockId;
    }
  }

  final List<String> candidates =
      vehicleProductLoadNameCandidates(place, columnIndex);
  if (candidates.isEmpty) {
    return 0;
  }

  var sum = 0;
  for (final Map<String, dynamic> line in loadLines) {
    final String loadName =
        (line['product'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
    for (final String candidate in candidates) {
      if (stationBalanceProductNamesMatch(loadName, candidate)) {
        sum += _loadLineRemainingQty(line);
        break;
      }
    }
  }
  if (sum > 0) {
    return sum;
  }

  if (saleProductId != null && saleProductId.isNotEmpty) {
    var fromSaleId = 0;
    for (final Map<String, dynamic> line in loadLines) {
      if (line['productId']?.toString() == saleProductId) {
        fromSaleId += _loadLineRemainingQty(line);
      }
    }
    if (fromSaleId > 0) {
      return fromSaleId;
    }
  }
  return sum;
}

/// أقصى كمية لتسجيل دين من المركبة — مطابق [add_vehicle_sale_sheet.dart] `_maxSellableQuantity`.
int vehicleDebtMaxSellableQuantity({
  required VehicleProductColumnPlace place,
  required int columnIndex,
  required int vehicleRemaining,
  required int stationStock,
}) {
  if (vehicleDebtColumnUsesVehicleLoad(place, columnIndex)) {
    return vehicleRemaining < 0 ? 0 : vehicleRemaining;
  }
  final bool homeMahdiOrCoupon =
      place == VehicleProductColumnPlace.home &&
          columnIndex >= kVehicleHomeMahdiColumnIndex &&
          columnIndex < kVehicleLoadFixedRowCount;
  final bool storeMahdi =
      place == VehicleProductColumnPlace.store && columnIndex == 2;
  if (!homeMahdiOrCoupon && !storeMahdi) {
    return 999999;
  }
  final int onVehicle = vehicleRemaining < 0 ? 0 : vehicleRemaining;
  final int atStation = stationStock < 0 ? 0 : stationStock;
  return onVehicle < atStation ? onVehicle : atStation;
}

/// رقم «المخزون» المعروض في شاشة دين المركبة (الكمية القابلة للبيع فعلياً).
int? vehicleDebtDisplayedStock({
  required VehicleProductColumnPlace place,
  required int columnIndex,
  required int vehicleRemaining,
  required int stationStock,
  required bool skipsStationStock,
}) {
  if (vehicleDebtColumnUsesVehicleLoad(place, columnIndex)) {
    return vehicleDebtMaxSellableQuantity(
      place: place,
      columnIndex: columnIndex,
      vehicleRemaining: vehicleRemaining,
      stationStock: stationStock,
    );
  }
  if (skipsStationStock) {
    return null;
  }
  return vehicleDebtMaxSellableQuantity(
    place: place,
    columnIndex: columnIndex,
    vehicleRemaining: vehicleRemaining,
    stationStock: stationStock,
  );
}

int aggregateStoreMahdiStationStock(List<Map<String, dynamic>> products) {
  final int rowSum = aggregateStationStockForBalanceRow(
    products: products,
    rowIndex: 0,
  );
  if (rowSum > 0) {
    return rowSum;
  }
  for (final Map<String, dynamic> p in products) {
    if (p['isActive'] == false) {
      continue;
    }
    final String ut =
        (p['unitType'] ?? p['type'])?.toString().trim().toLowerCase() ?? '';
    if (ut != 'carton') {
      continue;
    }
    final String raw = p['name']?.toString() ?? '';
    if (raw.contains('مهدي') || raw.toLowerCase().contains('mahdi')) {
      return stationStockFromProductJson(p);
    }
  }
  var sum = 0;
  final Set<String> seen = <String>{};
  for (final String n in kVehicleStoreMahdiStockNameCandidates) {
    final Map<String, dynamic>? m = resolveProductByNameCandidates(
      products: products,
      candidates: <String>[n],
    );
    final String? id = m?['id']?.toString();
    if (m == null || id == null || seen.contains(id)) {
      continue;
    }
    seen.add(id);
    sum += stationStockFromProductJson(m);
  }
  return sum;
}

final class VehicleProductColumnBinding {
  const VehicleProductColumnBinding({
    required this.displayLabel,
    this.saleProductId,
    this.stockProductId,
    this.unitPrice,
    this.stationStock = 0,
  });

  final String displayLabel;
  final String? saleProductId;
  final String? stockProductId;
  final double? unitPrice;
  final int stationStock;
}

VehicleProductColumnBinding bindVehicleProductColumn({
  required VehicleProductColumnPlace place,
  required int columnIndex,
  required List<Map<String, dynamic>> products,
}) {
  final String displayLabel =
      vehicleProductDisplayLabel(place, columnIndex);

  if (place == VehicleProductColumnPlace.home &&
      columnIndex < kVehicleHomeMahdiColumnIndex) {
    final Map<String, dynamic>? loadProduct =
        resolveVehicleLoadRowProduct(
          products: products,
          rowIndex: columnIndex,
        ) ??
            resolveProductByNameCandidates(
              products: products,
              candidates: vehicleProductLoadNameCandidates(
                VehicleProductColumnPlace.home,
                columnIndex,
              ),
            );
    return VehicleProductColumnBinding(
      displayLabel: displayLabel,
      saleProductId: loadProduct?['id']?.toString(),
      stockProductId: loadProduct?['id']?.toString(),
      unitPrice: parseDynamicDouble(loadProduct?['price']),
      stationStock: 0,
    );
  }

  if (place == VehicleProductColumnPlace.store && columnIndex < 2) {
    final Map<String, dynamic>? loadProduct =
        resolveVehicleLoadRowProduct(
          products: products,
          rowIndex: columnIndex,
        ) ??
            resolveProductByNameCandidates(
              products: products,
              candidates: vehicleProductLoadNameCandidates(
                VehicleProductColumnPlace.home,
                columnIndex,
              ),
            );
    final Map<String, dynamic>? storeSale =
        resolveProductByNameCandidates(
          products: products,
          candidates: <String>[kVehicleStoreProductApiNames[columnIndex]],
        ) ??
            (columnIndex == 0
                ? resolveStoreGallonSaleProduct(products: products)
                : resolveStoreBottleSaleProduct(products: products));
    final Map<String, dynamic>? saleSource = storeSale ?? loadProduct;
    return VehicleProductColumnBinding(
      displayLabel: displayLabel,
      saleProductId: saleSource?['id']?.toString(),
      stockProductId: loadProduct?['id']?.toString(),
      unitPrice: parseDynamicDouble(storeSale?['price']) ??
          parseDynamicDouble(loadProduct?['price']),
      stationStock: 0,
    );
  }

  if (place == VehicleProductColumnPlace.store && columnIndex == 2) {
    final Map<String, dynamic>? storeSale =
        resolveStoreMahdiSaleProduct(products: products) ??
            resolveProductByNameCandidates(
              products: products,
              candidates: <String>[kStoreMahdiProductApiName],
            );
    final Map<String, dynamic>? stockProduct =
        resolveMahdiCartonStockProduct(products: products);
    final String? stockId = stockProduct?['id']?.toString() ??
        resolveMahdiCartonStockProductId(products: products);
    final Map<String, dynamic>? saleSource = storeSale ?? stockProduct;
    return VehicleProductColumnBinding(
      displayLabel: kStoreMahdiProductApiName,
      saleProductId: saleSource?['id']?.toString(),
      stockProductId: stockId,
      unitPrice: storeMahdiSaleUnitPrice(products: products) ??
          parseDynamicDouble(storeSale?['price']) ??
          parseDynamicDouble(stockProduct?['price']),
      stationStock: aggregateStoreMahdiStationStock(products),
    );
  }

  if (place == VehicleProductColumnPlace.home &&
      columnIndex == kVehicleHomeMahdiColumnIndex) {
    final Map<String, dynamic>? storeSale =
        resolveStoreMahdiSaleProduct(products: products);
    final Map<String, dynamic>? stockProduct =
        resolveMahdiCartonStockProduct(products: products);
    final String? stockId = stockProduct?['id']?.toString() ??
        resolveMahdiCartonStockProductId(products: products);
    final Map<String, dynamic>? saleSource = storeSale ?? stockProduct;
    return VehicleProductColumnBinding(
      displayLabel: displayLabel,
      saleProductId: saleSource?['id']?.toString(),
      stockProductId: stockId,
      unitPrice: stationMahdiFillingAndHomeUnitPrice(products: products) ??
          parseDynamicDouble(stockProduct?['price']),
      stationStock: aggregateStationStockForBalanceRow(
        products: products,
        rowIndex: 0,
      ),
    );
  }

  Map<String, dynamic>? match;
  if (place == VehicleProductColumnPlace.home &&
      columnIndex < kVehicleLoadFixedRowCount) {
    match = resolveVehicleLoadRowProduct(
      products: products,
      rowIndex: columnIndex,
    );
  } else if (place == VehicleProductColumnPlace.store &&
      columnIndex < kVehicleStoreProductApiNames.length) {
    match = resolveProductByNameCandidates(
      products: products,
      candidates: <String>[kVehicleStoreProductApiNames[columnIndex]],
    );
  }

  match ??= resolveProductByNameCandidates(
    products: products,
    candidates: vehicleProductLoadNameCandidates(place, columnIndex),
  );

  final String? pid = match?['id']?.toString();
  final int stationStock = switch (place) {
    VehicleProductColumnPlace.home
        when columnIndex == kVehicleHomeMahdiColumnIndex =>
      aggregateStationStockForBalanceRow(products: products, rowIndex: 0),
    VehicleProductColumnPlace.home
        when columnIndex >= kVehicleHomeFirstCouponColumnIndex &&
            columnIndex < kVehicleLoadFixedRowCount =>
      stationStockForBalanceRowCanonical(
        products: products,
        rowIndex: stationBalanceRowIndexForVehicleCouponColumn(columnIndex),
      ),
    _ => stationStockFromProductJson(match ?? <String, dynamic>{}),
  };

  return VehicleProductColumnBinding(
    displayLabel: displayLabel,
    saleProductId: pid,
    stockProductId: pid,
    unitPrice: parseDynamicDouble(match?['price']),
    stationStock: stationStock,
  );
}

bool vehicleProductColumnDeductsStationStock(
  VehicleProductColumnPlace place,
  int columnIndex,
) {
  return switch (place) {
    VehicleProductColumnPlace.home =>
        columnIndex >= kVehicleHomeMahdiColumnIndex,
    VehicleProductColumnPlace.store => columnIndex == 2,
  };
}

bool vehicleProductColumnSkipsStationStock(
  VehicleProductColumnPlace place,
  int columnIndex,
) =>
    !vehicleProductColumnDeductsStationStock(place, columnIndex);

/// أعمدة تُخصم من حمولة السيارة (جالون/قارورة ٢٠ لتر) — منزل ١–٢ ومتجر ١–٢.
bool vehicleDebtColumnUsesVehicleLoad(
  VehicleProductColumnPlace place,
  int columnIndex,
) {
  return switch (place) {
    VehicleProductColumnPlace.home => columnIndex < kVehicleHomeMahdiColumnIndex,
    VehicleProductColumnPlace.store => columnIndex < 2,
  };
}

/// تسمية مصدر الحمولة المعروضة تحت «المتبقي» (دين المركبة).
String? vehicleDebtLoadStockSourceLabel(
  VehicleProductColumnPlace place,
  int columnIndex,
) {
  if (!vehicleDebtColumnUsesVehicleLoad(place, columnIndex)) {
    return null;
  }
  return switch (columnIndex) {
    0 => 'جالون ٢٠ لتر',
    1 => 'قاروره ٢٠ لتر',
    2 => 'جالون صغير',
    3 => 'قاروره صغير',
    _ => null,
  };
}

