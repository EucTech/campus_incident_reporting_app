# Pulse

Pulse is a Flutter mobile app for reporting campus issues. A school registers on Pulse, students join with their school email, and they report problems such as water, electricity, or safety issues with an optional photo, then track each report until it is resolved. Staff invited by the school review reports and update their status. Each school only sees its own reports.

Built with Flutter, Riverpod, Firebase Authentication, Cloud Firestore, and Cloudinary for photos.

## How to run

**Requirements:** Flutter 3.47+ and an Android emulator or device.

```bash
flutter pub get
flutter run
```

The app is already connected to its Firebase project and Cloudinary account, so no extra setup is needed.

## Roles

| Role | How they join |
|---|---|
| School admin | Taps **Register it on Pulse** on the welcome screen and enters the school's student email domain |
| Student | Signs up with an email on the school's student domain |
| Staff | Is invited by the admin from **Account → Manage team**, then signs up with that exact email |

Every account confirms its email with a link before it can use the app. The link can be opened on any device.

## Tests

```bash
flutter test
```
