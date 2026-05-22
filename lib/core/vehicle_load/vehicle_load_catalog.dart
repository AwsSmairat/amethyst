import 'package:amethyst/core/station_balance/station_balance_catalog.dart';

/// عدد صفوف منتجات نموذج «تحميل سيارة» الثابتة في الواجهة.
const int kVehicleLoadFixedRowCount = 6;

/// أسماء API الافتراضية لكل صف (مطابقة الخادم).
const List<String> kVehicleLoadFixedApiNames = <String>[
  'Water Gallon',
  'Water Bottle',
  'Water Carton',
  'Coupon',
  'Coupon 2',
  'Coupon 3',
];

List<String> vehicleLoadNameCandidatesForRow(int rowIndex) {
  return switch (rowIndex) {
    0 => <String>[
        'Water Gallon',
        'جالون ٢٠ لتر',
        'جالون',
        'Empty Gallon',
        'ج فارغ',
        'Gallon',
      ],
    1 => <String>[
        'Water Bottle',
        'قاروره ٢٠ لتر',
        'مياه 19 لتر',
        'مياه',
        'Saudi Bottle',
        'Jordanian Bottle',
      ],
    2 => kMahdiCartonStockNameCandidates,
    3 => StationBalanceProductLookup.nameCandidates[11],
    4 => StationBalanceProductLookup.nameCandidates[12],
    5 => StationBalanceProductLookup.nameCandidates[13],
    _ => <String>[],
  };
}

/// يعيد منتج الكتالوج المطابق لصف التحميل، أو `null`.
Map<String, dynamic>? resolveVehicleLoadRowProduct({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (rowIndex < 0 || rowIndex >= kVehicleLoadFixedRowCount) {
    return null;
  }
  if (rowIndex == 2) {
    return resolveMahdiCartonStockProduct(products: products);
  }
  if (rowIndex >= 3) {
    return resolveStationBalanceProduct(
      products: products,
      rowIndex: 8 + rowIndex,
    );
  }
  final String fixed = kVehicleLoadFixedApiNames[rowIndex];
  final List<String> candidates = <String>[
    fixed,
    ...vehicleLoadNameCandidatesForRow(rowIndex),
  ];
  return resolveProductByNameCandidates(
    products: products,
    candidates: candidates,
  );
}

/// جالون/قارورة: لا فحص مخزون المحطة عند التحميل.
bool vehicleLoadRowSkipsStationStockCheck(int rowIndex) =>
    rowIndex == 0 || rowIndex == 1;

/// ك مهدي والكوبونات: يُعرض مخزون المحطة ويُرفض التحميل إن تجاوز المتاح (بدون خصم).
bool vehicleLoadRowChecksStationStock(int rowIndex) =>
    rowIndex >= 2 && rowIndex < kVehicleLoadFixedRowCount;

/// مخزون المحطة المعروض لصف التحميل (مجمّع لصفوف رصيد المحطة).
int stationStockForVehicleLoadRow({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (!vehicleLoadRowChecksStationStock(rowIndex)) {
    return 0;
  }
  if (rowIndex == 2) {
    return aggregateStationStockForBalanceRow(
      products: products,
      rowIndex: 0,
    );
  }
  if (rowIndex >= 3 && rowIndex <= 5) {
    return aggregateStationStockForBalanceRow(
      products: products,
      rowIndex: 8 + rowIndex,
    );
  }
  return 0;
}

/// مواصفات إنشاء منتج عند غيابه في نموذج العرض.
({String name, String unitType}) vehicleLoadSeedSpecForRow(int rowIndex) {
  switch (rowIndex) {
    case 0:
      return (name: 'Water Gallon', unitType: 'gallon');
    case 1:
      return (name: 'Water Bottle', unitType: 'bottle');
    case 2:
      return stationBalanceSeedSpecForRow(0);
    case 3:
      return stationBalanceSeedSpecForRow(11);
    case 4:
      return stationBalanceSeedSpecForRow(12);
    case 5:
      return stationBalanceSeedSpecForRow(13);
    default:
      throw ArgumentError.value(
        rowIndex,
        'rowIndex',
        'vehicle load seed spec for rows 0..${kVehicleLoadFixedRowCount - 1} only',
      );
  }
}
