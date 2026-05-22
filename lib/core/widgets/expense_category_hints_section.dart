import 'package:amethyst/core/expenses/expense_aggregates.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// حقول تصنيفات المصاريف مع مبالغ اليوم والشهر داخل كل مربع.
class ExpenseCategoryHintsSection extends StatelessWidget {
  const ExpenseCategoryHintsSection({
    super.key,
    this.includeStationExpense = false,
    this.onCategoryTap,
    this.categoryTotals,
    this.formatAmount,
  });

  final bool includeStationExpense;
  final void Function(String categoryKey)? onCategoryTap;
  final Map<String, CategoryExpenseTotals>? categoryTotals;
  final String Function(double value)? formatAmount;

  static Widget _field(
    BuildContext context, {
    required String categoryKey,
    required IconData icon,
    required String label,
    void Function(String key)? onCategoryTap,
    CategoryExpenseTotals? totals,
    String Function(double value)? formatAmount,
  }) {
    final l10n = context.l10n;
    final String Function(double) fmt =
        formatAmount ?? _defaultFormatAmount;
    final CategoryExpenseTotals t =
        totals ?? const CategoryExpenseTotals();

    final Widget amountBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.expenseCategoryMonthLine(l10n.amountDinars(fmt(t.month))),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.expenseCategoryTodayLine(l10n.amountDinars(fmt(t.today))),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    final InputDecoration decoration = InputDecoration(
      labelText: label,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: Icon(icon),
    );

    if (onCategoryTap == null) {
      return InputDecorator(
        decoration: decoration,
        child: amountBody,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onCategoryTap(categoryKey),
        child: InputDecorator(
          decoration: decoration,
          child: amountBody,
        ),
      ),
    );
  }

  static String _defaultFormatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Map<String, CategoryExpenseTotals>? totals = categoryTotals;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _field(
            context,
            categoryKey: 'gasoline',
            icon: Icons.local_gas_station_outlined,
            label: l10n.gasolineExpenses,
            onCategoryTap: onCategoryTap,
            totals: totals?['gasoline'],
            formatAmount: formatAmount,
          ),
          const SizedBox(height: 10),
          _field(
            context,
            categoryKey: 'carRepair',
            icon: Icons.handyman_outlined,
            label: l10n.carRepairExpenses,
            onCategoryTap: onCategoryTap,
            totals: totals?['carRepair'],
            formatAmount: formatAmount,
          ),
          const SizedBox(height: 10),
          _field(
            context,
            categoryKey: 'other',
            icon: Icons.more_horiz,
            label: l10n.otherExpenses,
            onCategoryTap: onCategoryTap,
            totals: totals?['other'],
            formatAmount: formatAmount,
          ),
          if (includeStationExpense) ...<Widget>[
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'tankWater',
              icon: Icons.water_drop_outlined,
              label: l10n.expenseTankWater,
              onCategoryTap: onCategoryTap,
              totals: totals?['tankWater'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'cartons',
              icon: Icons.inventory_2_outlined,
              label: l10n.expenseCartons,
              onCategoryTap: onCategoryTap,
              totals: totals?['cartons'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'workersWages',
              icon: Icons.groups_outlined,
              label: l10n.expenseWorkersWages,
              onCategoryTap: onCategoryTap,
              totals: totals?['workersWages'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationCards',
              icon: Icons.credit_card_outlined,
              label: l10n.expenseStationCards,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationCards'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationCarTracking',
              icon: Icons.route_outlined,
              label: l10n.expenseStationCarTracking,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationCarTracking'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationInternet',
              icon: Icons.wifi_outlined,
              label: l10n.expenseStationInternet,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationInternet'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationShopRent',
              icon: Icons.storefront_outlined,
              label: l10n.expenseStationShopRent,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationShopRent'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationRoomRent',
              icon: Icons.door_front_door_outlined,
              label: l10n.expenseStationRoomRent,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationRoomRent'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationElectricity',
              icon: Icons.bolt_outlined,
              label: l10n.expenseStationElectricity,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationElectricity'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationBags',
              icon: Icons.shopping_bag_outlined,
              label: l10n.expenseStationBags,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationBags'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationEmptyBottles',
              icon: Icons.local_drink_outlined,
              label: l10n.expenseStationEmptyBottles,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationEmptyBottles'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationEmptyGallon',
              icon: Icons.water_outlined,
              label: l10n.expenseStationEmptyGallon,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationEmptyGallon'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationSalt',
              icon: Icons.grain_outlined,
              label: l10n.expenseStationSalt,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationSalt'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationShrinkWrap',
              icon: Icons.layers_outlined,
              label: l10n.expenseStationShrinkWrap,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationShrinkWrap'],
              formatAmount: formatAmount,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'stationFilters',
              icon: Icons.filter_alt_outlined,
              label: l10n.expenseStationFilters,
              onCategoryTap: onCategoryTap,
              totals: totals?['stationFilters'],
              formatAmount: formatAmount,
            ),
          ],
        ],
      ),
    );
  }
}
