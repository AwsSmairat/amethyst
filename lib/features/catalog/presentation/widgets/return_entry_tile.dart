import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// بطاقة سجل إرجاع واحد (منتج، كمية، مركبة، سائق، تاريخ).
class ReturnEntryTile extends StatelessWidget {
  const ReturnEntryTile({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String productName = _nestedString(item['product'], 'name');
    final String vehicleNo = _nestedString(item['vehicle'], 'vehicleNumber');
    final String driverName = _nestedString(item['driver'], 'fullName');
    final int qty = _intField(item, 'quantityReturned');
    final DateTime? created = _parseDate(item['createdAt']);
    final String locale = Localizations.localeOf(context).toString();
    final String dateText = created == null
        ? '—'
        : DateFormat.yMMMd(locale).add_jm().format(created);
    final String loadId = item['vehicleLoadId']?.toString() ?? '';
    final bool autoEod = item['automaticEndOfDay'] == true ||
        item['source']?.toString() == 'end_of_day';

    final List<String> metaParts = <String>[
      if (vehicleNo.isNotEmpty) l10n.vehicleWithNumber(vehicleNo),
      if (driverName.isNotEmpty) driverName,
      if (loadId.isNotEmpty) '${l10n.loadField}: $loadId',
    ];

    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.softSkyBlue.withValues(alpha: 0.45),
              child: const Icon(
                Icons.assignment_return_outlined,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    productName.isNotEmpty ? productName : l10n.product,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                  if (autoEod) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      l10n.returnAutomaticEndOfDay,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (metaParts.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      metaParts.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    dateText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  l10n.quantityReturned,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$qty',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _nestedString(dynamic obj, String key) {
  if (obj is Map<String, dynamic>) {
    return obj[key]?.toString() ?? '';
  }
  if (obj is Map) {
    return obj[key]?.toString() ?? '';
  }
  return '';
}

int _intField(Map<String, dynamic> map, String key) {
  final Object? v = map[key];
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

DateTime? _parseDate(Object? v) {
  if (v == null) {
    return null;
  }
  if (v is DateTime) {
    return v;
  }
  return DateTime.tryParse(v.toString());
}
