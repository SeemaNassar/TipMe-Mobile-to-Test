import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCIOCINZO8P2GVm07kIhrqJjZhsSM5GhgU',
    appId: '1:90241543608:web:bcf4b40f1580d94f98b34d',
    messagingSenderId: '90241543608',
    projectId: 'tipme-13a0c',
    authDomain: 'tipme-13a0c.firebaseapp.com',
    storageBucket: 'tipme-13a0c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9wEC6ozmiC5wWpSipWt_yR4rLcq8GbeM',
    appId: '1:90241543608:android:70ad7d7d610e314d98b34d',
    messagingSenderId: '90241543608',
    projectId: 'tipme-13a0c',
    storageBucket: 'tipme-13a0c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCIOCINZO8P2GVm07kIhrqJjZhsSM5GhgU',
    appId: '1:90241543608:ios:your_ios_app_id',
    messagingSenderId: '90241543608',
    projectId: 'tipme-13a0c',
    storageBucket: 'tipme-13a0c.firebasestorage.app',
    iosBundleId: 'iih.amman.tipme_app',
  );
}