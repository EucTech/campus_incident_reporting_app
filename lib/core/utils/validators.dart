abstract final class Validators {
  static const aluDomains = ['alustudent.com', 'alueducation.com'];

  static bool isAluEmail(String email) {
    final parts = email.trim().toLowerCase().split('@');
    return parts.length == 2 && parts.first.isNotEmpty && aluDomains.contains(parts.last);
  }

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Enter your full name';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your ALU email';
    if (!isAluEmail(text)) return 'Use your @alustudent.com or @alueducation.com email';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.length < 8) return 'Use at least 8 characters';
    if (!text.contains(RegExp(r'[0-9]'))) return 'Include at least one number';
    return null;
  }

  static String? requiredPassword(String? value) => (value ?? '').isEmpty ? 'Enter your password' : null;

  static String? title(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 5) return 'Give it a clear title of at least 5 characters';
    if (length > 80) return 'Keep the title under 80 characters';
    return null;
  }

  static String? description(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 15) return 'Add a few more details, at least 15 characters';
    if (length > 1000) return 'Keep the description under 1000 characters';
    return null;
  }

  static String? location(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 2) return 'Tell us where this is';
    if (length > 80) return 'Keep the location under 80 characters';
    return null;
  }
}
