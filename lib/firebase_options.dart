
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyA99u3hvHu17ybqPrE9qQcjw48a9V3ihKk',
    appId: '1:910119612022:web:6dc6fb88a6d0872bf83957',
    messagingSenderId: '910119612022',
    projectId: 'eplace-1de05',
    authDomain: 'eplace-1de05.firebaseapp.com',
    storageBucket: 'eplace-1de05.firebasestorage.app',
    measurementId: 'G-VBKKVZKS7B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7AyLCd21ASMyDJRI6G7XYzI9WkvX210Q',
    appId: '1:910119612022:android:3580da965cee2858f83957',
    messagingSenderId: '910119612022',
    projectId: 'eplace-1de05',
    storageBucket: 'eplace-1de05.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCnkC9foW8mTCMXfNxDA5fkEJj4X3iwJHU',
    appId: '1:910119612022:ios:6fae5f5fb0eea948f83957',
    messagingSenderId: '910119612022',
    projectId: 'eplace-1de05',
    storageBucket: 'eplace-1de05.firebasestorage.app',
    iosBundleId: 'com.ePlace.eplace',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCnkC9foW8mTCMXfNxDA5fkEJj4X3iwJHU',
    appId: '1:910119612022:ios:6fae5f5fb0eea948f83957',
    messagingSenderId: '910119612022',
    projectId: 'eplace-1de05',
    storageBucket: 'eplace-1de05.firebasestorage.app',
    iosBundleId: 'com.ePlace.eplace',
  );
}
