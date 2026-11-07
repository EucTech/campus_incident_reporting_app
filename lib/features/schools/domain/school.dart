import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/app_user.dart';

enum SchoolStatus {
  pending,
  approved,
  rejected;

  static SchoolStatus parse(String? value) => values.firstWhere((item) => item.name == value, orElse: () => pending);
}

class School {
  const School({
    required this.id,
    required this.name,
    required this.studentDomains,
    required this.status,
    required this.adminUid,
  });

  final String id;
  final String name;
  final List<String> studentDomains;
  final SchoolStatus status;
  final String adminUid;

  bool get isApproved => status == SchoolStatus.approved;

  factory School.fromMap(String id, Map<String, dynamic> map) => School(
    id: id,
    name: map['name'] as String? ?? '',
    studentDomains: List<String>.from(map['studentDomains'] as List? ?? const []),
    status: SchoolStatus.parse(map['status'] as String?),
    adminUid: map['adminUid'] as String? ?? '',
  );
}

class JoinOption {
  const JoinOption({required this.school, required this.role});

  final School school;
  final UserRole role;
}

enum InviteStatus { pending, accepted }

class StaffInvite {
  const StaffInvite({required this.email, required this.status, required this.invitedAt});

  final String email;
  final InviteStatus status;
  final DateTime invitedAt;

  factory StaffInvite.fromMap(Map<String, dynamic> map) => StaffInvite(
    email: map['email'] as String? ?? '',
    status: map['status'] == InviteStatus.accepted.name ? InviteStatus.accepted : InviteStatus.pending,
    invitedAt: (map['invitedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

List<JoinOption> mergeJoinOptions({required List<School> invitedTo, School? domainSchool}) {
  final options = [
    for (final school in invitedTo)
      if (school.isApproved) JoinOption(school: school, role: UserRole.staff),
  ];
  final student = domainSchool;
  if (student != null && student.isApproved && !options.any((option) => option.school.id == student.id)) {
    options.add(JoinOption(school: student, role: UserRole.student));
  }
  return options;
}
