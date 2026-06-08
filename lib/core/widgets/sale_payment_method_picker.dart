import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/vehicle_sale/vehicle_sale_payment_method.dart';
import 'package:flutter/material.dart';

/// أزرار اختيار طريقة الدفع (كاش / كليك) — مشتركة بين بيع المحطة والسيارة.
class SalePaymentMethodPicker extends StatelessWidget {
  const SalePaymentMethodPicker({
    super.key,
    required this.title,
    required this.cashLabel,
    required this.cliqLabel,
    required this.selected,
    required this.onCashTap,
    required this.onCliqTap,
    this.enabled = true,
  });

  final String title;
  final String cashLabel;
  final String cliqLabel;
  final VehicleSalePaymentMethod? selected;
  final VoidCallback? onCashTap;
  final VoidCallback? onCliqTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _SalePaymentMethodTile(
                label: cashLabel,
                selected: selected == VehicleSalePaymentMethod.cash,
                onTap: enabled ? onCashTap : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SalePaymentMethodTile(
                label: cliqLabel,
                selected: selected == VehicleSalePaymentMethod.cliq,
                onTap: enabled ? onCliqTap : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SalePaymentMethodTile extends StatelessWidget {
  const _SalePaymentMethodTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.1)
          : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? scheme.primary : AppColors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.primary : AppColors.primaryText,
                ),
          ),
        ),
      ),
    );
  }
}
