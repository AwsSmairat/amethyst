import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_aggregates.dart';
import 'package:flutter/material.dart';

/// صف تحميل واحد (منتج + مركبة + كمية) — يُستخدَم في قوائم التحميل.
class VehicleLoadLineTile extends StatelessWidget {
  const VehicleLoadLineTile({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final String rawProductName = _nestedString(item['product'], 'name');
    final String productTitle = rawProductName.isEmpty
        ? ''
        : catalogProductArabicDisplayLabel(rawProductName);
    final String vehicleNo = _nestedString(item['vehicle'], 'vehicleNumber');
    final String driverName = _nestedString(item['driver'], 'fullName');
    final String statusAr =
        _statusLabel(context, vehicleLoadEffectiveStatus(item));
    final dynamic qty = item['quantityLoaded'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          productTitle.isNotEmpty ? productTitle : l10n.product,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        if (vehicleNo.isNotEmpty || driverName.isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            <String>[
              if (vehicleNo.isNotEmpty) l10n.vehicleWithNumber(vehicleNo),
              if (driverName.isNotEmpty) driverName,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            _LoadStatusChip(
              label: statusAr,
              isClosed: vehicleLoadRemainingQty(item) <= 0,
            ),
            const Spacer(),
            Text(
              '${l10n.quantity}: $qty',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadStatusChip extends StatelessWidget {
  const _LoadStatusChip({required this.label, this.isClosed = false});

  final String label;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isClosed
            ? AppColors.onSurfaceVariant.withValues(alpha: 0.2)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
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

String _statusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  switch (status.toLowerCase()) {
    case 'open':
      return l10n.loadStatusOpen;
    case 'closed':
      return l10n.loadStatusClosed;
    default:
      return status;
  }
}
