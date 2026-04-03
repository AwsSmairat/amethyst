import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/features/admin/presentation/station_sale/station_sale_entry_kind.dart';
import 'package:flutter/material.dart';

class StationSaleKindPicker extends StatelessWidget {
  const StationSaleKindPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.stationSalePickKindTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(StationSaleEntryKind.filling),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: scheme.primary,
            ),
            child: Text(l10n.stationSaleKindFilling),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () =>
                Navigator.of(context).pop(StationSaleEntryKind.emptySale),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.stationSaleKindEmptySale),
          ),
        ],
      ),
    );
  }
}
