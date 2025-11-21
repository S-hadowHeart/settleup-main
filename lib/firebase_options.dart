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
    apiKey: 'AIzaSyBrtA5LlWZ0kcxyaHtwmpG9WfIESQwq0Kk',
    appId: '1:1019565377776:web:95fbd5e96ec5b237afda35',
    messagingSenderId: '1019565377776',
    projectId: 'settleup-era',
    authDomain: 'settleup-era.firebaseapp.com',
    storageBucket: 'settleup-era.firebasestorage.app',
    measurementId: 'G-9SZVPTZKPG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAicG7bM5N5Kr8i44Ei0dgBdBpfVt67lmg',
    appId: '1:1019565377776:android:ff34e6bb2aaa095cafda35',
    messagingSenderId: '1019565377776',
    projectId: 'settleup-era',
    storageBucket: 'settleup-era.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyem_BtqJa0kqZZjef5LTIMHN2Sh-RxcI',
    appId: '1:1019565377776:ios:73fbef76418e1484afda35',
    messagingSenderId: '1019565377776',
    projectId: 'settleup-era',
    storageBucket: 'settleup-era.firebasestorage.app',
    iosBundleId: 'com.example.settleup',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCyem_BtqJa0kqZZjef5LTIMHN2Sh-RxcI',
    appId: '1:1019565377776:ios:73fbef76418e1484afda35',
    messagingSenderId: '1019565377776',
    projectId: 'settleup-era',
    storageBucket: 'settleup-era.firebasestorage.app',
    iosBundleId: 'com.example.settleup',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBrtA5LlWZ0kcxyaHtwmpG9WfIESQwq0Kk',
    appId: '1:1019565377776:web:57ae236d2740bb84afda35',
    messagingSenderId: '1019565377776',
    projectId: 'settleup-era',
    authDomain: 'settleup-era.firebaseapp.com',
    storageBucket: 'settleup-era.firebasestorage.app',
    measurementId: 'G-XD28JV03LB',
  );
}
