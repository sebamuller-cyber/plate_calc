import 'package:flutter/material.dart';
import '../../models/plate.dart';
import '../../models/settings.dart';
import '../../data/presets.dart';

class InventoryScreen extends StatefulWidget {
  final Settings settings;
  final void Function(Settings) onSave;
  const InventoryScreen({super.key, required this.settings, required this.onSave});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Settings current;

  @override
  void initState() {
    super.initState();
    current = widget.settings.copyWith();
  }

  void _addPlate() {
    setState(() {
      current.plates.add(Plate(weight: 1, count: 2));
      current.plates.sort((a, b) => b.weight.compareTo(a.weight));
    });
  }

  void _applyPreset(Settings s) {
    setState(() => current = s.copyWith());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de discos'),
        actions: [
          TextButton(
            onPressed: () => widget.onSave(current),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _applyPreset(Presets.halteroKg()),
                child: const Text('Preset: Haltero KG'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _applyPreset(Presets.powerKg()),
                child: const Text('Preset: Power KG'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _applyPreset(Presets.comercialLb()),
            child: const Text('Preset: Comercial LB'),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('Unidades:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: current.units,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'lb', child: Text('lb')),
                ],
                onChanged: (v) => setState(() => current = current.copyWith(units: v)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: current.barWeight.toString(),
                  decoration: const InputDecoration(labelText: 'Peso barra'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() =>
                      current = current.copyWith(barWeight: double.tryParse(v) ?? current.barWeight)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: current.collarsWeight.toString(),
                  decoration: const InputDecoration(labelText: 'Collares'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() =>
                      current = current.copyWith(collarsWeight: double.tryParse(v) ?? current.collarsWeight)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Discos disponibles (peso / cantidad total):'),
          const SizedBox(height: 8),
          ...current.plates.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: p.weight.toString(),
                        decoration: const InputDecoration(labelText: 'Peso'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            setState(() => current.plates[i].weight = double.tryParse(v) ?? p.weight),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: p.count.toString(),
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            setState(() => current.plates[i].count = int.tryParse(v) ?? p.count),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => current.plates.removeAt(i)),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addPlate,
            icon: const Icon(Icons.add),
            label: const Text('Agregar disco'),
          ),
        ],
      ),
    );
  }
}
