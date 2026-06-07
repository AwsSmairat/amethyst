import 'package:intl/intl.dart';

String formatMoneyAmount(
  dynamic value, {
  String locale = 'ar',
  int fractionDigits = 2,
}) {
  if (value == null) {
    return '—';
  }
  final double? amount = value is num
      ? value.toDouble()
      : double.tryParse(value.toString());
  if (amount == null) {
    return value.toString();
  }
  return NumberFormat.decimalPattern(locale).format(amount);
}
