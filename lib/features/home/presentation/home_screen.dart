import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/failure.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/pulse_rings.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_providers.dart';
import '../../incidents/application/incident_providers.dart';
import '../../incidents/domain/incident.dart';
import '../../incidents/domain/incident_enums.dart';
import '../../incidents/presentation/widgets/category_visuals.dart';
import '../../incidents/presentation/widgets/incident_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final stats = ref.watch(campusStatsProvider);
    final incidents = ref.watch(incidentsProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hi, ${profile?.firstName ?? 'there'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headlineMedium,
                ),
              ),
              Pressable(
                onTap: () => context.go('/account'),
                semanticLabel: 'Account',
                child: UserAvatar(user: profile, size: 44),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _HeroCard(open: stats.open, urgent: stats.urgent),
          const SizedBox(height: 12),
          Row(
            children: [
              if (profile?.isStaff ?? false) ...[
                Expanded(
                  child: _StatTile(value: stats.total, label: 'Campus reports', onTap: () => _openAll(context, ref)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(value: stats.open, label: 'Still open', onTap: () => _openAll(context, ref)),
                ),
              ] else ...[
                Expanded(
                  child: _StatTile(value: stats.mine, label: 'My reports', onTap: () => _openMine(context, ref)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(value: stats.mineOpen, label: 'Still open', onTap: () => _openMine(context, ref)),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: stats.resolved,
                  label: 'Fixed on campus',
                  accent: true,
                  onTap: () => _openResolved(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Browse by type', style: context.text.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: IncidentCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = IncidentCategory.values[index];
                return _CategoryBubble(
                  category: category,
                  onTap: () {
                    ref.read(incidentFilterProvider.notifier).showCategory(category);
                    context.go('/reports');
                  },
                ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.2, curve: Curves.easeOutCubic);
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Latest on campus', style: context.text.titleLarge)),
              Pressable(
                onTap: () {
                  ref.read(incidentFilterProvider.notifier).clear();
                  context.go('/reports');
                },
                child: Text('See all', style: context.text.labelMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          incidents.when(
            loading: () => const SkeletonList(count: 2, height: 200),
            error: (error, _) =>
                ErrorView(message: friendlyError(error), onRetry: () => ref.invalidate(incidentsProvider)),
            data: (items) => items.isEmpty
                ? const EmptyView(title: 'All quiet', message: 'Nothing has been reported yet.')
                : _LatestRail(items: items.take(6).toList()),
          ),
        ],
      ),
    );
  }

  void _openAll(BuildContext context, WidgetRef ref) {
    ref.read(incidentFilterProvider.notifier).clear();
    context.go('/reports');
  }

  void _openMine(BuildContext context, WidgetRef ref) {
    ref.read(incidentFilterProvider.notifier)
      ..clear()
      ..setMineOnly(true);
    context.go('/reports');
  }

  void _openResolved(BuildContext context, WidgetRef ref) {
    ref.read(incidentFilterProvider.notifier)
      ..clear()
      ..setStatus(IncidentStatus.resolved);
    context.go('/reports');
  }
}

class _LatestRail extends StatelessWidget {
  const _LatestRail({required this.items});

  final List<Incident> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            FeatureCard(incident: items[index])
                .animate()
                .fadeIn(delay: (index * 70).ms, duration: 350.ms)
                .slideX(begin: 0.12, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.open, required this.urgent});

  final int open;
  final int urgent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        color: p.surface,
        padding: const EdgeInsets.all(22),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(right: -120, top: -120, child: PulseRings(size: 260, color: p.signalText, rings: 4)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: open.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) =>
                      Text(value.round().toString(), style: context.text.displayLarge?.copyWith(fontSize: 72)),
                ),
                Text(
                  urgent > 0 ? 'open on campus, $urgent urgent' : 'open on campus',
                  style: context.text.bodyLarge?.copyWith(color: p.muted),
                ),
                const SizedBox(height: 20),
                PillButton(
                  label: 'Report an issue',
                  icon: Icons.add_rounded,
                  style: PillStyle.signal,
                  onPressed: () => context.push('/report'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.onTap, this.accent = false});

  final int value;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$value $label',
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent ? p.signal : p.surface,
          borderRadius: BorderRadius.circular(AppRadius.tile + 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$value', style: context.text.headlineMedium?.copyWith(color: accent ? p.signalInk : p.ink)),
            Text(
              label,
              maxLines: 2,
              style: context.text.labelMedium?.copyWith(color: accent ? p.signalInk : p.muted, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.category, required this.onTap});

  final IncidentCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      semanticLabel: category.label,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle),
              child: Icon(category.icon, color: p.ink, size: 24),
            ),
            const SizedBox(height: 7),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}
