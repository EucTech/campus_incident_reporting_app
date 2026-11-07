import 'package:campus_incident_reporting_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ALU email', () {
    test('accepts student and staff domains in any case', () {
      expect(Validators.isAluEmail('a.student@alustudent.com'), isTrue);
      expect(Validators.isAluEmail('Staff.Member@ALUEDUCATION.com'), isTrue);
    });

    test('rejects other domains and lookalikes', () {
      expect(Validators.isAluEmail('someone@gmail.com'), isFalse);
      expect(Validators.isAluEmail('someone@alustudent.com.evil.io'), isFalse);
      expect(Validators.isAluEmail('@alustudent.com'), isFalse);
      expect(Validators.isAluEmail('a@b@alustudent.com'), isFalse);
    });
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
