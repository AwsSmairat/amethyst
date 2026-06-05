import 'package:amethyst/core/network/api_exception.dart';
import 'package:firebase_core/firebase_core.dart';

/// Shown when a write/delete action is attempted in UI-only mode.
const String kUiOnlyMessage =
    'This is UI only. Logic will be added later.';

Never throwUiOnlyWrite() {
  throw ApiException(kUiOnlyMessage, code: 'UI_ONLY');
}

String? uiOnlyErrorMessage(Object error) {
  if (error is ApiException && error.code == 'UI_ONLY') {
    return kUiOnlyMessage;
  }
  return null;
}

Object _unwrapInteropError(Object error, {int depth = 0}) {
  if (depth > 6) {
    return error;
  }
  try {
    // على Flutter Web تُغلَّف أخطاء JS داخل Future عبر خاصية error.
    // ignore: avoid_dynamic_calls
    final dynamic boxed = error;
    final Object? inner = boxed.error;
    if (inner != null) {
      return _unwrapInteropError(inner, depth: depth + 1);
    }
  } on Object {
    // ليس خطأاً مُغلَّفاً من JS.
  }
  return error;
}

String errorMessageFrom(Object error) {
  return _errorMessageFromUnwrapped(_unwrapInteropError(error));
}

String _errorMessageFromUnwrapped(Object error) {
  final String? uiOnly = uiOnlyErrorMessage(error);
  if (uiOnly != null) {
    return uiOnly;
  }
  if (error is ApiException) {
    return error.message;
  }
  if (error is FirebaseException) {
    return error.message ?? error.code;
  }
  final String text = error.toString();
  if (text.contains('Dart exception thrown from converted Future')) {
    return 'حدث خطأ أثناء الاتصال بالخادم. حاول مرة أخرى.';
  }
  return text;
}
