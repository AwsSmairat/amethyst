import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';

/// حقول عرض فقط توضّح تصنيفات مصاريف السائق (بانزين / تصليح / أخرى).
class ExpenseCategoryHintsSection extends StatelessWidget {
  const ExpenseCategoryHintsSection({super.key});

  static Widget _field(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return TextField(
      readOnly: true,
      canRequestFocus: false,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon),
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
            icon: Icons.local_gas_station_outlined,
            label: l10n.gasolineExpenses,
          ),
          const SizedBox(height: 10),
          _field(
            context,
            icon: Icons.handyman_outlined,
            label: l10n.carRepairExpenses,
          ),
          const SizedBox(height: 10),
          _field(
            context,
            icon: Icons.more_horiz,
            label: l10n.otherExpenses,
          ),
        ],
      ),
    );
  }
}
