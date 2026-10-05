import 'dart:math' as math;
import '../../../data/models/ar_task.dart';
import '../../assessment/assessment_engine.dart';
import '../engine/vec3.dart';
import 'task_controller.dart';

/// Smoke (fire) or a gas cloud that widens over time and can drift with the
/// wind. Routes inside it become visibly blocked.
class SpreadEffect {
  SpreadEffect({
    required this.isGas,
    required this.fromBearing,
    this.towardBearing,
    required this.degPerSec,
    required this.maxHalfWidth,
  });

  final bool isGas;
  final double fromBearing;
  final double? towardBearing; // wind direction; null = spreads evenly
  final double degPerSec;
  final double maxHalfWidth;

  factory SpreadEffect.fromJson(Map<String, dynamic> j) => SpreadEffect(
        isGas: j['type'] == 'gas',
        fromBearing: (j['fromBearing'] as num).toDouble(),
        towardBearing: (j['towardBearing'] as num?)?.toDouble(),
        degPerSec: (j['degPerSec'] as num? ?? 4).toDouble(),
        maxHalfWidth: (j['maxHalfWidth'] as num? ?? 60).toDouble(),
      );

  double halfWidthAt(double t) => math.min(maxHalfWidth, 10 + degPerSec * t);

  double centerAt(double t) {
    final to = towardBearing;
    if (to == null) return fromBearing;
    return fromBearing + wrapDeg(to - fromBearing) * math.min(1, t / 12);
  }

  bool covers(double bearing, double t) => wrapDeg(bearing - centerAt(t)).abs() <= halfWidthAt(t);
}

/// Evacuation decision under time pressure.
/// Score: 1 if the safe route is picked first time, 0.5 after one mistake, 0.25 after more.
class ChooseExitTask extends TaskController {
  ChooseExitTask(super.task)
      : spread = task.config['spread'] == null
            ? null
            : SpreadEffect.fromJson(task.config['spread'] as Map<String, dynamic>);

  final SpreadEffect? spread;
  final Set<String> wrongIds = {};

  @override
  bool isSelectable(SceneObject o) => o.kind == SceneObjectKind.exit;

  @override
  MarkerState stateOf(SceneObject o) {
    if (wrongIds.contains(o.id)) return MarkerState.wrong;
    if (finished && o.correct) return MarkerState.correct;
    return MarkerState.idle;
  }

  bool isBlocked(SceneObject o) => spread?.covers(o.bearing, elapsed) ?? false;

  @override
  void select(SceneObject o) {
    if (finished || !isSelectable(o) || wrongIds.contains(o.id)) return;
    if (o.correct) {
      finish(AssessmentEngine.scoreIdentify(foundCorrect: true, wrongTaps: wrongIds.length));
    } else {
      wrongIds.add(o.id);
      showInfo(o.info, good: false);
    }
  }
}
