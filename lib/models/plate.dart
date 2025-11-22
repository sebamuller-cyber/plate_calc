class Plate {
  double weight;   // editable (kg o lb según settings.units)
  int count;       // cantidad total disponible
  Plate({required this.weight, required this.count});

  // Copia simple (la dejo por si algo la usa)
  Plate copy() => Plate(weight: weight, count: count);

  // NUEVO → requerido por el editor de inventario
  Plate copyWith({
    double? weight,
    int? count,
  }) {
    return Plate(
      weight: weight ?? this.weight,
      count: count ?? this.count,
    );
  }
}
