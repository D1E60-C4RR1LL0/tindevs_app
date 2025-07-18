// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAEVhCpib7-RxArmbupn-l4f6G9yQJ5iJc',
    appId: '1:305613084851:web:718b0719cd69c807fb38c6',
    messagingSenderId: '305613084851',
    projectId: 'tindevs-1f6ed',
    authDomain: 'tindevs-1f6ed.firebaseapp.com',
    storageBucket: 'tindevs-1f6ed.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCmlPq2ar-1OV20zT3UlsEHUmb4yFmIQbo',
    appId: '1:305613084851:android:18591c9de907abe2fb38c6',
    messagingSenderId: '305613084851',
    projectId: 'tindevs-1f6ed',
    storageBucket: 'tindevs-1f6ed.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD84NgKn8DUj_XpWpT_z1q10IomB7yyChI',
    appId: '1:305613084851:ios:b3e8625a94242e21fb38c6',
    messagingSenderId: '305613084851',
    projectId: 'tindevs-1f6ed',
    storageBucket: 'tindevs-1f6ed.appspot.com',
    iosBundleId: 'com.example.tindevsApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD84NgKn8DUj_XpWpT_z1q10IomB7yyChI',
    appId: '1:305613084851:ios:b3e8625a94242e21fb38c6',
    messagingSenderId: '305613084851',
    projectId: 'tindevs-1f6ed',
    storageBucket: 'tindevs-1f6ed.appspot.com',
    iosBundleId: 'com.example.tindevsApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAEVhCpib7-RxArmbupn-l4f6G9yQJ5iJc',
    appId: '1:305613084851:web:dc5fea33a9e1dcbcfb38c6',
    messagingSenderId: '305613084851',
    projectId: 'tindevs-1f6ed',
    authDomain: 'tindevs-1f6ed.firebaseapp.com',
    storageBucket: 'tindevs-1f6ed.appspot.com',
  );
}
