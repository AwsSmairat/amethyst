import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';

class DriverDashboardModel {
  const DriverDashboardModel({
    required this.title,
    required this.vehicleLabel,
    required this.shiftRemaining,
    required this.isActive,
    required this.inventory,
    required this.expensesTotal,
    required this.expenseNote,
  });

  final String title;
  final String vehicleLabel;
  final String shiftRemaining;
  final bool isActive;
  final List<InventoryItemModel> inventory;
  final double expensesTotal;
  final String expenseNote;

  DriverDashboard toEntity() => DriverDashboard(
        title: title,
        vehicleLabel: vehicleLabel,
        shiftRemaining: shiftRemaining,
        isActive: isActive,
        inventory: inventory.map((e) => e.toEntity()).toList(growable: false),
        expensesTotal: expensesTotal,
        expenseNote: expenseNote,
      );
}

class InventoryItemModel {
  const InventoryItemModel({
    required this.name,
    required this.loaded,
    required this.sold,
    required this.left,
    required this.iconKey,
  });

  final String name;
  final int loaded;
  final int sold;
  final int left;
  final String iconKey;

  InventoryItem toEntity() => InventoryItem(
        name: name,
        loaded: loaded,
        sold: sold,
        left: left,
        iconKey: iconKey,
      );
}

