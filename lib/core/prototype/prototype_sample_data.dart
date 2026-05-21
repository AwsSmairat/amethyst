import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/core/station_balance/station_balance_catalog.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_catalog.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

/// Static sample maps for UI prototype lists and dashboards.
final class PrototypeSampleData {
  PrototypeSampleData._();

  static final DateTime _now = DateTime.now();
  static DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  static List<Map<String, dynamic>> get users => <Map<String, dynamic>>[
        _user(
          id: 'proto_super',
          fullName: 'مدير عام (عرض)',
          email: 'super@preview.local',
          phone: '+201000000001',
          role: 'super_admin',
        ),
        _user(
          id: 'proto_admin',
          fullName: 'مسؤول المحطة',
          email: 'admin@preview.local',
          phone: '+201000000002',
          role: 'admin',
        ),
        _user(
          id: 'proto_admin2',
          fullName: 'مسؤول مساعد',
          email: 'admin2@preview.local',
          phone: '+201000000004',
          role: 'admin',
        ),
        _user(
          id: 'proto_driver',
          fullName: 'سائق (عرض)',
          email: 'driver@preview.local',
          phone: '+201000000003',
          role: 'driver',
        ),
        _user(
          id: 'proto_driver2',
          fullName: 'أحمد السائق',
          email: 'driver2@preview.local',
          phone: '+201000000005',
          role: 'driver',
        ),
      ];

  static final List<Map<String, dynamic>> _products = <Map<String, dynamic>>[
    _product(
      id: 'p_water',
      name: 'قاروره ٢٠ لتر',
      unitType: 'bottle',
      price: 25,
      stationStock: 420,
    ),
    _product(
      id: 'p_mahdi_carton',
      name: 'ك مهدي',
      unitType: 'carton',
      price: 180,
      stationStock: 85,
    ),
    _product(
      id: 'p_gallon',
      name: 'جالون ٢٠ لتر',
      unitType: 'bottle',
      price: 12,
      stationStock: 30,
    ),
    _product(
      id: 'p_coupon50',
      name: 'Coupon 3',
      unitType: 'coupon',
      price: 0,
      stationStock: 0,
    ),
  ];

  static List<Map<String, dynamic>> get products =>
      List<Map<String, dynamic>>.from(_products);

  static bool _pricingCatalogEnsured = false;

  /// يضمن وجود منتج في الكتالوج لكل صف تسعير سوبر أدمن (ربط بالأسماء المعيارية).
  static void ensurePricingCatalogProducts() {
    if (_pricingCatalogEnsured) {
      return;
    }
    _pricingCatalogEnsured = true;
    for (final int rowIndex in kStationPricingBalanceRowIndices) {
      final Map<String, dynamic>? existing = resolveStationBalanceProduct(
        products: _products,
        rowIndex: rowIndex,
      );
      if (existing != null) {
        continue;
      }
      upsertStationBalanceRow(rowIndex: rowIndex, stationStock: 0);
    }
    ensureStoreMahdiSaleProduct();
  }

  /// منتج «مهدي متجر» للتسعير والبيع — مخزون المحطة والسيارة من «ك مهدي».
  static void ensureStoreMahdiSaleProduct() {
    if (resolveStoreMahdiSaleProduct(products: _products) != null) {
      return;
    }
    _products.add(
      _product(
        id: 'p_store_mahdi',
        name: kStoreMahdiProductApiName,
        unitType: 'carton',
        price: 200,
        stationStock: 0,
      ),
    );
  }

