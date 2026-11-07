# Pulse

A Flutter app for reporting campus issues. Students report problems like broken facilities, water or power cuts and safety hazards, then follow each report until it is fixed. Staff review reports and update their status. Many schools can use the app, and each school only sees its own reports.

## Features

- **Schools**: a school registers with its student email domain, and the person who registers becomes the school admin.
- **Sign up and verification**: students join automatically with their school email, and staff join only by the admin's invite. Every account confirms its email before using the app.
- **Reports**: title, description, location, category, urgency and an optional photo, with an option to hide your name.
- **Browse**: search and filter by status, category or your own reports, and mark "this affects me too" on an existing report.
- **Status tracking**: Submitted, In review, In progress, Resolved or Dismissed, with a history of who changed what.
- **Staff desk**: a queue sorted by urgency, then age.
- **Team**: the admin invites and removes staff.
- **Account**: edit your name and photo, change your password or email, switch between dark and light mode, and delete your account.

## Tech stack

| Area | Tool |
|---|---|
| App | Flutter, Dart |
| State management | Riverpod |
| Navigation | go_router |
| Login | Firebase Authentication |
| Database | Cloud Firestore, protected by security rules |
| Photos | Cloudinary |

## Project structure

```
lib/
  core/        shared theme, router, widgets, validators and photo upload
  features/
    auth/      sign up, log in, verify email
    schools/   register a school, join a school, manage the team
    incidents/ create, browse, update and delete reports
    home/      dashboard
    staff/     staff desk
    account/   profile and settings
```

Each feature is split into `domain` (models), `data` (Firebase calls), `application` (Riverpod state) and `presentation` (screens).

## How to run

**Requirements:** Flutter 3.47 or newer, and an Android emulator or a physical Android phone.

```bash
git clone https://github.com/EucTech/campus_incident_reporting_app.git
cd campus_incident_reporting_app
git checkout feature/campus-incident-app
flutter pub get
flutter run
```

The app is already connected to its Firebase project and Cloudinary account, so no extra setup is needed.

## Try it

1. On the welcome screen, tap **Run a school? Register it on Pulse**, then enter the school name, its student email domain (for example `students.school.com`) and your admin details.
2. Open the verification link sent to your email. It works on any device, and the app moves on by itself.
3. Sign up as a student with an email on that domain.
4. As the admin, invite a staff email from **Account → Manage team**, then sign up with that email.

## Tests

```bash
flutter test
```
