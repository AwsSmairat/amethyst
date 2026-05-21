import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_api_error.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_formatting.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_kind.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// تفاصيل سجلات الدين لشخص واحد (يُمرَّر من [StationDebtListPage]).
class StationDebtorDetailPage extends StatefulWidget {
  const StationDebtorDetailPage({
    super.key,
    required this.debtorName,
    required this.entries,
  });

  final String debtorName;
  final List<Map<String, dynamic>> entries;

  @override
  State<StationDebtorDetailPage> createState() =>
      _StationDebtorDetailPageState();
}

class _StationDebtorDetailPageState extends State<StationDebtorDetailPage> {
  bool _submitting = false;

  bool _hasStationDebt(List<Map<String, dynamic>> entries) =>
      entries.any(isStationDebtEntry);

  bool _hasVehicleDebt(List<Map<String, dynamic>> entries) =>
      entries.any(isVehicleDebtEntry);

  Future<void> _onRepayPressed() async {
    final l10n = context.l10n;
    final bool hasStation = _hasStationDebt(widget.entries);
    final bool hasVehicle = _hasVehicleDebt(widget.entries);
    final String confirmMessage = hasStation && hasVehicle
        ? l10n.stationDebtRepayConfirmMessageMixed
        : hasVehicle
            ? l10n.stationDebtRepayConfirmMessageVehicle
            : l10n.stationDebtRepayConfirmMessage;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.stationDebtRepayConfirmTitle),
        content: Text(confirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) {
      return;
    }
    setState(() => _submitting = true);
    try {
      var vehicleRepaid = 0;
      var stationRepaid = 0;
      if (hasVehicle) {
        await sl<RepayStationDebtFromVehicleUseCase>().call(
          debtorName: widget.debtorName,
        );
        vehicleRepaid = 1;
      }
      if (hasStation) {
        await sl<RepayStationDebtUseCase>().call(debtorName: widget.debtorName);
        stationRepaid = 1;
      }
      if (!mounted) {
        return;
      }
      final String successMessage = vehicleRepaid > 0 && stationRepaid > 0
          ? l10n.stationDebtRepaySuccessMixed
          : vehicleRepaid > 0
              ? l10n.stationDebtRepaySuccessVehicle
              : l10n.stationDebtRepaySuccess;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_repayErrorUserMessage(l10n, e))),
      );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<Map<String, dynamic>> sorted =
        List<Map<String, dynamic>>.from(widget.entries);
    sorted.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime? da = DateTime.tryParse(a['createdAt']?.toString() ?? '');
      final DateTime? db = DateTime.tryParse(b['createdAt']?.toString() ?? '');
      if (da == null && db == null) {
        return 0;
      }
      if (da == null) {
        return 1;
      }
      if (db == null) {
        return -1;
      }
      return db.compareTo(da);
    });

    final bool showRepay = sorted.isNotEmpty;
    final AuthState authState = context.watch<AuthCubit>().state;
    final bool repayAllowed = authState is AuthAuthenticated &&
        (authState.user.role == 'admin' ||
            authState.user.role == 'super_admin' ||
            authState.user.role == 'driver');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.debtorName.isEmpty ? l10n.titleStationDebtList : widget.debtorName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: sorted.isEmpty
                ? Center(child: Text(l10n.nothingHereYet))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int i) {
                      final Map<String, dynamic> item = sorted[i];
                      final Map<String, dynamic>? product =
                          item['product'] is Map<String, dynamic>
                              ? item['product'] as Map<String, dynamic>
                              : null;
                      final String pname = product?['name']?.toString() ?? '—';
                      final String qty = item['quantity']?.toString() ?? '';
                      final String total =
                          formatStationDebtAmount(item['totalAmount']);
                      final String? when =
                          formatStationDebtDateTime(context, item['createdAt']);
                      final Map<String, dynamic>? rec =
                          item['recordedBy'] is Map<String, dynamic>
                              ? item['recordedBy'] as Map<String, dynamic>
                              : null;
                      final String rname = rec?['fullName']?.toString() ?? '';
                      final String kindLabel = isStationDebtEntry(item)
                          ? l10n.stationDebtKindStation
                          : l10n.stationDebtKindVehicle;
                      final List<String> parts = <String>[
                        kindLabel,
                        '${l10n.quantity}: $qty',
                        '${l10n.totalAmountLabel}: $total',
                        if (when != null) when,
                        if (rname.isNotEmpty) '${l10n.sellerLabel}: $rname',
                      ];
                      return ListTile(
                        title: Text(
                          pname,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(parts.join(' · ')),
                      );
                    },
                  ),
          ),
          if (showRepay && repayAllowed)
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _submitting ? null : _onRepayPressed,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.stationDebtRepayButton),
              ),
            ),
        ],
      ),
    );
  }
}

String _repayErrorUserMessage(AppLocalizations l10n, ApiException e) {
  final String mapped = mapStationDebtApiException(e);
  if (mapped == kStationDebtApiRouteMissingMarker) {
    return l10n.stationDebtErrorApiRouteMissing;
  }
  if (mapped == kStationDebtInsufficientStockSubmitMarker) {
    return l10n.stationSaleSubmitInsufficientStock;
  }
  if (mapped == kStationDebtForbiddenMarker) {
    return l10n.stationDebtErrorForbidden;
  }
  final String lower = e.message.toLowerCase();
  if (e.code == 'NOT_FOUND' &&
      (lower.contains('no unpaid') || lower.contains('unpaid debt'))) {
    return l10n.stationDebtRepayNoUnpaid;
  }
  return e.message;
}
