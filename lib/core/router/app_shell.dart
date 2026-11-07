import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = ref.watch(isStaffProvider);
    final p = context.palette;
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: p.raised,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavItem(icon: Icons.home_outlined, label: 'Home', index: 0, shell: shell),
                      _NavItem(icon: Icons.view_agenda_outlined, label: 'Reports', index: 1, shell: shell),
                      if (isStaff) _NavItem(icon: Icons.inbox_outlined, label: 'Desk', index: 2, shell: shell),
                      _NavItem(icon: Icons.person_outline_rounded, label: 'Account', index: 3, shell: shell),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Pressable(
                onTap: () => context.push('/report'),
                semanticLabel: 'Report an issue',
                scale: 0.9,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle),
                  child: Icon(Icons.add_rounded, size: 30, color: p.signalInk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.index, required this.shell});

  final IconData icon;
  final String label;
  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = shell.currentIndex == index;
    final color = selected ? p.canvas : p.muted;
    return Pressable(
      onTap: () => shell.goBranch(index, initialLocation: selected),
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected ? p.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: color),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(label, style: context.text.labelMedium?.copyWith(color: color)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
