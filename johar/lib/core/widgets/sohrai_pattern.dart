import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Original geometric band inspired by Sohrai / Khovar wall painting of
/// Hazaribagh: hills, diamond chains and dot rows, drawn in thin lines.
/// Decoration only; keep it low-contrast behind text.
class SohraiPattern extends StatelessWidget {
  const SohraiPattern({
    super.key,
    this.line = const Color(0x2EFFFFFF),
    this.accent = AppColors.ochre,
    this.height = 64,
  });

  final Color line;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _SohraiPainter(line, accent)),
      );
}

class _SohraiPainter extends CustomPainter {
  _SohraiPainter(this.line, this.accent);
  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = line;
    final accentDot = Paint()..color = accent.withValues(alpha: 0.9);

    // 1. Dotted border line at the top.
    for (var x = 4.0; x < w; x += 9) {
      canvas.drawCircle(Offset(x, 3), 1.3, dot);
    }

    // 2. Diamond chain with centre dots (alternating ochre).
    final cy = h * 0.42, d = h * 0.2;
    var i = 0;
    for (var x = d; x < w + d; x += d * 2.2, i++) {
      final path = Path()
        ..moveTo(x, cy - d)
        ..lineTo(x + d, cy)
        ..lineTo(x, cy + d)
        ..lineTo(x - d, cy)
        ..close();
      canvas.drawPath(path, stroke);
      canvas.drawCircle(Offset(x, cy), 2.4, i.isEven ? accentDot : dot);
      // tiny connecting ticks
      canvas.drawLine(Offset(x + d, cy), Offset(x + d * 1.2, cy), stroke);
    }

    // 3. Hills: a zigzag of triangles along the bottom, with a dot on each peak.
    final base = h - 2, peak = h * 0.7, step = h * 0.32;
    final hills = Path()..moveTo(0, base);
    var up = true;
    for (var x = step / 2; x <= w + step; x += step / 2) {
      hills.lineTo(x, up ? peak : base);
      if (up) canvas.drawCircle(Offset(x, peak - 5), 1.6, dot);
      up = !up;
    }
    canvas.drawPath(hills, stroke);

    // 4. A few sun-rings as focal accents.
    for (var k = 0; k < 2; k++) {
      final c = Offset(w * (0.78 + 0.14 * k), h * 0.18);
      for (var r = 3.0; r <= 9; r += 3) {
        canvas.drawCircle(c, r, stroke..strokeWidth = 1.2);
      }
      for (var a = 0; a < 8; a++) {
        final ang = a * math.pi / 4;
        canvas.drawLine(c + Offset(math.cos(ang), math.sin(ang)) * 11, c + Offset(math.cos(ang), math.sin(ang)) * 14, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SohraiPainter old) => old.line != line || old.accent != accent;
}
