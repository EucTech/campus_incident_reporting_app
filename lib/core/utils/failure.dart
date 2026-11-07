import 'package:firebase_core/firebase_core.dart';

String friendlyError(Object error) {
  if (error is NotAluEmail) return error.message;
  if (error is AccountDeleted) return error.message;
  if (error is! FirebaseException) return 'Something went wrong. Please try again.';
  return switch (error.code) {
    'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-login-credentials' =>
      'That email and password do not match.',
    'email-already-in-use' => 'An account already exists for this email. Try logging in.',
    'weak-password' => 'Choose a stronger password.',
    'user-token-expired' || 'requires-recent-login' || 'user-mismatch' =>
      'Your session expired. Log in again.',
    'invalid-email' => 'That email address is not valid.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'user-disabled' => 'This account has been disabled.',
    'network-request-failed' || 'unavailable' => 'No connection. Check your network and try again.',
    'permission-denied' || 'unauthorized' => 'You do not have permission to do that.',
    _ => error.message ?? 'Something went wrong. Please try again.',
  };
}

class AccountDeleted implements Exception {
  const AccountDeleted();
  String get message => 'This account was deleted. Contact campus support to restore it.';
}

class NotAluEmail implements Exception {
  const NotAluEmail();
  String get message => 'Only ALU email addresses can use Pulse.';
}
