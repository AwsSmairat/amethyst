part of 'prototype_sample_data.dart';

mixin _PrototypeSampleNotes on _PrototypeSampleReports {
  Map<String, dynamic> meFromSession() {
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

  final List<Map<String, dynamic>> _staffNotes =
      <Map<String, dynamic>>[];

  /// مسؤولو المحطة + السائقون (مستلمو الملاحظات).
  List<Map<String, dynamic>> staffNoteRecipientOptions() {
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> u in users) {
      if (u['isActive'] == false) {
        continue;
      }
      final String role = u['role']?.toString() ?? '';
      if (role == 'admin' || role == 'driver') {
        out.add(Map<String, dynamic>.from(u));
      }
    }
    return out;
  }

  /// إنشاء ملاحظة لمسؤولي المحطة كلهم أو لسائق واحد.
  List<Map<String, dynamic>> createStaffNotes({
    required String senderUserId,
    required String message,
    required String recipientKind,
    String? driverUserId,
  }) {
    final String text = message.trim();
    if (text.isEmpty) {
      throw StateError('EMPTY_MESSAGE');
    }
    final List<String> targetUserIds = <String>[];
    switch (recipientKind) {
      case 'all_admins':
        for (final Map<String, dynamic> u in users) {
          if (u['isActive'] == false) {
            continue;
          }
          if (u['role']?.toString() == 'admin') {
            final String? id = u['id']?.toString();
            if (id != null && id.isNotEmpty) {
              targetUserIds.add(id);
            }
          }
        }
      case 'driver':
        final String? id = driverUserId?.trim();
        if (id == null || id.isEmpty) {
          throw StateError('MISSING_DRIVER');
        }
        targetUserIds.add(id);
      default:
        throw StateError('INVALID_RECIPIENT');
    }
    if (targetUserIds.isEmpty) {
      throw StateError('NO_RECIPIENTS');
    }
    final Map<String, dynamic> fromUser = userBrief(senderUserId);
    final String createdAt = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> created = <Map<String, dynamic>>[];
    for (final String toUserId in targetUserIds) {
      if (toUserId == senderUserId) {
        continue;
      }
      final Map<String, dynamic> row = <String, dynamic>{
        'id': 'staff_note_${_staffNotes.length + 1}',
        'message': text,
        'toUserId': toUserId,
        'fromUserId': senderUserId,
        'fromUser': fromUser,
        'createdAt': createdAt,
        'readAt': null,
      };
      _staffNotes.add(row);
      created.add(Map<String, dynamic>.from(row));
    }
    if (created.isEmpty) {
      throw StateError('NO_RECIPIENTS');
    }
    _persist();
    return created;
  }

  /// أقدم ملاحظة غير مقروءة للمستخدم الحالي (تُعرض واحدة في كل مرة).
  Map<String, dynamic>? firstUnreadStaffNoteForUser(String userId) {
    final String want = userId.trim();
    if (want.isEmpty) {
      return null;
    }
    Map<String, dynamic>? newest;
    DateTime? newestAt;
    for (final Map<String, dynamic> n in _staffNotes) {
      if (n['toUserId']?.toString() != want) {
        continue;
      }
      if (n['readAt'] != null) {
        continue;
      }
      final DateTime? at = DateTime.tryParse(n['createdAt']?.toString() ?? '');
      if (newest == null ||
          (at != null && (newestAt == null || at.isAfter(newestAt)))) {
        newest = n;
        newestAt = at;
      }
    }
    return newest == null ? null : Map<String, dynamic>.from(newest);
  }

  void markStaffNoteRead({
    required String noteId,
    required String userId,
  }) {
    final String wantId = noteId.trim();
    final String wantUser = userId.trim();
    for (final Map<String, dynamic> n in _staffNotes) {
      if (n['id']?.toString() != wantId) {
        continue;
      }
      if (n['toUserId']?.toString() != wantUser) {
        return;
      }
      n['readAt'] = DateTime.now().toIso8601String();
      _persist();
      return;
    }
  }

  void _seedUsersAndVehicles() {
    _users
      ..clear()
      ..addAll(<Map<String, dynamic>>[
        _user(
          id: 'proto_super',
          fullName: 'صهيب بيك',
          email: 'super@preview.local',
          phone: '+201000000001',
          role: 'super_admin',
          password: kPrototypeDefaultPassword,
        ),
        _user(
          id: 'proto_admin',
          fullName: 'مسؤول المحطة',
          email: 'admin@preview.local',
          phone: '+201000000002',
          role: 'admin',
          password: kPrototypeDefaultPassword,
        ),
        _user(
          id: 'proto_driver',
          fullName: 'سائق (عرض)',
          email: 'driver@preview.local',
          phone: '+201000000003',
          role: 'driver',
          password: kPrototypeDefaultPassword,
        ),
        _user(
          id: 'proto_driver2',
          fullName: 'أحمد السائق',
          email: 'driver2@preview.local',
          phone: '+201000000005',
          role: 'driver',
          password: kPrototypeDefaultPassword,
        ),
      ]);
    _vehicles
      ..clear()
      ..addAll(<Map<String, dynamic>>[
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
      ]);
  }

  Map<String, dynamic> _publicUserMap(Map<String, dynamic> u) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(u);
    copy.remove('password');
    return copy;
  }

  void _persist() {
    if (!_loaded) {
      return;
    }
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(
        PrototypeLocalStore.saveSnapshot(_exportSnapshot()),
      );
    });
  }

  Map<String, dynamic> _exportSnapshot() => <String, dynamic>{
        'version': 1,
        'users': _encodeList(_users),
        'vehicles': _encodeList(_vehicles),
        'products': _encodeList(_products),
        'stationSales': _encodeList(_stationSales),
        'stationDebtEntries': _encodeList(_stationDebtEntries),
        'vehicleLoads': _encodeList(_vehicleLoads),
        'vehicleSales': _encodeList(_vehicleSales),
        'expenses': _encodeList(_expenses),
        'returns': _encodeList(_returns),
        'staffNotes': _encodeList(_staffNotes),
        'pricingCatalogEnsured': _pricingCatalogEnsured,
      };

  void _importSnapshot(Map<String, dynamic> snapshot) {
    _users
      ..clear()
      ..addAll(_decodeList(snapshot['users']));
    _vehicles
      ..clear()
      ..addAll(_decodeList(snapshot['vehicles']));
    _products
      ..clear()
      ..addAll(_decodeList(snapshot['products']));
    _stationSales
      ..clear()
      ..addAll(_decodeList(snapshot['stationSales']));
    _stationDebtEntries
      ..clear()
      ..addAll(_decodeList(snapshot['stationDebtEntries']));
    _vehicleLoads
      ..clear()
      ..addAll(_decodeList(snapshot['vehicleLoads']));
    _vehicleSales
      ..clear()
      ..addAll(_decodeList(snapshot['vehicleSales']));
    _expenses
      ..clear()
      ..addAll(_decodeList(snapshot['expenses']));
    _returns
      ..clear()
      ..addAll(_decodeList(snapshot['returns']));
    _staffNotes
      ..clear()
      ..addAll(_decodeList(snapshot['staffNotes']));
    _pricingCatalogEnsured = snapshot['pricingCatalogEnsured'] == true;
    if (_users.isEmpty || _vehicles.isEmpty) {
      _seedUsersAndVehicles();
    }
    if (_products.isEmpty) {
      _products.addAll(<Map<String, dynamic>>[
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
      ]);
    }
  }

  List<Map<String, dynamic>> _encodeList(List<Map<String, dynamic>> rows) =>
      rows
          .map(
            (Map<String, dynamic> row) =>
                _encodeValue(row) as Map<String, dynamic>,
          )
          .toList(growable: false);

  List<Map<String, dynamic>> _decodeList(Object? raw) {
    if (raw is! List<dynamic>) {
      return <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> row) =>
              _decodeValue(row) as Map<String, dynamic>,
        )
        .toList(growable: false);
  }

  Object? _encodeValue(Object? value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return value.map(
        (Object? k, Object? v) => MapEntry(k, _encodeValue(v)),
      );
    }
    if (value is List) {
      return value.map(_encodeValue).toList(growable: false);
    }
    return value;
  }

  Object? _decodeValue(Object? value) {
    if (value is String) {
      final DateTime? dt = DateTime.tryParse(value);
      if (dt != null && value.contains('T')) {
        return dt;
      }
      return value;
    }
    if (value is Map) {
      return value.map(
        (Object? k, Object? v) => MapEntry(k, _decodeValue(v)),
      );
    }
    if (value is List) {
      return value.map(_decodeValue).toList(growable: false);
    }
    return value;
  }
}
