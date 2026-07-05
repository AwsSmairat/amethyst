import 'package:amethyst/core/driver_cash/driver_cash_list_refresh.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/format_money.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/driver_cash/domain/entities/driver_cash_balance_snapshot.dart';
import 'package:amethyst/features/driver_cash/domain/usecases/get_driver_cash_snapshot_usecase.dart';
import 'package:amethyst/features/driver_cash/domain/usecases/set_driver_cash_balance_usecase.dart';
import 'package:flutter/material.dart';

Future<bool> showRegisterDriverCashSheet(BuildContext context) async {
  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: const _RegisterDriverCashBody(),
    ),
  );
  return saved == true;
}

class _RegisterDriverCashBody extends StatefulWidget {
  const _RegisterDriverCashBody();

  @override
  State<_RegisterDriverCashBody> createState() =>
      _RegisterDriverCashBodyState();
}

class _RegisterDriverCashBodyState extends State<_RegisterDriverCashBody> {
  late final TextEditingController _newAmountController;
  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  String? _submitError;
  double _yesterdayBalance = 0;
  double _storedTodayBalance = 0;
  String? _previewTodayText;

  @override
  void initState() {
    super.initState();
    _newAmountController = TextEditingController();
    _newAmountController.addListener(_onNewAmountChanged);
    _loadSnapshot();
  }

  @override
  void dispose() {
    _newAmountController
      ..removeListener(_onNewAmountChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final DriverCashBalanceSnapshot snapshot =
          await sl<GetDriverCashSnapshotUseCase>()();
      if (!mounted) {
        return;
      }
      setState(() {
        _yesterdayBalance = snapshot.yesterdayAmount;
        _storedTodayBalance = snapshot.todayAmount;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _onNewAmountChanged() {
    final String raw = _newAmountController.text.trim();
    setState(() {
      _previewTodayText = raw.isEmpty ? null : raw;
    });
  }

  double? _parseAmount(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  double get _displayTodayAmount {
    final double? preview = _previewTodayText == null
        ? null
        : _parseAmount(_previewTodayText!);
    if (preview != null) {
      return preview;
    }
    return _storedTodayBalance;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final double? todayBalance = _parseAmount(_newAmountController.text);
    if (todayBalance == null || todayBalance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.stationCashBalanceInvalidTodayAmount)),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await sl<SetDriverCashBalanceUseCase>()(amount: todayBalance);
      if (!mounted) {
        return;
      }
      DriverCashListRefresh.request();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.stationCashBalanceSaved)),
      );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadSnapshot,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.registerStationCashBalance,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.stationCashBalanceYesterdayLabel,
              prefixIcon: const Icon(Icons.history_outlined),
            ),
            child: Text(
              formatMoneyAmount(_yesterdayBalance),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.stationCashBalanceNewAmountLabel,
              prefixIcon: const Icon(Icons.add_circle_outline),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.stationCashBalanceTodayLabel,
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
            child: Text(
              formatMoneyAmount(_displayTodayAmount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
          if (_submitError != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _submitError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.stationCashBalanceRegisterHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
