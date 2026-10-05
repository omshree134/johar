import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/certificate/certificate_codec.dart';
import '../models/attempt_record.dart';
import '../models/certificate_record.dart';
import '../models/worker.dart';

/// Single JSON file on the phone. It is the source of truth; Firestore is a
/// copy that catches up whenever there is internet. Supports several workers
/// on one shared supervisor phone.
class LocalStore extends ChangeNotifier {
  LocalStore._(this._file);

  final File _file;
  final List<Worker> workers = [];
  final List<AttemptRecord> attempts = [];
  final List<CertificateRecord> certificates = [];
  String? activeWorkerId;
  Future<void> _writeChain = Future.value();

  static Future<LocalStore> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final store = LocalStore._(File('${dir.path}/johar_store.json'));
    await store._load();
    return store;
  }

  Worker? get activeWorker {
    for (final w in workers) {
      if (w.id == activeWorkerId) return w;
    }
    return null;
  }

  List<Worker> get unsyncedWorkers => workers.where((w) => !w.synced).toList();
  List<AttemptRecord> get unsyncedAttempts => attempts.where((a) => !a.synced).toList();
  int get pendingCount => unsyncedWorkers.length + unsyncedAttempts.length;

  bool hasPassed(String workerId, String moduleId) =>
      attempts.any((a) => a.workerId == workerId && a.moduleId == moduleId && a.passed);

  List<CertificateRecord> certificatesFor(String workerId) =>
      certificates.where((c) => c.workerId == workerId).toList()..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

  /// Passed attempts whose certificate has not arrived from the server yet.
  List<AttemptRecord> pendingCertificatesFor(String workerId) => attempts
      .where((a) => a.workerId == workerId && a.passed && !certificates.any((c) => c.certId == a.id))
      .toList();

  Future<void> addWorker(Worker w) async {
    workers.add(w);
    activeWorkerId = w.id;
    await _save();
  }

  Future<void> setActiveWorker(String id) async {
    activeWorkerId = id;
    await _save();
  }

  Future<void> addAttempt(AttemptRecord a) async {
    attempts.add(a);
    await _save();
  }

  Future<void> markSynced({required Set<String> workerIds, required Set<String> attemptIds}) async {
    for (final w in workers) {
      if (workerIds.contains(w.id)) w.synced = true;
    }
    for (final a in attempts) {
      if (attemptIds.contains(a.id)) a.synced = true;
    }
    await _save();
  }

  Future<void> upsertCertificates(List<CertificateRecord> incoming) async {
    if (incoming.isEmpty) return;
    final codec = CertificateCodec.production();
    for (final c in incoming) {
      final existingIndex = certificates.indexWhere((e) => e.certId == c.certId);
      if (existingIndex != -1) {
        final existingRes = await codec.verify(certificates[existingIndex].token);
        final incomingRes = await codec.verify(c.token);
        if (existingRes.status == VerifyStatus.valid && incomingRes.status != VerifyStatus.valid) {
          continue; // Preserve genuine local certificate signature
        }
        certificates[existingIndex] = c;
      } else {
        certificates.add(c);
      }
    }
    await _save();
  }

  Future<void> _load() async {
    if (!await _file.exists()) return;
    try {
      final j = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      activeWorkerId = j['activeWorkerId'] as String?;
      workers.addAll([for (final w in j['workers'] as List? ?? []) Worker.fromJson(w as Map<String, dynamic>)]);
      attempts.addAll([for (final a in j['attempts'] as List? ?? []) AttemptRecord.fromJson(a as Map<String, dynamic>)]);
      certificates.addAll([for (final c in j['certificates'] as List? ?? []) CertificateRecord.fromJson(c as Map<String, dynamic>)]);
    } catch (e) {
      // Corrupt file: keep a copy for debugging and start fresh rather than crash.
      debugPrint('LocalStore: could not read store ($e)');
      await _file.copy('${_file.path}.corrupt');
    }
  }

  /// Writes are serialised and atomic (temp file + rename) so a crash or
  /// battery death mid-write never loses a worker's results.
  Future<void> _save() {
    notifyListeners();
    final data = jsonEncode({
      'version': 1,
      'activeWorkerId': activeWorkerId,
      'workers': [for (final w in workers) w.toJson()],
      'attempts': [for (final a in attempts) a.toJson()],
      'certificates': [for (final c in certificates) c.toJson()],
    });
    return _writeChain = _writeChain.then((_) async {
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(data, flush: true);
      await tmp.rename(_file.path);
    });
  }
}
