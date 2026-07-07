import 'package:amethyst/core/vehicle_sale/vehicle_sale_payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sumSalePaymentMethodAmounts splits cash and cliq sales', () {
    final SalePaymentMethodAmountTotals totals = sumSalePaymentMethodAmounts(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'totalAmount': 10,
          'paymentMethod': 'cash',
        },
        <String, dynamic>{
          'totalAmount': 5.5,
          'paymentMethod': 'cliq',
        },
        <String, dynamic>{
          'totalAmount': 3,
          'paymentMethod': 'CLIQ',
        },
        <String, dynamic>{
          'totalAmount': 7,
        },
        <String, dynamic>{
          'totalAmount': 0,
          'paymentMethod': 'cash',
        },
      ],
    );

    expect(totals.cash, 10);
    expect(totals.cliq, 8.5);
    expect(totals.hasAny, isTrue);
  });

  test('sumSalePaymentMethodAmounts adds debt repayment to cash', () {
    final SalePaymentMethodAmountTotals totals = sumSalePaymentMethodAmounts(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'totalAmount': 10,
          'paymentMethod': 'cash',
        },
        <String, dynamic>{
          'totalAmount': 1.5,
          'settledFromDebtSaleId': 'debt-1',
        },
      ],
    );

    expect(totals.cash, 11.5);
    expect(totals.cliq, 0);
  });
}
