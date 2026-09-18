import 'package:amethyst/core/utils/parse_dynamic_double.dart';


part 'station_balance_catalog_match.dart';
part 'station_balance_catalog_pricing.dart';

/// عدد صفوف رصيد المحطة المعروضة في الواجهة (١٥ بنداً ثابتاً + صف اختياري).
const int kStationBalanceRowCount = 16;

/// آخر فهرس للبند الثابت (قبل الصف الاختياري).
const int kStationBalanceLastFixedRowIndex = 14;

/// أول صف كوبون في رصيد المحطة (كوبون ١٢) — أعمدة التحميل/البيع ٣–٥.
const int kStationBalanceFirstCouponRowIndex = 10;

/// صف رصيد المحطة لعمود كوبون في تحميل/بيع السيارة (منزل: أعمدة ٥–٧).
int stationBalanceRowIndexForVehicleCouponColumn(int columnIndex) {
  return kStationBalanceFirstCouponRowIndex + (columnIndex - 5);
}

/// عدد أعمدة «تعبئة» من المحطة.
const int kStationFillingColumnCount = 8;

/// أعمدة التعبئة بدون خصم مخزون المحطة (جالون/قارورة عادية + صغير).
const List<int> kStationFillingSkipStockColumnIndices = <int>[0, 1, 2, 3];

/// صف رصيد المحطة لعمود تعبئة (null = الاعتماد على اسم API فقط).
const List<int?> kStationFillingBalanceRowByColumn = <int?>[
  null, // 0 جالون
  null, // 1 قارورة
  null, // 2 جالون صغير — منتج مستقل ([kWaterSmallGallonProductApiName])
  null, // 3 قاروره صغير — منتج مستقل ([kWaterSmallBottleProductApiName])
  0, // 4 مهدي
  null, // 5 كوبون ١٢
  null,
  null,
];

/// عدد أعمدة «بيع فارغ» من المحطة.
const int kStationEmptySaleColumnCount = 5;

/// صفوف رصيد المحطة لكل عمود في بيع فارغ (يُخصم المخزون عند البيع).
const List<int> kStationEmptySaleBalanceRowIndices = <int>[
  5, // ق سعودي
  6, // ق اردني
  7, // ج فارغ
  13, // ق صغير فارغ
  14, // ج صغير فارغ
];

/// صفوف التسعير في شاشة سوبر أدمن «تعديل أسعار المنتجات» فقط — **بدون** أرضية المحطة
/// (Ground Bottle / Ground Gallon ↔ «ق ارضية» / «ج ارضية»).
///
/// هذان الصفّان يبقيان في **شاشة مخزون المحطة** (`AdminStationBalancePage` + نموذج تسجيل الرصيد)
/// لتعديل **الكمية يدوياً** فقط، وليس السعر من سوبر أدمن.
/// صفوف تسعير رصيد المحطة في سوبر أدمن (٠ «ك مهدي» = سعر موحّد لتعبئة مهدي + منزل؛ «مهدي متجر» منفصل).
const List<int> kStationPricingBalanceRowIndices = <int>[
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  10,
  11,
  12,
  13,
  14,
];

/// نفس الصفوف مستبعدة من قسم «باقي المنتجات» في شاشة أسعار سوبر أدمن حتى لا يظهر المنتج مرتين.
const List<int> kStationPricingHiddenBalanceRowIndices = <int>[8, 9];

/// اسم ووحدة إنشاء المنتج في الـ API عند عدم وجوده (يتطابق مع [StationBalanceProductLookup]).
({String name, String unitType}) stationBalanceSeedSpecForRow(int rowIndex) {
  switch (rowIndex) {
    case 0:
      return (name: 'Water Carton', unitType: 'carton');
    case 1:
      return (name: 'Carton Yafa', unitType: 'carton');
    case 2:
      return (name: 'Shrink Large', unitType: 'carton');
    case 3:
      return (name: 'Shrink Medium', unitType: 'carton');
    case 4:
      return (name: 'Shrink Small', unitType: 'carton');
    case 5:
      return (name: 'Saudi Bottle', unitType: 'bottle');
    case 6:
      return (name: 'Jordanian Bottle', unitType: 'bottle');
    case 7:
      return (name: 'Empty Gallon', unitType: 'gallon');
    case 8:
      return (name: 'Ground Bottle', unitType: 'bottle');
    case 9:
      return (name: 'Ground Gallon', unitType: 'gallon');
    case 10:
      return (name: 'Coupon', unitType: 'coupon');
    case 11:
      return (name: 'Coupon 2', unitType: 'coupon');
    case 12:
      return (name: 'Coupon 3', unitType: 'coupon');
    case 13:
      return (name: 'Small Empty Bottle', unitType: 'bottle');
    case 14:
      return (name: 'Small Empty Gallon', unitType: 'gallon');
    default:
      throw ArgumentError.value(
        rowIndex,
        'rowIndex',
        'seed spec defined for fixed balance rows 0..$kStationBalanceLastFixedRowIndex only',
      );
  }
}

/// أسماء المنتج في الـ API لكل صف (يُجرى البحث بالتطابق بدون حساسية لحالة الأحرف).
abstract final class StationBalanceProductLookup {
  static const List<List<String>> nameCandidates = <List<String>>[
    <String>[
      'Water Carton',
      'Carton Mahdi',
      'ك مهدي',
      'مهدي (كرتون)',
    ],
    <String>['Carton Yafa', 'ك يافا', 'Yafa Carton'],
    <String>[
      'Shrink Large',
      'Shanta Large',
      'شرنك كبير',
      'ش كبير',
      'Sh Large',
      'Large Shanta',
    ],
    <String>[
      'Shrink Medium',
      'Shanta Medium',
      'شرنك وسط',
      'ش وسط',
      'Sh Medium',
      'Medium Shanta',
    ],
    <String>[
      'Shrink Small',
      'Shanta Small',
      'شرنك صغير',
      'ش صغير',
      'Sh Small',
      'Small Shanta',
    ],
    <String>['Saudi Bottle', 'ق سعودي', 'Bottle Saudi'],
    <String>['Jordanian Bottle', 'ق اردني', 'Bottle Jordanian'],
    <String>[
      'Empty Gallon',
      'ج فارغ',
      'جالون فارغ',
      'جالون فاضي',
      'Gallon Empty',
    ],
    <String>['Ground Bottle', 'ق ارضية', 'Bottle Ground'],
    <String>['Ground Gallon', 'ج ارضية', 'Gallon Ground'],
    /// مطابقة [StationSaleApiProductNames.filling] وباقي التطبيق (كوبون ١٢ / ٢٤ / ٥٠).
    <String>['Coupon', 'دفتر كوبون ١٢', 'Coupon Book 12', 'كوبون ١٢'],
    <String>['Coupon 2', 'دفتر كوبون ٢٤', 'Coupon Book 24', 'كوبون ٢٤'],
    <String>['Coupon 3', 'دفتر كوبون ٥٠', 'Coupon Book 50', 'كوبون ٥٠'],
    <String>[
      'Small Empty Bottle',
      'ق صغير فارغ',
      'قارورة صغير فارغ',
      'Empty Bottle Small',
    ],
    <String>[
      'Small Empty Gallon',
      'ج صغير فارغ',
      'جالون صغير فارغ',
      'Empty Gallon Small',
    ],
  ];
}
