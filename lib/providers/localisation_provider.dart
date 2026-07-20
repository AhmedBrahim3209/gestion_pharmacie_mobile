import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class LocalisationProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  bool _isRtl = false;

  Locale get locale => _locale;
  bool get isRtl => _isRtl;

  void setLocale(String langCode) {
    _locale = Locale(langCode);
    _isRtl = AppLocalizations.isRtl(_locale);
    notifyListeners();
  }
}
