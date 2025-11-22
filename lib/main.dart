import 'package:flutter/material.dart';
import 'ui/screens/rm_list_screen.dart';
// 👇 Usamos el AppLocalizations que tienes en lib/l10n
import 'package:plate_calc/l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Título según idioma
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),

      // 👇 Usamos los delegados y locales que ya define app_localizations.dart
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // 👇 SIN 'locale': usa el idioma del sistema (en, es, fr)
      home: const RmListScreen(),
    );
  }
}
