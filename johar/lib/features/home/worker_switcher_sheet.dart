import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../onboarding/register_worker_screen.dart';

/// Contract workers often share one supervisor phone. This lets the
/// supervisor switch between workers or add a new one.
Future<void> showWorkerSwitcher(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _WorkerSwitcher(),
    );

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  return parts.take(2).map((p) => p.characters.first).join().toUpperCase();
}

class _WorkerSwitcher extends StatelessWidget {
  const _WorkerSwitcher();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = AppScope.of(context).store;
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.workersTitle, style: t.titleLarge),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
            child: ListView(shrinkWrap: true, children: [
              for (final w in store.workers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: w.id == store.activeWorkerId ? AppColors.manganeseSoft : AppColors.mineral,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.ochreSoft,
                        child: Text(initialsOf(w.name),
                            style: const TextStyle(color: AppColors.ochre, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${w.employeeId} · ${w.employer}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: w.id == store.activeWorkerId
                          ? const Icon(Icons.check_circle, color: AppColors.manganese)
                          : null,
                      onTap: () async {
                        await store.setActiveWorker(w.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RegisterWorkerScreen()));
            },
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(l.addWorker),
          ),
        ]),
      ),
    );
  }
}
