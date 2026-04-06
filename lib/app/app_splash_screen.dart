import 'package:amethyst/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// شاشة أولية: شعار المتجر + مؤشر تحميل (أثناء تهيئة الجلسة في [main]).
class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({super.key});

  static const String logoAsset = 'assets/images/icon_amt.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              logoAsset,
              width: 140,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder:
                  (BuildContext _, Object __, StackTrace? ___) => Icon(
                        Icons.water_drop_rounded,
                        size: 100,
                        color: AppColors.brandPrimary,
                      ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3.2,
                color: AppColors.brandPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
