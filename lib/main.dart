import 'package:amethyst/app/app.dart';
import 'package:amethyst/app/router/app_router.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
