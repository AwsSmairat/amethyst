String normalizeDebtorName(String? name) => (name ?? '').trim();

bool isUnpaidDebtEntry(Map<String, dynamic> entry) {
  final Object? repaid = entry['repaidAt'];
  return repaid == null;
}

/// مبيعة سيارة مفتوحة كدين (يدعم سجلات قديمة باسم مدين دون حقل isDebt).
bool isOpenVehicleDebtSale(Map<String, dynamic> data) {
  if (data['repaidAt'] != null) {
    return false;
  }
  if (data['settledFromDebtSaleId'] != null) {
    return false;
  }
  if (data['isDebt'] == true) {
    return true;
  }
  return normalizeDebtorName(data['debtorName']?.toString()).isNotEmpty;
}

String debtEntryOwnerId(Map<String, dynamic> entry) =>
    entry['recordedById']?.toString() ??
    entry['driverId']?.toString() ??
    '';

bool isVehicleDebtEntry(Map<String, dynamic> entry) {
  if (entry['vehicleSaleId'] != null) {
    return true;
  }
  return entry['recordingSource']?.toString() == 'vehicle';
}

/// دين مركبة يخص سائقاً معيّناً (مبيعات سيارة أو سجل محطة قديم).
bool isDriverVehicleDebtEntry(
  Map<String, dynamic> entry, {
  required String driverId,
}) {
  if (!isUnpaidDebtEntry(entry)) {
    return false;
  }
  if (debtEntryOwnerId(entry) != driverId) {
    return false;
  }
  if (isVehicleDebtEntry(entry)) {
    return true;
  }
  // سجلات station_debt_entries التي سجّلها السائق قبل حقل recordingSource.
  return entry['vehicleSaleId'] == null;
}
