import 'package:flutter/material.dart';
import '../../models/settings.dart';
import '../../models/plate.dart';
import '../../services/plate_calculator.dart';
import '../widgets/barbell_visual.dart';
import '../widgets/plate_colors.dart';

enum TargetInputMode { totalInclBar, perSideWithoutBar }

class HomeScreen extends StatefulWidget {
  final Settings initial;
  const HomeScreen({super.key, required this.initial});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Settings settings;
  final rmCtrl  = TextEditingController(text: '200');
  final pctCtrl = TextEditingController(text: '100');
  TargetInputMode mode = TargetInputMode.totalInclBar;

  PlateResult? result;
  String? error;

  // Overlay deslizante
  bool _showPanel = false;

  @override
  void initState() {
    super.initState();
    settings = widget.initial;
    // No calculamos de inicio; esperamos al botón.
  }

  // --- Unidades y barra ---
  List<double> _barOptions() => settings.units == 'lb' ? [45, 33] : [20, 15];

  double _mapBarBetweenUnits(double bar, String from, String to) {
    if (from == to) return bar;
    if (from == 'lb' && to == 'kg') return (bar - 45).abs() <= (bar - 33).abs() ? 20 : 15;
    if (from == 'kg' && to == 'lb') return (bar - 20).abs() <= (bar - 15).abs() ? 45 : 33;
    return (to == 'lb') ? 45 : 20;
  }

  // --- Porcentajes ---
  double _parsePct(String raw) {
    final cleaned = raw.trim().replaceAll('%', '').replaceAll(',', '.');
    final v = double.tryParse(cleaned) ?? 0.0;
    return (v / 100.0).clamp(0.0, 1.0);
  }

