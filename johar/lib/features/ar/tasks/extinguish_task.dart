import 'dart:math' as math;
import 'dart:ui';
import '../../../data/models/ar_task.dart';
import '../engine/projector.dart';
import 'task_controller.dart';

enum AimZone { none, flames, base }

/// P-A-S-S simulation, driven by how the worker actually moves the phone:
///  Pull    - must tap "Pull the pin" before spraying works.
///  Aim     - the reticle must be on the BASE of the fire; aiming at flames
///            barely helps, exactly like real life.
///  Squeeze - hold the spray button; the extinguisher empties (~12 s).
///  Sweep   - turning the phone side to side over the base doubles speed.
/// The fire keeps growing while not being fought. If it grows too big or the
/// extinguisher runs out, the lesson is "leave and raise the alarm".
class ExtinguishTask extends TaskController {
  ExtinguishTask(super.task)
      : capacitySec = (task.config['capacitySec'] as num? ?? 12).toDouble(),
        growthPerSec = (task.config['growthPerSec'] as num? ?? 0.03).toDouble(),
        intensity = (task.config['startIntensity'] as num? ?? 0.5).toDouble() {
    capacityLeft = capacitySec;
  }

  static const knockdownPerSec = 0.14;
  static const sweepWindowSec = 1.5;

  final double capacitySec;
  final double growthPerSec;
  double intensity;
  late double capacityLeft;

  bool pinPulled = false;
  bool spraying = false;
  bool triedWithoutPin = false;
  AimZone aim = AimZone.none;

  double sprayTime = 0, aimTime = 0, sweepTime = 0;
  double? _lastRelX;
  int _sweepDir = 0;
  double _lastReversalAt = -10;

  late final SceneObject fire = objects.firstWhere((o) => o.kind == SceneObjectKind.fire);

  @override
  bool get wantsFastHud => true;

  @override
  Set<String> get guideIds => {fire.id};

  @override
  bool isSelectable(SceneObject o) => false;

  @override
  double fireIntensity(SceneObject o) => o.id == fire.id ? intensity : super.fireIntensity(o);

  bool get sweeping => elapsed - _lastReversalAt < sweepWindowSec;
  double get capacityFraction => capacitySec == 0 ? 0 : capacityLeft / capacitySec;

  void pullPin() {
    if (finished) return;
    pinPulled = true;
    notifyListeners();
  }

  void setSpraying(bool on) {
    if (finished) return;
    if (on && !pinPulled) {
      triedWithoutPin = true;
      showHint(HudHint.pullPinFirst);
      return;
    }
    spraying = on && capacityLeft > 0;
    notifyListeners();
  }

  static AimZone aimZone(Rect fireBox, Offset reticle) {
    final relX = (reticle.dx - fireBox.center.dx) / fireBox.width;
    if (relX.abs() > 0.6) return AimZone.none;
    final relY = (fireBox.bottom - reticle.dy) / fireBox.height; // 0 = base, 1 = tip
    if (relY >= -0.2 && relY < 0.4) return AimZone.base;
    if (relY >= 0.4 && relY <= 1.05) return AimZone.flames;
    return AimZone.none;
  }

  @override
  void tick(double dt, FrameInfo frame) {
    final p = frame.objects[fire.id];
    aim = AimZone.none;
    if (p != null && p.inFront) {
      final box = fireRect(p.screen, p.scale, intensity);
      aim = aimZone(box, frame.reticle);
      _trackSweep((frame.reticle.dx - box.center.dx) / box.width, dt);
    } else {
      _lastRelX = null;
    }

    if (spraying && capacityLeft > 0) {
      capacityLeft = math.max(0, capacityLeft - dt);
      sprayTime += dt;
      if (aim == AimZone.base) {
        aimTime += dt;
        if (sweeping) sweepTime += dt;
      }
      final aimFactor = switch (aim) { AimZone.base => 1.0, AimZone.flames => 0.15, AimZone.none => 0.0 };
      intensity -= dt * knockdownPerSec * aimFactor * (sweeping ? 1.0 : 0.6);

      if (aim == AimZone.flames) showHint(HudHint.aimLower);
      if (aim == AimZone.base && !sweeping && sprayTime > 1.5) showHint(HudHint.sweep);
      if (capacityLeft <= 0) spraying = false;
    } else {
      intensity += dt * growthPerSec;
    }
    intensity = intensity.clamp(0.0, 1.0).toDouble();

    if (intensity <= 0.02) {
      intensity = 0;
      finish(_score(out: true));
    } else if (intensity >= 1) {
      finish(_score(out: false), TaskOutcome.fireTooBig);
    } else if (capacityLeft <= 0) {
      finish(_score(out: false), TaskOutcome.extinguisherEmpty);
    }
  }

  void _trackSweep(double relX, double dt) {
    final last = _lastRelX;
    _lastRelX = relX;
    if (last == null || dt <= 0) return;
    final v = (relX - last) / dt; // fire-widths per second
    if (v.abs() < 0.35) return;
    final dir = v > 0 ? 1 : -1;
    if (_sweepDir != 0 && dir != _sweepDir) _lastReversalAt = elapsed;
    _sweepDir = dir;
  }

  double get aimQuality => sprayTime == 0 ? 0 : aimTime / sprayTime;
  double get sweepQuality => aimTime == 0 ? 0 : sweepTime / aimTime;

  double _score({required bool out}) {
    var s = out ? 0.6 + 0.25 * aimQuality + 0.15 * sweepQuality : 0.25 * aimQuality;
    if (triedWithoutPin) s -= 0.15;
    return s;
  }

  @override
  void onTimeUp() => finish(_score(out: false), TaskOutcome.timeUp);
}
