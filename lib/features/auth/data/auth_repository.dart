import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db, this._storage);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  Stream<User?> userChanges() => _auth.userChanges();

  Stream<AppUser?> watchProfile(String uid) => _userDoc(uid).snapshots().map(
        (snapshot) => snapshot.exists ? AppUser.fromMap(uid, snapshot.data()!) : null,
      );

  Future<void> register({required String name, required String email, required String password}) async {
    if (!Validators.isAluEmail(email)) throw const NotAluEmail();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    await _createProfile(user, name.trim());
    await user.sendEmailVerification();
  }

  Future<void> signIn({required String email, required String password}) async {
    if (!Validators.isAluEmail(email)) throw const NotAluEmail();
    final credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    final user = credential.user!;
    final profile = await _userDoc(user.uid).get();
    if (!profile.exists) {
      await _createProfile(user, user.displayName ?? 'ALU member');
      return;
    }
    if (profile.data()?['deletedAt'] != null) {
      await _auth.signOut();
      throw const AccountDeleted();
    }
    if (profile.data()?['email'] != user.email) await _userDoc(user.uid).update({'email': user.email});
  }

  Future<void> _createProfile(User user, String name) => _userDoc(user.uid).set({
        'name': name,
        'email': user.email,
        'role': UserRole.student.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> resendVerification() async => _auth.currentUser?.sendEmailVerification();

  // The token refreshes before reload so Firestore sees the verified claim first.
  Future<bool> refreshVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.getIdToken(true);
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> updateProfile({
    required AppUser profile,
    required String name,
    File? photo,
    bool removePhoto = false,
  }) async {
    final changes = <String, dynamic>{'name': name.trim()};
    if (photo != null) {
      final path = 'avatars/${profile.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final reference = _storage.ref(path);
      await reference.putFile(photo, SettableMetadata(contentType: 'image/jpeg'));
      changes['photoUrl'] = await reference.getDownloadURL();
      changes['photoPath'] = path;
    } else if (removePhoto) {
      changes['photoUrl'] = null;
      changes['photoPath'] = null;
    }
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _userDoc(profile.uid).update(changes);
    if (changes.containsKey('photoPath') && profile.photoPath != null) {
      await _storage.ref(profile.photoPath).delete().catchError((Object _) {});
    }
  }

  Future<User> _confirmPassword(String password) async {
    final user = _auth.currentUser!;
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
    return user;
  }

  Future<void> requestEmailChange({required String newEmail, required String password}) async {
    if (!Validators.isAluEmail(newEmail)) throw const NotAluEmail();
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
