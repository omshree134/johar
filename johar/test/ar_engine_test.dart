import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:johar/data/models/ar_task.dart';
import 'package:johar/features/ar/engine/projector.dart';
import 'package:johar/features/ar/engine/vec3.dart';
import 'package:johar/features/ar/tasks/extinguish_task.dart';
import 'package:johar/features/ar/tasks/find_hazards_task.dart';
import 'package:johar/features/ar/tasks/gas_test_task.dart';
import 'package:johar/features/ar/tasks/task_controller.dart';

SceneObject obj(String id, SceneObjectKind kind, {double bearing = 0, double elevation = 0, double distance = 3, bool correct = false}) =>
    SceneObject(id: id, kind: kind, label: const {'en': 'x'}, icon: 'fire', bearing: bearing, elevation: elevation, distance: distance, correct: correct);

void main() {
  const screen = Size(400, 800);

  group('camera maths', () {
    test('object straight ahead lands on screen centre', () {
      final pj = Projector(Pose.initial, screen, 60);
      final p = pj.project(Vec3.direction(0, 0) * 5);
      expect(p.inFront, isTrue);
      expect(p.screen.dx, closeTo(200, 0.01));
      expect(p.screen.dy, closeTo(400, 0.01));
    });

    test('object to the right appears right of centre, above appears higher', () {
      final pj = Projector(Pose.initial, screen, 60);
      expect(pj.project(Vec3.direction(10, 0) * 5).screen.dx, greaterThan(200));
      expect(pj.project(Vec3.direction(0, 10) * 5).screen.dy, lessThan(400));
    });

    test('turning the phone right brings a right-hand object to the centre', () {
      final pj = Projector(Pose.fromYawPitch(40, 0), screen, 60);
      final p = pj.project(Vec3.direction(40, 0) * 5);
      expect(p.screen.dx, closeTo(200, 0.5));
    });

    test('object behind the worker is not drawn', () {
      final pj = Projector(Pose.initial, screen, 60);
      expect(pj.project(Vec3.direction(180, 0) * 5).inFront, isFalse);
    });

    test('bearing shift and wrap', () {
      expect(Vec3.direction(30, 0).shiftBearing(20).bearingDeg, closeTo(50, 1e-9));
      expect(wrapDeg(190), closeTo(-170, 1e-9));
      final pose = Pose.fromYawPitch(75, 20);
      expect(pose.forward.dot(pose.up), closeTo(0, 1e-9));
      expect(pose.up.z, greaterThan(0));
    });
  });

  group('find hazards', () {
    test('score counts hazards found and penalises false alarms', () {
      final t = FindHazardsTask(ArTask(
        id: 'h',
        type: ArTaskType.findHazards,
        prompt: const {},
        feedback: const {},
        timeLimitSec: 60,
        objects: [obj('a', SceneObjectKind.hazard), obj('b', SceneObjectKind.hazard), obj('s', SceneObjectKind.safe)],
      ));
      t.select(t.objects[2]); // safe item flagged
      t.select(t.objects[0]);
      t.select(t.objects[1]);
      expect(t.finished, isTrue);
      expect(t.score, closeTo((2 - 0.25) / 2, 1e-9));
    });
  });

  group('extinguisher (P-A-S-S)', () {
    ExtinguishTask make() => ExtinguishTask(ArTask(
          id: 'e',
          type: ArTaskType.extinguish,
          prompt: const {},
          feedback: const {},
          timeLimitSec: 60,
          objects: [obj('fire', SceneObjectKind.fire)],
          config: const {'capacitySec': 12, 'startIntensity': 0.5, 'growthPerSec': 0.03},
        ));

    /// Simulates the fire drawn at a fixed spot while the reticle moves.
    void run(ExtinguishTask t, {required double seconds, required Offset Function(double time, Rect fire) aimAt}) {
      const base = Offset(200, 500);
      const dt = 1 / 30;
      for (var time = 0.0; time < seconds && !t.finished; time += dt) {
        final fire = fireRect(base, 200, t.intensity);
        final p = ProjectedObject(t.fire, base, 200, true, Offset.zero, fire);
        t.update(dt, FrameInfo(objects: {'fire': p}, reticle: aimAt(time, fire), size: screen));
      }
    }

    Offset sweepAtBase(double time, Rect fire) =>
        Offset(fire.center.dx + fire.width * 0.3 * (time % 1.0 < 0.5 ? 1 : -1) * ((time * 4) % 1.0), fire.bottom - fire.height * 0.15);

    test('pulling pin, aiming at base and sweeping puts the fire out', () {
      final t = make()
        ..pullPin()
        ..setSpraying(true);
      run(t, seconds: 15, aimAt: sweepAtBase);
      expect(t.outcome, TaskOutcome.done);
      expect(t.intensity, 0);
      expect(t.score, greaterThan(0.8));
    });

    test('aiming at the flames empties the extinguisher without putting the fire out', () {
      final t = make()
        ..pullPin()
        ..setSpraying(true);
      run(t, seconds: 20, aimAt: (_, fire) => Offset(fire.center.dx, fire.top + fire.height * 0.2));
      expect(t.outcome, TaskOutcome.extinguisherEmpty);
      expect(t.score, lessThan(0.1));
    });

    test('spraying before pulling the pin does nothing and costs marks', () {
      final t = make()..setSpraying(true);
      expect(t.spraying, isFalse);
      expect(t.triedWithoutPin, isTrue);
      t
        ..pullPin()
        ..setSpraying(true);
      run(t, seconds: 15, aimAt: sweepAtBase);
      expect(t.outcome, TaskOutcome.done);
      expect(t.score, lessThan(0.9));
    });

    test('an ignored fire grows until it is too big', () {
      final t = make();
      run(t, seconds: 30, aimAt: (_, f) => Offset.zero);
      expect(t.outcome, TaskOutcome.fireTooBig);
    });
  });

  group('gas test', () {
    GasTestTask make() => GasTestTask(ArTask(
          id: 'g',
          type: ArTaskType.gasTest,
          prompt: const {},
          feedback: const {},
          timeLimitSec: 60,
          objects: [obj('sump', SceneObjectKind.sump, elevation: -55, distance: 1.6)],
          config: const {
            'holdSec': 1,
            'levels': [
              {'id': 'top', 'label': {'en': 'Top'}, 'elevation': -30, 'readings': {'o2': 20.9, 'h2s': 0}},
              {'id': 'bottom', 'label': {'en': 'Bottom'}, 'elevation': -70, 'readings': {'o2': 17.5, 'h2s': 25}},
            ],
          },
        ));

    void measure(GasTestTask t, String levelId) {
      final level = t.objects.firstWhere((o) => o.id == levelId);
      t.setMeasuring(true);
      for (var i = 0; i < 40; i++) {
        t.update(1 / 30, FrameInfo(objects: const {}, reticle: Offset.zero, size: screen, focused: level));
      }
      t.setMeasuring(false);
    }

    test('testing every level and refusing entry scores full marks', () {
      final t = make();
      measure(t, 'top');
      measure(t, 'bottom');
      expect(t.measured.length, 2);
      expect(t.actuallySafe, isFalse);
      t.decide(safe: false);
      expect(t.score, closeTo(1, 1e-9));
    });

    test('testing only the top and entering is marked wrong', () {
      final t = make();
      measure(t, 'top');
      t.decide(safe: true);
      expect(t.score, closeTo(0.25, 1e-9));
    });
  });
}
