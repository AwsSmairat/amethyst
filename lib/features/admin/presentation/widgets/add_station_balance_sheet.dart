import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<void> showAddStationBalanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => const _StationBalanceBody(),
  );
}

class _StationBalanceBody extends StatefulWidget {
  const _StationBalanceBody();

  @override
  State<_StationBalanceBody> createState() => _StationBalanceBodyState();
}

class _StationBalanceBodyState extends State<_StationBalanceBody> {
  static const int _fieldCount = 13;

  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(
    _fieldCount,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _labelForIndex(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.stationBalanceField1;
      case 1:
        return l10n.stationBalanceField2;
      case 2:
        return l10n.stationBalanceField3;
      case 3:
        return l10n.stationBalanceField4;
      case 4:
        return l10n.stationBalanceField5;
      case 5:
        return l10n.stationBalanceField6;
      case 6:
        return l10n.stationBalanceField7;
      case 7:
        return l10n.stationBalanceField8;
      case 8:
        return l10n.stationBalanceField9;
      case 9:
        return l10n.stationBalanceField10;
      case 10:
        return l10n.stationBalanceField11;
      case 11:
        return l10n.stationBalanceField12;
      default:
        return '';
    }
  }

  Widget _field(BuildContext context, int index) {
    final l10n = context.l10n;
    final bool isOptional = index == 12;
    if (isOptional) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _controllers[index],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: l10n.stationBalanceField13Optional,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controllers[index],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: _labelForIndex(l10n, index),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottom + 20,
        top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.stationBalanceTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.stationBalanceSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < _fieldCount; i++) _field(context, i),
            FilledButton(
              onPressed: () {
                final ScaffoldMessengerState messenger =
                    ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.stationBalanceSaved)),
                );
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
