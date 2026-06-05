import 'package:amethyst/app/app.dart';
import 'package:amethyst/app/app_splash_screen.dart';
import 'package:amethyst/app/router/app_router.dart';
import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:amethyst/core/theme/app_theme.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// يعرض [AppSplashScreen] حتى اكتمال [AuthCubit.checkSession] ثم يشغّل التطبيق الفعلي.
class AmethystBootstrap extends StatefulWidget {
  const AmethystBootstrap({super.key});

  @override
  State<AmethystBootstrap> createState() => _AmethystBootstrapState();
}

class _AmethystBootstrapState extends State<AmethystBootstrap> {
  Widget? _readyApp;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await PrototypeSampleData.ensureLoaded();
    setupDependencies();
    final AuthCubit authCubit = sl<AuthCubit>();
    try {
      await authCubit.checkSession();
    } on Object catch (e, st) {
      debugPrint('checkSession failed: $e\n$st');
      await authCubit.logout();
    }
    final GoRouter router = createAppRouter(authCubit);
    if (!mounted) {
      return;
    }
    setState(() {
      _readyApp = BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: AmethystApp(router: router),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_readyApp != null) {
      return _readyApp!;
    }
    // أثناء انتظار الجلسة: امتص مسار الويب (مثلاً /admin/dashboard) حتى لا يفشل
    // MaterialApp عند Hot Restart بينما الـ URL ما زال على مسار GoRouter.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppSplashScreen(),
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const AppSplashScreen(),
      ),
    );
  }
}
