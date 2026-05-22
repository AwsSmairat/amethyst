// تمييز دين المحطة عن دين المركبة في القوائم والسداد.

bool isStationDebtEntry(Map<String, dynamic> entry) {
  final String source = entry['recordingSource']?.toString() ?? '';
  return source == 'station' && entry['vehicleSaleId'] == null;
}

bool isVehicleDebtEntry(Map<String, dynamic> entry) {
  if (entry['vehicleSaleId'] != null) {
    return true;
  }
  return entry['recordingSource']?.toString() == 'vehicle';
}
