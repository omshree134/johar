import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageOption {
  final String code;
  final String nativeName;
  final String letter;
  final Locale appLocale;

  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.letter,
    required this.appLocale,
  });
}

/// Remembers the worker's language preference. `null` = not chosen yet.
class LocaleController extends ChangeNotifier {
  LocaleController._(this._prefs, this._selectedCode);

  static const _key = 'app_locale';

  /// Available language choices on the language selection screen.
  static const options = [
    LanguageOption(code: 'en', nativeName: 'English', letter: 'A', appLocale: Locale('en')),
    LanguageOption(code: 'hi', nativeName: 'हिन्दी', letter: 'अ', appLocale: Locale('hi')),
    LanguageOption(code: 'sat', nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ', letter: 'ᱚ', appLocale: Locale('sat')),
    LanguageOption(code: 'bn', nativeName: 'বাংলা', letter: 'ব', appLocale: Locale('en')),
    LanguageOption(code: 'ta', nativeName: 'தமிழ்', letter: 'த', appLocale: Locale('en')),
    LanguageOption(code: 'te', nativeName: 'తెలుగు', letter: 'తె', appLocale: Locale('en')),
  ];

  static const supported = [Locale('en'), Locale('hi'), Locale('sat')];
  static const nativeNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'sat': 'ᱥᱟᱱᱛᱟᱲᱤ',
    'bn': 'বাংলা',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
  };

  final SharedPreferences _prefs;
  String? _selectedCode;

  String? get selectedCode => _selectedCode;
  bool get hasChosen => _selectedCode != null;

  /// Locale used by MaterialApp UI.
  Locale? get locale {
    if (_selectedCode == null) return null;
    for (final opt in options) {
      if (opt.code == _selectedCode) return opt.appLocale;
    }
    return const Locale('en');
  }

  /// Language code used to pick text inside module content JSON.
  String get contentLang {
    if (_selectedCode == null) return 'en';
    for (final opt in options) {
      if (opt.code == _selectedCode) return opt.appLocale.languageCode;
    }
    return 'en';
  }

  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    return LocaleController._(prefs, code);
  }

  Future<void> setLanguageCode(String code) async {
    _selectedCode = code;
    await _prefs.setString(_key, code);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    await setLanguageCode(locale.languageCode);
  }
}
