import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_icons.dart';
import '../../core/widgets/narration_button.dart';
import '../../core/widgets/sign_badge.dart';
import '../../data/content/module_catalog.dart';
import '../../data/models/localized.dart';
import '../../data/models/module_content.dart';
import '../ar/ar_task_screen.dart';
import '../assessment/quiz_screen.dart';

/// Flow for one module: lessons -> AR practice -> quiz -> result.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.entry});
  final ModuleCatalogEntry entry;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _pager = PageController();
  final _startedAt = DateTime.now();
  ModuleContent? _module;
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_module == null) {
      AppScope.of(context).content.load(widget.entry).then((m) {
        if (mounted) {
          setState(() => _module = m);
          _speakCurrentLesson();
        }
      });
    }
  }

  void _speakCurrentLesson() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final module = _module;
      if (module == null || !mounted) return;
      if (_page >= 0 && _page < module.lessons.length) {
        final lang = AppScope.of(context).localeController.contentLang;
        final step = module.lessons[_page];
        final title = tr(step.title, lang);
        final body = tr(step.body, lang);
        final spokenText = body.isEmpty ? title : '$title. $body';
        try {
          Narrator.instance.speak(spokenText, lang);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    Narrator.instance.stop();
    _pager.dispose();
    super.dispose();
  }

  Future<void> _startPractice() async {
    Narrator.instance.stop();
    final module = _module!;
    final scores = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(builder: (_) => ArTaskScreen(module: module)),
    );
    if (scores == null || !mounted) return; // worker backed out of practice
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => QuizScreen(module: module, arScores: scores, startedAt: _startedAt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = AppScope.of(context).localeController.contentLang;
    final module = _module;

    return Scaffold(
      appBar: AppBar(title: Text(widget.entry.title(l))),
      body: module == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _StepProgress(current: _page, total: module.lessons.length),
                  Expanded(
                    child: PageView.builder(
                      controller: _pager,
                      itemCount: module.lessons.length,
                      onPageChanged: (p) {
                        setState(() => _page = p);
                        _speakCurrentLesson();
                      },
                      itemBuilder: (context, i) => _LessonPage(
                        step: module.lessons[i],
                        sign: module.sign,
                        lang: lang,
                        label: l.lessonStep(i + 1, module.lessons.length),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        if (_page > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pager.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                              child: Text(l.back),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: _page < module.lessons.length - 1
                              ? FilledButton(
                                  onPressed: () => _pager.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                                  child: Text(l.next),
                                )
                              : FilledButton.icon(
                                  onPressed: _startPractice,
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: Text(l.startPractice),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.manganese : AppColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonPage extends StatelessWidget {
  const _LessonPage({required this.step, required this.sign, required this.lang, required this.label});
  final LessonStep step;
  final SignKind sign;
  final String lang;
  final String label;

  static const Map<String, String> _stepAssets = {
    'alarm': 'assets/ar/items/fire_alarm.png',
    'exit': 'assets/ar/items/exit_sign.png',
    'extinguisher': 'assets/ar/items/extinguisher.png',
    'assembly': 'assets/ar/items/assembly_point.png',
    'stairs': 'assets/ar/items/stairs.png',
    'elevator': 'assets/ar/items/lift.png',
    'smoke': 'assets/ar/items/smoking_drums.png',
    'gas': 'assets/ar/items/gas_cylinder.png',
    'detector': 'assets/ar/items/gas_detector.png',
    'harness': 'assets/ar/items/harness.png',
    'helmet': 'assets/ar/items/helmet.png',
    'breathing': 'assets/ar/items/breathing_apparatus.png',
    'mask': 'assets/ar/items/cloth_mask.png',
    'buddy': 'assets/ar/items/attendant.png',
    'tank': 'assets/ar/items/gas_cylinder.png',
    'pit': 'assets/ar/items/pit.png',
    'machinery': 'assets/ar/items/exposed_gears.png',
    'warning': 'assets/ar/items/danger_tag.png',
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final title = tr(step.title, lang);
    final body = tr(step.body, lang);
    final spokenText = body.isEmpty ? title : '$title. $body';
    final imageAsset = _stepAssets[step.icon];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        // Top Action Header with Step Pill and Replay Audio
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.manganeseSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.manganese,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            NarrationButton(text: spokenText, lang: lang, compact: true),
          ],
        ),
        const SizedBox(height: 16),

        // Visual Illustration Hero Card
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Real equipment illustration or fallback icon
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: imageAsset != null
                      ? Image.asset(
                          imageAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(AppIcons.of(step.icon), size: 90, color: AppColors.manganese),
                        )
                      : Icon(AppIcons.of(step.icon), size: 90, color: AppColors.manganese),
                ),
              ),
              // Prominent ISO 7010 compliance badge in the top corner
              Positioned(
                top: 14,
                left: 14,
                child: SignBadge(kind: sign, icon: AppIcons.of(step.icon), size: 52),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Text & Instructions Content Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.headlineSmall?.copyWith(
                  color: AppColors.coal,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                body,
                style: t.bodyLarge?.copyWith(
                  color: AppColors.slate,
                  height: 1.55,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
