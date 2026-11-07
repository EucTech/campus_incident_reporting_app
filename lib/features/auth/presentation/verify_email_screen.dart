import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/failure.dart';
import '../../../core/widgets/pulse_rings.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_views.dart';
import '../application/auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _resendWait = 30;

  Timer? _poll;
  Timer? _tick;
  int _cooldown = _resendWait;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown = _resendWait;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) timer.cancel();
      setState(() => _cooldown--);
    });
  }

  Future<void> _check() async {
    try {
      await ref.read(authRepositoryProvider).refreshVerification();
    } on Exception catch (_) {
      return;
    }
  }

  Future<void> _resend() async {
    final done = await ref.read(authControllerProvider.notifier).resendVerification();
    if (!mounted) return;
    if (done) setState(_startCooldown);
    showMessage(
      context,
      done ? 'Verification email sent.' : friendlyError(ref.read(authControllerProvider).error!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final email = ref.watch(authUserProvider).value?.email ?? 'your inbox';
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
                  size: 200,
                  color: p.signalText,
                  child: Icon(Icons.mark_email_unread_outlined, size: 34, color: p.ink),
                ),
              ),
              const SizedBox(height: 28),
              Text('Check your\nALU inbox.', style: context.text.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to $email. This screen moves on by itself once you open it.',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(color: p.muted),
              ),
              const Spacer(),
              PillButton(
                label: _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend email',
                onPressed: _cooldown > 0 ? null : _resend,
              ),
              const SizedBox(height: 10),
              PillButton(
                label: 'Use another account',
                style: PillStyle.outline,
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}
