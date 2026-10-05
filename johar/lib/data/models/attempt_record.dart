class AttemptRecord {
  AttemptRecord({
    required this.id,
    required this.workerId,
    required this.moduleId,
    required this.quizPercent,
    required this.arPercent,
    required this.totalPercent,
    required this.passed,
    required this.criticalMissed,
    required this.wrongQuestionIds,
    required this.startedAt,
    required this.completedAt,
    required this.arMode,
    this.synced = false,
  });

  final String id;
  final String workerId;
  final String moduleId;
  final double quizPercent;
  final double arPercent;
  final double totalPercent;
  final bool passed;
  final List<String> criticalMissed;
  final List<String> wrongQuestionIds; // feeds the admin "weak topics" report
  final DateTime startedAt;
  final DateTime completedAt;
  final String arMode;
  bool synced;

  Map<String, dynamic> toJson() => {
        ...toFirestoreBase(),
        'id': id,
        'synced': synced,
      };

  Map<String, dynamic> toFirestoreBase() => {
        'workerId': workerId,
        'moduleId': moduleId,
        'quizPercent': quizPercent,
        'arPercent': arPercent,
        'totalPercent': totalPercent,
        'passed': passed,
        'criticalMissed': criticalMissed,
        'wrongQuestionIds': wrongQuestionIds,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'durationSec': completedAt.difference(startedAt).inSeconds,
        'arMode': arMode,
      };

  Map<String, dynamic> toFirestore(String deviceUid) => {...toFirestoreBase(), 'deviceUid': deviceUid};

  factory AttemptRecord.fromJson(Map<String, dynamic> j) => AttemptRecord(
        id: j['id'] as String,
        workerId: j['workerId'] as String,
        moduleId: j['moduleId'] as String,
        quizPercent: (j['quizPercent'] as num).toDouble(),
        arPercent: (j['arPercent'] as num).toDouble(),
        totalPercent: (j['totalPercent'] as num).toDouble(),
        passed: j['passed'] as bool,
        criticalMissed: List<String>.from(j['criticalMissed'] as List? ?? const []),
        wrongQuestionIds: List<String>.from(j['wrongQuestionIds'] as List? ?? const []),
        startedAt: DateTime.parse(j['startedAt'] as String),
        completedAt: DateTime.parse(j['completedAt'] as String),
        arMode: j['arMode'] as String? ?? 'cameraOverlay',
        synced: j['synced'] as bool? ?? false,
      );
}
