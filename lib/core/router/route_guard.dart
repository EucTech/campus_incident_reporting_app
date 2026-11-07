enum SessionStage { loading, signedOut, unverified, needsSchool, ready }

abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const registerSchool = '/register-school';
  static const forgot = '/forgot';
  static const verify = '/verify';
  static const join = '/join';
  static const home = '/home';
  static const desk = '/desk';
  static const team = '/team';
  static const publicRoutes = {welcome, login, register, registerSchool, forgot};
  static const holdingRoutes = {splash, verify, join};
}

String? guardRoute({
  required SessionStage stage,
  required String location,
  required bool isStaff,
  required bool isAdmin,
}) {
  String? holdAt(String route) => location == route ? null : route;

  switch (stage) {
    case SessionStage.loading:
      return holdAt(Routes.splash);
    case SessionStage.signedOut:
      return Routes.publicRoutes.contains(location) ? null : Routes.welcome;
    case SessionStage.unverified:
      return holdAt(Routes.verify);
    case SessionStage.needsSchool:
      return holdAt(Routes.join);
    case SessionStage.ready:
      if (Routes.publicRoutes.contains(location) || Routes.holdingRoutes.contains(location)) return Routes.home;
      if (location.startsWith(Routes.desk) && !isStaff) return Routes.home;
      if (location.startsWith(Routes.team) && !isAdmin) return Routes.home;
      return null;
  }
}
