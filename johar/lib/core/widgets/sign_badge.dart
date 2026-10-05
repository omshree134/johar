import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The five ISO 7010 sign families. Each training module is drawn as the real
/// sign shape a worker will meet on site, so recognising the sign is learned
/// just by using the app.
enum SignKind { fireEquipment, warning, mandatory, prohibition, safeCondition }

SignKind signKindFromString(String s) => SignKind.values.firstWhere(
      (k) => k.name == s,
      orElse: () => SignKind.warning,
    );

class SignBadge extends StatelessWidget {
  const SignBadge({super.key, required this.kind, required this.icon, this.size = 64, this.muted = false});

  final SignKind kind;
  final IconData icon;
  final double size;
  final bool muted; // greyed out for locked modules

  @override
  Widget build(BuildContext context) {
    final iconColor = switch (kind) {
      SignKind.warning || SignKind.prohibition => AppColors.coal,
      _ => Colors.white,
    };
    final isTriangle = kind == SignKind.warning;
    Widget badge = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SignShapePainter(kind),
        foregroundPainter: kind == SignKind.prohibition ? _SlashPainter() : null,
        child: Align(
          alignment: isTriangle ? const Alignment(0, 0.4) : Alignment.center,
          child: Icon(icon, size: size * (isTriangle ? 0.36 : 0.5), color: iconColor),
        ),
      ),
    );
    if (muted) {
      badge = Opacity(
        opacity: 0.45,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: badge,
        ),
      );
    }
    return Semantics(label: kind.name, child: badge);
  }
}

class _SignShapePainter extends CustomPainter {
  _SignShapePainter(this.kind);
  final SignKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final fill = Paint()..style = PaintingStyle.fill;
    switch (kind) {
      case SignKind.fireEquipment:
      case SignKind.safeCondition:
        fill.color = kind == SignKind.fireEquipment ? AppColors.fireRed : AppColors.safeGreen;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.14)),
          fill,
        );
      case SignKind.mandatory:
        fill.color = AppColors.mandatoryBlue;
        canvas.drawCircle(size.center(Offset.zero), s / 2, fill);
      case SignKind.warning:
        final stroke = s * 0.07;
        final path = Path()
          ..moveTo(s / 2, stroke)
          ..lineTo(s - stroke, s - stroke * 1.2)
          ..lineTo(stroke, s - stroke * 1.2)
          ..close();
        fill.color = AppColors.warningYellow;
        canvas.drawPath(path, fill);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeJoin = StrokeJoin.round
            ..color = AppColors.coal,
        );
      case SignKind.prohibition:
        fill.color = Colors.white;
        canvas.drawCircle(size.center(Offset.zero), s / 2, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _SignShapePainter old) => old.kind != kind;
}

class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final ring = s * 0.1;
    final p = Paint()
      ..color = AppColors.fireRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring;
    final c = size.center(Offset.zero);
    final r = s / 2 - ring / 2;
    canvas.drawCircle(c, r, p);
    final d = Offset(math.cos(math.pi / 4), math.sin(math.pi / 4)) * r;
    canvas.drawLine(c - d, c + d, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
