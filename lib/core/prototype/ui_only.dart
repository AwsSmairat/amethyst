import 'package:amethyst/core/network/api_exception.dart';

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

String errorMessageFrom(Object error) =>
    uiOnlyErrorMessage(error) ??
    (error is ApiException ? error.message : error.toString());
