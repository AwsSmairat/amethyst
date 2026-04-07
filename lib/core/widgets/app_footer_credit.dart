import 'package:flutter/material.dart';

/// Small credit line shown in a bottom corner on main app surfaces (RTL-friendly).
class AppFooterCredit extends StatelessWidget {
  const AppFooterCredit({super.key, this.textColor});

  /// When null, uses a subtle [ColorScheme.onSurface]. Use on dark backgrounds (e.g. login).
  final Color? textColor;

  static const String creditText = 'Eng. Aws Smairat';

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color resolved = textColor ??
        scheme.onSurface.withValues(alpha: 0.42);
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 6),
          child: IgnorePointer(
            child: Text(
              creditText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: resolved,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
