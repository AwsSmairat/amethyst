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
      child: Image.asset(
        BrandAssets.logo,
        fit: BoxFit.contain,
        semanticLabel: 'Amethyst',
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
            Icon(Icons.water_drop, size: size * 0.6),
      ),
    );
  }
}

abstract final class BrandAssets {
  static const String loginBanner = 'assets/images/login_banner.png';

  /// شعار العلامة — شاشة التحميل وتسجيل الدخول (`amethyst_brand_logo.png`).
  static const String appBrandMark = 'assets/images/amethyst_brand_logo.png';

  static const String logo = appBrandMark;

  /// شعار دائري لصفحة تسجيل الدخول.
  static const String loginIcon = appBrandMark;
}
