// Flutter's built-in Material/Cupertino/Widgets localizations do not include
// Santali ('sat'). Without these delegates, any Material widget crashes with
// "No MaterialLocalizations found" when the app runs in Santali.
// They reuse Hindi system strings (date pickers, tooltips) for Santali.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const Locale _fallback = Locale('hi');

bool _isSat(Locale l) => l.languageCode == 'sat';

class _SatMaterialDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _SatMaterialDelegate();
  @override
  bool isSupported(Locale locale) => _isSat(locale);
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_fallback);
  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}

class _SatCupertinoDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _SatCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => _isSat(locale);
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_fallback);
  @override
  bool shouldReload(covariant LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

class _SatWidgetsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const _SatWidgetsDelegate();
  @override
  bool isSupported(Locale locale) => _isSat(locale);
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_fallback);
  @override
  bool shouldReload(covariant LocalizationsDelegate<WidgetsLocalizations> old) => false;
}

/// Put these BEFORE AppLocalizations.localizationsDelegates.
const List<LocalizationsDelegate<dynamic>> santaliFallbackDelegates = [
  _SatMaterialDelegate(),
  _SatCupertinoDelegate(),
  _SatWidgetsDelegate(),
];

/// intl has no date symbols for 'sat', so format dates with Hindi rules.
String intlLocaleFor(Locale locale) => _isSat(locale) ? 'hi' : locale.languageCode;
