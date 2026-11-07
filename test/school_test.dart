import 'package:campus_incident_reporting_app/features/auth/domain/app_user.dart';
import 'package:campus_incident_reporting_app/features/schools/domain/school.dart';
import 'package:flutter_test/flutter_test.dart';

School _school(String id, {SchoolStatus status = SchoolStatus.approved}) =>
    School(id: id, name: 'School $id', studentDomains: const [], status: status, adminUid: 'admin');

void main() {
  test('a staff invite wins over a student match at the same school', () {
    final options = mergeJoinOptions(invitedTo: [_school('one')], domainSchool: _school('one'));

    expect(options, hasLength(1));
    expect(options.single.role, UserRole.staff);
  });

  test('invites from several schools and a domain match are all offered', () {
    final options = mergeJoinOptions(invitedTo: [_school('a'), _school('b')], domainSchool: _school('c'));

    expect(options.map((option) => '${option.school.id}:${option.role.name}'), ['a:staff', 'b:staff', 'c:student']);
  });

  test('schools waiting for approval are never offered', () {
    final pending = _school('new', status: SchoolStatus.pending);

    expect(mergeJoinOptions(invitedTo: [pending], domainSchool: pending), isEmpty);
  });

  test('roles read safely from stored profiles', () {
    final admin = AppUser.fromMap('u', {'role': 'admin', 'schoolId': 'one'});
    final unknown = AppUser.fromMap('u', {'role': 'superuser'});

    expect(admin.isStaff, isTrue);
    expect(admin.isAdmin, isTrue);
    expect(admin.hasSchool, isTrue);
    expect(unknown.role, UserRole.none);
    expect(unknown.hasSchool, isFalse);
  });
}
