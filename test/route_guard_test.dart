import 'package:campus_incident_reporting_app/core/router/route_guard.dart';
import 'package:campus_incident_reporting_app/features/auth/application/auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? guard(AuthStage stage, String location, {bool isStaff = false}) =>
      guardRoute(stage: stage, location: location, isStaff: isStaff);

  test('signed out users only reach public routes', () {
    expect(guard(AuthStage.signedOut, '/home'), Routes.welcome);
    expect(guard(AuthStage.signedOut, '/incident/1'), Routes.welcome);
    expect(guard(AuthStage.signedOut, '/login'), isNull);
  });

  test('unverified users are held on the verification screen', () {
    expect(guard(AuthStage.unverified, '/home'), Routes.verify);
    expect(guard(AuthStage.unverified, '/report'), Routes.verify);
    expect(guard(AuthStage.unverified, Routes.verify), isNull);
  });

  test('verified users skip the entry routes', () {
    expect(guard(AuthStage.ready, '/login'), Routes.home);
    expect(guard(AuthStage.ready, Routes.verify), Routes.home);
    expect(guard(AuthStage.ready, '/reports'), isNull);
  });

  test('only staff reach the desk', () {
    expect(guard(AuthStage.ready, Routes.desk), Routes.home);
    expect(guard(AuthStage.ready, Routes.desk, isStaff: true), isNull);
  });
}
