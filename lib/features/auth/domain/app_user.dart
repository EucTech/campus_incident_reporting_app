enum UserRole { student, staff }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    this.photoPath,
    this.isDeleted = false,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final String? photoPath;
  final bool isDeleted;

  bool get isStaff => role == UserRole.staff;
  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final letters = parts.length == 1 ? parts.first[0] : parts.first[0] + parts.last[0];
    return letters.toUpperCase();
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    role: map['role'] == UserRole.staff.name ? UserRole.staff : UserRole.student,
    photoUrl: map['photoUrl'] as String?,
    photoPath: map['photoPath'] as String?,
    isDeleted: map['deletedAt'] != null,
  );
}
