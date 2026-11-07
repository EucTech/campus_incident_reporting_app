import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_providers.dart';
import '../../incidents/application/incident_providers.dart';
import 'account_security_sheets.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final profile = ref.watch(profileProvider).value;
    final stats = ref.watch(campusStatsProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          Text('Account', style: context.text.displayMedium),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Row(
              children: [
                UserAvatar(user: profile, size: 62),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleLarge,
                      ),
                      Text(
                        profile?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: p.raised, borderRadius: BorderRadius.circular(100)),
                        child: Text(
                          (profile?.isStaff ?? false) ? 'Staff' : 'Student',
                          style: context.text.labelMedium?.copyWith(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(value: stats.mine, label: 'Reported'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(value: stats.mineOpen, label: 'Open'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(value: stats.mineResolved, label: 'Resolved'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PillButton(
            label: 'Edit profile',
            icon: Icons.edit_outlined,
            compact: true,
            style: PillStyle.outline,
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(height: 26),
          Text('Appearance', style: context.text.titleLarge),
          const SizedBox(height: 12),
          const _ThemeSwitch(),
          const SizedBox(height: 26),
          Text('Privacy', style: context.text.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Reports are visible to verified ALU accounts. When you hide your name, other people on Pulse see you as Anonymous.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 26),
          Text('Security', style: context.text.titleLarge),
          const SizedBox(height: 12),
          PillButton(
            label: 'Change password',
            icon: Icons.lock_outline_rounded,
            compact: true,
            style: PillStyle.outline,
            onPressed: () => showChangePasswordSheet(context),
          ),
          const SizedBox(height: 10),
          PillButton(
            label: 'Log out',
            style: PillStyle.outline,
            icon: Icons.logout_rounded,
            compact: true,
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(height: 18),
          Center(
            child: Pressable(
              onTap: () => showDeleteAccountSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Delete account', style: context.text.labelMedium?.copyWith(color: p.danger)),
              ),
            ),
          ),
        ].animate(interval: 45.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(AppRadius.tile + 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: context.text.headlineMedium),
          Text(label, style: context.text.labelMedium?.copyWith(color: p.muted)),
        ],
      ),
    );
  }
}

class _ThemeSwitch extends ConsumerWidget {
  const _ThemeSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    final controller = ref.read(themeModeProvider.notifier);

    return Container(
      height: 62,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode_outlined,
                selected: isDark,
                onTap: () => controller.set(ThemeMode.dark),
              ),
              _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode_outlined,
                selected: !isDark,
                onTap: () => controller.set(ThemeMode.light),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.canvas : p.muted;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        semanticLabel: '$label mode',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: context.text.labelLarge?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
