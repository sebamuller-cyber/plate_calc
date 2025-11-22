import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/rm_list_screen.dart';
import 'package:plate_calc/l10n/app_localizations.dart';
import 'ui/screens/app_settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  Locale? _appLocale; // null => usa idioma del sistema

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale');
    if (code != null) {
      setState(() => _appLocale = Locale(code));
    }
  }

  Future<void> _changeLocale(String? code) async {
    final prefs = await SharedPreferences.getInstance();

    if (code == null) {
      await prefs.remove('app_locale');
      setState(() => _appLocale = null);
    } else {
      await prefs.setString('app_locale', code);
      setState(() => _appLocale = Locale(code));
    }
  }

  Future<void> _openSettings() async {
    final ctx = _navKey.currentContext;
    if (ctx == null) return;

    await Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => AppSettingsScreen(
          currentLocaleCode: _appLocale?.languageCode,
          onLocaleChanged: _changeLocale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      locale: _appLocale, // si es null, usa la del sistema
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RmListScreen(onOpenSettings: _openSettings),
    );
  }
}
