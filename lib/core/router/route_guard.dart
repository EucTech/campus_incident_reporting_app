import '../../features/auth/application/auth_providers.dart';

abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot';
  static const verify = '/verify';
  static const home = '/home';
  static const desk = '/desk';
  static const publicRoutes = {welcome, login, register, forgot};
}

String? guardRoute({required AuthStage stage, required String location, required bool isStaff}) {
  switch (stage) {
    case AuthStage.loading:
      return location == Routes.splash ? null : Routes.splash;
    case AuthStage.signedOut:
      return Routes.publicRoutes.contains(location) ? null : Routes.welcome;
    case AuthStage.unverified:
      return location == Routes.verify ? null : Routes.verify;
    case AuthStage.ready:
      final isEntryRoute =
          location == Routes.splash || location == Routes.verify || Routes.publicRoutes.contains(location);
      if (isEntryRoute) return Routes.home;
      if (location.startsWith(Routes.desk) && !isStaff) return Routes.home;
      return null;
  }
}
