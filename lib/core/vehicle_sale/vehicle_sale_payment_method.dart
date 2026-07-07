import 'package:amethyst/l10n/app_localizations.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';

enum VehicleSalePaymentMethod {
  cash,
  cliq,
}

extension VehicleSalePaymentMethodFirestore on VehicleSalePaymentMethod {
  String get firestoreValue => switch (this) {
        VehicleSalePaymentMethod.cash => 'cash',
        VehicleSalePaymentMethod.cliq => 'cliq',
      };
}

/// تسمية عربية لقيمة [paymentMethod] المخزّنة في Firestore.
String? vehicleSalePaymentMethodLabel(
  AppLocalizations l10n,
  String? raw,
) {
  return switch (raw?.trim().toLowerCase()) {
    'cash' => l10n.vehicleSalePaymentCash,
    'cliq' => l10n.vehicleSalePaymentCliq,
    _ => null,
  };
}

/// إجمالي مبالغ المبيعات حسب طريقة الدفع (كاش / كليك).
final class SalePaymentMethodAmountTotals {
  const SalePaymentMethodAmountTotals({
    this.cash = 0,
    this.cliq = 0,
  });

  final double cash;
  final double cliq;

  bool get hasAny => cash != 0 || cliq != 0;
}

SalePaymentMethodAmountTotals sumSalePaymentMethodAmounts(
  Iterable<Map<String, dynamic>> sales,
) {
  var cash = 0.0;
  var cliq = 0.0;
  for (final Map<String, dynamic> row in sales) {
    final double amount = parseDynamicDouble(row['totalAmount']) ?? 0;
    if (amount == 0) {
      continue;
    }
    if (isDebtRepaymentSale(row)) {
      cash += amount;
      continue;
    }
    switch (row['paymentMethod']?.toString().trim().toLowerCase()) {
      case 'cash':
        cash += amount;
      case 'cliq':
        cliq += amount;
      default:
        break;
    }
  }
  return SalePaymentMethodAmountTotals(cash: cash, cliq: cliq);
}
