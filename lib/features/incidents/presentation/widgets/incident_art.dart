import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/incident.dart';
import 'category_visuals.dart';

class IncidentArt extends StatelessWidget {
  const IncidentArt({super.key, required this.incident, this.iconSize = 30});

  final Incident incident;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final url = incident.imageUrl;
    return Hero(
      tag: 'incident-art-${incident.id}',
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 250),
              placeholder: (context, _) => ColoredBox(color: p.raised),
              errorWidget: (context, _, _) => _CategoryArt(incident: incident, iconSize: iconSize),
            )
          : _CategoryArt(incident: incident, iconSize: iconSize),
    );
  }
}

class _CategoryArt extends StatelessWidget {
  const _CategoryArt({required this.incident, required this.iconSize});

  final Incident incident;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _RingsPainter(p.line),
      child: ColoredBox(
        color: p.raised.withValues(alpha: 0.55),
        child: Center(
          child: Icon(incident.category.icon, size: iconSize, color: p.ink),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    final center = size.center(Offset.zero);
    final step = size.longestSide / 6;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, step * i, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}
