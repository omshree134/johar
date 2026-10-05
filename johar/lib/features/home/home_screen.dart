import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/johar_header.dart';
import '../../core/widgets/sign_badge.dart';
import '../../data/content/module_catalog.dart';
import '../../data/sync/sync_service.dart';
import '../certificate/verify_screen.dart';
import '../module/lesson_screen.dart';
import '../onboarding/language_screen.dart';
import 'home_banners.dart';
import 'worker_switcher_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final t = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([scope.store, scope.sync]),
      builder: (context, _) {
        final worker = scope.store.activeWorker!;
        final available = moduleCatalog.where((m) => m.available).toList();
        final passed = available.where((m) => scope.store.hasPassed(worker.id, m.id)).length;

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            JoharHeader(
              overlap: 64,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  // Tap the avatar to switch worker on a shared phone.
                  InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () => showWorkerSwitcher(context),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.ochre,
                        child: Text(initialsOf(worker.name),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.expand_more_rounded, color: Colors.white70),
                    ]),
                  ),
                  const Spacer(),
                  _GlassButton(
                    icon: Icons.qr_code_scanner_rounded,
                    tooltip: l.navVerify,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const VerifyScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GlassButton(
                    icon: Icons.translate_rounded,
                    tooltip: l.changeLanguage,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const LanguageScreen(popOnSelect: true)),
                    ),
                  ),
                ]),
                const SizedBox(height: 18),
                Text(
                  l.homeJohar(worker.name.split(' ').first),
                  style: t.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(l.homeSubtitle, style: const TextStyle(color: Color(0xFFD9D4E8), fontSize: 16)),
              ]),
            ),
            Transform.translate(
              offset: const Offset(0, -64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _ProgressCard(
                    passed: passed,
                    total: available.length,
                    passedIds: {for (final m in available) if (scope.store.hasPassed(worker.id, m.id)) m.id},
                    sync: scope.sync,
                    pending: scope.store.pendingCount,
                  ),
                  const SizedBox(height: 16),
                  const CertificateStatusBanner(),
                  const RefresherBanner(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                    child: Text(l.sectionTrainings, style: t.titleLarge),
                  ),
                  for (final entry in moduleCatalog) ...[
                    _ModuleTile(entry: entry, passed: scope.store.hasPassed(worker.id, entry.id)),
                    const SizedBox(height: 12),
                  ],
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, color: Colors.white)),
          ),
        ),
      );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.passed,
    required this.total,
    required this.passedIds,
    required this.sync,
    required this.pending,
  });
  final int passed;
  final int total;
  final Set<String> passedIds;
  final SyncService sync;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final (syncIcon, syncText, syncColor) = switch ((sync.state, pending)) {
      (SyncState.syncing, _) => (Icons.cloud_sync_rounded, l.syncWorking, AppColors.manganese),
      (_, > 0) => (Icons.cloud_off_rounded, l.syncPending(pending), AppColors.slate),
      _ => (Icons.cloud_done_rounded, l.syncDone, AppColors.safeGreen),
    };
    final available = moduleCatalog.where((m) => m.available).toList();

    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(l.progressTitle, style: t.titleMedium)),
          Text('$passed/$total', style: t.headlineSmall?.copyWith(color: AppColors.manganese)),
        ]),
        const SizedBox(height: 4),
        Text(l.progressCount(passed, total), style: t.bodyMedium?.copyWith(color: AppColors.slate)),
        const SizedBox(height: 14),
        // One segment per training, green once passed.
        Row(children: [
          for (var i = 0; i < available.length; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 10,
                decoration: BoxDecoration(
                  color: passedIds.contains(available[i].id) ? AppColors.safeGreen : AppColors.line,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            if (i < available.length - 1) const SizedBox(width: 6),
          ],
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Icon(syncIcon, size: 18, color: syncColor),
          const SizedBox(width: 6),
          Flexible(child: Text(syncText, style: TextStyle(color: syncColor, fontWeight: FontWeight.w700, fontSize: 14))),
        ]),
      ]),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.entry, required this.passed});
  final ModuleCatalogEntry entry;
  final bool passed;

  static Color _tint(SignKind k) => switch (k) {
        SignKind.fireEquipment || SignKind.prohibition => AppColors.fireRedSoft,
        SignKind.warning => AppColors.warningSoft,
        SignKind.mandatory => AppColors.mandatorySoft,
        SignKind.safeCondition => AppColors.safeGreenSoft,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final available = entry.available;
    final t = Theme.of(context).textTheme;

    final status = !available
        ? Pill(text: l.comingSoon, color: AppColors.slate, icon: Icons.lock_clock_rounded)
        : passed
            ? Pill(text: l.passedStatus, color: AppColors.safeGreen, icon: Icons.verified_rounded)
            : Pill(text: l.notStarted, color: AppColors.manganese, icon: Icons.play_circle_outline_rounded);

    return Opacity(
      opacity: available ? 1 : 0.7,
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        onTap: available
            ? () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => LessonScreen(entry: entry)))
            : null,
        child: Row(children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: available ? _tint(entry.sign) : AppColors.mineral,
              borderRadius: BorderRadius.circular(AppRadii.md + 2),
            ),
            child: SignBadge(kind: entry.sign, icon: AppIcons.of(entry.icon), size: 58, muted: !available),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.title(l), style: t.titleMedium),
              const SizedBox(height: 8),
              status,
            ]),
          ),
          if (available)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.mineral, borderRadius: BorderRadius.circular(AppRadii.sm)),
              child: const Icon(Icons.arrow_forward_rounded, color: AppColors.manganese),
            ),
        ]),
      ),
    );
  }
}
