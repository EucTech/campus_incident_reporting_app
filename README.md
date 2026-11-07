# Pulse

Pulse is a Flutter mobile app for reporting campus issues at ALU. Students sign in with a verified ALU email, report problems such as water, electricity, or safety issues with an optional photo, and track each report until it is resolved. Authorized staff review reports and update their status.

Built with Flutter, Riverpod, Firebase Authentication, Cloud Firestore, and Firebase Storage.

## How to run

**Requirements:** Flutter 3.47+, an Android emulator or device, Node.js, and the [Firebase CLI](https://firebase.google.com/docs/cli).

1. Install the packages:

   ```bash
   flutter pub get
   ```

2. Connect your Firebase project. Enable Email/Password sign-in, Firestore, and Storage in the console, then run:

   ```bash
   firebase login
   flutterfire configure
   firebase use <your-project-id>
   firebase deploy --only firestore:rules,storage
   ```

3. Start an emulator and run the app:

   ```bash
   flutter run
   ```

## Staff access

New accounts are students. To make someone staff, open their document in the Firestore `users` collection and set `role` to `staff`.

## Run without a Firebase project

Use the local Firebase emulators. This needs Java and skips step 2:

```bash
firebase emulators:start
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

## Tests

```bash
flutter test
```
