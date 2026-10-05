import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/local/local_store.dart';
import '../../data/models/attempt_record.dart';

/// Result of a 7-day memory check. Compared with the worker's original test
/// score, this measures retention: the problem statement says classroom
/// training keeps under 20% after one week.
class RefresherRecord {
  RefresherRecord({
    required this.id,
    required this.workerId,
    required this.moduleId,
    required this.sourceAttemptId,
    required this.originalPercent,
    required this.percent,
    required this.daysAfter,
    required this.takenAt,
    this.synced = false,
  });

  final String id;
  final String workerId;
  final String moduleId;
  final String sourceAttemptId;
  final double originalPercent; // quiz score right after training
  final double percent; // score now
  final int daysAfter;
  final DateTime takenAt;
  bool synced;

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'moduleId': moduleId,
        'sourceAttemptId': sourceAttemptId,
        'originalPercent': originalPercent,
        'percent': percent,
        'daysAfter': daysAfter,
        'takenAt': takenAt.toIso8601String(),
        'synced': synced,
      };

  Map<String, dynamic> toFirestore(String deviceUid) =>
      {...toJson()..remove('synced')..remove('id'), 'deviceUid': deviceUid};

  factory RefresherRecord.fromJson(Map<String, dynamic> j) => RefresherRecord(
        id: j['id'] as String,
        workerId: j['workerId'] as String,
        moduleId: j['moduleId'] as String,
        sourceAttemptId: j['sourceAttemptId'] as String,
        originalPercent: (j['originalPercent'] as num).toDouble(),
        percent: (j['percent'] as num).toDouble(),
        daysAfter: j['daysAfter'] as int? ?? 7,
        takenAt: DateTime.parse(j['takenAt'] as String),
        synced: j['synced'] as bool? ?? false,
      );
}

/// Separate small JSON file so the main LocalStore stays unchanged.
/// Call `await RefresherStore.init()` in main() before runApp.
class RefresherStore extends ChangeNotifier {
  RefresherStore._(this._file);

  static RefresherStore? _instance;
  static RefresherStore get instance => _instance!;

  /// How long after passing the memory check becomes due.
  static const interval = Duration(days: 7);

  final File _file;
  final List<RefresherRecord> records = [];
  Future<void> _writeChain = Future.value();

  static Future<RefresherStore> init() async {
    if (_instance != null) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    final s = RefresherStore._(File('${dir.path}/johar_refreshers.json'));
    if (await s._file.exists()) {
      try {
        final list = jsonDecode(await s._file.readAsString()) as List;
        s.records.addAll(list.map((e) => RefresherRecord.fromJson(e as Map<String, dynamic>)));
      } catch (e) {
        debugPrint('RefresherStore: unreadable file ($e), starting fresh');
      }
    }
    return _instance = s;
  }

  /// Latest passed attempt per module that is at least [interval] old and
  /// has not had its memory check yet.
  List<AttemptRecord> dueFor(LocalStore store, String workerId, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final latest = <String, AttemptRecord>{};
    for (final a in store.attempts) {
      if (a.workerId != workerId || !a.passed) continue;
      final cur = latest[a.moduleId];
      if (cur == null || a.completedAt.isAfter(cur.completedAt)) latest[a.moduleId] = a;
    }
    return latest.values
        .where((a) => t.difference(a.completedAt) >= interval)
        .where((a) => !records.any((r) => r.sourceAttemptId == a.id))
        .toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }

  Future<void> add(RefresherRecord r) async {
    records.add(r);
    await _save();
  }

  List<RefresherRecord> get unsynced => records.where((r) => !r.synced).toList();

  /// Called from SyncService.syncNow() after attempts are pushed.
  /// `employerOf` adds the worker's employer so supervisors in the web
  /// portal can read their own company's memory checks (see firestore.rules).
  Future<void> push(FirebaseFirestore db, String uid, {String Function(String workerId)? employerOf}) async {
    final pending = unsynced;
    if (pending.isEmpty) return;
    final batch = db.batch();
    for (final r in pending) {
      batch.set(db.collection('refreshers').doc(r.id), {
        ...r.toFirestore(uid),
        'employer': employerOf?.call(r.workerId) ?? '',
      });
    }
    await batch.commit().timeout(const Duration(seconds: 20));
    for (final r in pending) {
      r.synced = true;
    }
    await _save();
  }

  Future<void> _save() {
    notifyListeners();
    final data = jsonEncode([for (final r in records) r.toJson()]);
    return _writeChain = _writeChain.then((_) async {
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(data, flush: true);
      await tmp.rename(_file.path);
    });
  }
}
