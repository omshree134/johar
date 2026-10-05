import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/ar_task.dart';
import '../../../data/models/localized.dart';
import '../engine/projector.dart';
import '../engine/sprite_cache.dart';
import '../engine/vec3.dart';
import '../tasks/choose_exit_task.dart';
import '../tasks/extinguish_task.dart';
import '../tasks/gas_test_task.dart';
import '../tasks/sequence_task.dart';
import '../tasks/task_controller.dart';
import 'ar_icons.dart';

/// Everything the painter needs for one frame. Mutated by the screen's ticker,
/// so painting never allocates widgets (keeps 60 fps on budget phones).
class ArFrame {
  Size size = Size.zero;
  Projector? projector;
  List<ProjectedObject> layout = const [];
  TaskController? task;
  String? focusedId;
  bool drawRoom = true;
  double time = 0;
  String lang = 'en';
  final Map<String, TextPainter> labelCache = {};
  final SpriteCache sprites = SpriteCache();

  /// Objects the worker has tapped: their names are now shown.
  final Set<String> revealed = {};
}

class WorldPainter extends CustomPainter {
  WorldPainter(this.frame, {required Listenable repaint}) : super(repaint: repaint);
  final ArFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final pj = frame.projector;
    final task = frame.task;
    if (pj == null || task == null) return;

    if (frame.drawRoom) _paintRoom(canvas, size, pj);
    if (task is ChooseExitTask && task.spread != null) _paintSpread(canvas, pj, task);

    for (final p in frame.layout) {
      if (!p.inFront || !_nearScreen(p.hitRect, size)) continue;
      final focused = p.object.id == frame.focusedId;
      switch (p.object.kind) {
        case SceneObjectKind.fire:
          _paintFire(canvas, p, task.fireIntensity(p.object));
        case SceneObjectKind.gasLeak:
          _paintGasLeak(canvas, p);
        case SceneObjectKind.sump:
          _paintSump(canvas, p);
        case SceneObjectKind.level:
          _paintLevel(canvas, p, task, focused);
        default:
          _paintMarker(canvas, p, task.stateOf(p.object), focused, task is ChooseExitTask && task.isBlocked(p.object));
      }
    }

