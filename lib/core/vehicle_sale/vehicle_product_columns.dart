import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_catalog.dart';

/// أعمدة منتجات البيع/الدين من المركبة (منزل = ٦، متجر = ٣) — مطابقة [add_vehicle_sale_sheet.dart].

const List<String> kVehicleHomeProductApiNames = kVehicleLoadFixedApiNames;

const List<String> kVehicleStoreProductApiNames = <String>[
  'جالون متجر',
  'قاروره متجر',
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
    2 => 'ك مهدي',
    3 => 'كوبون ١٢',
    4 => 'كوبون ٢٤',
    5 => 'كوبون ٥٠',
    _ => '',
  };
}

/// شارة أعلى البطاقة: دفاتر الكوبون (منزل ٣–٥) تعرض اسم النوع بدل «منتج ٤/٥/٦».
String? vehicleProductBadgeLabel(
  VehicleProductColumnPlace place,
  int columnIndex,
) {
  if (place == VehicleProductColumnPlace.home &&
      columnIndex >= 3 &&
      columnIndex <= 5) {
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

/// متبقي الحمولة لعمود واحد (مطابقة منطق شاشة البيع).
int vehicleRemainingFromDriverLoad({
  required List<Map<String, dynamic>> loadLines,
  required VehicleProductColumnPlace place,
  required int columnIndex,
  String? stockProductId,
  String? saleProductId,
}) {
  final String? columnProductId = stockProductId ?? saleProductId;
  if (columnProductId != null && columnProductId.isNotEmpty) {
    var fromProductId = 0;
    for (final Map<String, dynamic> line in loadLines) {
      if (line['productId']?.toString() == columnProductId) {
        fromProductId += (line['remaining'] as int?) ?? 0;
      }
    }
    if (fromProductId > 0) {
      return fromProductId;
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
        sum += (line['remaining'] as int?) ?? 0;
        break;
      }
    }
  }
  return sum;
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

  if (place == VehicleProductColumnPlace.store && columnIndex == 2) {
    final Map<String, dynamic>? storeSale =
        resolveStoreMahdiSaleProduct(products: products) ??
            resolveProductByNameCandidates(
              products: products,
              candidates: <String>[kStoreMahdiProductApiName],
            );
    final String? stockId =
        resolveMahdiCartonStockProductId(products: products);
    return VehicleProductColumnBinding(
      displayLabel: kStoreMahdiProductApiName,
      saleProductId: storeSale?['id']?.toString(),
      stockProductId: stockId,
      unitPrice: parseDynamicDouble(storeSale?['price']),
      stationStock: aggregateStoreMahdiStationStock(products),
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
    VehicleProductColumnPlace.home when columnIndex == 2 =>
      aggregateStationStockForBalanceRow(products: products, rowIndex: 0),
    VehicleProductColumnPlace.home
        when columnIndex >= 3 && columnIndex <= 5 =>
      aggregateStationStockForBalanceRow(
        products: products,
        rowIndex: 8 + columnIndex,
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
    VehicleProductColumnPlace.home => columnIndex >= 2,
    VehicleProductColumnPlace.store => columnIndex == 2,
  };
}

bool vehicleProductColumnSkipsStationStock(
  VehicleProductColumnPlace place,
  int columnIndex,
) =>
    !vehicleProductColumnDeductsStationStock(place, columnIndex);

/// جالون وقاروره (منتج ١ و ٢): يُسجَّل الدين دون خصم من الحمولة أو مخزون المحطة.
bool vehicleDebtColumnSkipsInventoryDeduction(int columnIndex) =>
    columnIndex < 2;
