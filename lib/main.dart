import 'package:flutter/material.dart';
import 'data/presets.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Discos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      // Puedes cambiar el preset inicial si prefieres iniciar en LB
      home: HomeScreen(initial: Presets.comercialLb()),
    );
  }
}
