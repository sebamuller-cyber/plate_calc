import '../models/plate.dart';
import '../models/settings.dart';

class Presets {
  static Settings powerKg() => Settings(
        units: 'kg',
        barWeight: 20,
        collarsWeight: 0,
        plates: [
          Plate(weight: 45, count: 8),
          Plate(weight: 35, count: 8),
          Plate(weight: 25, count: 8),
          Plate(weight: 10, count: 8),
          Plate(weight: 5,  count: 6),
          Plate(weight: 2.5, count: 6),
        ],
      );

  static Settings halteroKg() => Settings(
      units: 'kg',
      barWeight: 20,
      collarsWeight: 0,
      plates: [
        Plate(weight: 25, count: 2),
        Plate(weight: 20, count: 2),
        Plate(weight: 15, count: 2),
        Plate(weight: 10, count: 4),
        Plate(weight: 5, count: 4),
        Plate(weight: 2.5, count: 4),
        Plate(weight: 1.25, count: 4),
        Plate(weight: 0.5, count: 4),
      ],
    );

  /// Inventario comercial LB: discos 45, 25, 10, 5, 2.5
  static Settings comercialLb() => Settings(
        units: 'lb',
        barWeight: 45, // olímpica estándar
        collarsWeight: 0,
        plates: [
          Plate(weight: 45, count: 8),
          Plate(weight: 35, count: 8),
          Plate(weight: 25, count: 8),
          Plate(weight: 10, count: 8),
          Plate(weight: 5,  count: 6),
          Plate(weight: 2.5, count: 6),
        ],
      );
}
