import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/failure.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/pulse_rings.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../application/school_providers.dart';
import '../domain/school.dart';

class JoinSchoolScreen extends ConsumerWidget {
  const JoinSchoolScreen({super.key});

  Future<void> _join(WidgetRef ref, JoinOption option) async {
    final controller = ref.read(onboardingControllerProvider.notifier);
    if (!await controller.join(option)) showAppMessage(friendlyError(controller.lastError));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final options = ref.watch(joinOptionsProvider);
    final joining = ref.watch(onboardingControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: options.when(
            loading: () => Center(child: PulseRings(size: 200, color: p.signalText)),
            error: (error, _) => Center(
              child: ErrorView(message: friendlyError(error), onRetry: () => ref.invalidate(joinOptionsProvider)),
            ),
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  items.isEmpty ? 'No school\nfound yet.' : 'Choose your\nschool.',
                  style: context.text.displayMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  items.isEmpty
                      ? 'Students need an email from their school. Staff need an invite from their school admin. Ask them, then check again.'
                      : 'Your email can join these schools. You can belong to one school at a time.',
                  style: context.text.bodyLarge?.copyWith(color: p.muted),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _OptionCard(
                      option: items[index],
                      onTap: joining ? null : () => _join(ref, items[index]),
                    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.1),
                  ),
                ),
                PillButton(
                  label: 'Check again',
                  style: PillStyle.outline,
                  loading: joining,
                  onPressed: () => ref.invalidate(joinOptionsProvider),
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: 'Log out',
                  style: PillStyle.outline,
                  onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option, required this.onTap});

  final JoinOption option;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final asStaff = option.role == UserRole.staff;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Join ${option.school.name}',
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle),
              child: Icon(asStaff ? Icons.badge_outlined : Icons.school_outlined, color: p.signalInk),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.school.name, style: context.text.titleMedium),
                  Text(asStaff ? 'Invited as staff' : 'Join as a student', style: context.text.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: p.muted),
          ],
        ),
      ),
    );
  }
}
