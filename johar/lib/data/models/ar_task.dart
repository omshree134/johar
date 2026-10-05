import 'localized.dart';

enum ArTaskType {
  /// Look all around and report every hazard (decoys are safe things).
  findHazards,

  /// Hazard spreads over time; pick the safe way out.
  chooseExit,

  /// P-A-S-S extinguisher simulation: pull pin, aim at base, squeeze, sweep.
  extinguish,

  /// Point a gas detector at top/middle/bottom, then decide if entry is safe.
  gasTest,

  /// Pick every correct item placed around the worker, then check.
  selectSet,

  /// Do the steps in the right order (evacuation, lockout-tagout, rescue).
  /// Items without an `order` are wrong actions.
  sequence,
}

enum SceneObjectKind { hazard, safe, exit, item, fire, gasLeak, sump, level }

/// Something placed around the worker. Position is a direction plus distance
/// from where they stand, so it stays put in the room as they turn:
///   bearing   = degrees clockwise from the direction they faced at start
///   elevation = degrees above the horizon (negative = on the floor)
///   distance  = metres
class SceneObject {
  const SceneObject({
    required this.id,
    required this.kind,
    required this.label,
    required this.icon,
    required this.bearing,
    required this.elevation,
    required this.distance,
    this.image,
    this.description = const {},
    this.correct = false,
    this.order,
    this.info = const {},
    this.alwaysShowLabel = false,
  });

  final String id;
  final SceneObjectKind kind;
  final LocalizedText label;
  final String icon; // fallback when there is no picture
  final String? image; // assets/ar/items/<image>.png
  final LocalizedText description; // shown on the inspect card
  final double bearing;
  final double elevation;
  final double distance;
  final bool correct;
  final int? order; // sequence tasks: 1-based step number
  final LocalizedText info; // feedback after the worker acts on it

  /// Pictures hide their name until tapped, so workers learn to recognise
  /// the real object. Set true for things that must always be labelled.
  final bool alwaysShowLabel;

  String? get imageAsset => image == null ? null : 'assets/ar/items/$image.png';

  factory SceneObject.fromJson(Map<String, dynamic> j) => SceneObject(
        id: j['id'] as String,
        kind: SceneObjectKind.values.byName(j['kind'] as String),
        label: parseLocalized(j['label']),
        icon: j['icon'] as String? ?? 'warning',
        image: j['image'] as String?,
        description: parseLocalized(j['description']),
        bearing: (j['bearing'] as num).toDouble(),
        elevation: (j['elevation'] as num? ?? 0).toDouble(),
        distance: (j['distance'] as num? ?? 4).toDouble(),
        correct: j['correct'] as bool? ?? false,
        order: j['order'] as int?,
        info: parseLocalized(j['info']),
        alwaysShowLabel: j['alwaysShowLabel'] as bool? ?? false,
      );
}

class ArTask {
  const ArTask({
    required this.id,
    required this.type,
    required this.prompt,
    required this.feedback,
    required this.timeLimitSec,
    required this.objects,
    this.config = const {},
  });

  final String id;
  final ArTaskType type;
  final LocalizedText prompt;
  final LocalizedText feedback;
  final int timeLimitSec;
  final List<SceneObject> objects;
  final Map<String, dynamic> config;

  Iterable<String> get imageNames => objects.map((o) => o.image).whereType<String>();

  factory ArTask.fromJson(Map<String, dynamic> j) => ArTask(
        id: j['id'] as String,
        type: ArTaskType.values.byName(j['type'] as String),
        prompt: parseLocalized(j['prompt']),
        feedback: parseLocalized(j['feedback']),
        timeLimitSec: j['timeLimitSec'] as int? ?? 45,
        objects: [for (final o in j['objects'] as List? ?? const []) SceneObject.fromJson(o as Map<String, dynamic>)],
        config: j['config'] as Map<String, dynamic>? ?? const {},
      );
}
