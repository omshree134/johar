import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/content/module_catalog.dart';
import '../module/lesson_screen.dart';
import '../refresher/refresher_screen.dart';
import '../refresher/refresher_store.dart';

/// Periodic certification (Factories Act / Mines Act): warns 30 days before a
/// certificate expires, and after it has expired, with a one-tap retake.
class CertificateStatusBanner extends StatelessWidget {
  const CertificateStatusBanner({super.key});

  static const warnBefore = Duration(days: 30);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = AppScope.of(context).store;
    final worker = store.activeWorker;
    if (worker == null) return const SizedBox.shrink();

    final now = DateTime.now();
    // Newest certificate per module.
    final latest = <String, DateTime>{};
    for (final c in store.certificatesFor(worker.id)) {
      if (c.status != 'active') continue;
      final cur = latest[c.moduleId];
      if (cur == null || c.expiresAt.isAfter(cur)) latest[c.moduleId] = c.expiresAt;
    }
    final entries = latest.entries.where((e) => e.value.difference(now) < warnBefore).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (entries.isEmpty) return const SizedBox.shrink();

    final e = entries.first;
    final module = moduleCatalog.firstWhere((m) => m.id == e.key, orElse: () => moduleCatalog.first);
    final expired = e.value.isBefore(now);
    final days = e.value.difference(now).inDays;

    return _Banner(
      icon: expired ? Icons.event_busy_rounded : Icons.schedule_rounded,
      color: expired ? AppColors.fireRed : AppColors.warningYellow,
      background: expired ? AppColors.fireRedSoft : AppColors.warningSoft,
      title: expired ? l.certExpiredBanner(module.title(l)) : l.certExpiresSoon(module.title(l), days),
      action: l.retakeTraining,
      onTap: module.available
          ? () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => LessonScreen(entry: module)))
          : null,
    );
  }
}

/// 7 days after passing, invites the worker to a 5-question memory check.
class RefresherBanner extends StatelessWidget {
  const RefresherBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = AppScope.of(context).store;
    final worker = store.activeWorker;
    if (worker == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: RefresherStore.instance,
      builder: (context, _) {
        final due = RefresherStore.instance.dueFor(store, worker.id);
        if (due.isEmpty) return const SizedBox.shrink();
        final attempt = due.first;
        final module = moduleCatalog.firstWhere((m) => m.id == attempt.moduleId, orElse: () => moduleCatalog.first);
        return _Banner(
          icon: Icons.psychology_rounded,
          color: AppColors.mandatoryBlue,
          background: AppColors.mandatorySoft,
          title: l.refresherBannerTitle,
          body: l.refresherBannerBody(module.title(l)),
          action: l.refresherStart,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => RefresherScreen(entry: module, source: attempt)),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.action,
    this.body,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String? body;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadii.md)),
                child: Icon(icon, color: color == AppColors.warningYellow ? AppColors.coal : Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: t.titleMedium),
                  if (body != null) Text(body!, style: t.bodyMedium?.copyWith(color: AppColors.slate)),
                  if (onTap != null) ...[
                    const SizedBox(height: 6),
                    Text(action, style: const TextStyle(color: AppColors.manganese, fontWeight: FontWeight.w700)),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
