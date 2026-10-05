import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/l10n/santali_fallback_delegates.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/sign_badge.dart';
import '../../data/content/module_catalog.dart';
import '../../data/models/certificate_record.dart';

String formatDate(BuildContext context, DateTime d) =>
    DateFormat.yMMMd(intlLocaleFor(Localizations.localeOf(context))).format(d);

/// Short, readable form of the certificate ID for printing and reading aloud.
String shortCertId(String id) => (id.length > 8 ? id.substring(0, 8) : id).toUpperCase();

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = AppScope.of(context).store;
    return Scaffold(
      appBar: AppBar(title: Text(l.navCertificates)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final worker = store.activeWorker!;
          final certs = store.certificatesFor(worker.id);
          final pending = store.pendingCertificatesFor(worker.id);
          if (certs.isEmpty && pending.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.certificatesEmpty, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final c in certs)
                _CertTile(
                  moduleId: c.moduleId,
                  subtitle: l.certValidUntil(formatDate(context, c.expiresAt)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => CertificateDetailScreen(cert: c, workerName: worker.name)),
                  ),
                ),
              for (final a in pending) _CertTile(moduleId: a.moduleId, subtitle: l.certPending, pending: true),
            ],
          );
        },
      ),
    );
  }
}

class _CertTile extends StatelessWidget {
  const _CertTile({required this.moduleId, required this.subtitle, this.onTap, this.pending = false});
  final String moduleId;
  final String subtitle;
  final VoidCallback? onTap;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entry = moduleCatalog.firstWhere((e) => e.id == moduleId);
    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: SignBadge(kind: entry.sign, icon: AppIcons.of(entry.icon), size: 48, muted: pending),
        title: Text(entry.title(l), style: Theme.of(context).textTheme.titleMedium),
        subtitle: Row(children: [
          Icon(pending ? Icons.cloud_off_outlined : Icons.verified, size: 16,
              color: pending ? AppColors.slate : AppColors.safeGreen),
          const SizedBox(width: 6),
          Flexible(child: Text(subtitle)),
        ]),
        trailing: pending ? null : const Icon(Icons.qr_code_2, size: 32),
        onTap: onTap,
      ),
    );
  }
}

class CertificateDetailScreen extends StatelessWidget {
  const CertificateDetailScreen({super.key, required this.cert, required this.workerName});
  final CertificateRecord cert;
  final String workerName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entry = moduleCatalog.firstWhere((e) => e.id == cert.moduleId);
    return Scaffold(
      appBar: AppBar(title: Text(entry.title(l))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(workerName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(l.certValidUntil(formatDate(context, cert.expiresAt)),
                style: const TextStyle(color: AppColors.safeGreen, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: cert.token,
                  size: 260,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.certShowHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('${l.certIdLabel}: ${shortCertId(cert.certId)}',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate)),
          ],
        ),
      ),
    );
  }
}
