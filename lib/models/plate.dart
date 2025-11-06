class Plate {
  double weight;   // editable (kg o lb según settings.units)
  int count;       // cantidad total disponible (ambos lados)
  Plate({required this.weight, required this.count});

  Plate copy() => Plate(weight: weight, count: count);
}
