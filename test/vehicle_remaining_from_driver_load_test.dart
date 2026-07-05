import 'package:amethyst/core/vehicle_sale/vehicle_product_columns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('vehicleRemainingFromDriverLoad', () {
    test('returns zero when stock product line is sold out', () {
      final int remaining = vehicleRemainingFromDriverLoad(
        loadLines: <Map<String, dynamic>>[
          <String, dynamic>{
            'productId': 'gallon',
            'quantityLoaded': 10,
            'quantitySold': 10,
            'quantityReturned': 0,
            'product': <String, dynamic>{'name': 'Water Gallon'},
          },
          <String, dynamic>{
            'productId': 'small_gallon',
            'quantityLoaded': 8,
            'quantitySold': 0,
            'quantityReturned': 0,
            'product': <String, dynamic>{'name': 'Small Water Gallon'},
          },
        ],
        place: VehicleProductColumnPlace.home,
        columnIndex: 0,
        stockProductId: 'gallon',
        saleProductId: 'gallon',
      );

      expect(remaining, 0);
    });

    test('does not borrow remaining from a different product by name', () {
      final int remaining = vehicleRemainingFromDriverLoad(
        loadLines: <Map<String, dynamic>>[
          <String, dynamic>{
            'productId': 'small_gallon',
            'quantityLoaded': 8,
            'quantitySold': 0,
            'quantityReturned': 0,
            'product': <String, dynamic>{'name': 'Small Water Gallon'},
          },
        ],
        place: VehicleProductColumnPlace.home,
        columnIndex: 0,
        stockProductId: 'gallon',
        saleProductId: 'gallon',
      );

      expect(remaining, 0);
    });

    test('sums remaining for matching stock product id', () {
      final int remaining = vehicleRemainingFromDriverLoad(
        loadLines: <Map<String, dynamic>>[
          <String, dynamic>{
            'productId': 'gallon',
            'quantityLoaded': 10,
            'quantitySold': 2,
            'quantityReturned': 0,
            'product': <String, dynamic>{'name': 'Water Gallon'},
          },
          <String, dynamic>{
            'productId': 'gallon',
            'quantityLoaded': 5,
            'quantitySold': 1,
            'quantityReturned': 0,
            'product': <String, dynamic>{'name': 'Water Gallon'},
          },
        ],
        place: VehicleProductColumnPlace.home,
        columnIndex: 0,
        stockProductId: 'gallon',
        saleProductId: 'gallon',
      );

      expect(remaining, 12);
    });
  });
}
