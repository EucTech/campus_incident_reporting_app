import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/image_uploader.dart';
import '../../auth/domain/app_user.dart';
import '../domain/incident.dart';
import '../domain/incident_enums.dart';

class IncidentRepository {
  IncidentRepository(this._db, this._uploader);

  final FirebaseFirestore _db;
  final ImageUploader _uploader;

  static const _feedLimit = 300;

  CollectionReference<Map<String, dynamic>> _incidents(String schoolId) =>
      _db.collection('schools').doc(schoolId).collection('incidents');

  Stream<List<Incident>> watchAll(String schoolId) =>
      _incidents(schoolId)
          .orderBy('createdAt', descending: true)
          .limit(_feedLimit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Incident.fromMap(doc.id, doc.data())).toList());

  Future<String> create({
    required String schoolId,
    required IncidentDraft draft,
    required AppUser reporter,
    File? photo,
  }) async {
    final doc = _incidents(schoolId).doc();
    final image = photo == null ? null : await _uploader.upload(photo);
    final displayName = draft.anonymous ? null : reporter.name;
    await doc.set({
      ...draft.toMap(),
      'status': IncidentStatus.submitted.name,
      'reporterId': reporter.uid,
      'reporterName': displayName,
      'imageUrl': image?.url,
      'imagePath': image?.id,
      'affectedBy': <String>[],
      'timeline': [
        TimelineEntry(
          status: IncidentStatus.submitted,
          actorName: displayName ?? 'Anonymous',
          at: DateTime.now(),
        ).toMap(),
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> update({
    required String schoolId,
    required Incident incident,
    required IncidentDraft draft,
    File? photo,
    bool removePhoto = false,
  }) async {
    final replacesPhoto = photo != null || removePhoto;
    final image = photo == null ? null : await _uploader.upload(photo);
    await _incidents(schoolId).doc(incident.id).update({
      ...draft.toMap(),
      if (replacesPhoto) 'imageUrl': image?.url,
      if (replacesPhoto) 'imagePath': image?.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Photos stay in Cloudinary because unsigned clients are not allowed to delete them.
  Future<void> delete({required String schoolId, required Incident incident}) =>
      _incidents(schoolId).doc(incident.id).delete();

  Future<void> setAffected({
    required String schoolId,
    required String incidentId,
    required String uid,
    required bool affected,
  }) => _incidents(schoolId).doc(incidentId).update({
    'affectedBy': affected ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
  });

  Future<void> changeStatus({
    required String schoolId,
    required Incident incident,
    required IncidentStatus status,
    required String note,
    required String actorName,
  }) => _incidents(schoolId).doc(incident.id).update({
    'status': status.name,
    'timeline': FieldValue.arrayUnion([
      TimelineEntry(status: status, actorName: actorName, at: DateTime.now(), note: note.trim()).toMap(),
    ]),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
