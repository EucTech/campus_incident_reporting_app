import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/account/presentation/edit_profile_screen.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/incidents/application/incident_providers.dart';
import '../../features/incidents/presentation/incident_detail_screen.dart';
import '../../features/incidents/presentation/report_form_screen.dart';
import '../../features/incidents/presentation/reports_screen.dart';
import '../../features/staff/presentation/staff_desk_screen.dart';
import '../theme/app_palette.dart';
import '../widgets/pulse_rings.dart';
import 'app_shell.dart';
import 'route_guard.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authStageProvider, (_, _) => refresh.value++);
  ref.listen(isStaffProvider, (_, _) => refresh.value++);
  ref.listen(profileProvider, (_, next) {
    if (next.value?.isDeleted ?? false) ref.read(authRepositoryProvider).signOut();
  });

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => guardRoute(
      stage: ref.read(authStageProvider),
      location: state.matchedLocation,
      isStaff: ref.read(isStaffProvider),
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.forgot, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.verify, builder: (_, _) => const VerifyEmailScreen()),
      GoRoute(path: '/report', builder: (_, _) => const ReportFormScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const EditProfileScreen()),
      GoRoute(
        path: '/incident/:id',
        builder: (_, state) => IncidentDetailScreen(incidentId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => _EditReportRoute(incidentId: state.pathParameters['id']!),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          _branch(Routes.home, const HomeScreen()),
          _branch('/reports', const ReportsScreen()),
          _branch(Routes.desk, const StaffDeskScreen()),
          _branch('/account', const AccountScreen()),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);

class _EditReportRoute extends ConsumerWidget {
  const _EditReportRoute({required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.read(incidentByIdProvider(incidentId)).value;
    if (incident == null) return const _SplashScreen();
    return ReportFormScreen(existing: incident);
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Center(
        child: PulseRings(
          size: 220,
          color: p.signalText,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
