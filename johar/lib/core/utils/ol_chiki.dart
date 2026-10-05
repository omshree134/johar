/// Utility for transliterating Ol Chiki (Santali script) to Devanagari script.
///
/// Standard mobile Text-To-Speech engines (Google TTS / iOS Speech) do not
/// natively support the Ol Chiki Unicode block (U+1C50 - U+1C7F). Transliterating
/// Ol Chiki text into Devanagari phonemes allows Indic TTS engines to synthesize
/// native Santali speech clearly, accurately, and offline at zero cost.
class OlChikiTransliterator {
  OlChikiTransliterator._();

  /// Aspirated digraph pairs in Ol Chiki mapped to Devanagari aspirated consonants.
  static const Map<String, String> _digraphs = {
    'ᱠᱷ': 'ख',
    'ᱜᱷ': 'घ',
    'ᱪᱷ': 'छ',
    'ᱡᱷ': 'झ',
    'ᱴᱷ': 'ठ',
    'ᱰᱷ': 'ढ',
    'ᱛᱷ': 'थ',
    'ᱫᱷ': 'ध',
    'ᱯᱷ': 'फ',
    'ᱵᱷ': 'भ',
    'ᱲᱷ': 'ढ़',
  };

  static const Set<String> _consonants = {
    'ᱛ', 'ᱜ', 'ᱝ', 'ᱞ', 'ᱠ', 'ᱡ', 'ᱢ', 'ᱣ', 'ᱥ', 'ᱦ',
    'ᱧ', 'ᱨ', 'ᱪ', 'ᱫ', 'ᱬ', 'ᱭ', 'ᱯ', 'ᱰ', 'ᱱ', 'ᱲ',
    'ᱴ', 'ᱵ',
  };

  /// Independent letter mapping (word-initial or standalone vowels & consonants)
  static const Map<String, String> _independentMap = {
    // Digits
    '᱐': '0', '᱑': '1', '᱒': '2', '᱓': '3', '᱔': '4',
    '᱕': '5', '᱖': '6', '᱗': '7', '᱘': '8', '᱙': '9',

    // Vowels (Independent)
    'ᱚ': 'ऑ',
    'ᱟ': 'आ',
    'ᱤ': 'इ',
    'ᱩ': 'उ',
    'ᱮ': 'ए',
    'ᱳ': 'ओ',

    // Consonants
    'ᱛ': 'त',
    'ᱜ': 'ग',
    'ᱝ': 'ङ',
    'ᱞ': 'ल',
    'ᱠ': 'क',
    'ᱡ': 'ज',
    'ᱢ': 'म',
    'ᱣ': 'व',
    'ᱥ': 'स',
    'ᱦ': 'ह',
    'ᱧ': 'ञ',
    'ᱨ': 'र',
    'ᱪ': 'च',
    'ᱫ': 'द',
    'ᱬ': 'ण',
    'ᱭ': 'य',
    'ᱯ': 'प',
    'ᱰ': 'ड',
    'ᱱ': 'न',
    'ᱲ': 'ड़',
    'ᱴ': 'ट',
    'ᱵ': 'ब',

    // Modifiers & Punctuation
    'ᱶ': 'ँ',
    'ᱷ': '',
    'ᱸ': 'ं',
    'ᱹ': '़',
    'ᱺ': 'ं़',
    'ᱼ': '',
    '᱾': '।',
    '‖</I': '॥',
  };

  /// Dependent vowel matras (when vowel follows a consonant)
  static const Map<String, String> _matraMap = {
    'ᱚ': 'ॉ',
    'ᱟ': 'ा',
    'ᱤ': 'ि',
    'ᱩ': 'ु',
    'ᱮ': 'े',
    'ᱳ': 'ो',
  };

  /// Returns true if [text] contains Ol Chiki script characters.
  static bool isOlChiki(String text) {
    return text.runes.any((rune) => rune >= 0x1C50 && rune <= 0x1C7F);
  }

  /// Transliterates Ol Chiki text into Devanagari script for speech engines.
  static String olChikiToDevanagari(String text) {
    if (text.isEmpty) return text;
    final buffer = StringBuffer();
    int i = 0;
    bool prevWasConsonant = false;

    while (i < text.length) {
      // Check 2-character aspirated digraphs first
      if (i + 1 < text.length) {
        final pair = text.substring(i, i + 2);
        if (_digraphs.containsKey(pair)) {
          buffer.write(_digraphs[pair]);
          prevWasConsonant = true;
          i += 2;
          continue;
        }
      }

      final char = text[i];

      // If current char is a vowel and previous token was a consonant, use matra
      if (prevWasConsonant && _matraMap.containsKey(char)) {
        buffer.write(_matraMap[char]);
        prevWasConsonant = false;
      } else if (_independentMap.containsKey(char)) {
        buffer.write(_independentMap[char]);
        prevWasConsonant = _consonants.contains(char);
      } else {
        buffer.write(char);
        prevWasConsonant = false;
      }

      i++;
    }

    return buffer.toString();
  }
}
