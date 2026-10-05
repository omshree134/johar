/// Text in several languages, e.g. {"en": "Exit", "hi": "निकास"}.
typedef LocalizedText = Map<String, String>;

LocalizedText parseLocalized(Object? json) =>
    (json as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, v as String));

/// Santali falls back to Hindi (same Devanagari readership in Jharkhand),
/// then English, until Santali content is translated.
String tr(LocalizedText text, String lang) =>
    text[lang] ?? (lang == 'sat' ? text['hi'] : null) ?? text['en'] ?? '';
