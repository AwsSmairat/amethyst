import 'package:amethyst/app/amethyst_bootstrap.dart';
import 'package:amethyst/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } on Object catch (_) {
    // بعض المنصات تتجاهل إعداد الكاش — التطبيق يعمل بدونها.
  }
  runApp(const AmethystBootstrap());
}
