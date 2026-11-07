import 'package:flutter/material.dart';

class PulseRings extends StatefulWidget {
  const PulseRings({super.key, required this.size, required this.color, this.rings = 3, this.child});

  final double size;
  final Color color;
  final int rings;
  final Widget? child;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PulsePainter(_controller, widget.color, widget.rings),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.progress, this.color, this.rings) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final int rings;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    for (var i = 0; i < rings; i++) {
      final t = (progress.value + i / rings) % 1;
      final eased = Curves.easeOutCubic.transform(t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: (1 - t) * 0.7);
      canvas.drawCircle(center, maxRadius * (0.12 + eased * 0.88), paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.color != color || old.rings != rings;
}
