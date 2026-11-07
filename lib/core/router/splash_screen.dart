import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/schools/application/school_providers.dart';
import '../theme/app_palette.dart';
import '../utils/failure.dart';
import '../widgets/pill_button.dart';
import '../widgets/pulse_rings.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _patience = Duration(seconds: 15);

  Timer? _timer;
  bool _slow = false;
  bool _retrying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_patience, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  Future<void> _retry() async {
    setState(() {
      _retrying = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).ensureProfile();
    } on Exception catch (error) {
      _error = friendlyError(error);
    }
    ref
      ..invalidate(verifiedTokenProvider)
      ..invalidate(profileProvider)
      ..invalidate(currentSchoolProvider);
    if (!mounted) return;
    setState(() {
      _retrying = false;
      _slow = _error != null;
    });
    if (_error == null) _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final signedIn = ref.watch(currentUidProvider) != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
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
              const Spacer(),
              if (_slow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Can't reach the server", textAlign: TextAlign.center, style: context.text.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      _error ?? 'This is taking longer than usual. Check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    PillButton(label: 'Try again', loading: _retrying, onPressed: _retry),
                    if (signedIn) ...[
                      const SizedBox(height: 10),
                      PillButton(
                        label: 'Log out',
                        style: PillStyle.outline,
                        onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                      ),
                    ],
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
