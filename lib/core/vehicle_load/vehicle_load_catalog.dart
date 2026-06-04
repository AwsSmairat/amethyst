import 'package:amethyst/core/station_balance/station_balance_catalog.dart';

/// عدد صفوف منتجات نموذج «تحميل سيارة» الثابتة في الواجهة.
const int kVehicleLoadFixedRowCount = 8;

/// أول عمود «ك مهدي» في تحميل/بيع المنزل.
const int kVehicleHomeMahdiColumnIndex = 4;

/// أول عمود كوبون في تحميل/بيع المنزل.
const int kVehicleHomeFirstCouponColumnIndex = 5;

/// أسماء API الافتراضية لكل صف (مطابقة الخادم).
const List<String> kVehicleLoadFixedApiNames = <String>[
  'Water Gallon',
  'Water Bottle',
  kWaterSmallGallonProductApiName,
  kWaterSmallBottleProductApiName,
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
        'Gallon',
      ],
    1 => <String>[
        'Water Bottle',
        'قاروره ٢٠ لتر',
        'مياه 19 لتر',
        'مياه',
        'قاروره',
      ],
    2 => <String>[
        kWaterSmallGallonProductApiName,
        'Water Small Gallon',
      ],
    3 => <String>[
        kWaterSmallBottleProductApiName,
        'Water Small Bottle',
      ],
    4 => kMahdiCartonStockNameCandidates,
    5 => StationBalanceProductLookup
        .nameCandidates[kStationBalanceFirstCouponRowIndex],
    6 => StationBalanceProductLookup
        .nameCandidates[kStationBalanceFirstCouponRowIndex + 1],
    7 => StationBalanceProductLookup
        .nameCandidates[kStationBalanceFirstCouponRowIndex + 2],
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
  if (rowIndex == kVehicleHomeMahdiColumnIndex) {
    return resolveMahdiCartonStockProduct(products: products);
  }
  if (rowIndex == 2) {
    return resolveWaterSmallGallonProduct(products: products);
  }
  if (rowIndex == 3) {
    return resolveWaterSmallBottleProduct(products: products);
  }
  if (rowIndex >= kVehicleHomeFirstCouponColumnIndex) {
    return resolveStationBalanceProduct(
      products: products,
      rowIndex: stationBalanceRowIndexForVehicleCouponColumn(rowIndex),
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

/// جالون/قارورة (عادية وصغيرة): لا فحص مخزون المحطة عند التحميل.
bool vehicleLoadRowSkipsStationStockCheck(int rowIndex) =>
    rowIndex >= 0 && rowIndex < kVehicleHomeMahdiColumnIndex;

/// ك مهدي والكوبونات: يُعرض مخزون المحطة ويُرفض التحميل إن تجاوز المتاح (بدون خصم).
bool vehicleLoadRowChecksStationStock(int rowIndex) =>
    rowIndex >= kVehicleHomeMahdiColumnIndex &&
    rowIndex < kVehicleLoadFixedRowCount;

/// مخزون المحطة المعروض لصف التحميل (مجمّع لصفوف رصيد المحطة).
int stationStockForVehicleLoadRow({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (!vehicleLoadRowChecksStationStock(rowIndex)) {
    return 0;
  }
  if (rowIndex == kVehicleHomeMahdiColumnIndex) {
    return aggregateStationStockForBalanceRow(
      products: products,
      rowIndex: 0,
    );
  }
  if (rowIndex >= kVehicleHomeFirstCouponColumnIndex) {
    return stationStockForBalanceRowCanonical(
      products: products,
      rowIndex: stationBalanceRowIndexForVehicleCouponColumn(rowIndex),
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
      return (name: kWaterSmallGallonProductApiName, unitType: 'gallon');
    case 3:
      return (name: kWaterSmallBottleProductApiName, unitType: 'bottle');
    case 4:
      return stationBalanceSeedSpecForRow(0);
    case 5:
      return stationBalanceSeedSpecForRow(10);
    case 6:
      return stationBalanceSeedSpecForRow(11);
    case 7:
      return stationBalanceSeedSpecForRow(12);
    default:
      throw ArgumentError.value(
        rowIndex,
        'rowIndex',
        'vehicle load seed spec for rows 0..${kVehicleLoadFixedRowCount - 1} only',
      );
  }
}
