import 'package:campus_incident_reporting_app/core/router/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? guard(SessionStage stage, String location, {bool isStaff = false, bool isAdmin = false}) =>
      guardRoute(stage: stage, location: location, isStaff: isStaff, isAdmin: isAdmin);

  test('signed out users only reach public routes', () {
    expect(guard(SessionStage.signedOut, '/home'), Routes.welcome);
    expect(guard(SessionStage.signedOut, '/incident/1'), Routes.welcome);
    expect(guard(SessionStage.signedOut, Routes.login), isNull);
    expect(guard(SessionStage.signedOut, Routes.registerSchool), isNull);
  });

  test('loading never shows a screen with half loaded data', () {
    expect(guard(SessionStage.loading, '/home'), Routes.splash);
    expect(guard(SessionStage.loading, Routes.splash), isNull);
  });

  test('each onboarding step holds the user on its own screen', () {
    expect(guard(SessionStage.unverified, '/home'), Routes.verify);
    expect(guard(SessionStage.unverified, Routes.verify), isNull);
    expect(guard(SessionStage.needsSchool, '/reports'), Routes.join);
    expect(guard(SessionStage.needsSchool, Routes.join), isNull);
  });

  test('ready users skip entry and holding screens', () {
    expect(guard(SessionStage.ready, Routes.login), Routes.home);
    expect(guard(SessionStage.ready, Routes.join), Routes.home);
    expect(guard(SessionStage.ready, '/reports'), isNull);
  });

  test('only staff reach the desk and only admins reach the team', () {
    expect(guard(SessionStage.ready, Routes.desk), Routes.home);
    expect(guard(SessionStage.ready, Routes.desk, isStaff: true), isNull);
    expect(guard(SessionStage.ready, Routes.team, isStaff: true), Routes.home);
    expect(guard(SessionStage.ready, Routes.team, isStaff: true, isAdmin: true), isNull);
  });
}
