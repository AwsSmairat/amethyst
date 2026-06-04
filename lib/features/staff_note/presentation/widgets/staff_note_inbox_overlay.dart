import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/staff_note/presentation/staff_note_inbox_refresh.dart';
import 'package:flutter/material.dart';

/// يعرض ملاحظة غير مقروءة في منتصف الشاشة حتى يضغط المستلم «تم القراءة».
class StaffNoteInboxOverlay extends StatefulWidget {
  const StaffNoteInboxOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<StaffNoteInboxOverlay> createState() => _StaffNoteInboxOverlayState();
}

class _StaffNoteInboxOverlayState extends State<StaffNoteInboxOverlay>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _pending;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    StaffNoteInboxRefresh.onRefreshRequested = _refresh;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    if (StaffNoteInboxRefresh.onRefreshRequested == _refresh) {
      StaffNoteInboxRefresh.onRefreshRequested = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final Map<String, dynamic>? note =
          await sl<AmethystApi>().getPendingStaffNoteForMe();
      if (!mounted) {
        return;
      }
      setState(() => _pending = note);
    } on Object {
      // تجاهل — لا نعطل الشاشة
    }
  }

  Future<void> _markRead() async {
    final String? id = _pending?['id']?.toString();
    if (id == null || id.isEmpty || _markingRead) {
      return;
    }
    setState(() => _markingRead = true);
    try {
      await sl<AmethystApi>().markStaffNoteRead(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _pending = null;
        _markingRead = false;
      });
      await _refresh();
    } on Object {
      if (mounted) {
        setState(() => _markingRead = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (_pending != null) ...<Widget>[
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.55),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(20),
                color: AppColors.cardWhite,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.campaign_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.staffNoteKpi,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.staffNoteFromSender(
                          _senderName(_pending!),
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _pending!['message']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.45,
                              color: AppColors.primaryText,
                            ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _markingRead ? null : _markRead,
                          child: _markingRead
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(context.l10n.staffNoteMarkRead),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _senderName(Map<String, dynamic> note) {
    final Object? from = note['fromUser'];
    if (from is Map<String, dynamic>) {
      final String? n = from['fullName']?.toString().trim();
      if (n != null && n.isNotEmpty) {
        return n;
      }
    }
    return note['fromUserId']?.toString() ?? '—';
  }
}
