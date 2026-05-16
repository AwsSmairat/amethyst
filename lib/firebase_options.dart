import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCsuPxGcE6JzibDeIlxvUDMDlZiDlXOUc0',
    appId: '1:963427966128:web:2d42382a73c9608e352f75',
    messagingSenderId: '963427966128',
    projectId: 'amethyst-6a511',
    authDomain: 'amethyst-6a511.firebaseapp.com',
    storageBucket: 'amethyst-6a511.firebasestorage.app',
    measurementId: 'G-L1YGNDNSWD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvxJTGATtdH5of2gD5cI-BTz6zOlRnCt0',
    appId: '1:963427966128:android:d95d8b2a6644e479352f75',
    messagingSenderId: '963427966128',
    projectId: 'amethyst-6a511',
    storageBucket: 'amethyst-6a511.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBMVp8JxH-bM4QDaWaNEROEoRYwHtNnNI8',
    appId: '1:963427966128:ios:73feee188126971e352f75',
    messagingSenderId: '963427966128',
    projectId: 'amethyst-6a511',
    storageBucket: 'amethyst-6a511.firebasestorage.app',
    iosBundleId: 'com.example.amethyst',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBMVp8JxH-bM4QDaWaNEROEoRYwHtNnNI8',
    appId: '1:963427966128:ios:73feee188126971e352f75',
    messagingSenderId: '963427966128',
    projectId: 'amethyst-6a511',
    storageBucket: 'amethyst-6a511.firebasestorage.app',
    iosBundleId: 'com.example.amethyst',
  );

}