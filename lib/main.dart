import 'package:amethyst/app/amethyst_bootstrap.dart';
import 'package:amethyst/app/api_base_url_missing_page.dart';
import 'package:amethyst/core/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint(
      '[env] API_BASE_URL="${ApiConfig.resolvedBaseUrl}" (raw="${ApiConfig.baseUrl}") '
      'mode=${ApiConfig.mode}',
    );
  }

  final String? configIssue = ApiConfig.configurationBlockReason;
  if (configIssue != null) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ApiBaseUrlMissingPage(detail: configIssue),
      ),
    );
    return;
  }

  runApp(const AmethystBootstrap());
}
