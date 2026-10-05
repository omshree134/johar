import 'package:flutter_test/flutter_test.dart';
import 'package:johar/data/models/ar_task.dart';
import 'package:johar/features/ar/tasks/sequence_task.dart';
import 'package:johar/features/ar/tasks/task_controller.dart';

SceneObject step(String id, int? order) => SceneObject(
      id: id,
      kind: SceneObjectKind.item,
      label: const {'en': 'x'},
      icon: 'check',
      bearing: 0,
      elevation: 0,
      distance: 3,
      order: order,
      info: const {'en': 'info'},
    );

SequenceTask make() => SequenceTask(ArTask(
      id: 'loto',
      type: ArTaskType.sequence,
      prompt: const {},
      feedback: const {},
      timeLimitSec: 60,
      objects: [step('stop', 1), step('isolate', 2), step('lock', 3), step('reach_in', null)],
    ));

void main() {
  test('steps in the right order finish with full marks', () {
    final t = make();
    for (final id in ['stop', 'isolate', 'lock']) {
      t.select(t.objects.firstWhere((o) => o.id == id));
    }
    expect(t.finished, isTrue);
    expect(t.score, 1);
    expect(t.stepNumber(t.objects[2]), 3);
  });

  test('wrong order and wrong actions cost marks but can be recovered', () {
    final t = make();
    t.select(t.objects[2]); // lock before stopping: wrong order
    t.select(t.objects[3]); // reach in: a wrong action
    expect(t.stateOf(t.objects[3]), MarkerState.wrong);
    for (final o in t.objects.take(3)) {
      t.select(o);
    }
    expect(t.finished, isTrue);
    expect(t.score, closeTo(1 - 2 / 3, 1e-9));
  });
}
