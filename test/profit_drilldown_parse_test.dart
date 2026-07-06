import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw);
  }
  throw TypeError();
}

void main() {
  test('reportsProfitLoss profitDays entries are maps', () {
    final Map<String, dynamic> data = PrototypeSampleData.reportsProfitLoss(
      dateFrom: '2026-01-01',
      dateTo: '2026-05-21',
    );
    expect(data['today'], isA<Map<String, dynamic>>());
    final List<Map<String, dynamic>> days =
        (data['profitDays'] as List<dynamic>)
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList(growable: false);
    expect(days, isNotEmpty);
    for (final Map<String, dynamic> row in days) {
      expect(() => _asMap(row), returnsNormally);
      final Object? vehicles = row['vehicles'];
      if (vehicles is List) {
        for (final Object? vehicle in vehicles) {
          if (vehicle is Map) {
            expect(() => Map<String, dynamic>.from(vehicle), returnsNormally);
          }
        }
      }
    }
  });
}
