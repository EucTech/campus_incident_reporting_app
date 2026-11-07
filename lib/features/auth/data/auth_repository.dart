import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/image_uploader.dart';
import '../../../core/utils/failure.dart';
import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db, this._uploader);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final ImageUploader _uploader;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  Stream<User?> userChanges() => _auth.userChanges();

  Stream<bool> verifiedTokenChanges() => _auth.idTokenChanges().asyncMap(
    (user) async => user != null && (await user.getIdTokenResult()).claims?['email_verified'] == true,
  );

  Stream<AppUser?> watchProfile(String uid) =>
      _userDoc(uid).snapshots().map((snapshot) => snapshot.exists ? AppUser.fromMap(uid, snapshot.data()!) : null);

  Future<User> createAccount({required String name, required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    return user;
  }

  Future<void> createProfile(User user, String name) => _userDoc(user.uid).set({
    'name': name.trim(),
    'email': user.email!.toLowerCase(),
    'role': UserRole.none.name,
    'schoolId': null,
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<void> discardNewAccount() async => _auth.currentUser?.delete();

  Future<void> sendVerification() async => _auth.currentUser?.sendEmailVerification();

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    final user = credential.user!;
    final profile = await _userDoc(user.uid).get();
    if (!profile.exists) {
      await createProfile(user, user.displayName ?? 'Pulse member');
      return;
    }
    if (profile.data()?['deletedAt'] != null) {
      await _auth.signOut();
      throw const AccountDeleted();
    }
    final currentEmail = user.email!.toLowerCase();
    if (profile.data()?['email'] != currentEmail) await _userDoc(user.uid).update({'email': currentEmail});
  }

  // Firestore only trusts the token, so a fresh one is issued once the account reports verified.
  Future<bool> refreshVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    if (verified) await _auth.currentUser?.getIdToken(true);
    return verified;
  }

  Future<void> updateProfile({
    required AppUser profile,
    required String name,
    File? photo,
    bool removePhoto = false,
  }) async {
    final changes = <String, dynamic>{'name': name.trim()};
    if (photo != null) {
      final image = await _uploader.upload(photo);
      changes['photoUrl'] = image.url;
      changes['photoPath'] = image.id;
    } else if (removePhoto) {
      changes['photoUrl'] = null;
      changes['photoPath'] = null;
    }
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _userDoc(profile.uid).update(changes);
  }

  Future<User> _confirmPassword(String password) async {
    final user = _auth.currentUser!;
    await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: user.email!, password: password));
    return user;
  }

  Future<void> requestEmailChange({required String newEmail, required String password}) async {
    final user = await _confirmPassword(password);
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  Future<void> changePassword({required String current, required String next}) async {
    final user = await _confirmPassword(current);
    await user.updatePassword(next);
  }

  // Soft delete keeps the Auth user and profile so an admin can restore the account.
  Future<void> softDeleteAccount(String password) async {
    final user = await _confirmPassword(password);
    await _userDoc(user.uid).update({'deletedAt': FieldValue.serverTimestamp()});
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();
}
