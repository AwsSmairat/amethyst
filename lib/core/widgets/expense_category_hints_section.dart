import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';

/// حقول توضّح تصنيفات المصاريف.
/// [includeStationExpense] للأدمن/السوبر أدمن: يظهر «تنك مي» و«كراتين» و«رواتب عمال» إضافة لمصاريف السائق.
/// [onCategoryTap] عند تمريره (مثلاً للأدمن): الضغط يفتح تقرير التصنيف؛ مفاتيح: gasoline, carRepair, other, tankWater, cartons, workersWages.
class ExpenseCategoryHintsSection extends StatelessWidget {
  const ExpenseCategoryHintsSection({
    super.key,
    this.includeStationExpense = false,
    this.onCategoryTap,
  });

  /// عند `true`: حقول إضافية للأدمن (تنك مي، كراتين، رواتب عمال).
  final bool includeStationExpense;

  /// استدعاء عند الضغط على حقل تصنيف (يُمرَّر مفتاح التصنيف).
  final void Function(String categoryKey)? onCategoryTap;

  static const double _innerH = 22;

  static Widget _field(
    BuildContext context, {
    required String categoryKey,
    required IconData icon,
    required String label,
    void Function(String key)? onCategoryTap,
  }) {
    final decoration = InputDecoration(
      labelText: label,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: Icon(icon),
    );
    if (onCategoryTap == null) {
      return TextField(
        readOnly: true,
        canRequestFocus: false,
        enableInteractiveSelection: false,
        decoration: decoration,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onCategoryTap(categoryKey),
        child: InputDecorator(
          decoration: decoration,
          child: const SizedBox(height: _innerH),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          ),
          const SizedBox(height: 10),
          _field(
            context,
            categoryKey: 'carRepair',
            icon: Icons.handyman_outlined,
            label: l10n.carRepairExpenses,
            onCategoryTap: onCategoryTap,
          ),
          const SizedBox(height: 10),
          _field(
            context,
            categoryKey: 'other',
            icon: Icons.more_horiz,
            label: l10n.otherExpenses,
            onCategoryTap: onCategoryTap,
          ),
          if (includeStationExpense) ...<Widget>[
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'tankWater',
              icon: Icons.water_drop_outlined,
              label: l10n.expenseTankWater,
              onCategoryTap: onCategoryTap,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'cartons',
              icon: Icons.inventory_2_outlined,
              label: l10n.expenseCartons,
              onCategoryTap: onCategoryTap,
            ),
            const SizedBox(height: 10),
            _field(
              context,
              categoryKey: 'workersWages',
              icon: Icons.groups_outlined,
              label: l10n.expenseWorkersWages,
              onCategoryTap: onCategoryTap,
            ),
          ],
        ],
      ),
    );
  }
}
