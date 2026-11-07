import 'package:firebase_core/firebase_core.dart';

// Local emulator values; run `flutterfire configure` to replace with a real project.
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-pulse',
    storageBucket: 'demo-pulse.appspot.com',
  );
}
