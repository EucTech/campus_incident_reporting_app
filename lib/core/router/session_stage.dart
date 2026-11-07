import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/schools/application/school_providers.dart';
import 'route_guard.dart';

final sessionStageProvider = Provider<SessionStage>((ref) {
  final auth = ref.watch(authUserProvider);
  if (!auth.hasValue) return SessionStage.loading;
  final user = auth.value;
  if (user == null) return SessionStage.signedOut;
  final verifiedToken = ref.watch(verifiedTokenProvider);
  if (!verifiedToken.hasValue) return SessionStage.loading;
  if (!user.emailVerified || !verifiedToken.value!) return SessionStage.unverified;

  final profile = ref.watch(profileProvider).value;
  if (profile == null || profile.isDeleted) return SessionStage.loading;
  if (!profile.hasSchool) return SessionStage.needsSchool;

  final school = ref.watch(currentSchoolProvider);
  if (!school.hasValue) return SessionStage.loading;
  return school.value?.isApproved ?? false ? SessionStage.ready : SessionStage.needsSchool;
});
