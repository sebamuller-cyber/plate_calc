import 'dart:math';
import '../models/plate.dart';

class PlateResult {
  final List<double> perSide;     // lista de pesos por lado en orden de carga
  final Map<double, int> used;    // peso -> cantidad total usada
  final double totalAchieved;     // peso total logrado
  final bool exact;               // si se alcanzó exactamente el objetivo
  final double shortfall;         // cuánto faltó si no es exacto

  PlateResult({
    required this.perSide,
    required this.used,
    required this.totalAchieved,
    required this.exact,
    required this.shortfall,
  });
}

/// Calcula la distribución de discos.
/// - `target` es SIEMPRE el peso TOTAL objetivo (incluye barra y collares).
PlateResult? computePlates({
  required double target,
  required double barWeight,
  required double collarsWeight,
  required List<Plate> plates,
}) {
  const eps = 1e-6;
  final effective = target - barWeight - collarsWeight;
  if (effective < -eps) return null; // objetivo menor que barra+collares
  if (effective.abs() < eps) {
    return PlateResult(
      perSide: [],
      used: {},
      totalAchieved: barWeight + collarsWeight,
      exact: true,
      shortfall: 0,
    );
  }

  double perSide = effective / 2.0;
  if (perSide < 0) return null;

  final sorted = plates.map((p) => p.copy()).toList()
    ..sort((a, b) => b.weight.compareTo(a.weight));

  final used = <double, int>{};
  final perSideList = <double>[];

  // Greedy: de mayor a menor
  for (final p in sorted) {
    final pairsAvail = (p.count / 2).floor();
    if (pairsAvail <= 0) continue;
    final pairsNeeded = min(pairsAvail, (perSide / p.weight).floor());
    if (pairsNeeded > 0) {
      perSide -= pairsNeeded * p.weight;
      perSideList.addAll(List<double>.filled(pairsNeeded, p.weight));
      used[p.weight] = (used[p.weight] ?? 0) + pairsNeeded * 2;
    }
  }

  // Intento microdiscos (<= 2.5) para cerrar brecha pequeña (opcional)
  double remaining = perSide;
  final micro = sorted
      .where((p) => p.weight <= 2.5 && p.count >= 2)
      .map((p) => p.weight)
      .toList();

  bool tryComplete(double rem) {
    if (rem.abs() < 1e-6) return true;
    for (final w in micro) {
      if (rem - w >= -1e-6) {
        final plate = sorted.firstWhere((p) => p.weight == w);
        final availPairs =
            (plate.count / 2).floor() - ((used[w] ?? 0) / 2).floor();
        if (availPairs > 0) {
          perSideList.add(w);
          used[w] = (used[w] ?? 0) + 2;
          if (tryComplete(rem - w)) return true;
          perSideList.removeLast();
          used[w] = (used[w] ?? 2) - 2;
        }
      }
    }
    return false;
  }

  bool exact = true;
  if (remaining > 1e-6) {
    final ok = tryComplete(remaining);
    exact = ok;
  }

  final totalAchieved =
      barWeight + collarsWeight + perSideList.fold<double>(0, (s, w) => s + 2 * w);

  final double shortfall = exact ? 0.0 : max(0.0, target - totalAchieved);

  return PlateResult(
    perSide: perSideList,
    used: used,
    totalAchieved: totalAchieved,
    exact: exact,
    shortfall: shortfall,
  );
}

