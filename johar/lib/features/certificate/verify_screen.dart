import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/content/module_catalog.dart';
import 'certificate_codec.dart';
import 'certificates_screen.dart' show formatDate, shortCertId;

/// For supervisors and inspectors. Signature check is fully offline; if the
/// phone is online it also checks the certificate has not been cancelled.
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _scanner = MobileScannerController();
  final _codec = CertificateCodec.production();
  VerifyResult? _result;
  bool? _onlineActive; // null = could not check
  bool _busy = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _result != null) return;
    final firebaseEnabled = AppScope.of(context).sync.firebaseEnabled;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null) return;
    _busy = true;
    await _scanner.stop();
    final result = await _codec.verify(raw);
    bool? online;
    if (result.payload != null && firebaseEnabled) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('certificates')
            .doc(result.payload!.certId)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 6));
        if (doc.exists) online = doc.data()?['status'] == 'active';
      } catch (_) {
        online = null; // offline or not signed in: signature result still stands
      }
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _onlineActive = online;
      _busy = false;
    });
  }

  Future<void> _reset() async {
    setState(() {
      _result = null;
      _onlineActive = null;
    });
    await _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navVerify)),
      // The scanner stays mounted so stop()/start() always have a view to drive.
      body: Stack(
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),
          if (_result == null) ...[
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: Text(l.verifyScanHint, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ] else
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.mineral,
                child: _ResultView(result: _result!, onlineActive: _onlineActive, onScanAgain: _reset),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onlineActive, required this.onScanAgain});
  final VerifyResult result;
  final bool? onlineActive;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final revoked = onlineActive == false;
    final ok = result.status == VerifyStatus.valid && !revoked;
    final (color, icon, title) = switch (result.status) {
      _ when revoked => (AppColors.fireRed, Icons.block, l.verifyRevoked),
      VerifyStatus.valid => (AppColors.safeGreen, Icons.verified, l.verifyValid),
      VerifyStatus.expired => (AppColors.warningYellow, Icons.event_busy, l.verifyExpired),
      VerifyStatus.notConfigured => (AppColors.slate, Icons.key_off, l.verifyNotConfigured),
      _ => (AppColors.fireRed, Icons.gpp_bad, l.verifyInvalid),
    };
    final p = result.payload;
    // Only show certificate details if the signature was genuine.
    final showDetails = result.status == VerifyStatus.valid || result.status == VerifyStatus.expired;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        if (showDetails && p != null) ...[
          const SizedBox(height: 24),
          Text(p.workerName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          _Row(l.workerIdLabel, p.employeeId),
          _Row(l.navLearn, _moduleTitle(l, p.moduleId)),
          _Row(l.yourScore(p.score), ''),
          _Row(l.certValidUntil(formatDate(context, p.expiresAt)), ''),
          _Row(l.certIdLabel, shortCertId(p.certId)),
          const SizedBox(height: 12),
          if (ok)
            Row(children: [
              Icon(onlineActive == true ? Icons.cloud_done : Icons.cloud_off, color: AppColors.slate, size: 18),
              const SizedBox(width: 8),
              Text(onlineActive == true ? l.verifyOnlineOk : l.verifyOnlineUnknown,
                  style: const TextStyle(color: AppColors.slate)),
            ]),
        ],
        const SizedBox(height: 32),
        FilledButton.icon(onPressed: onScanAgain, icon: const Icon(Icons.qr_code_scanner), label: Text(l.scanAnother)),
      ],
    );
  }

  String _moduleTitle(AppLocalizations l, String id) {
    for (final e in moduleCatalog) {
      if (e.id == id) return e.title(l);
    }
    return id;
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(value.isEmpty ? label : '$label: $value', style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
