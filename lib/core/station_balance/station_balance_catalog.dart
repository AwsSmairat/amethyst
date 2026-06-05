import 'package:amethyst/core/utils/parse_dynamic_double.dart';

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

sealed class ParsedStationStockInput {
  const ParsedStationStockInput();
}

/// حقل فارغ — لا يُحدَّث مخزون هذا الصف.
final class ParsedStationStockSkip extends ParsedStationStockInput {
  const ParsedStationStockSkip();
}

/// إدخال غير صالح (ليس رقماً صحيحاً ≥ 0).
final class ParsedStationStockInvalid extends ParsedStationStockInput {
  const ParsedStationStockInvalid();
}

/// قيمة صالحة للمخزون.
final class ParsedStationStockOk extends ParsedStationStockInput {
  const ParsedStationStockOk(this.value);

  final int value;
}

/// تحليل حقل الكمية في نموذج الرصيد.
ParsedStationStockInput parseStationStockInput(String raw) {
  final String t = raw.trim();
  if (t.isEmpty) {
    return const ParsedStationStockSkip();
  }
  final String normalized =
      t.replaceAll('٫', '.').replaceAll(',', '.').replaceAll(' ', '');
  final num? n = num.tryParse(normalized);
  if (n == null || n < 0) {
    return const ParsedStationStockInvalid();
  }
  final double d = n.toDouble();
  final int v = d.round();
  if ((d - v).abs() > 1e-9) {
    return const ParsedStationStockInvalid();
  }
  return ParsedStationStockOk(v);
}

/// تطبيع بسيط لأسماء المنتجات عند المطابقة (مسافات، أحرف خفية، حركات عربية).
String normalizeStationBalanceProductName(String raw) {
  var s = raw.trim();
  if (s.isEmpty) {
    return '';
  }
  s = s.replaceAll(
    RegExp(r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]'),
    '',
  );
  s = s.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670]'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.toLowerCase();
}

/// مطابقة مرنة بين اسم منتج في الكتالوج/الحمولة واسم قالب الواجهة.
bool stationBalanceProductNamesMatch(String dbName, String candidate) =>
    _stationBalanceNamesMatch(dbName, candidate);

bool _isCouponBookLabel(String normalized) =>
    normalized.contains('coupon') || normalized.contains('كوبون');

bool _nameIndicatesSmallSize(String normalized) =>
    normalized.contains('صغير') ||
    normalized.contains('small') ||
    normalized.contains('صغيرة');

bool _nameIndicatesEmpty(String normalized) =>
    normalized.contains('empty') ||
    normalized.contains('فارغ') ||
    normalized.contains('فاضي') ||
    normalized.contains('فارغه');

/// يمنع خلط «ج فارغ» مع «ج صغير فارغ» ونحوها عند التطابق الجزئي.
bool _stationBalanceSizeClassConflict(String a, String b) {
  if (a == b) {
    return false;
  }
  return _nameIndicatesSmallSize(a) != _nameIndicatesSmallSize(b);
}

/// يمنع اعتبار «Empty Gallon» مثل «Gallon» أو «Water Gallon».
bool _stationBalanceEmptyClassConflict(String a, String b) {
  if (a == b) {
    return false;
  }
  return _nameIndicatesEmpty(a) != _nameIndicatesEmpty(b);
}

bool _stationBalanceNamesMatch(String dbName, String candidate) {
  final String a = normalizeStationBalanceProductName(dbName);
  final String b = normalizeStationBalanceProductName(candidate);
  if (a.isEmpty || b.isEmpty) {
    return false;
  }
  if (a == b) {
    return true;
  }
  // لا تطابق جزئي بين «Coupon» و«Coupon 2/3» أو «كوبون ٢٤» و«كوبون ٢».
  if (_isCouponBookLabel(a) || _isCouponBookLabel(b)) {
    return false;
  }
  // أسماء طويلة قد تختلف بلاحقة (مثل "ق سعودي — مخزن")
  if (a.length >= 6 && b.length >= 6 && (a.contains(b) || b.contains(a))) {
    if (_stationBalanceSizeClassConflict(a, b)) {
      return false;
    }
    if (_stationBalanceEmptyClassConflict(a, b)) {
      return false;
    }
    return true;
  }
  return false;
}

int _stationBalanceMatchScore(String dbName, String candidate) {
  if (!_stationBalanceNamesMatch(dbName, candidate)) {
    return 0;
  }
  return normalizeStationBalanceProductName(candidate).length;
}

Map<String, dynamic>? _resolveStationBalanceProductFromPool({
  required List<Map<String, dynamic>> pool,
  required List<String> candidates,
}) {
  Map<String, dynamic>? best;
  var bestScore = 0;
  for (final String c in candidates) {
    if (c.trim().isEmpty) {
      continue;
    }
    for (final Map<String, dynamic> p in pool) {
      final String n = p['name']?.toString() ?? '';
      final int score = _stationBalanceMatchScore(n, c);
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }
  }
  return best;
}

