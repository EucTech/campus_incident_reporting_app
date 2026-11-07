import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/time_format.dart';
import '../../domain/incident.dart';
import '../../domain/incident_enums.dart';
import 'category_visuals.dart';

class StatusTrack extends StatelessWidget {
  const StatusTrack({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dismissed = status == IncidentStatus.dismissed;
    final reached = dismissed ? 0 : IncidentStatus.stages.indexOf(status);
    final activeColor = dismissed ? p.danger : p.signalText;
    final stops = IncidentStatus.stages.length - 1;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth - 14;
            return SizedBox(
              height: 14,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 7), color: p.line),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: reached / stops),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Container(height: 2, width: width * value, color: activeColor),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i <= stops; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= reached ? activeColor : p.canvas,
                            border: Border.all(color: i <= reached ? activeColor : p.line, width: 2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final stage in IncidentStatus.stages)
              Text(
                stage.label,
                style: context.text.labelSmall?.copyWith(letterSpacing: 0, color: stage == status ? p.ink : p.muted),
              ),
          ],
        ),
      ],
    );
  }
}

class StatusHistory extends StatelessWidget {
  const StatusHistory({super.key, required this.entries});

  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final latestFirst = entries.reversed.toList();
    return Column(
      children: [
        for (var i = 0; i < latestFirst.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(color: latestFirst[i].status.color(p), shape: BoxShape.circle),
                    ),
                    if (i != latestFirst.length - 1) Expanded(child: Container(width: 1.5, color: p.line)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(latestFirst[i].status.label, style: context.text.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${latestFirst[i].actorName} · ${TimeFormat.full(latestFirst[i].at)}',
                          style: context.text.bodyMedium,
                        ),
                        if (latestFirst[i].note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(latestFirst[i].note, style: context.text.bodyLarge),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (i * 70).ms, duration: 300.ms).slideX(begin: 0.04),
      ],
    );
  }
}
