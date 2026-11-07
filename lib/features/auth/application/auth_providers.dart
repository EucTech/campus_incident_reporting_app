import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_uploader.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance, ref.watch(imageUploaderProvider)),
);

final authUserProvider = StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).userChanges());

final verifiedTokenProvider = StreamProvider<bool>((ref) => ref.watch(authRepositoryProvider).verifiedTokenChanges());

final currentUidProvider = Provider<String?>((ref) => ref.watch(authUserProvider).value?.uid);

final profileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(uid);
});

final isStaffProvider = Provider<bool>((ref) => ref.watch(profileProvider).value?.isStaff ?? false);

final isAdminProvider = Provider<bool>((ref) => ref.watch(profileProvider).value?.isAdmin ?? false);

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  void build() {}

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Object get lastError => state.error ?? StateError('Unknown error');

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _repository.signIn(email: email, password: password));

  Future<bool> sendPasswordReset(String email) => _run(() => _repository.sendPasswordReset(email));

  Future<bool> resendVerification() => _run(_repository.sendVerification);

  Future<bool> updateProfile({required String name, File? photo, bool removePhoto = false}) => _run(
    () => _repository.updateProfile(
      profile: ref.read(profileProvider).value!,
      name: name,
      photo: photo,
      removePhoto: removePhoto,
    ),
  );

  Future<bool> requestEmailChange(String email, String password) => _run(() async {
    final profile = ref.read(profileProvider).value!;
    final keepsDomain = Validators.emailDomain(email) == Validators.emailDomain(profile.email);
    if (profile.role == UserRole.student && !keepsDomain) throw const SchoolEmailRequired();
    await _repository.requestEmailChange(newEmail: email, password: password);
  });

  Future<bool> changePassword(String current, String next) =>
      _run(() => _repository.changePassword(current: current, next: next));

  Future<bool> deleteAccount(String password) => _run(() => _repository.softDeleteAccount(password));

  Future<void> signOut() => _run(_repository.signOut);
}
