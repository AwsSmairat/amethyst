import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter/material.dart';

Future<void> showAddStationExpenseSheet(
  BuildContext context, {
  VoidCallback? onRecorded,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _StationExpenseBody(
      onRecorded: onRecorded,
    ),
  );
}

class _StationExpenseBody extends StatefulWidget {
  const _StationExpenseBody({this.onRecorded});

  final VoidCallback? onRecorded;

  @override
  State<_StationExpenseBody> createState() => _StationExpenseBodyState();
}

class _StationExpenseBodyState extends State<_StationExpenseBody> {
  final _tankWater = TextEditingController();
  final _cartonsWater = TextEditingController();
  final _staffSalaries = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _tankWater.dispose();
    _cartonsWater.dispose();
    _staffSalaries.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final useCase = sl<CreateExpenseUseCase>();

    double? parsePositive(String s) {
      final v = double.tryParse(s.trim());
      if (v == null || v <= 0) return null;
      return v;
    }

    final entries = <({String note, double amount})>[];
    final a1 = parsePositive(_tankWater.text);
    if (a1 != null) entries.add((note: l10n.expenseTankWater, amount: a1));
    final a2 = parsePositive(_cartonsWater.text);
    if (a2 != null) {
      entries.add((note: l10n.expenseCartonsWater, amount: a2));
    }
    final a3 = parsePositive(_staffSalaries.text);
    if (a3 != null) {
      entries.add((note: l10n.expenseStaffSalaries, amount: a3));
    }

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.stationExpenseNeedOneAmount)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      for (final e in entries) {
        await useCase(
          vehicleId: null,
          amount: e.amount,
          note: e.note,
        );
      }
      widget.onRecorded?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.expenseSaved)),
      );
    } on Object catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: bottom + 20, top: 8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.newStationExpense,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.stationExpenses,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tankWater,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.expenseTankWater,
                prefixIcon: const Icon(Icons.water_drop_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cartonsWater,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.expenseCartonsWater,
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _staffSalaries,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.expenseStaffSalaries,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.submit),
            ),
          ],
        ),
      ),
    );
  }
}
