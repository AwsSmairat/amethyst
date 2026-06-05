String normalizeDebtorName(String? name) => (name ?? '').trim();

bool isUnpaidDebtEntry(Map<String, dynamic> entry) {
  final Object? repaid = entry['repaidAt'];
  return repaid == null;
}
