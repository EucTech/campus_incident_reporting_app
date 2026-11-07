import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/incident_enums.dart';

extension CategoryIcon on IncidentCategory {
  IconData get icon => switch (this) {
    IncidentCategory.facilities => Icons.domain_rounded,
    IncidentCategory.water => Icons.water_drop_outlined,
    IncidentCategory.electricity => Icons.bolt_rounded,
    IncidentCategory.furniture => Icons.chair_outlined,
    IncidentCategory.sanitation => Icons.cleaning_services_outlined,
    IncidentCategory.safety => Icons.shield_outlined,
    IncidentCategory.other => Icons.more_horiz_rounded,
  };
}

extension StatusColor on IncidentStatus {
  Color color(AppPalette p) => switch (this) {
    IncidentStatus.submitted => p.muted,
    IncidentStatus.inReview => p.sky,
    IncidentStatus.inProgress => p.amber,
    IncidentStatus.resolved => p.signalText,
    IncidentStatus.dismissed => p.danger,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context.palette);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(status.label, style: context.text.labelMedium?.copyWith(color: color, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class UrgentTag extends StatelessWidget {
  const UrgentTag({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: p.danger.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(100)),
      child: Text(
        IncidentSeverity.high.label,
        style: context.text.labelMedium?.copyWith(color: p.danger, fontSize: 11.5),
      ),
    );
  }
}
