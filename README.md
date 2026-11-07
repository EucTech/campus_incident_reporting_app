# Pulse

Pulse is a Flutter mobile app for reporting campus issues at ALU. Students sign in with a verified ALU email, report problems such as water, electricity, or safety issues with an optional photo, and track each report until it is resolved. Authorized staff review reports and update their status.

Built with Flutter, Riverpod, Firebase Authentication, Cloud Firestore, and Cloudinary for photos.

## How to run

**Requirements:** Flutter 3.47+ and an Android emulator or device.

```bash
flutter pub get
flutter run
```

The app is already connected to its Firebase project and Cloudinary account, so no extra setup is needed.

## Staff access

New accounts are students. To make someone staff, open their document in the Firestore `users` collection and set `role` to `staff`.

## Tests

```bash
flutter test
```
