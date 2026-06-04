import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// قسم واحد في شاشة رصيد المحطة.
final class StationBalanceSection {
  const StationBalanceSection({
    required this.title,
    required this.rowIndices,
    required this.icon,
    required this.tint,
  });

  final String title;
  final List<int> rowIndices;
  final IconData icon;
  final Color tint;
}

List<StationBalanceSection> stationBalanceSections(AppLocalizations l10n) {
  return <StationBalanceSection>[
    StationBalanceSection(
      title: l10n.stationBalanceSectionCartons,
      rowIndices: const <int>[0, 1],
      icon: Icons.inventory_2_outlined,
      tint: const Color(0xFF2F80ED),
    ),
    StationBalanceSection(
      title: l10n.stationBalanceSectionBags,
      rowIndices: const <int>[2, 3, 4],
      icon: Icons.shopping_bag_outlined,
      tint: const Color(0xFF0F2747),
    ),
    StationBalanceSection(
      title: l10n.stationBalanceSectionBottles,
      rowIndices: const <int>[5, 6, 13],
      icon: Icons.water_drop_outlined,
      tint: const Color(0xFF4FC3F7),
    ),
    StationBalanceSection(
      title: l10n.stationBalanceSectionGallons,
      rowIndices: const <int>[7, 14],
      icon: Icons.propane_tank_outlined,
      tint: const Color(0xFF56CCF2),
    ),
    StationBalanceSection(
      title: l10n.stationBalanceSectionStationFloor,
      rowIndices: const <int>[8, 9],
      icon: Icons.layers_outlined,
      tint: const Color(0xFF8B7355),
    ),
    StationBalanceSection(
      title: l10n.stationBalanceSectionCoupons,
      rowIndices: const <int>[10, 11, 12],
      icon: Icons.confirmation_number_outlined,
      tint: const Color(0xFF7ED957),
    ),
    StationBalanceSection(
      title: l10n.stationBalanceSectionOptional,
      rowIndices: const <int>[15],
      icon: Icons.add_box_outlined,
      tint: const Color(0xFF6B7280),
    ),
  ];
}

/// ملخص أرقام رصيد المحطة للعرض في الأعلى.
final class StationBalanceSummary {
  const StationBalanceSummary({
    required this.totalUnits,
    required this.itemsWithStock,
    required this.lowStockCount,
    required this.unlinkedCount,
    required this.trackedRowCount,
  });

  final int totalUnits;
  final int itemsWithStock;
  final int lowStockCount;
  final int unlinkedCount;
  final int trackedRowCount;

  static const int lowStockThreshold = 5;
}

StationBalanceSummary computeStationBalanceSummary({
  required List<Map<String, dynamic>> products,
}) {
  var totalUnits = 0;
  var itemsWithStock = 0;
  var lowStockCount = 0;
  var unlinkedCount = 0;
  const int tracked = kStationBalanceLastFixedRowIndex + 1;

  for (var i = 0; i < tracked; i++) {
    final Map<String, dynamic>? match = resolveStationBalanceProduct(
      products: products,
      rowIndex: i,
    );
    if (match == null) {
      unlinkedCount++;
      continue;
    }
    final int stock = stationStockForBalanceRow(
      products: products,
      rowIndex: i,
    );
    totalUnits += stock;
    if (stock > 0) {
      itemsWithStock++;
      if (stock <= StationBalanceSummary.lowStockThreshold) {
        lowStockCount++;
      }
    }
  }

  return StationBalanceSummary(
    totalUnits: totalUnits,
    itemsWithStock: itemsWithStock,
    lowStockCount: lowStockCount,
    unlinkedCount: unlinkedCount,
    trackedRowCount: tracked,
  );
}

IconData stationBalanceRowIcon(int rowIndex) {
  return switch (rowIndex) {
    0 || 1 => Icons.inventory_2_outlined,
    2 || 3 || 4 => Icons.shopping_bag_outlined,
    5 || 6 || 13 => Icons.water_drop_outlined,
    7 || 14 => Icons.propane_tank_outlined,
    8 || 9 => Icons.layers_outlined,
    10 || 11 || 12 => Icons.confirmation_number_outlined,
    _ => Icons.category_outlined,
  };
}
