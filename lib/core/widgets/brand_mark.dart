import 'package:flutter/material.dart';

/// Circular brand logo (Amethyst mascot). Asset: [BrandAssets.logo].
class BrandMarkSmall extends StatelessWidget {
  const BrandMarkSmall({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          BrandAssets.logo,
          fit: BoxFit.cover,
          semanticLabel: 'Amethyst',
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
              Icon(Icons.water_drop, size: size * 0.6),
        ),
      ),
    );
  }
}

abstract final class BrandAssets {
  static const String loginBanner = 'assets/images/login_banner.png';
  static const String logo = 'assets/images/brand_logo.png';
  /// شعار دائري لصفحة تسجيل الدخول.
  static const String loginIcon = 'assets/images/icon_amt.png';
}
