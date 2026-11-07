import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../data/school_repository.dart';
import '../domain/school.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) => SchoolRepository(FirebaseFirestore.instance));

final currentSchoolIdProvider = Provider<String?>((ref) => ref.watch(profileProvider).value?.schoolId);

final currentSchoolProvider = StreamProvider<School?>((ref) {
  final schoolId = ref.watch(currentSchoolIdProvider);
  if (schoolId == null) return Stream.value(null);
  return ref.watch(schoolRepositoryProvider).watchSchool(schoolId);
});

final joinOptionsProvider = FutureProvider.autoDispose<List<JoinOption>>((ref) async {
  final email = ref.watch(authUserProvider).value?.email;
  if (email == null) return const [];
  return ref.watch(schoolRepositoryProvider).findJoinOptions(email);
});

final pendingInvitesProvider = StreamProvider.autoDispose<List<StaffInvite>>((ref) {
  final schoolId = ref.watch(currentSchoolIdProvider);
  if (schoolId == null || !ref.watch(isAdminProvider)) return Stream.value(const []);
  return ref.watch(schoolRepositoryProvider).watchPendingInvites(schoolId);
});

final teamProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  final schoolId = ref.watch(currentSchoolIdProvider);
  if (schoolId == null || !ref.watch(isAdminProvider)) return Stream.value(const []);
  return ref.watch(schoolRepositoryProvider).watchTeam(schoolId);
});

final onboardingControllerProvider = AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<void> {
  @override
  void build() {}

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  SchoolRepository get _schools => ref.read(schoolRepositoryProvider);

  Object get lastError => state.error ?? StateError('Unknown error');

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> registerMember({required String name, required String email, required String password}) =>
      _run(() async {
        final user = await _auth.createAccount(name: name, email: email, password: password);
        final options = await _schools.findJoinOptions(user.email!);
        if (options.isEmpty) {
          await _auth.discardNewAccount();
          throw const NoSchoolForEmail();
        }
        await _auth.createProfile(user, name);
        if (options.length == 1) await _schools.join(uid: user.uid, email: user.email!, option: options.single);
        await _auth.sendVerification();
      });

  Future<bool> registerSchool({
    required String adminName,
    required String email,
    required String password,
    required String schoolName,
    required String domain,
  }) => _run(() async {
    final cleanDomain = Validators.normalizeDomain(domain);
    final user = await _auth.createAccount(name: adminName, email: email, password: password);
    if (await _schools.isDomainTaken(cleanDomain)) {
      await _auth.discardNewAccount();
      throw const DomainTaken();
    }
    await _auth.createProfile(user, adminName);
    await _schools.registerSchool(uid: user.uid, adminEmail: user.email!, name: schoolName, domain: cleanDomain);
    await _auth.sendVerification();
  });

  Future<bool> join(JoinOption option) => _run(() async {
    final profile = ref.read(profileProvider).value!;
    await _schools.join(uid: profile.uid, email: profile.email, option: option);
  });
}

final teamControllerProvider = AsyncNotifierProvider<TeamController, void>(TeamController.new);

class TeamController extends AsyncNotifier<void> {
  @override
  void build() {}

  SchoolRepository get _schools => ref.read(schoolRepositoryProvider);
  String get _schoolId => ref.read(currentSchoolIdProvider)!;

  Object get lastError => state.error ?? StateError('Unknown error');

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> invite(String email) =>
      _run(() => _schools.invite(schoolId: _schoolId, email: email, invitedBy: ref.read(profileProvider).value!.name));

  Future<bool> cancelInvite(String email) => _run(() => _schools.cancelInvite(schoolId: _schoolId, email: email));

  Future<bool> removeStaff(AppUser member) => _run(() => _schools.removeStaff(schoolId: _schoolId, member: member));
}

String inviteMessage({required String schoolName, required String email}) =>
    'You have been invited to join $schoolName on Pulse as staff. Download Pulse and sign up with $email.';
