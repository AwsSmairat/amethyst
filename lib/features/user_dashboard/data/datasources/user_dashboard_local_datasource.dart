import 'package:amethyst/features/user_dashboard/data/models/driver_dashboard_model.dart';

class UserDashboardLocalDataSource {
  const UserDashboardLocalDataSource();

  Future<DriverDashboardModel> getDriverDashboard() async {
    // Local mock data matching the supplied Stitch HTML layout.
    return const DriverDashboardModel(
      title: 'My Route - Driver',
      vehicleLabel: 'Vehicle #4 | Downtown',
      shiftRemaining: '04:30 Remaining',
      isActive: true,
      inventory: <InventoryItemModel>[
        InventoryItemModel(
          name: 'Bottles',
          loaded: 150,
          sold: 120,
          left: 30,
          iconKey: 'eco',
        ),
        InventoryItemModel(
          name: 'Cartons',
          loaded: 50,
          sold: 30,
          left: 20,
          iconKey: 'inventory_2',
        ),
        InventoryItemModel(
          name: 'Gallons',
          loaded: 20,
          sold: 15,
          left: 5,
          iconKey: 'water_drop',
        ),
      ],
      expensesTotal: 45.00,
      expenseNote: 'Fuel & Parking',
    );
  }
}

