import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/staff_note/presentation/staff_note_inbox_refresh.dart';
import 'package:flutter/material.dart';

const String _recipientAllAdmins = 'all_admins';

Future<void> showSendStaffNoteSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => const _SendStaffNoteSheet(),
  );
}

class _SendStaffNoteSheet extends StatefulWidget {
  const _SendStaffNoteSheet();

  @override
  State<_SendStaffNoteSheet> createState() => _SendStaffNoteSheetState();
}

class _SendStaffNoteSheetState extends State<_SendStaffNoteSheet> {
  final TextEditingController _messageController = TextEditingController();
  bool _loadingRecipients = true;
  bool _submitting = false;
  String? _error;
  List<Map<String, dynamic>> _drivers = <Map<String, dynamic>>[];
  String _recipientKind = _recipientAllAdmins;
  String? _driverUserId;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    try {
      final List<Map<String, dynamic>> items =
          await sl<AmethystApi>().listStaffNoteRecipients();
      if (!mounted) {
        return;
      }
      setState(() {
        _drivers = items
            .where((Map<String, dynamic> u) => u['role']?.toString() == 'driver')
            .toList(growable: false);
        _loadingRecipients = false;
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingRecipients = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submit() async {
    final String text = _messageController.text.trim();
    final l10n = context.l10n;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.staffNoteEmptyMessage)),
      );
      return;
    }
    if (_recipientKind != _recipientAllAdmins &&
        (_driverUserId == null || _driverUserId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.staffNotePickDriver)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await sl<AmethystApi>().createStaffNotes(
        message: text,
        recipientKind: _recipientKind,
        driverUserId: _driverUserId,
      );
      if (!mounted) {
        return;
      }
      StaffNoteInboxRefresh.request();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.staffNoteSentSuccess)),
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
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.staffNoteSendTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          if (_loadingRecipients)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...<Widget>[
            if (_error != null) ...<Widget>[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              l10n.staffNoteRecipientLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _recipientKind == _recipientAllAdmins
                  ? _recipientAllAdmins
                  : _driverUserId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: _recipientAllAdmins,
                  child: Text(l10n.staffNoteRecipientAllAdmins),
                ),
                for (final Map<String, dynamic> d in _drivers)
                  DropdownMenuItem<String>(
                    value: d['id']?.toString(),
                    child: Text(d['fullName']?.toString() ?? '—'),
                  ),
              ],
              onChanged: _submitting
                  ? null
                  : (String? v) {
                      if (v == null) {
                        return;
                      }
                      setState(() {
                        if (v == _recipientAllAdmins) {
                          _recipientKind = _recipientAllAdmins;
                          _driverUserId = null;
                        } else {
                          _recipientKind = 'driver';
                          _driverUserId = v;
                        }
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.staffNoteKpi,
                hintText: l10n.staffNoteMessageHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.staffNoteSendButton),
            ),
          ],
        ],
      ),
    );
  }
}
