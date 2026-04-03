import 'package:amethyst/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PrimaryGradientCard extends StatelessWidget {
  const PrimaryGradientCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}
