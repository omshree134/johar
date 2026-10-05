import 'package:flutter/material.dart';
import '../../core/app_scope.dart';
import '../../core/services/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/johar_header.dart';
import 'register_worker_screen.dart';

/// Language selection screen. Shown as the first onboarding step or when
/// changing language from settings.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, this.popOnSelect = false});
  final bool popOnSelect;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).localeController;
    final currentCode = controller.selectedCode;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          JoharHeader(
            bottomPadding: 84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (popOnSelect && Navigator.canPop(context))
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  )
                else
                  const SizedBox(height: 32),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF4B400).withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, color: AppColors.warningYellow, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('जोहार', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700, height: 1.1)),
                        Text('Johar', style: TextStyle(color: Color(0xFFD9D4E8), fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'सुरक्षित काम, सुरक्षित घर',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose your language', style: t.headlineSmall),
                const Text('अपनी भाषा चुनें', style: TextStyle(fontSize: 19, color: AppColors.slate)),
                const SizedBox(height: 22),
                for (final opt in LocaleController.options) ...[
                  _LanguageCard(
                    letter: opt.letter,
                    label: opt.nativeName,
                    selected: currentCode == opt.code,
                    onTap: () async {
                      await controller.setLanguageCode(opt.code);
                      if (!context.mounted) return;
                      if (popOnSelect) {
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const RegisterWorkerScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.letter, required this.label, required this.selected, required this.onTap});
  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? AppColors.manganeseSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: selected ? AppColors.manganese : Colors.transparent, width: 2),
        boxShadow: selected ? null : kCardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.manganese : AppColors.ochreSoft,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.ochre,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? const Icon(Icons.check_circle, key: ValueKey(1), color: AppColors.manganese, size: 30)
                      : const Icon(Icons.circle_outlined, key: ValueKey(0), color: AppColors.line, size: 30),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
