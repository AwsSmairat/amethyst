import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:flutter/material.dart';

class StationSaleBackBar extends StatelessWidget {
  const StationSaleBackBar({
    super.key,
    required this.onBack,
    this.enabled = true,
  });

  final VoidCallback onBack;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: context.l10n.stationSaleBack,
          onPressed: enabled ? onBack : null,
          icon: const Icon(Icons.arrow_back),
        ),
        const Spacer(),
      ],
    );
  }
}
