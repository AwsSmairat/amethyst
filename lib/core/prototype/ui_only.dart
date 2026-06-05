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

String errorMessageFrom(Object error) {
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
