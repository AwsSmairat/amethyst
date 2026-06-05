import 'dart:async';

import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when [stream] emits so redirects re-run.
final class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    AuthState? previous;
    _subscription = stream.listen((dynamic state) {
      if (state is! AuthState) {
        notifyListeners();
        return;
      }
      final AuthState next = state;
      final bool shouldRefresh = switch (previous) {
        null => true,
        AuthAuthenticated(:final user) when next is AuthAuthenticated =>
          user.id != next.user.id,
        AuthAuthenticated() when next is AuthUnauthenticated => true,
        AuthUnauthenticated() when next is AuthAuthenticated => true,
        AuthLoading() when next is AuthLoading => false,
        _ => previous.runtimeType != next.runtimeType,
      };
      previous = next;
      if (shouldRefresh) {
        notifyListeners();
      }
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
