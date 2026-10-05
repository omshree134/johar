import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/ol_chiki.dart';

/// Reads text aloud with high-quality TTS voice synthesis.
///
/// For Hindi ('hi'): Selects high-definition Neural/Network voices if available.
/// For Santali ('sat'): Transliterates Ol Chiki script to Devanagari phonemes,
/// enabling Indic TTS engines to synthesize native Santali speech offline at zero cost.
class Narrator {
  Narrator._();
  static final Narrator instance = Narrator._();

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<String?> speaking = ValueNotifier(null);
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.42); // slower speech rate for workers
      _tts.setCompletionHandler(() => speaking.value = null);
      _tts.setCancelHandler(() => speaking.value = null);
      _tts.setErrorHandler((_) => speaking.value = null);
      _ready = true;
    } catch (_) {}
  }

  /// Selects the highest quality neural/network voice for [langCode].
  Future<void> _optimizeVoice(String langCode) async {
    try {
      // Always use hi-IN locale for Hindi and Santali (phonetic Devanagari synthesis)
      final targetLocale = langCode == 'en' ? 'en-IN' : 'hi-IN';
      await _tts.setLanguage(targetLocale);

      final List<dynamic>? voices = await _tts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        Map<String, String>? bestVoice;
        for (var v in voices) {
          if (v is Map) {
            final name = (v['name'] ?? '').toString().toLowerCase();
            final locale = (v['locale'] ?? '').toString().toLowerCase();
            final matchesLocale = locale.replaceAll('_', '-').startsWith(targetLocale.toLowerCase());

            if (matchesLocale) {
              if (name.contains('network') ||
                  name.contains('neural') ||
                  name.contains('wavenet') ||
                  name.contains('natural')) {
                bestVoice = {'name': v['name'].toString(), 'locale': v['locale'].toString()};
                break;
              } else if (bestVoice == null) {
                bestVoice = {'name': v['name'].toString(), 'locale': v['locale'].toString()};
              }
            }
          }
        }
        if (bestVoice != null) {
          await _tts.setVoice(bestVoice);
        }
      }
      // Re-confirm language after setVoice to ensure engine doesn't revert to default locale
      await _tts.setLanguage(targetLocale);
    } catch (_) {
      await _tts.setLanguage(langCode == 'en' ? 'en-IN' : 'hi-IN');
    }
  }

  Future<void> speak(String text, String lang) async {
    try {
      await _init();
      await _tts.stop();

      // Optimize engine to use high-definition neural voice
      await _optimizeVoice(lang);

      // Transliterate Ol Chiki script for Santali to Devanagari phonemes for TTS
      String spokenText = text;
      if (lang == 'sat' || OlChikiTransliterator.isOlChiki(text)) {
        spokenText = OlChikiTransliterator.olChikiToDevanagari(text);
      }

      await _tts.setSpeechRate(0.42); // clear, deliberate pacing for workers
      await _tts.setPitch(1.0);

      speaking.value = text;
      await _tts.speak(spokenText);
    } catch (_) {
      speaking.value = null;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    speaking.value = null;
  }
}

class NarrationButton extends StatelessWidget {
  const NarrationButton({super.key, required this.text, required this.lang, this.compact = false});
  final String text;
  final String lang;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final n = Narrator.instance;
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: n.speaking,
      builder: (context, current, _) {
        final playing = current == text;
        final icon = Icon(playing ? Icons.stop_circle_outlined : Icons.volume_up_rounded);
        void onTap() => playing ? n.stop() : n.speak(text, lang);
        if (compact) {
          return IconButton(
            onPressed: onTap,
            icon: icon,
            color: AppColors.manganese,
            tooltip: playing ? l.narrationStop : l.narrationListen,
          );
        }
        return FilledButton.tonalIcon(
          onPressed: onTap,
          icon: icon,
          label: Text(playing ? l.narrationStop : l.narrationListen),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        );
      },
    );
  }
}
