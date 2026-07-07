import 'package:amethyst/core/vehicle_sale/vehicle_sales_aggregates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sumDebtRepaymentAmounts includes vehicle and station repayments', () {
    final double total = sumDebtRepaymentAmounts(
      <Map<String, dynamic>>[
        <String, dynamic>{
          'totalAmount': 1.5,
          'settledFromDebtSaleId': 'debt-1',
        },
        <String, dynamic>{
          'totalAmount': 2,
          'settledFromDebtId': 'debt-2',
        },
        <String, dynamic>{
          'totalAmount': 10,
          'paymentMethod': 'cash',
        },
        <String, dynamic>{
          'totalAmount': 0,
          'settledFromDebtSaleId': 'debt-3',
        },
      ],
    );

    expect(total, 3.5);
  });
}
