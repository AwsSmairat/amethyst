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

String stationDebtKindSummary(List<Map<String, dynamic>> entries) {
  if (entries.isEmpty) {
    return '';
  }
  final int station =
      entries.where(isStationDebtEntry).length;
  final int vehicle =
      entries.where(isVehicleDebtEntry).length;
  if (station > 0 && vehicle > 0) {
    return 'دين محطة ($station) · دين سيارة ($vehicle)';
  }
  if (station > 0) {
    return 'دين محطة';
  }
  return 'دين سيارة';
}
