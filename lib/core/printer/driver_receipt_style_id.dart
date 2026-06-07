/// ثلاثة أنماط طباعة للسائق — يختار واحداً للطباعة ويعدّل كل نمط على حدة.
enum DriverReceiptStyleId {
  pattern1,
  pattern2,
  pattern3,
}

extension DriverReceiptStyleIdX on DriverReceiptStyleId {
  String storageKey() => name;

  static DriverReceiptStyleId fromStorageKey(String? raw) {
    return DriverReceiptStyleId.values.firstWhere(
      (DriverReceiptStyleId id) => id.name == raw,
      orElse: () => DriverReceiptStyleId.pattern1,
    );
  }
}
