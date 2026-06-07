import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/printer/printer_exception.dart';
import 'package:amethyst/core/printer/printer_service.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef ReceiptBytesBuilder = Future<List<int>> Function();

Future<void> showPrintReceiptPromptSheet(
  BuildContext context, {
  required ReceiptBytesBuilder buildReceiptBytes,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return _PrintReceiptPromptBody(
        buildReceiptBytes: buildReceiptBytes,
      );
    },
  );
}

class _PrintReceiptPromptBody extends StatefulWidget {
  const _PrintReceiptPromptBody({required this.buildReceiptBytes});

  final ReceiptBytesBuilder buildReceiptBytes;

  @override
  State<_PrintReceiptPromptBody> createState() =>
      _PrintReceiptPromptBodyState();
}

class _PrintReceiptPromptBodyState extends State<_PrintReceiptPromptBody> {
  bool _printing = false;

  Future<void> _print() async {
    final l10n = context.l10n;
    setState(() => _printing = true);
    try {
      final List<int> bytes = await widget.buildReceiptBytes();
      await sl<PrinterService>().printBytes(bytes);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printerPrintSuccess)),
      );
    } on PrinterException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
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
        setState(() => _printing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.printerPromptTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.printerPromptSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _printing ? null : _print,
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            label: Text(l10n.printerPrintReceipt),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _printing ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.printerSkip),
          ),
          TextButton(
            onPressed: _printing
                ? null
                : () {
                    Navigator.of(context).pop();
                    context.push('/driver/printer-settings');
                  },
            child: Text(l10n.printerOpenSettings),
          ),
        ],
      ),
    );
  }
}
