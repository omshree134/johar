import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_scope.dart';
import '../../core/config/cert_keys.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/johar_header.dart';
import '../../core/widgets/narration_button.dart';
import '../../data/content/module_catalog.dart';
import '../../data/models/attempt_record.dart';
import '../../data/models/localized.dart';
import '../../data/models/module_content.dart';
import '../module/lesson_screen.dart';
import 'refresher_store.dart';

/// 5 quick questions, no hints, no feedback until the end: this measures what
/// the worker actually remembers a week after training.
class RefresherScreen extends StatefulWidget {
  const RefresherScreen({super.key, required this.entry, required this.source});
  final ModuleCatalogEntry entry;
  final AttemptRecord source;

  static const questionCount = 5;

  @override
  State<RefresherScreen> createState() => _RefresherScreenState();
}

class _RefresherScreenState extends State<RefresherScreen> {
  List<({Question q, List<int> order})>? _items;
  late List<int?> _answers;
  int _index = 0;
  double? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items != null) return;
    AppScope.of(context).content.load(widget.entry).then((m) {
      final rng = Random();
      // Critical (life-safety) questions first, then random others.
      final critical = m.questions.where((q) => q.critical).toList()..shuffle(rng);
      final others = m.questions.where((q) => !q.critical).toList()..shuffle(rng);
      final picked = [...critical, ...others].take(RefresherScreen.questionCount).toList()..shuffle(rng);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final q in picked) (q: q, order: List<int>.generate(q.options.length, (i) => i)..shuffle(rng)),
        ];
        _answers = List<int?>.filled(picked.length, null);
      });
    });
  }

  Future<void> _finish() async {
    final items = _items!;
    var correct = 0;
    for (var i = 0; i < items.length; i++) {
      final a = _answers[i];
      if (a != null && items[i].order[a] == items[i].q.correctIndex) correct++;
    }
    final pct = correct / items.length * 100;
    final scope = AppScope.of(context);
    final store = scope.store;
    await RefresherStore.instance.add(RefresherRecord(
      id: const Uuid().v4(),
      workerId: store.activeWorker!.id,
      moduleId: widget.entry.id,
      sourceAttemptId: widget.source.id,
      originalPercent: widget.source.quizPercent,
      percent: pct,
      daysAfter: DateTime.now().difference(widget.source.completedAt).inDays,
      takenAt: DateTime.now(),
    ));
    scope.sync.syncNow(); // upload now if online; otherwise it waits in the store
    if (mounted) setState(() => _result = pct);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = AppScope.of(context).localeController.contentLang;
    final items = _items;

    if (items == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_result != null) return _ResultView(entry: widget.entry, percent: _result!, before: widget.source.quizPercent);

    final item = items[_index];
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('${l.refresherBannerTitle}: ${widget.entry.title(l)}')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: _index / items.length, minHeight: 8),
            ),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Text(l.questionOf(_index + 1, items.length), style: t.bodyMedium?.copyWith(color: AppColors.slate)),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(tr(item.q.prompt, lang), style: t.headlineSmall)),
                NarrationButton(text: tr(item.q.prompt, lang), lang: lang, compact: true),
              ]),
              const SizedBox(height: 20),
              for (var pos = 0; pos < item.order.length; pos++) ...[
                _Option(
                  text: tr(item.q.options[item.order[pos]], lang),
                  selected: _answers[_index] == pos,
                  onTap: () => setState(() => _answers[_index] = pos),
                ),
                const SizedBox(height: 12),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: FilledButton(
              onPressed: _answers[_index] == null
                  ? null
                  : () => _index < items.length - 1 ? setState(() => _index++) : _finish(),
              child: Text(_index < items.length - 1 ? l.next : l.seeResult),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.manganeseSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: selected ? AppColors.manganese : AppColors.line, width: selected ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(children: [
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? AppColors.manganese : AppColors.slate),
                const SizedBox(width: 14),
                Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
              ]),
            ),
          ),
        ),
      );
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.entry, required this.percent, required this.before});
  final ModuleCatalogEntry entry;
  final double percent;
  final double before;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final good = percent >= kPassMark;
    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        JoharHeader(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            Icon(good ? Icons.psychology_rounded : Icons.replay_rounded, color: Colors.white, size: 52),
            const SizedBox(height: 12),
            Text(l.refresherResultTitle, style: t.headlineMedium?.copyWith(color: Colors.white)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SoftCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.refresherRemembered(percent.round()),
                    style: t.headlineSmall?.copyWith(color: good ? AppColors.safeGreen : AppColors.fireRed)),
                const SizedBox(height: 6),
                Text(l.refresherBefore(before.round()), style: t.bodyLarge?.copyWith(color: AppColors.slate)),
                const SizedBox(height: 14),
                _Bar(label: '7d', value: percent / 100, color: good ? AppColors.safeGreen : AppColors.fireRed),
                const SizedBox(height: 8),
                _Bar(label: '0d', value: before / 100, color: AppColors.manganese),
              ]),
            ),
            const SizedBox(height: 16),
            Text(good ? l.refresherGood : l.refresherRetake, style: t.bodyLarge),
            const SizedBox(height: 24),
            if (!good) ...[
              FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(builder: (_) => LessonScreen(entry: entry)),
                ),
                child: Text(l.retakeTraining),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l.backHome)),
          ]),
        ),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(width: 32, child: Text(label, style: const TextStyle(color: AppColors.slate, fontWeight: FontWeight.w700))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: value.clamp(0.0, 1.0).toDouble(), minHeight: 12, color: color),
          ),
        ),
      ]);
}
