import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7AblVZQuTRyOnpTkLINeJgBMMG0gnl4A',
    appId: '1:696407003370:android:9ff6cca29d809c1bc04793',
    messagingSenderId: '696407003370',
    projectId: 'pack-vault-be672',
    databaseURL: 'https://pack-vault-be672-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'pack-vault-be672.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD9j4YmwqIHqmznDfggfmYWV4bMAeTmfNA',
    appId: '1:696407003370:ios:cc8b4415f4046e01c04793',
    messagingSenderId: '696407003370',
    projectId: 'pack-vault-be672',
    databaseURL: 'https://pack-vault-be672-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'pack-vault-be672.firebasestorage.app',
    iosBundleId: 'com.packvault.app',
  );

}