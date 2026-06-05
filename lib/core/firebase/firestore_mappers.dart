import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> mapProductDoc(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final Map<String, dynamic> p = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
  p['id'] = doc.id;
  p['price'] = _num(p['price']);
  p['stationStock'] = (p['stationStock'] as num?)?.toInt() ?? 0;
  p['type'] = p['unitType'];
  p['stock'] = p['stationStock'];
  return p;
}

Map<String, dynamic> mapUserDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, dynamic> u = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
  u['id'] = doc.id;
  return u;
}

Map<String, dynamic> mapStationSaleDoc(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  Map<String, dynamic>? product,
  Map<String, dynamic>? soldBy,
}) {
  final Map<String, dynamic> s = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
  s['id'] = doc.id;
  s['unitPrice'] = _num(s['unitPrice']);
  s['totalAmount'] = _num(s['totalAmount']);
  if (product != null) {
    s['product'] = product;
  }
  if (soldBy != null) {
    s['soldBy'] = soldBy;
  }
  final Object? note = s['note'];
  s['note'] = note != null && note.toString().trim().isNotEmpty ? note.toString() : null;
  return s;
}

Map<String, dynamic> mapStationDebtDoc(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  Map<String, dynamic>? product,
  Map<String, dynamic>? recordedBy,
}) {
  final Map<String, dynamic> s = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
  s['id'] = doc.id;
  s['unitPrice'] = _num(s['unitPrice']);
  s['totalAmount'] = _num(s['totalAmount']);
  s['recordingSource'] = s['recordingSource'] ?? 'station';
  if (product != null) {
    s['product'] = product;
  }
  if (recordedBy != null) {
    s['recordedBy'] = recordedBy;
  }
  return s;
}

Map<String, dynamic> mapVehicleSaleDoc(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  Map<String, dynamic>? product,
  Map<String, dynamic>? vehicle,
  Map<String, dynamic>? driver,
}) {
  final Map<String, dynamic> s = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
  s['id'] = doc.id;
  s['unitPrice'] = _num(s['unitPrice']);
  s['totalAmount'] = _num(s['totalAmount']);
  if (product != null) {
    s['product'] = product;
  }
  if (vehicle != null) {
    s['vehicle'] = vehicle;
  }
  if (driver != null) {
    s['driver'] = driver;
  }
  return s;
}

Map<String, dynamic> mapExpenseDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, dynamic> e = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
  e['id'] = doc.id;
  e['amount'] = _num(e['amount']);
  final DateTime? created = timestampToDate(e['createdAt']);
  if (created != null) {
    e['createdAt'] = created;
  }
  final DateTime? updated = timestampToDate(e['updatedAt']);
  if (updated != null) {
    e['updatedAt'] = updated;
  }
  return e;
}

Map<String, dynamic> mapVehicleDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, dynamic> v = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
  v['id'] = doc.id;
  return v;
}

Map<String, dynamic> mapVehicleLoadDoc(
  DocumentSnapshot<Map<String, dynamic>> doc, {
  Map<String, dynamic>? vehicle,
  Map<String, dynamic>? driver,
  Map<String, dynamic>? product,
  Map<String, dynamic>? createdBy,
}) {
  final Map<String, dynamic> l = Map<String, dynamic>.from(doc.data() ?? <String, dynamic>{});
  l['id'] = doc.id;
  if (vehicle != null) {
    l['vehicle'] = vehicle;
  }
  if (driver != null) {
    l['driver'] = driver;
  }
  if (product != null) {
    l['product'] = product;
  }
  if (createdBy != null) {
    l['createdBy'] = createdBy;
  }
  return l;
}

double _num(Object? v) {
  if (v == null) {
    return 0;
  }
  if (v is num) {
    return v.toDouble();
  }
  return double.tryParse(v.toString()) ?? 0;
}

DateTime? timestampToDate(Object? v) {
  if (v is Timestamp) {
    return v.toDate();
  }
  if (v is DateTime) {
    return v;
  }
  return null;
}

FieldValue serverTimestamp() => FieldValue.serverTimestamp();
