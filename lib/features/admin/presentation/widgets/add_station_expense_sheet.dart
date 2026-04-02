import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/l10n/app_localizations.dart';
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

class _StationFieldSpec {
  const _StationFieldSpec({
    required this.icon,
    required this.label,
    required this.note,
  });

  final IconData icon;
  final String Function(AppLocalizations l10n) label;
  final String Function(AppLocalizations l10n) note;
}

/// ترتيب الحقول ١–١٥ كما في واجهة المحطة.
List<_StationFieldSpec> _stationFieldSpecs() => <_StationFieldSpec>[
      _StationFieldSpec(
        icon: Icons.water_drop_outlined,
        label: (AppLocalizations l) => l.expenseTankWater,
        note: (AppLocalizations l) => l.expenseTankWater,
      ),
      _StationFieldSpec(
        icon: Icons.inventory_2_outlined,
        label: (AppLocalizations l) => l.expenseCartonsWater,
        note: (AppLocalizations l) => l.expenseCartonsWater,
      ),
      _StationFieldSpec(
        icon: Icons.badge_outlined,
        label: (AppLocalizations l) => l.expenseStaffSalaries,
        note: (AppLocalizations l) => l.expenseStaffSalaries,
      ),
      _StationFieldSpec(
        icon: Icons.credit_card_outlined,
        label: (AppLocalizations l) => l.expenseStationCards,
        note: (AppLocalizations l) => l.expenseStationCards,
      ),
      _StationFieldSpec(
        icon: Icons.route_outlined,
        label: (AppLocalizations l) => l.expenseStationCarTracking,
        note: (AppLocalizations l) => l.expenseStationCarTracking,
      ),
      _StationFieldSpec(
        icon: Icons.wifi_outlined,
        label: (AppLocalizations l) => l.expenseStationInternet,
        note: (AppLocalizations l) => l.expenseStationInternet,
      ),
      _StationFieldSpec(
        icon: Icons.storefront_outlined,
        label: (AppLocalizations l) => l.expenseStationShopRent,
        note: (AppLocalizations l) => l.expenseStationShopRent,
      ),
      _StationFieldSpec(
        icon: Icons.door_front_door_outlined,
        label: (AppLocalizations l) => l.expenseStationRoomRent,
        note: (AppLocalizations l) => l.expenseStationRoomRent,
      ),
      _StationFieldSpec(
        icon: Icons.bolt_outlined,
        label: (AppLocalizations l) => l.expenseStationElectricity,
        note: (AppLocalizations l) => l.expenseStationElectricity,
      ),
      _StationFieldSpec(
        icon: Icons.shopping_bag_outlined,
        label: (AppLocalizations l) => l.expenseStationBags,
        note: (AppLocalizations l) => l.expenseStationBags,
      ),
      _StationFieldSpec(
        icon: Icons.local_drink_outlined,
        label: (AppLocalizations l) => l.expenseStationEmptyBottles,
        note: (AppLocalizations l) => l.expenseStationEmptyBottles,
      ),
      _StationFieldSpec(
        icon: Icons.water_outlined,
        label: (AppLocalizations l) => l.expenseStationEmptyGallon,
        note: (AppLocalizations l) => l.expenseStationEmptyGallon,
      ),
      _StationFieldSpec(
        icon: Icons.grain_outlined,
        label: (AppLocalizations l) => l.expenseStationSalt,
        note: (AppLocalizations l) => l.expenseStationSalt,
      ),
      _StationFieldSpec(
        icon: Icons.layers_outlined,
        label: (AppLocalizations l) => l.expenseStationShrinkWrap,
        note: (AppLocalizations l) => l.expenseStationShrinkWrap,
      ),
      _StationFieldSpec(
        icon: Icons.filter_alt_outlined,
        label: (AppLocalizations l) => l.expenseStationFilters,
        note: (AppLocalizations l) => l.expenseStationFilters,
      ),
    ];

class _StationExpenseBody extends StatefulWidget {
  const _StationExpenseBody({this.onRecorded});

  final VoidCallback? onRecorded;

  @override
  State<_StationExpenseBody> createState() => _StationExpenseBodyState();
}

class _StationExpenseBodyState extends State<_StationExpenseBody> {
  late final List<_StationFieldSpec> _specs;
  late final List<TextEditingController> _controllers;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _specs = _stationFieldSpecs();
    _controllers = List<TextEditingController>.generate(
      _specs.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
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
    for (var i = 0; i < _specs.length; i++) {
      final amt = parsePositive(_controllers[i].text);
      if (amt != null) {
        entries.add((note: _specs[i].note(l10n), amount: amt));
      }
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
            for (var i = 0; i < _specs.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 12),
              TextField(
                controller: _controllers[i],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _specs[i].label(l10n),
                  prefixIcon: Icon(_specs[i].icon),
                ),
              ),
            ],
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
