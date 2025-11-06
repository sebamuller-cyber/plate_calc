import 'package:flutter/material.dart';

class PlateChip extends StatelessWidget {
  final double weight;
  const PlateChip({super.key, required this.weight});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(weight.toString().replaceAll('.0', '')),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
