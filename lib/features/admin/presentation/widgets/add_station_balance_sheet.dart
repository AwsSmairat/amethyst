import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/domain/usecases/save_station_balance_usecase.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter/material.dart';

Future<void> showAddStationBalanceSheet(
  BuildContext context, {
  VoidCallback? onSuccess,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => _StationBalanceBody(onSuccess: onSuccess),
  );
}

class _StationBalanceBody extends StatefulWidget {
  const _StationBalanceBody({this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  State<_StationBalanceBody> createState() => _StationBalanceBodyState();
}

class _StationBalanceBodyState extends State<_StationBalanceBody> {
  static const int _fieldCount = kStationBalanceRowCount;

  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(
    _fieldCount,
    (_) => TextEditingController(),
  );

  bool _prefilling = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromApi());
  }

  Future<void> _prefillFromApi() async {
    try {
      final List<Map<String, dynamic>> items =
          await sl<ListProductItemsUseCase>()();
      if (!mounted) {
        return;
      }
      for (var i = 0; i <= kStationBalanceLastFixedRowIndex; i++) {
        final Map<String, dynamic>? match = resolveStationBalanceProduct(
          products: items,
          rowIndex: i,
        );
        if (match != null) {
          _controllers[i].text =
              stationStockFromProductJson(match).toString();
        }
      }
    } on Object catch (_) {
      // يبقى الحقول فارغة عند فشل التحميل.
    } finally {
      if (mounted) {
        setState(() => _prefilling = false);
      }
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final SaveStationBalanceUseCase save = sl<SaveStationBalanceUseCase>();
    setState(() => _saving = true);
    final SaveStationBalanceOutcome outcome = await save(
      _controllers.map((TextEditingController c) => c.text).toList(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    final l10n = context.l10n;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    switch (outcome) {
      case SaveStationBalanceSuccess():
        widget.onSuccess?.call();
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.stationBalanceSaved)),
        );
        return;
      case SaveStationBalanceInvalidQuantity():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.stationBalanceInvalidQuantity)),
        );
      case SaveStationBalanceUnlinkedRow(:final int rowIndex):
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.stationBalanceSaveRowUnlinked(
                stationBalanceRowLabel(l10n, rowIndex),
              ),
            ),
          ),
        );
      case SaveStationBalanceFailure(:final String message):
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _field(BuildContext context, int index) {
    final l10n = context.l10n;
    final bool isOptional = index > kStationBalanceLastFixedRowIndex;
    if (isOptional) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _controllers[index],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: stationBalanceRowLabel(l10n, index),
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
          labelText: stationBalanceRowLabel(l10n, index),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;
    final bool busy = _prefilling || _saving;
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
            if (_prefilling)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...<Widget>[
              for (var i = 0; i < _fieldCount; i++) _field(context, i),
              FilledButton(
                onPressed: busy ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
