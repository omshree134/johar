import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../local/local_store.dart';
import '../models/certificate_record.dart';
import '../../features/refresher/refresher_store.dart';

enum SyncState { idle, syncing, offline, disabled }

/// Pushes locally saved workers/attempts to Firestore when online, then pulls
/// back any certificates the Cloud Function has signed. Every write uses a
/// fixed document ID, so re-sending after a timeout is harmless.
class SyncService extends ChangeNotifier {
  SyncService(this.store, {required this.firebaseEnabled});

  final LocalStore store;
  final bool firebaseEnabled;
  SyncState state = SyncState.idle;
  bool _busy = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _debounce;
  int _certRetries = 0;

  void start() {
    if (!firebaseEnabled) {
      state = SyncState.disabled;
      return;
    }
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) syncNow();
    });
    store.addListener(_onStoreChanged);
    syncNow();
  }

  void _onStoreChanged() {
    if (store.pendingCount == 0) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), syncNow);
  }

  Future<void> syncNow() async {
    if (!firebaseEnabled || _busy) return;
    _busy = true;
    _set(SyncState.syncing);
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously().timeout(const Duration(seconds: 15));
      }
      final uid = auth.currentUser!.uid;
      final db = FirebaseFirestore.instance;

      // Employer is copied onto attempts and memory checks so a supervisor in
      // the web portal can query their company's records (firestore.rules
      // can only allow queries it can prove from the query's own filters).
      final employerOf = {for (final w in store.workers) w.id: w.employer};
      final workers = store.unsyncedWorkers;
      final attempts = store.unsyncedAttempts;
      if (workers.isNotEmpty || attempts.isNotEmpty) {
        final batch = db.batch();
        for (final w in workers) {
          batch.set(db.collection('workers').doc(w.id), w.toFirestore(uid));
        }
        for (final a in attempts) {
          batch.set(db.collection('attempts').doc(a.id), {
            ...a.toFirestore(uid),
            'employer': employerOf[a.workerId] ?? '',
          });
        }
        // commit() only completes once the server confirms.
        await batch.commit().timeout(const Duration(seconds: 20));
        await store.markSynced(
          workerIds: {for (final w in workers) w.id},
          attemptIds: {for (final a in attempts) a.id},
        );
      }

      await RefresherStore.instance.push(db, uid, employerOf: (id) => employerOf[id] ?? '');

      final snap = await db
          .collection('certificates')
          .where('deviceUid', isEqualTo: uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      await store.upsertCertificates([for (final d in snap.docs) CertificateRecord.fromFirestore(d.id, d.data())]);
      _set(SyncState.idle);

      // The Cloud Function signs certificates a few seconds after an attempt
      // arrives. If some are still missing, check again shortly.
      final missing = store.workers.any((w) => store.pendingCertificatesFor(w.id).any((a) => a.synced));
      if (missing && _certRetries < 3) {
        _certRetries++;
        Timer(const Duration(seconds: 8), syncNow);
      } else {
        _certRetries = 0;
      }
    } catch (e) {
      debugPrint('Sync failed, will retry when online: $e');
      _set(SyncState.offline);
    } finally {
      _busy = false;
    }
  }

  void _set(SyncState s) {
    state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    store.removeListener(_onStoreChanged);
    super.dispose();
  }
}
