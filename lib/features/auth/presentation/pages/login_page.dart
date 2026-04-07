import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/brand_mark.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة تسجيل الدخول — شعار [BrandAssets.loginIcon] داخل دائرة مع توهج.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _prefsKeySavedEmail = 'saved_email';

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefsKeySavedEmail);
    if (saved != null && saved.isNotEmpty) {
      _email.text = saved;
      if (mounted) {
        setState(() => _rememberMe = true);
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _persistRememberMe() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_prefsKeySavedEmail, _email.text.trim());
    } else {
      await prefs.remove(_prefsKeySavedEmail);
    }
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await context.read<AuthCubit>().login(
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!context.mounted) return;
    if (context.read<AuthCubit>().state is AuthAuthenticated) {
      await _persistRememberMe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.black),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const _LoginStoreLogo(),
                        const SizedBox(height: 28),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _LoginFormPanel(
                              textTheme: textTheme,
                              emailController: _email,
                              passwordController: _password,
                              rememberMe: _rememberMe,
                              onRememberMeChanged: (bool value) {
                                setState(() => _rememberMe = value);
                              },
                              onSubmit: () => _submit(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginStoreLogo extends StatelessWidget {
  const _LoginStoreLogo();

  /// حجم الدائرة الخارجية (أكبر من السابق).
  static const double _size = 220;

  /// تكبير طفيف يقصّ الحواف السوداء حول الشعار في ملف PNG.
  static const double _cropScale = 1.22;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: context.l10n.brandSemantic,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF3EC5FF).withValues(alpha: 0.24),
                blurRadius: 44,
                spreadRadius: 2,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipOval(
            child: Transform.scale(
              scale: _cropScale,
              alignment: Alignment.center,
              child: Image.asset(
                BrandAssets.loginIcon,
                fit: BoxFit.cover,
                width: _size,
                height: _size,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) {
                  return ColoredBox(
                    color: Colors.white.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.textTheme,
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onSubmit,
  });

  final TextTheme textTheme;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLowest,
      elevation: 8,
      shadowColor: const Color.fromRGBO(10, 37, 64, 0.2),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.signIn,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.signInSubtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (String? v) =>
                  v == null || v.trim().isEmpty ? context.l10n.enterEmail : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: context.l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (String? v) =>
                  v == null || v.isEmpty ? context.l10n.enterPassword : null,
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: Directionality.of(context),
              children: <Widget>[
                Checkbox(
                  value: rememberMe,
                  onChanged: (bool? value) {
                    onRememberMeChanged(value ?? false);
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onRememberMeChanged(!rememberMe),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        context.l10n.rememberMe,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocConsumer<AuthCubit, AuthState>(
              listener: (BuildContext context, AuthState state) {
                if (state is AuthUnauthenticated && state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message!)),
                  );
                }
              },
              builder: (BuildContext context, AuthState state) {
                final bool loading = state is AuthLoading;
                return FilledButton(
                  onPressed: loading ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.l10n.signIn),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
