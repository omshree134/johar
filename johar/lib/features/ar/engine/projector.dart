import 'dart:math' as math;
import 'dart:ui';
import '../../../data/models/ar_task.dart';
import '../tasks/task_controller.dart';
import 'vec3.dart';

/// Pinhole camera: turns 3D scene points into screen pixels.
class Projector {
  Projector(this.pose, this.size, double verticalFovDeg)
      : focal = (size.height / 2) / math.tan(degToRad(verticalFovDeg) / 2),
        _right = pose.right;

  final Pose pose;
  final Size size;
  final double focal; // pixels
  final Vec3 _right;

  Offset get center => size.center(Offset.zero);

  /// [scale] = pixels per metre at that depth.
  ({Offset screen, double scale, bool inFront, Offset direction}) project(Vec3 p) {
    final z = p.dot(pose.forward);
    final x = p.dot(_right);
    final y = p.dot(pose.up);
    final dir = Offset(x, -y);
    if (z < 0.05) return (screen: center, scale: 0, inFront: false, direction: dir);
    return (
      screen: Offset(center.dx + focal * x / z, center.dy - focal * y / z),
      scale: focal / z,
      inFront: true,
      direction: dir,
    );
  }
}

class ProjectedObject {
  ProjectedObject(this.object, this.screen, this.scale, this.inFront, this.direction, this.hitRect);
  final SceneObject object;
  final Offset screen;
  final double scale;
  final bool inFront;
  final Offset direction; // toward the object on screen, for edge arrows
  final Rect hitRect;
}

Vec3 scenePosition(SceneObject o) => Vec3.direction(o.bearing, o.elevation) * o.distance;

// ---- Shared geometry (used by the painter AND the task logic, so what the
// worker sees is exactly what gets scored) ----

double markerDiameter(double scale) => (scale * 0.45).clamp(46.0, 84.0).toDouble();

/// Pictures are drawn a bit larger than icon markers.
double spriteSize(double scale) => markerDiameter(scale) * 1.6;

/// Tap area: the picture (or icon) plus room for its name below.
Rect markerRect(Offset screen, double scale) {
  final s = spriteSize(scale);
  return Rect.fromCenter(center: screen.translate(0, s * 0.12), width: math.max(s, 100), height: s * 1.25);
}

double levelMarkerDiameter(double scale) => (scale * 0.22).clamp(40.0, 64.0).toDouble();

Rect levelMarkerRect(Offset screen, double scale) {
  final d = levelMarkerDiameter(scale);
  return Rect.fromCenter(center: screen, width: d * 2.4, height: d * 1.6);
}

/// Fire drawn with its base at [base]; grows with [intensity] (0..1).
Rect fireRect(Offset base, double scale, double intensity) {
  final w = scale * (0.5 + 0.8 * intensity);
  final h = scale * (0.3 + 1.5 * intensity);
  return Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h);
}

Rect sumpRect(Offset screen, double scale) {
  final w = scale * 0.9;
  return Rect.fromCenter(center: screen, width: w, height: w * 0.4);
}

/// Projects every object in the task, sorted far to near for drawing.
List<ProjectedObject> projectScene(Projector pj, TaskController task) {
  final out = <ProjectedObject>[];
  for (final o in task.objects) {
    final p = pj.project(scenePosition(o));
    final rect = !p.inFront
        ? Rect.zero
        : switch (o.kind) {
            SceneObjectKind.fire => fireRect(p.screen, p.scale, task.fireIntensity(o)),
            SceneObjectKind.level => levelMarkerRect(p.screen, p.scale),
            SceneObjectKind.sump => sumpRect(p.screen, p.scale),
            _ => markerRect(p.screen, p.scale),
          };
    out.add(ProjectedObject(o, p.screen, p.scale, p.inFront, p.direction, rect));
  }
  out.sort((a, b) => b.object.distance.compareTo(a.object.distance));
  return out;
}
