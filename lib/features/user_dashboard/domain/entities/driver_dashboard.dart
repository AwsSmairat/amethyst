import 'package:equatable/equatable.dart';

class DriverDashboard extends Equatable {
  const DriverDashboard({
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
  final List<InventoryItem> inventory;
  final double expensesTotal;
  final String expenseNote;

  @override
  List<Object?> get props => <Object?>[
        title,
        vehicleLabel,
        shiftRemaining,
        isActive,
        inventory,
        expensesTotal,
        expenseNote,
      ];
}

class InventoryItem extends Equatable {
  const InventoryItem({
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

  /// Icon key that stays UI-agnostic.
  /// Presentation maps it to `Icons` / Symbols.
  final String iconKey;

  @override
  List<Object?> get props => <Object?>[name, loaded, sold, left, iconKey];
}

