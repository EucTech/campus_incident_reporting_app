import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/route_guard.dart';
import '../../../core/router/session_stage.dart';
import '../../../core/services/image_uploader.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../schools/application/school_providers.dart';
import '../data/incident_repository.dart';
import '../domain/incident.dart';
import '../domain/incident_enums.dart';
import '../domain/incident_filter.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => IncidentRepository(FirebaseFirestore.instance, ref.watch(imageUploaderProvider)),
);

final incidentsProvider = StreamProvider<List<Incident>>((ref) {
  final schoolId = ref.watch(currentSchoolIdProvider);
  if (schoolId == null || ref.watch(sessionStageProvider) != SessionStage.ready) return Stream.value(const []);
  return ref.watch(incidentRepositoryProvider).watchAll(schoolId);
});

final incidentByIdProvider = Provider.family<AsyncValue<Incident?>, String>((ref, id) {
  return ref.watch(incidentsProvider).whenData((incidents) {
    for (final incident in incidents) {
      if (incident.id == id) return incident;
    }
    return null;
  });
});

final incidentFilterProvider = NotifierProvider<IncidentFilterController, IncidentFilter>(IncidentFilterController.new);

class IncidentFilterController extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() => const IncidentFilter();

  void setQuery(String query) => state = state.copyWith(query: query);
  void setStatus(IncidentStatus? status) => state = state.copyWith(status: () => status);
  void setCategory(IncidentCategory? category) => state = state.copyWith(category: () => category);
  void setMineOnly(bool mineOnly) => state = state.copyWith(mineOnly: mineOnly);
  void showCategory(IncidentCategory category) => state = IncidentFilter(category: category);
  void clear() => state = const IncidentFilter();
}

final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  final uid = ref.watch(currentUidProvider);
  return ref.watch(incidentsProvider).whenData((incidents) => filter.apply(incidents, uid));
});

class CampusStats {
  const CampusStats({
    this.total = 0,
    this.open = 0,
    this.urgent = 0,
    this.resolved = 0,
    this.mine = 0,
    this.mineOpen = 0,
    this.mineResolved = 0,
  });

  final int total;
  final int open;
  final int urgent;
  final int resolved;
  final int mine;
  final int mineOpen;
  final int mineResolved;
}

final campusStatsProvider = Provider<CampusStats>((ref) {
  final uid = ref.watch(currentUidProvider);
  final incidents = ref.watch(incidentsProvider).value ?? const <Incident>[];
  final mine = incidents.where((incident) => incident.isOwnedBy(uid));
  final open = incidents.where((incident) => incident.status.isOpen);
  return CampusStats(
    total: incidents.length,
    open: open.length,
    urgent: open.where((incident) => incident.severity == IncidentSeverity.high).length,
    resolved: incidents.where((incident) => incident.status == IncidentStatus.resolved).length,
    mine: mine.length,
    mineOpen: mine.where((incident) => incident.status.isOpen).length,
    mineResolved: mine.where((incident) => incident.status == IncidentStatus.resolved).length,
  );
});

final deskStatusProvider = NotifierProvider<DeskStatusController, IncidentStatus>(DeskStatusController.new);

class DeskStatusController extends Notifier<IncidentStatus> {
  @override
  IncidentStatus build() => IncidentStatus.submitted;

  void select(IncidentStatus status) => state = status;
}

final deskQueueProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final status = ref.watch(deskStatusProvider);
  return ref
      .watch(incidentsProvider)
      .whenData((incidents) => staffQueue(incidents.where((incident) => incident.status == status).toList()));
});

final incidentControllerProvider = AsyncNotifierProvider<IncidentController, void>(IncidentController.new);

class IncidentController extends AsyncNotifier<void> {
  @override
  void build() {}

  IncidentRepository get _repository => ref.read(incidentRepositoryProvider);

  AppUser _requireProfile() {
    final profile = ref.read(profileProvider).value;
    if (profile == null) throw StateError('Profile is not loaded');
    return profile;
  }

  String get _schoolId => _requireProfile().schoolId!;

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<String?> submit(IncidentDraft draft, File? photo) async {
    String? id;
    final done = await _run(() async {
      id = await _repository.create(schoolId: _schoolId, draft: draft, reporter: _requireProfile(), photo: photo);
    });
    return done ? id : null;
  }

  Future<bool> edit(Incident incident, IncidentDraft draft, File? photo, {bool removePhoto = false}) => _run(
    () => _repository.update(
      schoolId: _schoolId,
      incident: incident,
      draft: draft,
      photo: photo,
      removePhoto: removePhoto,
    ),
  );

  Future<bool> remove(Incident incident) => _run(() => _repository.delete(schoolId: _schoolId, incident: incident));

  Future<bool> setAffected(Incident incident, bool affected) => _run(
    () => _repository.setAffected(
      schoolId: _schoolId,
      incidentId: incident.id,
      uid: _requireProfile().uid,
      affected: affected,
    ),
  );

  Future<bool> changeStatus(Incident incident, IncidentStatus status, String note) => _run(
    () => _repository.changeStatus(
      schoolId: _schoolId,
      incident: incident,
      status: status,
      note: note,
      actorName: _requireProfile().name,
    ),
  );
}
