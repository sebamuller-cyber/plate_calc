import 'package:flutter/material.dart';

class PlateVisual {
  static Color color(String units, double w) {
    if (units == 'kg') {
      if ((w - 25).abs() < 0.01) return const Color(0xFFE53935); // rojo
      if ((w - 20).abs() < 0.01) return const Color(0xFF1E88E5); // azul
      if ((w - 15).abs() < 0.01) return const Color(0xFFFDD835); // amarillo
      if ((w - 10).abs() < 0.01) return const Color(0xFF43A047); // verde
      if ((w - 5 ).abs() < 0.01) return const Color(0xFF8E24AA); // morado
      if ((w - 2.5).abs() < 0.01) return const Color(0xFF546E7A); // gris
      if ((w - 1.25).abs() < 0.01) return const Color(0xFF90A4AE);
      if ((w - 0.5).abs() < 0.01) return const Color(0xFFB0BEC5);
      return const Color(0xFF757575);
    } else {
      // lb: 45, 25, 10, 5, 2.5
      if ((w - 45).abs() < 0.01) return const Color(0xFFE53935); // rojo
      if ((w - 25).abs() < 0.01) return const Color(0xFF43A047); // verde
      if ((w - 10).abs() < 0.01) return const Color(0xFF1E88E5); // azul
      if ((w - 5 ).abs() < 0.01) return const Color(0xFFFDD835); // amarillo
      if ((w - 2.5).abs() < 0.01) return const Color(0xFF546E7A); // gris
      return const Color(0xFF757575);
    }
  }

  // Solo visual (no escala real); grandes un poco más anchos.
  static double width(String units, double w) {
    if (units == 'kg') {
      if ((w - 25).abs() < 0.01) return 30;
      if ((w - 20).abs() < 0.01) return 28;
      if ((w - 15).abs() < 0.01) return 26;
      if ((w - 10).abs() < 0.01) return 24;
      if ((w - 5 ).abs() < 0.01) return 18;
      if ((w - 2.5).abs() < 0.01) return 14;
      return 10;
    } else {
      if ((w - 45).abs() < 0.01) return 30;
      if ((w - 25).abs() < 0.01) return 28;
      if ((w - 10).abs() < 0.01) return 20;
      if ((w - 5 ).abs() < 0.01) return 14;
      if ((w - 2.5).abs() < 0.01) return 10;
      return 10;
    }
  }
}
