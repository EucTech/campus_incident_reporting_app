import 'package:campus_incident_reporting_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts real email shapes and rejects broken ones', () {
    expect(Validators.email('a.student@students.school.com'), isNull);
    expect(Validators.email('someone+staff@gmail.com'), isNull);
    expect(Validators.email('@school.com'), isNotNull);
    expect(Validators.email('a@b'), isNotNull);
    expect(Validators.email(''), isNotNull);
  });

  test('reads the email domain in lower case', () {
    expect(Validators.emailDomain('Amara@Students.School.com'), 'students.school.com');
  });

  test('school domains must be real and not public mail providers', () {
    expect(Validators.studentDomain('students.school.com'), isNull);
    expect(Validators.studentDomain('@Students.School.com'), isNull);
    expect(Validators.studentDomain('gmail.com'), isNotNull);
    expect(Validators.studentDomain('not a domain'), isNotNull);
    expect(Validators.studentDomain('localhost'), isNotNull);
  });

  test('password needs length and a number', () {
    expect(Validators.password('short1'), isNotNull);
    expect(Validators.password('longenough'), isNotNull);
    expect(Validators.password('longenough1'), isNull);
  });

  test('report fields enforce the same limits as the security rules', () {
    expect(Validators.title('Leak'), isNotNull);
    expect(Validators.title('Leak in lab'), isNull);
    expect(Validators.title('x' * 81), isNotNull);
    expect(Validators.description('Too short'), isNotNull);
    expect(Validators.description('The tap has been leaking all day'), isNull);
    expect(Validators.location(' '), isNotNull);
    expect(Validators.location('Library'), isNull);
  });
}
