import 'dart:async';

import 'package:amethyst/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

/// Branded splash: gradient, radial glow, logo pulse, title stack.
/// Shown while session/bootstrap runs ([AmethystBootstrap]).
class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with TickerProviderStateMixin {
  static const Color _top = Color(0xFF0F2747);
  static const Color _mid = Color(0xFF2F80ED);
  static const Color _bottom = Color(0xFF56CCF2);

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController.forward();
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 420)).then((_) {
        if (mounted) {
          _pulseController.repeat(reverse: true);
        }
      }),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[_top, _mid, _bottom],
                stops: <double>[0.0, 0.52, 1.0],
              ),
            ),
          ),
          const _SplashRadialGlow(),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: const _SplashLogoWithGlow(),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Amethyst',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        shadows: <Shadow>[
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Smart Water Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft cyan/blue halo centered behind the logo.
class _SplashRadialGlow extends StatelessWidget {
  const _SplashRadialGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double d = (constraints.biggest.shortestSide * 0.92)
              .clamp(280.0, 420.0);
          return Center(
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    const Color(0xFF56CCF2).withValues(alpha: 0.38),
                    const Color(0xFF2F80ED).withValues(alpha: 0.14),
                    const Color(0xFF0F2747).withValues(alpha: 0.0),
                  ],
                  stops: const <double>[0.0, 0.42, 1.0],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplashLogoWithGlow extends StatelessWidget {
  const _SplashLogoWithGlow();

  @override
  Widget build(BuildContext context) {
    const double size = 168;
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF56CCF2).withValues(alpha: 0.42),
              blurRadius: 36,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF2F80ED).withValues(alpha: 0.35),
              blurRadius: 52,
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Image.asset(
          BrandAssets.appBrandMark,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder:
              (BuildContext _, Object __, StackTrace? ___) => Icon(
                    Icons.water_drop_rounded,
                    size: size * 0.55,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
        ),
      ),
    );
  }
}
