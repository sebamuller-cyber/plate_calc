import 'plate.dart';

class Settings {
  final String units; // 'kg' o 'lb'
  final double barWeight;
  final double collarsWeight;
  final List<Plate> plates;

  Settings({
    required this.units,
    required this.barWeight,
    required this.collarsWeight,
    required this.plates,
  });

  Settings copyWith({
    String? units,
    double? barWeight,
    double? collarsWeight,
    List<Plate>? plates,
  }) =>
      Settings(
        units: units ?? this.units,
        barWeight: barWeight ?? this.barWeight,
        collarsWeight: collarsWeight ?? this.collarsWeight,
        plates: plates ?? this.plates.map((p) => p.copy()).toList(),
      );
}