    if (task is ExtinguishTask && task.spraying) _paintSpray(canvas, size);
    _paintGuides(canvas, size, task);
    _paintReticle(canvas, size, task);
  }

  bool _nearScreen(Rect r, Size s) => r.overlaps(Rect.fromLTWH(-200, -200, s.width + 400, s.height + 400));

  // ---------------- Virtual room (no camera) ----------------

  void _paintRoom(Canvas c, Size s, Projector pj) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B4148), Color(0xFF1F2327)],
        ).createShader(Offset.zero & s),
    );
    final grid = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;
    const floor = -1.5; // eye height above the floor, metres
    for (var i = -12; i <= 12; i += 2) {
      final d = i.toDouble();
      _line3d(c, pj, Vec3(d, -12, floor), Vec3(d, 12, floor), grid);
      _line3d(c, pj, Vec3(-12, d, floor), Vec3(12, d, floor), grid);
    }
    final horizon = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.5;
    for (var b = -180.0; b < 180; b += 15) {
      _line3d(c, pj, Vec3.direction(b, 0) * 40, Vec3.direction(b + 15, 0) * 40, horizon);
    }
    // Yellow-black hazard line painted on the floor, like real plant walkways.
    final stripe = Paint()
      ..color = const Color(0x99F4B400)
      ..strokeWidth = 3;
    _line3d(c, pj, const Vec3(-12, 2.5, floor), const Vec3(12, 2.5, floor), stripe);
  }

  /// Draws a 3D segment, clipping the part behind the camera.
  void _line3d(Canvas c, Projector pj, Vec3 a, Vec3 b, Paint paint) {
    const near = 0.2;
    final f = pj.pose.forward;
    final za = a.dot(f), zb = b.dot(f);
    if (za < near && zb < near) return;
    if (za < near) a = Vec3.lerp(a, b, (near - za) / (zb - za));
    if (zb < near) b = Vec3.lerp(b, a, (near - zb) / (za - zb));
    c.drawLine(pj.project(a).screen, pj.project(b).screen, paint);
  }

  // ---------------- Hazard effects ----------------

  void _paintSpread(Canvas c, Projector pj, ChooseExitTask task) {
    final sp = task.spread!;
    final t = task.elapsed;
    final center = sp.centerAt(t), half = sp.halfWidthAt(t);
    final base = sp.isGas ? const Color(0xFFB5C400) : const Color(0xFF6B6F73);
    final paint = Paint()..color = base.withValues(alpha: sp.isGas ? 0.20 : 0.26);
    for (var b = center - half; b <= center + half; b += 9) {
      for (final e in const [-6.0, 4.0, 14.0]) {
        final wobble = math.sin(frame.time * 0.8 + b * 0.13 + e) * 3;
        final p = pj.project(Vec3.direction(b + wobble, e) * 7);
        if (!p.inFront) continue;
        final r = p.scale * 1.3;
        c.drawCircle(p.screen, r, paint);
        c.drawCircle(p.screen, r * 0.6, paint);
      }
    }
  }

  void _paintFire(Canvas c, ProjectedObject p, double intensity) {
    if (intensity <= 0.01) {
      _paintLabel(c, p.object, p.screen.translate(0, 8), MarkerState.correct);
      return;
    }
    final box = fireRect(p.screen, p.scale, intensity);
    final t = frame.time;
    final img = frame.sprites[p.object.image];
    if (img != null) {
      final w = box.width * 0.9;
      _drawImage(c, img, Rect.fromLTWH(p.screen.dx - w / 2, p.screen.dy - w * 0.15, w, w));
    }
    // Glow on the ground
    c.drawOval(
      Rect.fromCenter(center: p.screen, width: box.width * 1.6, height: box.width * 0.35),
      Paint()..color = const Color(0x66FF8F00),
    );
    const layers = [
      (Color(0xE6D84315), 1.0),
      (Color(0xE6FB8C00), 0.72),
      (Color(0xE6FFD54F), 0.42),
    ];
    for (final (color, s) in layers) {
      final paint = Paint()..color = color;
      for (var k = 0; k < 5; k++) {
        final ox = (k - 2) / 2 * box.width * 0.28 * s;
        final flick = 0.75 + 0.25 * math.sin(t * 9 + k * 1.7 + s * 3);
        final hk = box.height * s * flick * (k == 2 ? 1.0 : 0.72);
        final wk = box.width * 0.42 * s;
        final sway = math.sin(t * 5 + k) * wk * 0.25;
        final bx = p.screen.dx + ox, by = p.screen.dy;
        final path = Path()
          ..moveTo(bx - wk / 2, by)
          ..quadraticBezierTo(bx - wk * 0.65, by - hk * 0.45, bx + sway, by - hk)
          ..quadraticBezierTo(bx + wk * 0.65, by - hk * 0.45, bx + wk / 2, by)
          ..close();
        c.drawPath(path, paint);
      }
    }
    _paintLabel(c, p.object, p.screen.translate(0, 8), MarkerState.idle);
  }

  void _paintGasLeak(Canvas c, ProjectedObject p) {
    final t = frame.time;
    final puff = Paint()..color = const Color(0x55B5C400);
    for (var i = 0; i < 6; i++) {
      final phase = (t * 0.5 + i / 6) % 1.0;
      final rise = phase * p.scale * 1.4;
      final drift = math.sin(t + i) * p.scale * 0.15;
      c.drawCircle(p.screen.translate(drift, -rise), p.scale * (0.12 + phase * 0.35), puff);
    }
    _paintMarker(c, p, MarkerState.idle, false, false, fill: AppColors.warningYellow, forceLabel: true);
  }

  void _paintSump(Canvas c, ProjectedObject p) {
    final r = sumpRect(p.screen, p.scale);
    c.drawOval(r.inflate(4), Paint()..color = const Color(0xFF8A8F94));
    c.drawOval(r, Paint()..color = const Color(0xFF0E1012));
  }

  void _paintLevel(Canvas c, ProjectedObject p, TaskController task, bool focused) {
    final d = levelMarkerDiameter(p.scale);
    final measured = task.stateOf(p.object) == MarkerState.correct;
    final color = measured ? AppColors.safeGreen : Colors.white;
    c.drawCircle(p.screen, d / 2, Paint()..color = Colors.black.withValues(alpha: 0.35));
    c.drawCircle(
      p.screen,
      d / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 5 : 3
        ..color = color,
    );
    if (task is GasTestTask && task.measuringId == p.object.id && task.progress > 0) {
      c.drawArc(
        Rect.fromCircle(center: p.screen, radius: d / 2 + 6),
        -math.pi / 2,
        2 * math.pi * task.progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = AppColors.warningYellow,
      );
    }
    if (measured) _paintIcon(c, Icons.check, p.screen, d * 0.6, AppColors.safeGreen);
    _paintLabel(c, p.object, p.screen.translate(d / 2 + 8, -12), MarkerState.idle, alignLeft: true);
  }

  // ---------------- Markers ----------------

  void _paintMarker(
    Canvas c,
    ProjectedObject p,
    MarkerState state,
    bool focused,
    bool blocked, {
    Color? fill,
    bool forceLabel = false,
  }) {
    final task = frame.task;
    final img = frame.sprites[p.object.image];
    final ring = switch (state) {
      MarkerState.idle => Colors.white,
      MarkerState.selected => AppColors.manganese,
      MarkerState.correct => AppColors.safeGreen,
      MarkerState.wrong => AppColors.fireRed,
    };

    final double labelTop;
    final double badgeRadius;
    final Offset badgeAt;

    if (img != null) {
      // Picture as a billboard standing in the room.
      final size = spriteSize(p.scale);
      final box = Rect.fromCenter(center: p.screen, width: size, height: size);
      final plate = RRect.fromRectAndRadius(box.inflate(6), Radius.circular(size * 0.22));
      if (focused || state != MarkerState.idle) {
        c.drawRRect(plate, Paint()..color = Colors.white.withValues(alpha: focused ? 0.55 : 0.4));
        c.drawRRect(
          plate,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = state == MarkerState.idle ? 3 : 5
            ..color = state == MarkerState.idle ? Colors.white : ring,
        );
      }
      c.drawOval(
        Rect.fromCenter(center: box.bottomCenter.translate(0, -size * 0.04), width: size * 0.7, height: size * 0.1),
        Paint()..color = Colors.black.withValues(alpha: 0.25),
      );
      _drawImage(c, img, box);
      labelTop = box.bottom + 8;
      badgeRadius = size * 0.13;
      badgeAt = box.topRight.translate(-badgeRadius * 0.6, badgeRadius * 0.6);
    } else {
      // Icon disc fallback.
      final d = markerDiameter(p.scale);
      if (focused) c.drawCircle(p.screen, d / 2 + 10, Paint()..color = Colors.white.withValues(alpha: 0.35));
      c.drawCircle(p.screen.translate(0, 3), d / 2, Paint()..color = Colors.black.withValues(alpha: 0.3));
      c.drawCircle(p.screen, d / 2, Paint()..color = fill ?? Colors.white);
      c.drawCircle(
        p.screen,
        d / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = state == MarkerState.idle ? 2 : 5
          ..color = state == MarkerState.idle ? AppColors.line : ring,
      );
      _paintIcon(c, arIcon(p.object.icon), p.screen, d * 0.55, AppColors.coal);
      labelTop = p.screen.dy + d / 2 + 6;
      badgeRadius = d * 0.2;
      badgeAt = p.screen.translate(d * 0.36, -d * 0.36);
    }

    // Status badge: step number for sequences, tick/cross otherwise.
    final step = task is SequenceTask ? task.stepNumber(p.object) : null;
    if (step != null || state != MarkerState.idle) {
      c.drawCircle(badgeAt, badgeRadius, Paint()..color = ring);
      if (step != null) {
        _paintText(c, '$step', badgeAt, badgeRadius * 1.2, Colors.white);
      } else {
        _paintIcon(c, state == MarkerState.wrong ? Icons.close : Icons.check, badgeAt, badgeRadius * 1.4, Colors.white);
      }
    }

    if (blocked) {
      c.drawCircle(p.screen, spriteSize(p.scale) * 0.45, Paint()..color = const Color(0x886B6F73));
    }

    final showName = forceLabel ||
        img == null ||
        p.object.alwaysShowLabel ||
        frame.revealed.contains(p.object.id) ||
        state != MarkerState.idle;
    if (showName) _paintLabel(c, p.object, Offset(p.screen.dx, labelTop), state);
  }

  void _drawImage(Canvas c, ui.Image img, Rect dst) {
    c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  void _paintText(Canvas c, String text, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintLabel(Canvas c, SceneObject o, Offset topCenter, MarkerState state, {bool alignLeft = false}) {
    final tp = _labelPainter(o);
    final pad = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    final w = tp.width + pad.horizontal, h = tp.height + pad.vertical;
    final left = alignLeft ? topCenter.dx : topCenter.dx - w / 2;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(left, topCenter.dy, w, h), const Radius.circular(8));
    c.drawRRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.92));
    tp.paint(c, Offset(left + pad.left, topCenter.dy + pad.top));
  }

  TextPainter _labelPainter(SceneObject o) {
    final key = '${o.id}|${frame.lang}';
    return frame.labelCache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: tr(o.label, frame.lang),
          style: const TextStyle(
            fontFamily: 'NotoSans',
            fontFamilyFallback: ['NotoSansDevanagari', 'NotoSansOlChiki'],
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.coal,
            height: 1.2,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: 150);
    });
  }

  void _paintIcon(Canvas c, IconData icon, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontSize: size, fontFamily: icon.fontFamily, package: icon.fontPackage, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ---------------- HUD elements drawn in world layer ----------------

  void _paintSpray(Canvas c, Size s) {
    final start = Offset(s.width / 2, s.height + 10);
    final end = s.center(Offset.zero);
    final perp = Offset(end.dy - start.dy, start.dx - end.dx) / (end - start).distance;
    final paint = Paint();
    for (var i = 0; i < 26; i++) {
      final t = (i / 26 + frame.time * 2.2) % 1.0;
      final jitter = math.sin(i * 12.9 + frame.time * 20) * 10 * t;
      paint.color = Colors.white.withValues(alpha: 0.55 * (1 - t * 0.6));
      c.drawCircle(Offset.lerp(start, end, t)! + perp * jitter, 3 + t * 12, paint);
    }
  }

  void _paintGuides(Canvas c, Size s, TaskController task) {
    for (final p in frame.layout) {
      if (!task.guideIds.contains(p.object.id)) continue;
      final visible = p.inFront && Rect.fromLTWH(0, 0, s.width, s.height).overlaps(p.hitRect);
      if (visible) continue;
      var dir = p.direction;
      if (dir.distance < 1e-6) dir = const Offset(1, 0);
      dir = dir / dir.distance;
      final cx = s.width / 2, cy = s.height / 2;
      final tx = dir.dx.abs() < 1e-6 ? double.infinity : (cx - 36) / dir.dx.abs();
      final ty = dir.dy.abs() < 1e-6 ? double.infinity : (cy - 150) / dir.dy.abs();
      final tip = Offset(cx, cy) + dir * math.min(tx, ty);
      final back = tip - dir * 30;
      final side = Offset(-dir.dy, dir.dx) * 16;
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(back.dx + side.dx, back.dy + side.dy)
        ..lineTo(back.dx - side.dx, back.dy - side.dy)
        ..close();
      c.drawPath(path, Paint()..color = Colors.white);
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.coal,
      );
    }
  }

  void _paintReticle(Canvas c, Size s, TaskController task) {
    final center = s.center(Offset.zero);
    var color = Colors.white;
    if (task is ExtinguishTask) {
      color = switch (task.aim) {
        AimZone.base => const Color(0xFF3DDC84),
        AimZone.flames => AppColors.warningYellow,
        AimZone.none => Colors.white,
      };
    } else if (frame.focusedId != null) {
      color = const Color(0xFF3DDC84);
    }
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.black.withValues(alpha: 0.45);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    c.drawCircle(center, 22, outline);
    c.drawCircle(center, 22, ring);
    c.drawCircle(center, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant WorldPainter old) => old.frame != frame;
}
