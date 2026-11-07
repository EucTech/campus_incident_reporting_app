abstract final class Validators {
  static const publicDomains = {
    'gmail.com',
    'googlemail.com',
    'yahoo.com',
    'ymail.com',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'icloud.com',
    'aol.com',
    'proton.me',
    'protonmail.com',
  };

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _domainPattern = RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$');

  static bool isEmail(String value) => _emailPattern.hasMatch(value.trim());

  static String emailDomain(String email) => email.trim().toLowerCase().split('@').last;

  static String normalizeDomain(String value) {
    final text = value.trim().toLowerCase();
    return text.startsWith('@') ? text.substring(1) : text;
  }

  static bool isPublicDomain(String domain) => publicDomains.contains(normalizeDomain(domain));

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Enter your full name';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email';
    if (!isEmail(text)) return 'Enter a valid email address';
    return null;
  }

  static String? schoolName(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 2) return 'Enter the school name';
    if (length > 80) return 'Keep the name under 80 characters';
    return null;
  }

  static String? studentDomain(String? value) {
    final domain = normalizeDomain(value ?? '');
    if (!_domainPattern.hasMatch(domain)) return 'Enter a domain like students.school.com';
    if (isPublicDomain(domain)) return 'Use your school domain, not a public one like gmail.com';
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
