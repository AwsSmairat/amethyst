import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/vehicle_load/vehicle_load_batches.dart';
import 'package:amethyst/features/catalog/presentation/widgets/vehicle_load_line_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// بطاقة حمولة واحدة (عدة منتجات) في يوم التحميل.
class VehicleLoadBatchCard extends StatelessWidget {
  const VehicleLoadBatchCard({
    super.key,
    required this.batch,
    required this.batchNumber,
    this.initiallyExpanded = false,
  });

  final VehicleLoadBatch batch;
  final int batchNumber;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final DateTime? created = batch.createdAt?.toLocal();
    final String? timeLabel = created != null
        ? DateFormat.jm(locale).format(created)
        : null;
    final String subtitle = l10n.vehicleLoadBatchMetaLine(
      '${batch.lineCount}',
      '${batch.totalQuantityLoaded}',
      timeLabel ?? '—',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.surfaceLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsetsDirectional.only(
            start: 14,
            end: 10,
            top: 4,
            bottom: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.primary,
          title: Text(
            l10n.vehicleLoadBatchTitle('$batchNumber'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: <Widget>[
            for (int i = 0; i < batch.lines.length; i++) ...<Widget>[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
              VehicleLoadLineTile(item: batch.lines[i]),
            ],
          ],
        ),
      ),
    );
  }
}
