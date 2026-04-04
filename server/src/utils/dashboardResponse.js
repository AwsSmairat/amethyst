/**
 * Normalizes dashboard payloads so every role returns the same envelope:
 * { role, generatedAt, metrics, details }
 */

export function normalizeDashboard(role, raw) {
  const generatedAt = new Date().toISOString();

  if (role === 'super_admin') {
    return {
      role,
      generatedAt,
      metrics: {
        totalSalesToday: raw.totalSalesToday ?? 0,
        stationSalesToday: raw.stationSalesToday ?? 0,
        vehicleSalesToday: raw.vehicleSalesToday ?? 0,
        totalExpensesToday: raw.totalExpensesToday ?? 0,
        totalProfitToday: raw.totalProfitToday ?? 0,
        totalMonthlyExpenses: raw.totalMonthlyExpenses ?? 0,
        totalMonthlySales: raw.totalMonthlySales ?? 0,
        totalMonthlyCartonSales: raw.totalMonthlyCartonSales ?? 0,
        remainingStationStock: raw.remainingStationStock ?? 0,
        remainingOnVehicles: raw.remainingOnVehicles ?? 0,
        remainingOnVehicle: null,
      },
      details: {
        counts: {
          users: raw.totalUsers ?? 0,
          admins: raw.totalAdmins ?? 0,
          drivers: raw.totalDrivers ?? 0,
          vehicles: raw.totalVehicles ?? 0,
          products: raw.totalProducts ?? 0,
          pricedProducts: raw.pricedProductsCount ?? 0,
        },
        lowStockProducts: raw.lowStockProducts ?? [],
        recentActivities: raw.recentActivities ?? [],
      },
    };
  }

  if (role === 'admin') {
    return {
      role,
      generatedAt,
      metrics: {
        totalSalesToday: raw.totalSalesToday ?? 0,
        stationSalesToday: raw.stationSalesToday ?? 0,
        vehicleSalesToday: raw.vehicleSalesToday ?? 0,
        totalExpensesToday: null,
        totalProfitToday: null,
        totalMonthlySales: raw.totalMonthlySales ?? 0,
        remainingStationStock: raw.remainingStationStock ?? 0,
        remainingOnVehicles: raw.remainingOnVehicles ?? 0,
        remainingOnVehicle: null,
      },
      details: {
        stationStockSummary: raw.stationStockSummary ?? [],
        vehiclesLoadedToday: raw.vehiclesLoadedToday ?? 0,
        loadsToday: raw.loadsToday ?? [],
        returnedQuantitiesToday: raw.returnedQuantitiesToday ?? 0,
        activeDrivers: raw.activeDrivers ?? 0,
        lowStockProducts: raw.lowStockProducts ?? [],
      },
    };
  }

  // driver
  return {
    role,
    generatedAt,
    metrics: {
      totalSalesToday: raw.vehicleSalesAmountToday ?? 0,
      stationSalesToday: 0,
      vehicleSalesToday: raw.vehicleSalesAmountToday ?? 0,
      totalExpensesToday: raw.totalExpensesToday ?? 0,
      totalProfitToday: null,
      totalMonthlySales: null,
      remainingStationStock: null,
      remainingOnVehicles: null,
      remainingOnVehicle: raw.remainingOnVehicle ?? 0,
    },
    details: {
      assignedVehicle: raw.assignedVehicle,
      productsLoadedToday: raw.productsLoadedToday ?? [],
      soldQuantitiesToday: raw.soldQuantitiesToday ?? 0,
      remainingQuantities: raw.remainingQuantities ?? [],
      returnedQuantitiesToday: raw.returnedQuantitiesToday ?? 0,
      notesSummary: raw.notesSummary ?? [],
    },
  };
}
