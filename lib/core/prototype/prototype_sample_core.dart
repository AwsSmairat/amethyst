part of 'prototype_sample_data.dart';

Map<String, dynamic> _prototypeProduct({
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

mixin _PrototypeSampleCore on _PrototypeSampleDataBase {
  final DateTime _now = DateTime.now();

  DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  bool _loaded = false;

  Timer? _persistTimer;

  final List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> _vehicles = <Map<String, dynamic>>[];

  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    final Map<String, dynamic>? snapshot =
        await PrototypeLocalStore.loadSnapshot();
    if (snapshot != null) {
      _importSnapshot(snapshot);
    } else {
      _seedUsersAndVehicles();
    }
    _loaded = true;
  }

  List<Map<String, dynamic>> get users => _users
      .map((Map<String, dynamic> u) => _publicUserMap(u))
      .toList(growable: false);

  final List<Map<String, dynamic>> _products = <Map<String, dynamic>>[
    _prototypeProduct(
      id: 'p_water',
      name: 'Water Bottle',
      unitType: 'bottle',
      price: 25,
      stationStock: 0,
    ),
    _prototypeProduct(
      id: 'p_mahdi_carton',
      name: 'ك مهدي',
      unitType: 'carton',
      price: 180,
      stationStock: 0,
    ),
    _prototypeProduct(
      id: 'p_gallon',
      name: 'Water Gallon',
      unitType: 'gallon',
      price: 12,
      stationStock: 0,
    ),
    _prototypeProduct(
      id: 'p_coupon50',
      name: 'كوبون ٥٠',
      unitType: 'coupon',
      price: 0,
      stationStock: 0,
    ),
  ];

  List<Map<String, dynamic>> get products =>
      List<Map<String, dynamic>>.from(_products);

  bool _pricingCatalogEnsured = false;

  final List<Map<String, dynamic>> _vehicleLoads =
      <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> _vehicleSales =
      <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> _returns = <Map<String, dynamic>>[];

  void _persist() {}

  void _importSnapshot(Map<String, dynamic> snapshot) {}

  void _seedUsersAndVehicles() {}

  Map<String, dynamic> _publicUserMap(Map<String, dynamic> u) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(u);
    copy.remove('password');
    return copy;
  }

  Map<String, dynamic> _user({
    required String id,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    required String password,
  }) =>
      <String, dynamic>{
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'password': password,
        'isActive': true,
        'createdBy': 'proto_super',
        'createdAt': _today,
        'updatedAt': _today,
      };

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _loadDateOnly(Map<String, dynamic> load) {
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

  int _intField(Map<String, dynamic> map, String key) {
    final Object? v = map[key];
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  int _remainingForLoad(Map<String, dynamic> load) {
    final int loaded = _intField(load, 'quantityLoaded');
    final int sold = _intField(load, 'quantitySold');
    final int returned = _intField(load, 'quantityReturned');
    final int remaining = loaded - sold - returned;
    return remaining < 0 ? 0 : remaining;
  }

  void _closeLoadLineIfSettled(Map<String, dynamic> load) {
    if (_remainingForLoad(load) <= 0) {
      load['status'] = 'closed';
    }
  }

  String _sessionDriverId() =>
      PrototypeSession.current?.id ?? 'proto_driver';

  void _ensureInitialVehicleSales() {}

  Map<String, dynamic> _profitSnapshotForToday() => <String, dynamic>{};

  Map<String, dynamic> _profitSnapshotForCurrentMonth() => <String, dynamic>{};

  double _expensesAmountToday({String? driverId}) => 0;

  Map<String, dynamic> _recordReturnForLoad({
    required Map<String, dynamic> load,
    required int quantityReturned,
    bool automaticEndOfDay = false,
  }) =>
      <String, dynamic>{};
}
