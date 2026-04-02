import 'package:amethyst/app/app.dart';
import 'package:amethyst/app/api_base_url_missing_page.dart';
import 'package:amethyst/app/router/app_router.dart';
import 'package:amethyst/core/config/api_config.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint('[env] API_BASE_URL="${ApiConfig.baseUrl}" mode=${ApiConfig.mode}');
  }

  if (!ApiConfig.isConfigured) {
    runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: ApiBaseUrlMissingPage()));
    return;
  }

  setupDependencies();
  final AuthCubit authCubit = sl<AuthCubit>();
  try {
    await authCubit.checkSession();
  } on Object catch (e, st) {
    debugPrint('checkSession failed: $e\n$st');
    await authCubit.logout();
  }
  final GoRouter router = createAppRouter(authCubit);
  runApp(
    BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: AmethystApp(router: router),
    ),
  );
}