  static bool setProductPrice(String productId, double price) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id']?.toString() == productId) {
        p['price'] = price;
        return true;
      }
    }
    return false;
  }

  static void addProduct(Map<String, dynamic> product) {
    _products.add(product);
  }

  /// تحديث مخزون المحطة في الذاكرة (نموذج UI).
  static bool setStationStock(String productId, int stationStock) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id']?.toString() == productId) {
        p['stationStock'] = stationStock;
        p['stock'] = stationStock;
        return true;
      }
    }
    return false;
  }

  /// إنشاء أو تحديث منتج لصف رصيد المحطة (عرض فقط).
  static void upsertStationBalanceRow({
    required int rowIndex,
    required int stationStock,
  }) {
    final Map<String, dynamic>? existing = resolveStationBalanceProduct(
      products: _products,
      rowIndex: rowIndex,
    );
    if (existing != null) {
      setStationStock(existing['id']!.toString(), stationStock);
      return;
    }
    final ({String name, String unitType}) spec =
        stationBalanceSeedSpecForRow(rowIndex);
    _products.add(
      _product(
        id: 'p_row_$rowIndex',
        name: spec.name,
        unitType: spec.unitType,
        price: 1,
        stationStock: stationStock,
      ),
    );
  }

  static List<Map<String, dynamic>> get vehicles => <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'v1',
          'vehicleNumber': 'أ ب ج 1234',
          'driverId': 'proto_driver',
          'isActive': true,
          'notes': 'مركبة العرض',
        },
        <String, dynamic>{
          'id': 'v2',
          'vehicleNumber': 'د هـ و 5678',
          'driverId': 'proto_driver2',
          'isActive': true,
          'notes': null,
        },
      ];

  static Map<String, dynamic> vehicleById(String? id) {
    for (final Map<String, dynamic> v in vehicles) {
      if (v['id'] == id) {
        return Map<String, dynamic>.from(v);
      }
    }
    return vehicles.first;
  }

  static Map<String, dynamic> productById(String? id) {
    for (final Map<String, dynamic> p in _products) {
      if (p['id'] == id) {
        return Map<String, dynamic>.from(p);
      }
    }
    return Map<String, dynamic>.from(_products.first);
  }

  static Map<String, dynamic> userBrief(String? id) {
    for (final Map<String, dynamic> u in users) {
      if (u['id'] == id) {
        return <String, dynamic>{
          'id': u['id'],
          'fullName': u['fullName'],
          'email': u['email'],
        };
      }
    }
    return <String, dynamic>{
      'id': id ?? 'unknown',
      'fullName': 'مستخدم',
      'email': '',
    };
  }

  static final List<Map<String, dynamic>> _stationSales =
      <Map<String, dynamic>>[];

  static void _ensureInitialStationSales() {
    if (_stationSales.isNotEmpty) {
      return;
    }
    final Map<String, dynamic> water = productById('p_water');
    final Map<String, dynamic> carton = productById('p_mahdi_carton');
    _stationSales.addAll(<Map<String, dynamic>>[
      _stationSale(
        id: 'ss1',
        product: water,
        quantity: 12,
        unitPrice: 25,
        note: 'بيع محطة — صباح',
      ),
      _stationSale(
        id: 'ss2',
        product: carton,
        quantity: 4,
        unitPrice: 180,
        note: null,
      ),
    ]);
  }

  static List<Map<String, dynamic>> get stationSales {
    _ensureInitialStationSales();
    return List<Map<String, dynamic>>.from(_stationSales);
  }

  static Map<String, dynamic> addStationSale({
    required String productId,
    required int quantity,
    required double unitPrice,
    String? note,
    String? settledFromDebtId,
  }) {
    _ensureInitialStationSales();
    final Map<String, dynamic> product = productById(productId);
    final String soldById =
        PrototypeSession.current?.id ?? 'proto_admin';
    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'ss_${_stationSales.length + 1}',
      'productId': product['id'],
      'product': product,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': unitPrice * quantity,
      'soldById': soldById,
      'soldBy': userBrief(soldById),
      'note': note,
      if (settledFromDebtId != null && settledFromDebtId.isNotEmpty)
        'settledFromDebtId': settledFromDebtId,
      'createdAt': _now,
    };
    _stationSales.add(row);
    return row;
  }

  /// سداد دين المحطة: إغلاق السجل + مبيع محطة اليوم (بدون خصم مخزون مرة أخرى).
  static int repayStationDebtForDebtor({required String debtorName}) {
    _ensureInitialStationDebt();
    final String want = debtorName.trim();
    if (want.isEmpty) {
      return 0;
    }
    var count = 0;
    final DateTime now = _now;
    final List<Map<String, dynamic>> toSettle = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> e in _stationDebtEntries) {
      if (e['repaidAt'] != null) {
        continue;
      }
      if (e['recordingSource']?.toString() != 'station') {
        continue;
      }
      if (e['debtorName']?.toString().trim() != want) {
        continue;
      }
      toSettle.add(e);
    }
    for (final Map<String, dynamic> debt in toSettle) {
      debt['repaidAt'] = now;
      addStationSale(
        productId: debt['productId']?.toString() ?? '',
        quantity: (debt['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: ((debt['unitPrice'] as num?) ?? 0).toDouble(),
        note: 'سداد دين — $want',
        settledFromDebtId: debt['id']?.toString(),
      );
      count++;
    }
    return count;
  }

  static final List<Map<String, dynamic>> _stationDebtEntries =
      <Map<String, dynamic>>[];

  static void _ensureInitialStationDebt() {
    if (_stationDebtEntries.isNotEmpty) {
      return;
    }
    final Map<String, dynamic> carton = productById('p_mahdi_carton');
    _stationDebtEntries.addAll(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'debt1',
        'debtorName': 'محل الأمل',
        'productId': carton['id'],
        'product': carton,
        'quantity': 3,
        'unitPrice': 180.0,
        'totalAmount': 540.0,
        'recordedById': 'proto_admin',
        'recordedBy': userBrief('proto_admin'),
        'recordingSource': 'station',
        'repaidAt': null,
        'createdAt': _today,
      },
    ]);
  }

  static List<Map<String, dynamic>> get stationDebtEntries {
    _ensureInitialStationDebt();
    return List<Map<String, dynamic>>.from(_stationDebtEntries);
  }

  /// ديون مفتوحة: سجلات محطة + مبيعات سيارة مسجّلة كدين.
  static List<Map<String, dynamic>> get openStationDebtEntries {
    _ensureInitialStationDebt();
    _ensureInitialVehicleSales();
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> e in _stationDebtEntries) {
      if (e['repaidAt'] == null) {
        out.add(e);
      }
    }
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (vs['isDebt'] == true && vs['repaidAt'] == null) {
        out.add(_vehicleSaleAsDebtEntry(vs));
      }
    }
    return out;
  }

  static Map<String, dynamic> _vehicleSaleAsDebtEntry(
    Map<String, dynamic> vs,
  ) =>
      <String, dynamic>{
        'id': vs['id'],
        'debtorName': vs['debtorName'],
        'productId': vs['productId'],
        'product': vs['product'],
        'quantity': vs['quantity'],
        'unitPrice': vs['unitPrice'],
        'totalAmount': vs['totalAmount'],
        'recordedById': vs['driverId'],
        'recordedBy': vs['driver'],
        'recordingSource': 'vehicle',
        'vehicleSaleId': vs['id'],
        'repaidAt': vs['repaidAt'],
        'createdAt': vs['createdAt'],
      };

  /// إضافة سجلات دين (نموذج UI) — تظهر في قائمة الدين.
  static void addStationDebtEntries({
    required String debtorName,
    required List<Map<String, dynamic>> lines,
  }) {
    _ensureInitialStationDebt();
    final String recordedById =
        PrototypeSession.current?.id ?? 'proto_driver';
    const String recordingSource = 'station';
    final DateTime created = _now;
    for (final Map<String, dynamic> line in lines) {
      final String productId = line['productId']?.toString() ?? '';
      final int quantity = (line['quantity'] as num?)?.toInt() ?? 0;
      final double unitPrice =
          ((line['unitPrice'] as num?) ?? 0).toDouble();
      if (productId.isEmpty || quantity <= 0) {
        continue;
      }
      final Map<String, dynamic> product = productById(productId);
      _stationDebtEntries.add(
        <String, dynamic>{
          'id': 'debt_${_stationDebtEntries.length + 1}_${created.millisecondsSinceEpoch}',
          'debtorName': debtorName.trim(),
          'productId': product['id'],
          'product': product,
          'quantity': quantity,
          'unitPrice': unitPrice,
          'totalAmount': unitPrice * quantity,
          'recordedById': recordedById,
          'recordedBy': userBrief(recordedById),
          'recordingSource': recordingSource,
          'repaidAt': null,
          'createdAt': created,
        },
      );
    }
  }

  static final List<Map<String, dynamic>> _vehicleLoads =
      <Map<String, dynamic>>[];

  static List<Map<String, dynamic>> get vehicleLoads {
    _ensureInitialVehicleLoad();
    return List<Map<String, dynamic>>.from(_vehicleLoads);
  }

  static void _ensureInitialVehicleLoad() {
    if (_vehicleLoads.isNotEmpty) {
      return;
    }
    final Map<String, dynamic> vehicle = vehicleById('v1');
    final Map<String, dynamic> product = productById('p_water');
    _vehicleLoads.add(
      <String, dynamic>{
        'id': 'load1',
        'vehicleId': vehicle['id'],
        'vehicle': vehicle,
        'driverId': 'proto_driver',
        'driver': userBrief('proto_driver'),
        'productId': product['id'],
        'product': product,
        'quantityLoaded': 50,
        'quantitySold': 18,
        'quantityReturned': 2,
        'status': 'open',
        'loadDate': _today,
        'createdAt': _today,
        'createdBy': userBrief('proto_admin'),
      },
    );
  }

  /// إنشاء سطر تحميل في الذاكرة (نموذج UI).
  static Map<String, dynamic> addVehicleLoad({
    required String vehicleId,
    required String driverId,
    required String productId,
    required int quantityLoaded,
    required String loadDate,
  }) {
    _ensureInitialVehicleLoad();
    final Map<String, dynamic> vehicle = vehicleById(vehicleId);
    final Map<String, dynamic> product = productById(productId);
    final DateTime parsedDate = DateTime.tryParse(loadDate) ?? _today;
    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'load_${_vehicleLoads.length + 1}',
      'vehicleId': vehicle['id'],
      'vehicle': vehicle,
      'driverId': driverId,
      'driver': userBrief(driverId),
      'productId': product['id'],
      'product': product,
      'quantityLoaded': quantityLoaded,
      'quantitySold': 0,
      'quantityReturned': 0,
      'status': 'open',
      'loadDate': parsedDate,
      'createdAt': _now,
      'createdBy': userBrief(PrototypeSession.current?.id ?? 'proto_admin'),
    };
    _vehicleLoads.add(row);
    return row;
  }

  /// يضمن وجود منتج لصف التحميل ويعيد معرّفه.
  static String ensureVehicleLoadRowProductId(int rowIndex) {
    final Map<String, dynamic>? existing = resolveVehicleLoadRowProduct(
      products: _products,
      rowIndex: rowIndex,
    );
    if (existing != null) {
      return existing['id']!.toString();
    }
    final ({String name, String unitType}) spec =
        vehicleLoadSeedSpecForRow(rowIndex);
    final String id = 'p_vload_$rowIndex';
    addProduct(
      _product(
        id: id,
        name: spec.name,
        unitType: spec.unitType,
        price: 1,
        stationStock: 0,
      ),
    );
    return id;
  }

  static final List<Map<String, dynamic>> _vehicleSales =
      <Map<String, dynamic>>[];

  static List<Map<String, dynamic>> get vehicleSales {
    _ensureInitialVehicleSales();
    return List<Map<String, dynamic>>.from(_vehicleSales);
  }

  static void _ensureInitialVehicleSales() {
    if (_vehicleSales.isNotEmpty) {
      return;
    }
    final Map<String, dynamic> vehicle = vehicleById('v1');
    final Map<String, dynamic> product = productById('p_water');
    _vehicleSales.add(
      <String, dynamic>{
        'id': 'vs1',
        'vehicleId': vehicle['id'],
        'vehicle': vehicle,
        'driverId': 'proto_driver',
        'driver': userBrief('proto_driver'),
        'productId': product['id'],
        'product': product,
        'quantity': 6,
        'unitPrice': 25.0,
        'totalAmount': 150.0,
        'saleDestination': 'home',
        'isDebt': false,
        'createdAt': _today.toIso8601String(),
      },
    );
    final Map<String, dynamic> water = productById('p_water');
    _vehicleSales.add(
      <String, dynamic>{
        'id': 'vs_debt_sample',
        'vehicleId': vehicle['id'],
        'vehicle': vehicle,
        'driverId': 'proto_driver',
        'driver': userBrief('proto_driver'),
        'productId': water['id'],
        'product': water,
        'quantity': 2,
        'unitPrice': 180.0,
        'totalAmount': 360.0,
        'saleDestination': 'home',
        'debtorName': 'بقالة النور',
        'isDebt': true,
        'repaidAt': null,
        'createdAt': _today,
      },
    );
  }

  /// سداد ديون المركبة: إغلاق سجل الدين + تسجيل مبيع اليوم **بدون** خصم مخزون.
  static int repayVehicleDebtForDebtor({required String debtorName}) {
    _ensureInitialVehicleSales();
    final String want = debtorName.trim();
    if (want.isEmpty) {
      return 0;
    }
    var count = 0;
    final DateTime now = _now;
    final List<Map<String, dynamic>> toSettle = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> vs in _vehicleSales) {
      if (vs['isDebt'] != true || vs['repaidAt'] != null) {
        continue;
      }
      if (vs['debtorName']?.toString().trim() != want) {
        continue;
      }
      toSettle.add(vs);
    }
    for (final Map<String, dynamic> debt in toSettle) {
      debt['repaidAt'] = now.toIso8601String();
      addVehicleSale(
        vehicleId: debt['vehicleId']?.toString() ?? 'v1',
        productId: debt['productId']?.toString() ?? '',
        quantity: (debt['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: ((debt['unitPrice'] as num?) ?? 0).toDouble(),
        saleDestination: debt['saleDestination']?.toString() ?? 'home',
        debtorName: debt['debtorName']?.toString(),
        isDebt: false,
        skipLoadDeduction: true,
        settledFromDebtSaleId: debt['id']?.toString(),
      );
      count++;
    }
    return count;
  }

  /// خصم الكمية من حمولة السيارة المفتوحة (يزيد `quantitySold`).
  static void deductVehicleLoadForSale({
    required String productId,
    required int quantity,
    String? driverId,
    String? vehicleId,
  }) {
    _ensureInitialVehicleLoad();
    if (quantity <= 0) {
      return;
    }
    final Map<String, dynamic> soldProduct = productById(productId);
    final String soldName = soldProduct['name']?.toString() ?? '';
    var remaining = quantity;

    bool lineMatches(Map<String, dynamic> load) {
      if (load['status']?.toString() == 'closed') {
        return false;
      }
      if (driverId != null &&
          driverId.isNotEmpty &&
          load['driverId']?.toString() != driverId) {
        return false;
      }
      if (vehicleId != null &&
          vehicleId.isNotEmpty &&
          load['vehicleId']?.toString() != vehicleId) {
        return false;
      }
      if (load['productId']?.toString() == productId) {
        return true;
      }
      final String loadName =
          (load['product'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
      if (loadName.isEmpty || soldName.isEmpty) {
        return false;
      }
      return stationBalanceProductNamesMatch(loadName, soldName);
    }

    for (final Map<String, dynamic> load in _vehicleLoads) {
      if (remaining <= 0) {
        break;
      }
      if (!lineMatches(load)) {
        continue;
      }
      final int onLoad = _remainingForLoad(load);
      if (onLoad <= 0) {
        continue;
      }
      final int take = remaining < onLoad ? remaining : onLoad;
      load['quantitySold'] = _intField(load, 'quantitySold') + take;
      load['product'] = productById(load['productId']?.toString());
      remaining -= take;
    }
  }

  static Map<String, dynamic> addVehicleSale({
    required String vehicleId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String saleDestination = 'home',
    String? stockProductId,
    String? debtorName,
    bool isDebt = false,
    bool skipLoadDeduction = false,
    String? settledFromDebtSaleId,
  }) {
    _ensureInitialVehicleSales();
    final Map<String, dynamic> vehicle = vehicleById(vehicleId);
    final String? driverId = vehicle['driverId']?.toString();
    final Map<String, dynamic> product = productById(productId);
    if (!skipLoadDeduction) {
      final String deductFrom = stockProductId ?? productId;
      deductVehicleLoadForSale(
        productId: deductFrom,
        quantity: quantity,
        driverId: driverId,
        vehicleId: vehicleId,
      );
    }
    final Map<String, dynamic> row = <String, dynamic>{
      'id': 'vs_${_vehicleSales.length + 1}',
      'vehicleId': vehicle['id'],
      'vehicle': vehicle,
      'driverId': driverId,
      'driver': userBrief(driverId),
      'productId': product['id'],
      'product': product,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': unitPrice * quantity,
      'saleDestination': saleDestination,
      'isDebt': isDebt,
      if (debtorName != null && debtorName.trim().isNotEmpty)
        'debtorName': debtorName.trim(),
      if (settledFromDebtSaleId != null && settledFromDebtSaleId.isNotEmpty)
        'settledFromDebtSaleId': settledFromDebtSaleId,
      'repaidAt': null,
      'createdAt': _now.toIso8601String(),
    };
    _vehicleSales.add(row);
    return row;
  }

  static List<Map<String, dynamic>> get expenses => <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'ex1',
          'amount': 350.0,
          'note': 'صيانة مضخة',
          'vehicleId': 'v1',
          'driverId': 'proto_driver',
          'createdAt': _today,
        },
        <String, dynamic>{
          'id': 'ex2',
          'amount': 1200.0,
          'note': 'STATION_CARTON_WATER: شراء كراتين',
          'vehicleId': null,
          'driverId': null,
          'createdAt': _today,
        },
      ];

  static List<Map<String, dynamic>> get returns => <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'ret1',
          'vehicleLoadId': 'load1',
          'quantityReturned': 2,
          'createdAt': _today,
          'load': vehicleLoads.first,
        },
      ];

  static Map<String, dynamic> getDashboardSuperAdmin() {
    final List<Map<String, dynamic>> debtPreview = <Map<String, dynamic>>[
      <String, dynamic>{
        'debtorName': 'محل الأمل',
        'totalAmount': 540.0,
        'entryCount': 1,
      },
      <String, dynamic>{
        'debtorName': 'بقالة النور',
        'totalAmount': 360.0,
        'entryCount': 1,
      },
    ];
    return <String, dynamic>{
      'role': 'super_admin',
      'metrics': <String, dynamic>{
        'totalSalesToday': 870.0,
        'stationSalesToday': 720.0,
        'vehicleSalesToday': 150.0,
        'totalExpensesToday': 350.0,
        'totalMonthlyExpenses': 1550.0,
        'totalProfitToday': 520.0,
        'totalMonthlySales': 24500.0,
      },
      'details': <String, dynamic>{
        'counts': <String, dynamic>{
          'users': users.length,
          'admins': 2,
          'drivers': 2,
          'vehicles': vehicles.length,
          'products': products.length,
          'pricedProducts': 3,
        },
        'lowStockProducts': <Map<String, dynamic>>[products.last],
        'stationDebtOpenPreview': debtPreview,
        'remainingStationStock': 535,
        'remainingOnVehicles': 30,
      },
      'totalUsers': users.length,
      'totalAdmins': 2,
      'totalDrivers': 2,
      'totalVehicles': vehicles.length,
      'totalProducts': products.length,
      'productsWithPrice': 3,
      'totalSalesToday': 870.0,
      'stationSalesToday': 720.0,
      'vehicleSalesToday': 150.0,
      'totalExpensesToday': 350.0,
      'totalMonthlyExpenses': 1550.0,
      'totalProfitToday': 520.0,
      'totalMonthlySales': 24500.0,
      'totalMonthlyCartonSales': 12000.0,
      'remainingStationStock': 535,
      'remainingOnVehicles': 30,
      'lowStockProducts': <Map<String, dynamic>>[products.last],
      'stationDebtOpenPreview': debtPreview,
    };
  }

  static Map<String, dynamic> getSuperAdminCartonSummary() => <String, dynamic>{
        'cartonStock': 85,
        'monthlyCartonExpensesTotalAmount': 1200.0,
        'monthlyCartonSalesTotalAmount': 7200.0,
        'monthlyCartonSalesHomeQty': 28,
        'monthlyCartonSalesStoreQty': 12,
        'cartonDebtUnpaidQuantity': 5,
        'cartonDebtUnpaidTotalAmount': 900.0,
      };

  static Map<String, dynamic> getDashboardAdmin() => <String, dynamic>{
        'role': 'admin',
        'stationSalesToday': 720.0,
        'vehicleLoadsToday': 1,
        'openDebtCount': 2,
        'productsCount': products.length,
      };

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _loadDateOnly(Map<String, dynamic> load) {
    final Object? raw = load['loadDate'];
    if (raw is DateTime) {
      return _dateOnly(raw);
    }
    if (raw is String) {
      final DateTime? parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return _dateOnly(parsed);
      }
    }
    return _today;
  }

  static int _intField(Map<String, dynamic> map, String key) {
    final Object? v = map[key];
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _remainingForLoad(Map<String, dynamic> load) {
    final int loaded = _intField(load, 'quantityLoaded');
    final int sold = _intField(load, 'quantitySold');
    final int returned = _intField(load, 'quantityReturned');
    final int remaining = loaded - sold - returned;
    return remaining < 0 ? 0 : remaining;
  }

  static Map<String, dynamic> _enrichLoadRow(Map<String, dynamic> load) {
    final String? productId = load['productId']?.toString();
    final Map<String, dynamic> product = productId != null
        ? productById(productId)
        : Map<String, dynamic>.from(
            load['product'] as Map<String, dynamic>? ?? <String, dynamic>{},
          );
    return <String, dynamic>{
      ...Map<String, dynamic>.from(load),
      'product': product,
      'remaining': _remainingForLoad(load),
    };
  }

  static String _sessionDriverId() =>
      PrototypeSession.current?.id ?? 'proto_driver';

  static Map<String, dynamic>? _assignedVehicleForDriver(String driverId) {
    for (final Map<String, dynamic> v in vehicles) {
      if (v['driverId']?.toString() == driverId) {
        return Map<String, dynamic>.from(v);
      }
    }
    return null;
  }

  /// تحميلات مفتوحة للسائق؛ يُفضَّل تحميلات اليوم وإلا كل المفتوحة (نموذج عرض).
  static List<Map<String, dynamic>> _openLoadsForDriver(String driverId) {
    _ensureInitialVehicleLoad();
    final DateTime today = _dateOnly(DateTime.now());
    final List<Map<String, dynamic>> open = _vehicleLoads
        .where((Map<String, dynamic> l) {
          if (l['driverId']?.toString() != driverId) {
            return false;
          }
          final String status = l['status']?.toString() ?? 'open';
          return status != 'closed';
        })
        .map(_enrichLoadRow)
        .toList(growable: false);
    final List<Map<String, dynamic>> todayLoads = open
        .where((Map<String, dynamic> l) => _loadDateOnly(l) == today)
        .toList(growable: false);
    return todayLoads.isNotEmpty ? todayLoads : open;
  }

  static Map<String, dynamic> driverCurrentLoad() {
    final String driverId = _sessionDriverId();
    final Map<String, dynamic>? vehicle = _assignedVehicleForDriver(driverId);
    if (vehicle == null) {
      return <String, dynamic>{
        'vehicle': null,
        'loads': <Map<String, dynamic>>[],
      };
    }
    final List<Map<String, dynamic>> loads = _openLoadsForDriver(driverId);
    return <String, dynamic>{
      'vehicle': vehicle,
      'loads': loads,
    };
  }

  static Map<String, dynamic> getDashboardDriver() {
    final Map<String, dynamic> current = driverCurrentLoad();
    final Map<String, dynamic>? vehicle =
        current['vehicle'] as Map<String, dynamic>?;
    final List<Map<String, dynamic>> loads =
        (current['loads'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    final List<Map<String, dynamic>> remainingQuantities =
        <Map<String, dynamic>>[
      for (final Map<String, dynamic> l in loads)
        <String, dynamic>{
          'productId': l['productId'],
          'productName':
              (l['product'] as Map<String, dynamic>?)?['name']?.toString() ??
                  '',
          'remaining': l['remaining'],
          'quantityReturned': _intField(l, 'quantityReturned'),
          'quantitySold': _intField(l, 'quantitySold'),
        },
    ];
    var remainingOnVehicle = 0;
    var soldToday = 0;
    var returnedToday = 0;
    for (final Map<String, dynamic> l in loads) {
      remainingOnVehicle += _intField(l, 'remaining');
      soldToday += _intField(l, 'quantitySold');
      returnedToday += _intField(l, 'quantityReturned');
    }
    final Map<String, dynamic> assignedVehicle =
        vehicle ?? vehicleById('v1');
    return <String, dynamic>{
      'role': 'driver',
      'metrics': <String, dynamic>{
        'totalExpensesToday': 350.0,
        'vehicleSalesToday': 150.0,
        'remainingOnVehicle': remainingOnVehicle,
      },
      'details': <String, dynamic>{
        'assignedVehicle': assignedVehicle,
        'remainingQuantities': remainingQuantities,
        'notesSummary': <Map<String, dynamic>>[
          <String, dynamic>{'note': 'تسليم عينة — عرض فقط', 'at': _today},
        ],
        'productsLoadedToday': loads,
        'soldQuantitiesToday': soldToday,
        'returnedQuantitiesToday': returnedToday,
      },
      'assignedVehicle': assignedVehicle,
      'productsLoadedToday': loads,
      'soldQuantitiesToday': soldToday,
      'vehicleSalesAmountToday': 150.0,
      'remainingQuantities': remainingQuantities,
      'remainingOnVehicle': remainingOnVehicle,
      'returnedQuantitiesToday': returnedToday,
      'totalExpensesToday': 350.0,
      'notesSummary': <Map<String, dynamic>>[
        <String, dynamic>{'note': 'تسليم عينة — عرض فقط', 'at': _today},
      ],
    };
  }

  static Map<String, dynamic> reportsInventory() => <String, dynamic>{
        'stationProducts': products,
        'openLoadLines': 1,
        'estimatedUnitsOnVehicles': 30,
      };

  static Map<String, dynamic> reportsSalesWorkingDays() {
    final String key =
        '${_today.year.toString().padLeft(4, '0')}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}';
    return <String, dynamic>{
      'days': <Map<String, dynamic>>[
        <String, dynamic>{'date': key, 'combined': 870.0},
        <String, dynamic>{'date': '2026-05-15', 'combined': 1200.0},
      ],
    };
  }

  static Map<String, dynamic> reportsProfitLoss() => <String, dynamic>{
        'from': _today.toIso8601String(),
        'to': _today.toIso8601String(),
        'revenue': 870.0,
        'expenses': 1550.0,
        'net': -680.0,
      };

  static Map<String, dynamic> reportsSalesMonthly() => <String, dynamic>{
        'year': _now.year,
        'month': _now.month,
        'stationSales': stationSales,
        'vehicleSales': vehicleSales,
        'totals': <String, dynamic>{
          'stationAmount': 720.0,
          'vehicleAmount': 150.0,
        },
      };

  static Map<String, dynamic> meFromSession() {
    final UserEntity? u = PrototypeSession.current;
    if (u == null) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{
      'id': u.id,
      'email': u.email,
      'fullName': u.fullName,
      'role': u.role,
      'phone': u.phone,
      'isActive': u.isActive,
    };
  }

  static Map<String, dynamic> _user({
    required String id,
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) =>
      <String, dynamic>{
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'isActive': true,
        'createdBy': 'proto_super',
        'createdAt': _today,
        'updatedAt': _today,
      };

  static Map<String, dynamic> _product({
    required String id,
    required String name,
    required String unitType,
    required double price,
    required int stationStock,
  }) =>
      <String, dynamic>{
        'id': id,
        'name': name,
        'unitType': unitType,
        'type': unitType,
        'price': price,
        'stationStock': stationStock,
        'stock': stationStock,
        'isActive': true,
      };

  static Map<String, dynamic> _stationSale({
    required String id,
    required Map<String, dynamic> product,
    required int quantity,
    required double unitPrice,
    required String? note,
  }) =>
      <String, dynamic>{
        'id': id,
        'productId': product['id'],
        'product': product,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': quantity * unitPrice,
        'soldById': 'proto_admin',
        'soldBy': userBrief('proto_admin'),
        'note': note,
        'createdAt': _today,
      };
}
