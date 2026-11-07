import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/failure.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../../incidents/application/incident_providers.dart';
import '../../incidents/domain/incident.dart';
import '../../incidents/domain/incident_enums.dart';
import '../../incidents/presentation/widgets/category_visuals.dart';
import '../../incidents/presentation/widgets/incident_card.dart';

class StaffDeskScreen extends ConsumerWidget {
  const StaffDeskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(deskStatusProvider);
    final all = ref.watch(incidentsProvider).value ?? const <Incident>[];
    final queue = ref.watch(deskQueueProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          Text('Staff desk', style: context.text.displayMedium),
          const SizedBox(height: 4),
          Text('Urgent first, then oldest.', style: context.text.bodyMedium),
          const SizedBox(height: 18),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final status in IncidentStatus.values)
                _StatusCount(
                  status: status,
                  count: all.where((incident) => incident.status == status).length,
                  selected: status == selected,
                  onTap: () => ref.read(deskStatusProvider.notifier).select(status),
                ),
            ],
          ),
          const SizedBox(height: 20),
          queue.when(
            loading: () => const SkeletonList(),
            error: (error, _) =>
                ErrorView(message: friendlyError(error), onRetry: () => ref.invalidate(incidentsProvider)),
            data: (incidents) => incidents.isEmpty
                ? EmptyView(title: 'Queue clear', message: 'No reports are ${selected.label.toLowerCase()}.')
                : Column(
                    children: [
                      for (var i = 0; i < incidents.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: IncidentCard(
                            key: ValueKey('${incidents[i].id}-${incidents[i].status.name}'),
                            incident: incidents[i],
                          ).animate().fadeIn(delay: (i.clamp(0, 6) * 40).ms, duration: 260.ms).slideY(begin: 0.08),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({required this.status, required this.count, required this.selected, required this.onTap});

  final IncidentStatus status;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final foreground = selected ? p.canvas : p.ink;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$count ${status.label}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? p.ink : p.surface,
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$count', style: context.text.titleLarge?.copyWith(color: foreground)),
            Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                letterSpacing: 0,
                color: selected ? foreground : status.color(p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
