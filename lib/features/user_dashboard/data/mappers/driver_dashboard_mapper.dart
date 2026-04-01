import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';

DriverDashboard mapDriverDashboardApi(
  Map<String, dynamic> json, {
  required String driverDisplayName,
}) {
  final vehicle = json['assignedVehicle'] as Map<String, dynamic>?;
  final vehicleLabel = vehicle == null
      ? 'No vehicle assigned'
      : (vehicle['vehicleNumber']?.toString() ?? 'Vehicle');

  final remaining = json['remainingQuantities'] as List<dynamic>? ?? <dynamic>[];
  final inventory = <InventoryItem>[];
  for (final dynamic e in remaining) {
    final m = e as Map<String, dynamic>;
    final sold = m['quantitySold'] as int? ?? 0;
    final rem = m['remaining'] as int? ?? 0;
    final ret = m['quantityReturned'] as int? ?? 0;
    final loaded = sold + rem + ret;
    inventory.add(
      InventoryItem(
        name: m['productName'] as String? ?? 'Product',
        loaded: loaded,
        sold: sold,
        left: rem,
        iconKey: 'water_drop',
      ),
    );
  }

  final notesSummary = json['notesSummary'] as List<dynamic>? ?? <dynamic>[];
  var expenseNote = 'No notes yet';
  if (notesSummary.isNotEmpty) {
    final first = notesSummary.first as Map<String, dynamic>;
    expenseNote = first['note']?.toString() ?? expenseNote;
  }

  final expensesTotal = (json['totalExpensesToday'] as num?)?.toDouble() ?? 0.0;

  return DriverDashboard(
    title: driverDisplayName,
    vehicleLabel: vehicleLabel,
    shiftRemaining: 'Today',
    isActive: vehicle?['isActive'] as bool? ?? false,
    inventory: inventory,
    expensesTotal: expensesTotal,
    expenseNote: expenseNote,
  );
}
