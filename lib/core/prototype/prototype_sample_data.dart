import 'package:amethyst/core/prototype/prototype_session.dart';
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

  static List<Map<String, dynamic>> get products => <Map<String, dynamic>>[
        _product(
          id: 'p_water',
          name: 'مياه 19 لتر',
          unitType: 'bottle',
          price: 25,
          stationStock: 420,
        ),
        _product(
          id: 'p_carton',
          name: 'كراتين مياه',
          unitType: 'carton',
          price: 180,
          stationStock: 85,
        ),
        _product(
          id: 'p_gallon',
          name: 'جالون 5 لتر',
          unitType: 'bottle',
          price: 12,
          stationStock: 30,
        ),
      ];

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
    for (final Map<String, dynamic> p in products) {
      if (p['id'] == id) {
        return Map<String, dynamic>.from(p);
      }
    }
    return products.first;
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

  static List<Map<String, dynamic>> get stationSales {
    final Map<String, dynamic> water = productById('p_water');
    final Map<String, dynamic> carton = productById('p_carton');
    return <Map<String, dynamic>>[
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
    ];
  }

  static List<Map<String, dynamic>> get stationDebtEntries {
    final Map<String, dynamic> carton = productById('p_carton');
    return <Map<String, dynamic>>[
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
      <String, dynamic>{
        'id': 'debt2',
        'debtorName': 'بقالة النور',
        'productId': carton['id'],
        'product': carton,
        'quantity': 2,
        'unitPrice': 180.0,
        'totalAmount': 360.0,
        'recordedById': 'proto_driver',
        'recordedBy': userBrief('proto_driver'),
        'recordingSource': 'vehicle',
        'repaidAt': null,
        'createdAt': _today,
      },
    ];
  }

  static List<Map<String, dynamic>> get vehicleLoads {
    final Map<String, dynamic> vehicle = vehicleById('v1');
    final Map<String, dynamic> product = productById('p_water');
    return <Map<String, dynamic>>[
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
    ];
  }

  static List<Map<String, dynamic>> get vehicleSales {
    final Map<String, dynamic> vehicle = vehicleById('v1');
    final Map<String, dynamic> product = productById('p_water');
    return <Map<String, dynamic>>[
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
        'createdAt': _today,
      },
    ];
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

  static Map<String, dynamic> getDashboardDriver() {
    final Map<String, dynamic> vehicle = vehicleById('v1');
    final Map<String, dynamic> product = productById('p_water');
    final List<Map<String, dynamic>> loadsToday = <Map<String, dynamic>>[
      vehicleLoads.first,
    ];
    final List<Map<String, dynamic>> remainingQuantities = <Map<String, dynamic>>[
      <String, dynamic>{
        'productId': product['id'],
        'productName': product['name'],
        'remaining': 30,
        'quantityReturned': 2,
        'quantitySold': 18,
      },
    ];
    return <String, dynamic>{
      'role': 'driver',
      'metrics': <String, dynamic>{
        'totalExpensesToday': 350.0,
        'vehicleSalesToday': 150.0,
        'remainingOnVehicle': 30,
      },
      'details': <String, dynamic>{
        'assignedVehicle': vehicle,
        'remainingQuantities': remainingQuantities,
        'notesSummary': <Map<String, dynamic>>[
          <String, dynamic>{'note': 'تسليم عينة — عرض فقط', 'at': _today},
        ],
        'productsLoadedToday': loadsToday,
        'soldQuantitiesToday': 6,
        'returnedQuantitiesToday': 2,
      },
      'assignedVehicle': vehicle,
      'productsLoadedToday': loadsToday,
      'soldQuantitiesToday': 6,
      'vehicleSalesAmountToday': 150.0,
      'remainingQuantities': remainingQuantities,
      'remainingOnVehicle': 30,
      'returnedQuantitiesToday': 2,
      'totalExpensesToday': 350.0,
      'notesSummary': <Map<String, dynamic>>[
        <String, dynamic>{'note': 'تسليم عينة — عرض فقط', 'at': _today},
      ],
    };
  }

  static Map<String, dynamic> driverCurrentLoad() {
    return <String, dynamic>{
      'item': vehicleLoads.first,
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
