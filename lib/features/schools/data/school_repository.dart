import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../auth/domain/app_user.dart';
import '../domain/school.dart';

class SchoolRepository {
  SchoolRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _schools => _db.collection('schools');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  DocumentReference<Map<String, dynamic>> _domain(String domain) => _db.collection('domains').doc(domain);
  CollectionReference<Map<String, dynamic>> _invites(String schoolId) => _schools.doc(schoolId).collection('invites');

  Stream<School?> watchSchool(String schoolId) => _schools
      .doc(schoolId)
      .snapshots()
      .map((snapshot) => snapshot.exists ? School.fromMap(snapshot.id, snapshot.data()!) : null);

  Future<School?> _fetchSchool(String schoolId) async {
    final snapshot = await _schools.doc(schoolId).get();
    return snapshot.exists ? School.fromMap(snapshot.id, snapshot.data()!) : null;
  }

  Future<List<JoinOption>> findJoinOptions(String email) async {
    final address = email.trim().toLowerCase();
    final invites = await _db.collectionGroup('invites').where('email', isEqualTo: address).get();
    final invitedTo = <School>[];
    for (final invite in invites.docs) {
      if (invite.data()['status'] != InviteStatus.pending.name) continue;
      final school = await _fetchSchool(invite.reference.parent.parent!.id);
      if (school != null) invitedTo.add(school);
    }
    final domainSchoolId = (await _domain(Validators.emailDomain(address)).get()).data()?['schoolId'];
    final domainSchool = domainSchoolId is String ? await _fetchSchool(domainSchoolId) : null;
    return mergeJoinOptions(invitedTo: invitedTo, domainSchool: domainSchool);
  }

  Future<bool> isDomainTaken(String domain) async => (await _domain(domain).get()).exists;

  Future<void> join({required String uid, required String email, required JoinOption option}) {
    final batch = _db.batch()..update(_users.doc(uid), {'schoolId': option.school.id, 'role': option.role.name});
    if (option.role == UserRole.staff) {
      batch.update(_invites(option.school.id).doc(email.toLowerCase()), {
        'status': InviteStatus.accepted.name,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    }
    return batch.commit();
  }

  Future<void> registerSchool({
    required String uid,
    required String adminEmail,
    required String name,
    required String domain,
  }) {
    final school = _schools.doc();
    return (_db.batch()
          ..set(school, {
            'name': name.trim(),
            'studentDomains': [domain],
            'status': SchoolStatus.approved.name,
            'adminUid': uid,
            'adminEmail': adminEmail.toLowerCase(),
            'createdAt': FieldValue.serverTimestamp(),
          })
          ..set(_domain(domain), {'schoolId': school.id})
          ..update(_users.doc(uid), {'schoolId': school.id, 'role': UserRole.admin.name}))
        .commit();
  }

  Stream<List<StaffInvite>> watchPendingInvites(String schoolId) =>
      _invites(schoolId)
          .where('status', isEqualTo: InviteStatus.pending.name)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => StaffInvite.fromMap(doc.data())).toList());

  Stream<List<AppUser>> watchTeam(String schoolId) => _users
      .where('schoolId', isEqualTo: schoolId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).where((user) => user.isStaff).toList(),
      );

  Future<void> invite({required String schoolId, required String email, required String invitedBy}) async {
    final address = email.trim().toLowerCase();
    final reference = _invites(schoolId).doc(address);
    if ((await reference.get()).exists) throw const AlreadyInvited();
    await reference.set({
      'email': address,
      'role': UserRole.staff.name,
      'status': InviteStatus.pending.name,
      'invitedBy': invitedBy,
      'invitedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelInvite({required String schoolId, required String email}) =>
      _invites(schoolId).doc(email).delete();

  Future<void> removeStaff({required String schoolId, required AppUser member}) =>
      (_db.batch()
            ..update(_users.doc(member.uid), {'schoolId': null, 'role': UserRole.none.name})
            ..delete(_invites(schoolId).doc(member.email.toLowerCase())))
          .commit();
}
