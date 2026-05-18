import 'package:flutter/material.dart';

/// Compact action icons for super-admin user list rows (avoids ListTile overflow).
class UserListActionsRow extends StatelessWidget {
  const UserListActionsRow({
    super.key,
    required this.onEdit,
    required this.onResetPassword,
    required this.onToggleActive,
    required this.isActive,
    required this.editTooltip,
    required this.resetTooltip,
    required this.toggleTooltip,
  });

  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback? onToggleActive;
  final bool isActive;
  final String editTooltip;
  final String resetTooltip;
  final String toggleTooltip;

  static const ButtonStyle _compactIcon = ButtonStyle(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.all(8)),
  );

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          style: _compactIcon,
          tooltip: editTooltip,
          icon: const Icon(Icons.edit_outlined, size: 22),
          onPressed: onEdit,
        ),
        IconButton(
          style: _compactIcon,
          tooltip: resetTooltip,
          icon: const Icon(Icons.mail_outline, size: 22),
          onPressed: onResetPassword,
        ),
        IconButton(
          style: _compactIcon,
          tooltip: toggleTooltip,
          icon: Icon(
            isActive ? Icons.block_outlined : Icons.check_circle_outline,
            size: 22,
            color: isActive ? colors.error : colors.primary,
          ),
          onPressed: onToggleActive,
        ),
      ],
    );
  }
}
