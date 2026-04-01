import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension AppLocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
