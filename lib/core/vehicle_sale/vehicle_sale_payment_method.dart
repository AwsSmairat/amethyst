import 'package:amethyst/l10n/app_localizations.dart';

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
