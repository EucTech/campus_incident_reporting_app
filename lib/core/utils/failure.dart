import 'package:firebase_core/firebase_core.dart';

abstract class AppException implements Exception {
  const AppException();

  String get message;
}

String friendlyError(Object error) {
  if (error is AppException) return error.message;
  if (error is! FirebaseException) return 'Something went wrong. Please try again.';
  return switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-login-credentials' => 'That email and password do not match.',
    'email-already-in-use' => 'An account already exists for this email. Try logging in.',
    'weak-password' => 'Choose a stronger password.',
    'user-token-expired' || 'requires-recent-login' || 'user-mismatch' => 'Your session expired. Log in again.',
    'invalid-email' => 'That email address is not valid.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'user-disabled' => 'This account has been disabled.',
    'network-request-failed' || 'unavailable' => 'No connection. Check your network and try again.',
    'permission-denied' || 'unauthorized' => 'You do not have permission to do that.',
    _ => error.message ?? 'Something went wrong. Please try again.',
  };
}

class AccountDeleted extends AppException {
  const AccountDeleted();

  @override
  String get message => 'This account was deleted. Contact your school admin to restore it.';
}

class NoSchoolForEmail extends AppException {
  const NoSchoolForEmail();

  @override
  String get message =>
      'No school on Pulse uses this email. Students sign up with their school email, and staff need an invite from their school admin.';
}

class DomainTaken extends AppException {
  const DomainTaken();

  @override
  String get message => 'A school on Pulse already uses this email domain.';
}

class AlreadyInvited extends AppException {
  const AlreadyInvited();

  @override
  String get message => 'This email has already been invited.';
}

class SchoolEmailRequired extends AppException {
  const SchoolEmailRequired();

  @override
  String get message => 'Students must keep an email from their school domain.';
}
