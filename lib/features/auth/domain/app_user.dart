enum UserRole {
  none('No school'),
  student('Student'),
  staff('Staff'),
  admin('School admin');

  const UserRole(this.label);

  final String label;

  static UserRole parse(String? value) => values.firstWhere((role) => role.name == value, orElse: () => none);
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.photoUrl,
    this.photoPath,
    this.isDeleted = false,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? schoolId;
  final String? photoUrl;
  final String? photoPath;
  final bool isDeleted;

  bool get isStaff => role == UserRole.staff || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;
  bool get hasSchool => schoolId != null && role != UserRole.none;
  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters = parts.length == 1 ? parts.first[0] : parts.first[0] + parts.last[0];
    return letters.toUpperCase();
  }

  AppUser withoutPhoto() => AppUser(uid: uid, name: name, email: email, role: role, schoolId: schoolId);

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    role: UserRole.parse(map['role'] as String?),
    schoolId: map['schoolId'] as String?,
    photoUrl: map['photoUrl'] as String?,
    photoPath: map['photoPath'] as String?,
    isDeleted: map['deletedAt'] != null,
  );
}