  Map<String, double> _targetsForPct(double pct) {
    final rm = double.tryParse(rmCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final bar = settings.barWeight;
    final col = settings.collarsWeight;

    if (mode == TargetInputMode.totalInclBar) {
      final total = rm * pct;
      final perSide = ((total - bar - col) / 2.0).clamp(0.0, double.infinity);
      return {'total': total, 'perSide': perSide};
    } else {
      final perSide = rm * pct;
      final total = bar + col + 2.0 * perSide;
      return {'total': total, 'perSide': perSide};
    }
  }

  double _targetTotalFromPct(double pct) => _targetsForPct(pct)['total']!;

  // --- Acción principal: calcular y mostrar panel ---
  void _onCalculate() {
    setState(() {
      error = null;
      final pct = _parsePct(pctCtrl.text);
      if (pct <= 0) {
        error = 'Ingresa un porcentaje válido (> 0)';
        result = null;
        _showPanel = false;
        return;
      }
      final targetTotal = _targetTotalFromPct(pct);
      final r = computePlates(
        target: targetTotal,
        barWeight: settings.barWeight,
        collarsWeight: settings.collarsWeight,
        plates: settings.plates.map((p) => Plate(weight: p.weight, count: p.count)).toList(),
      );
      if (r == null) {
        error = 'El objetivo es menor que la barra o los datos no son válidos.';
        result = null;
        _showPanel = false;
        return;
      }
      result = r;
      _showPanel = true; // abre la ventana deslizante
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = _parsePct(pctCtrl.text);
    final targets = _targetsForPct(pct);
    final totalFromPct = targets['total']!;
    final perSideFromPct = targets['perSide']!;
    final tableRows = List<double>.generate(10, (i) => (i + 1) * 0.10);

    final size = MediaQuery.of(context).size;
    final panelHeight = size.height * 0.75;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Discos'),
      ),
      body: Stack(
        children: [
          // CONTENIDO BASE (no muestra distribución hasta presionar Calcular)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Unidades
                Row(
                  children: [
                    const Text('Unidades:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: settings.units,
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'lb', child: Text('lb')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        final newBar = _mapBarBetweenUnits(settings.barWeight, settings.units, v);
                        setState(() => settings = settings.copyWith(units: v, barWeight: newBar));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Barra + Collares
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Barra'),
                          DropdownButton<double>(
                            isExpanded: true,
                            value: _barOptions().contains(settings.barWeight)
                                ? settings.barWeight
                                : _barOptions().first,
                            items: _barOptions()
                                .map((w) => DropdownMenuItem(
                                      value: w,
                                      child: Text('${w.toStringAsFixed(0)} ${settings.units}'),
                                    ))
                                .toList(),
                            onChanged: (w) {
                              if (w == null) return;
                              setState(() => settings = settings.copyWith(barWeight: w));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: settings.collarsWeight.toString(),
                        decoration: const InputDecoration(labelText: 'Collares'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() =>
                            settings = settings.copyWith(collarsWeight: double.tryParse(v) ?? settings.collarsWeight)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Modo
                Row(
                  children: [
                    const Text('Interpretar RM/% como:'),
                    const SizedBox(width: 8),
                    DropdownButton<TargetInputMode>(
                      value: mode,
                      items: const [
                        DropdownMenuItem(value: TargetInputMode.totalInclBar, child: Text('Total (incluye barra)')),
                        DropdownMenuItem(value: TargetInputMode.perSideWithoutBar, child: Text('Por lado (sin barra)')),
                      ],
                      onChanged: (m) => setState(() => mode = m ?? mode),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // RM y % (no disparan cálculo)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rmCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tu 1RM (según modo)',
                          hintText: 'Ej. 200',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: pctCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Porcentaje',
                          hintText: 'Ej. 83',
                          suffixText: '%',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Vista textual del derivado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Objetivo derivado de ${((pct)*100).toStringAsFixed(1)}% del RM:',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      mode == TargetInputMode.totalInclBar
                          ? 'TOTAL: ${totalFromPct.toStringAsFixed(1)} ${settings.units}'
                          : 'POR LADO (discos): ${perSideFromPct.toStringAsFixed(1)} ${settings.units}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tabla 10..100 (informativa; no calcula hasta que toques el botón)
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tabla de porcentajes'),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: const [
                              SizedBox(width: 56, child: Text('%', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(child: Text('Por lado (sin barra)', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        Column(
                          children: tableRows.map((f) {
                            final label = '${(f * 100).round()}%';
                            final t = _targetsForPct(f);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(width: 56, child: Text(label)),
                                  Expanded(child: Text(t['total']!.toStringAsFixed(1))),
                                  Expanded(child: Text(t['perSide']!.toStringAsFixed(1))),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onCalculate,
                    child: const Text('Calcular distribución de discos'),
                  ),
                ),

                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 120), // espacio para que el panel pueda cubrir
              ],
            ),
          ),

          // OVERLAY DESLIZANTE (sube hasta arriba)
          // OVERLAY: fondo oscuro cuando la ventana está abierta
AnimatedOpacity(
  duration: const Duration(milliseconds: 250),
  opacity: _showPanel ? 0.5 : 0.0,
  child: IgnorePointer(
    ignoring: !_showPanel,
    child: Container(
      color: Colors.black.withOpacity(0.5),
    ),
  ),
),

// PANEL DESLIZANTE
AnimatedPositioned(
  duration: const Duration(milliseconds: 350),
  curve: Curves.easeOutCubic,
  left: 0,
  right: 0,
  bottom: _showPanel ? 0 : -panelHeight,
  height: panelHeight,
  child: Material(
    elevation: 12,
    color: Theme.of(context).colorScheme.surface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    child: result == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _showPanel = false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  result!.exact
                      ? 'Alcanzado: ${result!.totalAchieved.toStringAsFixed(2)} ${settings.units} (exacto)'
                      : 'Mejor aproximación: ${result!.totalAchieved.toStringAsFixed(2)} ${settings.units} '
                        '(faltan ${result!.shortfall.toStringAsFixed(2)} ${settings.units})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: BarbellView(
                      perSide: result!.perSide,
                      units: settings.units,
                      height: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Discos elegidos (totales):',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                PlateLegend(used: result!.used, units: settings.units),
              ],
            ),
          ),
  ),
),

        ],
      ),
    );
  }
}
