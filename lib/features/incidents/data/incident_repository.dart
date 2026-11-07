import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../auth/domain/app_user.dart';
import '../domain/incident.dart';
import '../domain/incident_enums.dart';

class IncidentRepository {
  IncidentRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const _feedLimit = 300;

  CollectionReference<Map<String, dynamic>> get _incidents => _db.collection('incidents');

  Stream<List<Incident>> watchAll() => _incidents
      .orderBy('createdAt', descending: true)
      .limit(_feedLimit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Incident.fromMap(doc.id, doc.data())).toList());

  Future<({String url, String path})> _upload(String uid, String incidentId, File photo) async {
    final path = 'incidents/$uid/$incidentId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final reference = _storage.ref(path);
    await reference.putFile(photo, SettableMetadata(contentType: 'image/jpeg'));
    return (url: await reference.getDownloadURL(), path: path);
  }

  Future<void> _deletePhoto(String? path) async {
    if (path == null) return;
    await _storage.ref(path).delete().catchError((Object _) {});
  }

  Future<String> create({required IncidentDraft draft, required AppUser reporter, File? photo}) async {
    final doc = _incidents.doc();
    final image = photo == null ? null : await _upload(reporter.uid, doc.id, photo);
    final displayName = draft.anonymous ? null : reporter.name;
    await doc.set({
      ...draft.toMap(),
      'status': IncidentStatus.submitted.name,
      'reporterId': reporter.uid,
      'reporterName': displayName,
      'imageUrl': image?.url,
      'imagePath': image?.path,
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
    required Incident incident,
    required IncidentDraft draft,
    File? photo,
    bool removePhoto = false,
  }) async {
    final replacesPhoto = photo != null || removePhoto;
    final image = photo == null ? null : await _upload(incident.reporterId, incident.id, photo);
    await _incidents.doc(incident.id).update({
      ...draft.toMap(),
      if (replacesPhoto) 'imageUrl': image?.url,
      if (replacesPhoto) 'imagePath': image?.path,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (replacesPhoto) await _deletePhoto(incident.imagePath);
  }

  Future<void> delete(Incident incident) async {
    await _incidents.doc(incident.id).delete();
    await _deletePhoto(incident.imagePath);
  }

  Future<void> setAffected({required String incidentId, required String uid, required bool affected}) =>
      _incidents.doc(incidentId).update({
        'affectedBy': affected ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
      });

  Future<void> changeStatus({
    required Incident incident,
    required IncidentStatus status,
    required String note,
    required String actorName,
  }) =>
      _incidents.doc(incident.id).update({
        'status': status.name,
        'timeline': FieldValue.arrayUnion([
          TimelineEntry(status: status, actorName: actorName, at: DateTime.now(), note: note.trim()).toMap(),
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
