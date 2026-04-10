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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAWy5-XK9_1bgrdU7pPIGxbt2TnKHYJKUg',
    appId: '1:720408733866:web:375d6d32e979230116c8d3',
    messagingSenderId: '720408733866',
    projectId: 'chess-d6bcf',
    authDomain: 'chess-d6bcf.firebaseapp.com',
    databaseURL: 'https://chess-d6bcf-default-rtdb.firebaseio.com',
    storageBucket: 'chess-d6bcf.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBxKzGF6vSEQmkkKnWK_yqUsYNyNNwQSB4',
    appId: '1:720408733866:android:8441faeaacda748d16c8d3',
    messagingSenderId: '720408733866',
    projectId: 'chess-d6bcf',
    databaseURL: 'https://chess-d6bcf-default-rtdb.firebaseio.com',
    storageBucket: 'chess-d6bcf.firebasestorage.app',
  );
}
