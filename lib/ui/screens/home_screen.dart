import 'package:flutter/material.dart';
import '../../models/settings.dart';
import '../../models/plate.dart';
import '../../services/plate_calculator.dart';
import '../widgets/barbell_visual.dart';

enum TargetInputMode { totalInclBar, perSideWithoutBar }

class HomeScreen extends StatefulWidget {
  final Settings initial;
  const HomeScreen({super.key, required this.initial});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Settings settings;

  final rmCtrl = TextEditingController(text: '200');
  final pctCtrl = TextEditingController(text: '100');

  TargetInputMode mode = TargetInputMode.totalInclBar;

  PlateResult? result;
  String? error;
  bool _showPanel = false;

  @override
  void initState() {
    super.initState();
    settings = widget.initial;
  }

  List<double> _barOptions() => settings.units == 'lb' ? [45, 33] : [20, 15];

  double _mapBarBetweenUnits(double bar, String from, String to) {
    if (from == to) return bar;
    if (from == 'lb' && to == 'kg') {
      return (bar - 45).abs() <= (bar - 33).abs() ? 20 : 15;
    }
    if (from == 'kg' && to == 'lb') {
      return (bar - 20).abs() <= (bar - 15).abs() ? 45 : 33;
    }
    return (to == 'lb') ? 45 : 20;
  }

  double _parsePct(String raw) {
    final cleaned = raw.trim().replaceAll('%', '').replaceAll(',', '.');
    final v = double.tryParse(cleaned) ?? 0.0;
    return (v / 100.0).clamp(0.0, 1.2);
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

  void _onCalculate() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      error = null;
      final pct = _parsePct(pctCtrl.text);
      if (pct <= 0) {
        error = 'Ingresa un porcentaje válido (> 0).';
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
      _showPanel = true;
    });
  }

  Widget _percentRow(double fraction) {
    final t = _targetsForPct(fraction);
    final percentLabel = '${(fraction * 100).round()}%';

    return InkWell(
      onTap: () {
        pctCtrl.text = (fraction * 100).round().toString();
        _onCalculate();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: 56, child: Text(percentLabel)),
            Expanded(child: Text(t['total']!.toStringAsFixed(1))),
            Expanded(child: Text(t['perSide']!.toStringAsFixed(1))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final pct = _parsePct(pctCtrl.text);
    final targets = _targetsForPct(pct);
    final totalFromPct = targets['total']!;
    final perSideFromPct = targets['perSide']!;
    final tableRows = List<double>.generate(10, (i) => (i + 1) * 0.10);
    final panelHeight = size.height * 0.65;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async {
        if (_showPanel) {
          setState(() => _showPanel = false);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Calculadora de Discos')),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rmCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Tu 1RM (según modo)'),
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
                            suffixText: '%',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Objetivo derivado de ${(pct * 100).toStringAsFixed(1)}% del RM:',
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

                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tabla de porcentajes (toca para aplicar)'),
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
                          Column(children: tableRows.map((f) => _percentRow(f)).toList()),
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
                  const SizedBox(height: 120),
                ],
              ),
            ),

            // Overlay oscuro
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showPanel ? 0.65 : 0.0,
              child: IgnorePointer(
                ignoring: !_showPanel,
                child: GestureDetector(
                  onTap: () => setState(() => _showPanel = false),
                  child: Container(color: Colors.black),
                ),
              ),
            ),

            // Panel deslizable
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: _showPanel ? 0 : -panelHeight,
              height: panelHeight + (bottomInset > 0 ? 12 : 0),
              child: SafeArea(
                top: false,
                child: Material(
                  elevation: 12,
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: result == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Cerrar',
                                    onPressed: () => setState(() => _showPanel = false),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result!.exact
                                          ? 'Alcanzado: ${result!.totalAchieved.toStringAsFixed(2)} ${settings.units} (exacto)'
                                          : 'Mejor aproximación: ${result!.totalAchieved.toStringAsFixed(2)} ${settings.units} '
                                              '(faltan ${result!.shortfall.toStringAsFixed(2)} ${settings.units})',
                                      style: theme.textTheme.titleMedium,
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
                                    Text('Discos elegidos (totales):', style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 6),

                                    // ✅ BLOQUE CORREGIDO
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: () {
                                        final entries = result!.used.entries.toList()
                                          ..sort((a, b) => b.key.compareTo(a.key));
                                        return entries
                                            .map((e) => Chip(
                                                  label: Text(
                                                    '${e.key.toString().replaceAll('.0', '')} ${settings.units} x${e.value}',
                                                  ),
                                                ))
                                            .toList();
                                      }(),
                                    ),

                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