/// يعيد أول منتج نشط يطابق أحد الأسماء المرشّحة (أو منتج معطّل إن لم يوجد نشط).
Map<String, dynamic>? resolveProductByNameCandidates({
  required List<Map<String, dynamic>> products,
  required List<String> candidates,
}) {
  final List<Map<String, dynamic>> active = products
      .where((Map<String, dynamic> p) => p['isActive'] != false)
      .toList(growable: false);
  final Map<String, dynamic>? fromActive = _resolveStationBalanceProductFromPool(
    pool: active,
    candidates: candidates,
  );
  if (fromActive != null) {
    return fromActive;
  }
  return _resolveStationBalanceProductFromPool(
    pool: products,
    candidates: candidates,
  );
}

/// مجموع `stationStock` لكل منتجات نشطة تطابق مرشّحات صف الرصيد (بدون تكرار `id`).
///
/// يُفضَّل لبند «مهدي متجر» حيث قد يوجد أكثر من اسم API (`Water Carton` و`ك مهدي`) —
/// [resolveStationBalanceProduct] يعيد مطابقة واحدة فقط وقد تكون بمخزون ٠.
int aggregateStationStockForBalanceRow({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (rowIndex < 0 ||
      rowIndex >= StationBalanceProductLookup.nameCandidates.length) {
    return 0;
  }
  final List<String> candidates =
      StationBalanceProductLookup.nameCandidates[rowIndex];
  final List<Map<String, dynamic>> active = products
      .where((Map<String, dynamic> p) => p['isActive'] != false)
      .toList(growable: false);
  final Set<String> seen = <String>{};
  var sum = 0;
  for (final Map<String, dynamic> p in active) {
    final String id = p['id']?.toString() ?? '';
    if (id.isEmpty || seen.contains(id)) {
      continue;
    }
    final String n = p['name']?.toString() ?? '';
    var matched = false;
    for (final String c in candidates) {
      if (_stationBalanceNamesMatch(n, c)) {
        matched = true;
        break;
      }
    }
    if (matched) {
      seen.add(id);
      sum += stationStockFromProductJson(p);
    }
  }
  return sum;
}

/// مخزون المنتج الأساسي لصف الرصيد (أول مطابقة) — للكوبونات وغيرها حيث لا يُجمَّع المخزون.
int stationStockForBalanceRowCanonical({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  final Map<String, dynamic>? product = resolveStationBalanceProduct(
    products: products,
    rowIndex: rowIndex,
  );
  return stationStockFromProductJson(product ?? <String, dynamic>{});
}

/// مخزون صف الرصيد للعرض والملخص — يجمّع كل منتج نشط يطابق مرشّحات الصف (بدون تكرار `id`).
int stationStockForBalanceRow({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (rowIndex < 0 ||
      rowIndex > kStationBalanceLastFixedRowIndex ||
      rowIndex >= StationBalanceProductLookup.nameCandidates.length) {
    return 0;
  }
  return aggregateStationStockForBalanceRow(
    products: products,
    rowIndex: rowIndex,
  );
}

/// يعيد منتج المحطة المطابق للصف، أو `null` إن لم يُعثر على اسم مطابق.
Map<String, dynamic>? resolveStationBalanceProduct({
  required List<Map<String, dynamic>> products,
  required int rowIndex,
}) {
  if (rowIndex < 0 ||
      rowIndex > kStationBalanceLastFixedRowIndex ||
      rowIndex >= StationBalanceProductLookup.nameCandidates.length) {
    return null;
  }
  final List<String> candidates =
      StationBalanceProductLookup.nameCandidates[rowIndex];
  final List<Map<String, dynamic>> active = products
      .where((Map<String, dynamic> p) => p['isActive'] != false)
      .toList(growable: false);
  final Map<String, dynamic>? fromActive = _resolveStationBalanceProductFromPool(
    pool: active,
    candidates: candidates,
  );
  if (fromActive != null) {
    return fromActive;
  }
  // منتج موجود لكن معطّل — ما زلنا نربط الصف لتحديث المخزون من رصيد المحطة
  return _resolveStationBalanceProductFromPool(
    pool: products,
    candidates: candidates,
  );
}

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

/// خصم [quantity] من مخزون المحطة بعد البيع/الدين (يُحدّث قوائم المنتجات في الذاكرة).
void applyStationStockDeductionForSale({
  required List<Map<String, dynamic>> products,
  required String productId,
  required int quantity,
}) {
  if (quantity <= 0) {
    return;
  }
  final String pid = productId.trim();
  if (pid.isEmpty) {
    throw StateError('INSUFFICIENT_STOCK');
  }
  var remaining = quantity;
  final int? row = balanceRowIndexForProductId(
    products: products,
    productId: pid,
  );
  if (row != null) {
    final List<String> rowIds = productIdsForBalanceRow(
      products: products,
      rowIndex: row,
    );
    final List<String> order = <String>[
      pid,
      for (final String id in rowIds)
        if (id != pid) id,
    ];
    for (final String id in order) {
      if (remaining <= 0) {
        break;
      }
      remaining -= _deductStationStockFromProductInList(
        products: products,
        productId: id,
        quantity: remaining,
      );
    }
  } else {
    remaining -= _deductStationStockFromProductInList(
      products: products,
      productId: pid,
      quantity: remaining,
    );
  }
  if (remaining > 0) {
    throw StateError('INSUFFICIENT_STOCK');
  }
}
