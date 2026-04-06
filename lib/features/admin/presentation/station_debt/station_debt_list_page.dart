import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/admin/presentation/station_debt/station_debt_api_error.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:amethyst/features/catalog/presentation/pages/json_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// قائمة سجلات الدين من `GET /station-debt-entries`.
class StationDebtListPage extends StatelessWidget {
  const StationDebtListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider<JsonListCubit>(
      create: (_) => JsonListCubit(
        () => sl<AmethystApi>().listStationDebtEntries(),
        mapLoadError: mapStationDebtListLoadError,
      )..load(),
      child: JsonListPage(
        title: l10n.titleStationDebtList,
        failureMessageBuilder: (BuildContext context, String raw) {
          if (raw == kStationDebtApiRouteMissingMarker) {
            return context.l10n.stationDebtErrorApiRouteMissing;
          }
          if (raw == kStationDebtInsufficientStockSubmitMarker) {
            return context.l10n.stationSaleSubmitInsufficientStock;
          }
          return raw;
        },
        titleBuilder: (BuildContext context, Map<String, dynamic> item) {
          final String debtor = item['debtorName']?.toString() ?? '';
          final Map<String, dynamic>? product =
              item['product'] is Map<String, dynamic>
                  ? item['product'] as Map<String, dynamic>
                  : null;
          final String pname = product?['name']?.toString() ?? '';
          return '$debtor · $pname';
        },
        subtitleBuilder: (BuildContext context, Map<String, dynamic> item) {
          final String qty = item['quantity']?.toString() ?? '';
          final String total = _formatAmount(item['totalAmount']);
          final String? when = _formatDateTime(context, item['createdAt']);
          final Map<String, dynamic>? rec =
              item['recordedBy'] is Map<String, dynamic>
                  ? item['recordedBy'] as Map<String, dynamic>
                  : null;
          final String rname = rec?['fullName']?.toString() ?? '';
          final List<String> parts = <String>[
            '${l10n.quantity}: $qty',
            '${l10n.totalAmountLabel}: $total',
            if (when != null) when,
            if (rname.isNotEmpty) rname,
          ];
          return parts.join(' · ');
        },
      ),
    );
  }
}

String _formatAmount(dynamic v) {
  if (v == null) {
    return '—';
  }
  if (v is num) {
    return v.toString();
  }
  return v.toString();
}

String? _formatDateTime(BuildContext context, dynamic raw) {
  if (raw == null) {
    return null;
  }
  final String s = raw.toString();
  if (s.isEmpty) {
    return null;
  }
  try {
    final DateTime d = DateTime.parse(s);
    final String locale = Localizations.localeOf(context).toString();
    final DateTime local = d.toLocal();
    return '${DateFormat.yMMMd(locale).format(local)} ${DateFormat.Hm(locale).format(local)}';
  } on Object {
    return s;
  }
}
