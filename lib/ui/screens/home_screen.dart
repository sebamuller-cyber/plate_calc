import 'package:flutter/material.dart';
import 'package:plate_calc/ui/widgets/plate_colors.dart';
import '../../models/settings.dart';
import '../../models/plate.dart';
import '../../services/plate_calculator.dart';
import '../widgets/barbell_visual.dart';
import '../../services/rm_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TargetInputMode { totalInclBar, perSideWithoutBar }

class HomeScreen extends StatefulWidget {
  final Settings initial;
  final String? movementName;    // nombre del movimiento (para guardar RM)
  final double? initialRm;       // RM inicial precargado (opcional)
  final String? forceUnits;      // 'kg' | 'lb' (opcional)

  const HomeScreen({
    super.key,
    required this.initial,
    this.movementName,
    this.initialRm,
    this.forceUnits,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Settings settings;

  // Deja vacío por defecto (como pediste)
  final rmCtrl = TextEditingController();       // ← sin texto inicial
  final pctCtrl = TextEditingController(text: '100');

  // Por defecto: Por lado (sin barra)
  TargetInputMode mode = TargetInputMode.perSideWithoutBar;

  PlateResult? result;
  String? error;
  bool _showPanel = false;

  @override
  void initState() {
    super.initState();
    settings = widget.initial;

    // Forzar unidades si vienen de la pantalla anterior
    if (widget.forceUnits != null && widget.forceUnits != settings.units) {
      settings = settings.copyWith(units: widget.forceUnits);
      settings = settings.copyWith(barWeight: settings.units == 'lb' ? 45 : 20);
    }

    _initRm();
  }
String _fmtDate(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}';
}

  Future<void> _initRm() async {
    // Si te pasaron un RM inicial, úsalo
    if (widget.initialRm != null) {
      rmCtrl.text = _fmt(widget.initialRm!);
      return;
    }
    // Si hay movimiento, intenta cargar su último RM guardado para estas unidades
    if (widget.movementName != null) {
      final last = await RmStorage.loadLastRm(widget.movementName!, settings.units);
      if (last != null) {
        rmCtrl.text = _fmt(last);
        setState(() {});
      }
    }
  }
  Future<void> _openRmHistory() async {
  if (widget.movementName == null) return;
  final name = widget.movementName!;
  final unit = settings.units;

  List<Map<String, dynamic>> entries = await RmStorage.loadRmHistory(name, unit);

  if (!mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> _clear() async {
            final ok = await RmStorage.clearRmHistory(name, unit);
            if (ok) {
              entries = [];
              setSheetState(() {}); // refresca la hoja
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historial limpiado.')),
                );
              }
            }
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Historial RM — $name (${unit})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: entries.isEmpty ? null : _clear,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No hay registros aún. Guarda un RM para crear entradas.'),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final e = entries[i];
                          final rm = (e['rm'] as num).toDouble();
                          final ts = DateTime.tryParse(e['ts'] as String ?? '') ?? DateTime.now();
                          return ListTile(
                            leading: const Icon(Icons.history),
                            title: Text('RM: ${rm.toStringAsFixed(1)} $unit'),
                            subtitle: Text(_fmtDate(ts)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

bool _wasDeleted = false; // ← nuevo: sabremos si se eliminó algo

  String _fmt(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  List<double> _barOptions() => settings.units == 'lb' ? [45, 33] : [20, 15];

  double _mapBarBetweenUnits(double bar, String from, String to) {
    if (from == to) return bar;
    if (from == 'lb' && to == 'kg') return (bar - 45).abs() <= (bar - 33).abs() ? 20 : 15;
    if (from == 'kg' && to == 'lb') return (bar - 20).abs() <= (bar - 15).abs() ? 45 : 33;
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

  // Guardar RM manualmente (botón en AppBar)
  Future<void> _saveRmManually() async {
  if (widget.movementName == null) return;
  final rm = double.tryParse(rmCtrl.text.replaceAll(',', '.'));
  if (rm == null || rm <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingresa un RM válido antes de guardar.')),
    );
    return;
  }

  await RmStorage.saveLastRm(widget.movementName!, settings.units, rm);

  // ⬇️ NUEVO: registrar en historial
  await RmStorage.appendRmHistory(
    widget.movementName!,
    settings.units,
    rm,
    DateTime.now(),
  );

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('RM guardado para ${widget.movementName} (${settings.units}).')),
  );
}


  // Elimina por completo el movimiento actual: lo quita de la lista de personalizados
  // y borra sus claves de RM / historial. Luego vuelve a la pantalla anterior.
  
  // Reemplaza COMPLETO este método en HomeScreen
Future<void> _deleteMovement() async {
  if (widget.movementName == null) return;
  final name = widget.movementName!.trim();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar movimiento'),
      content: Text('¿Eliminar “$name” por completo? Se borrará de tu lista y su RM/Historial.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
        FilledButton.tonal(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    final ok = await RmStorage.deleteMovement(name); // ← centraliza toda la eliminación
    if (!mounted) return;

    if (ok) {
      _wasDeleted = true;      // ← marcamos que hubo borrado
      rmCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Movimiento eliminado: $name')),
      );

      // Cerramos esta pantalla devolviendo un resultado para que la anterior refresque
      Future.microtask(() {
        if (mounted) {
          Navigator.of(context).pop(<String, dynamic>{
            'deleted': true,
            'name': name,
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar.')),
      );
    }
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo eliminar.')),
    );
  }
}



  void _onCalculate() {
    // Cerrar teclado
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      error = null;
    });

    final pct = _parsePct(pctCtrl.text);
    if (pct <= 0) {
      setState(() {
        error = 'Ingresa un porcentaje válido (> 0).';
        result = null;
        _showPanel = false;
      });
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
      setState(() {
        error = 'El objetivo es menor que la barra o los datos no son válidos.';
        result = null;
        _showPanel = false;
      });
      return;
    }

    // ❌ Ya NO guardamos RM aquí. Solo mostramos resultado.
    setState(() {
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
  if (_wasDeleted) {
    Navigator.of(context).pop(<String, dynamic>{ 'deleted': true });
    return false;
  }
  return true;
},

      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.movementName ?? 'Calculadora de Discos'),
          actions: [
            if (widget.movementName != null)
              IconButton(
                tooltip: 'Guardar RM',
                onPressed: _saveRmManually,
                icon: const Icon(Icons.save_outlined),
              ),
          ],
        ),
        body: Stack(
          children: [
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

                  // Interpretación
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

                  // RM y %
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rmCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: widget.movementName == null
                                ? 'Tu 1RM'
                                : '1RM de ${widget.movementName}',
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
                            suffixText: '%',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Vista derivada
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

                  // Tabla de % clickeable
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
                          Column(
                            children: tableRows.map((f) => _percentRow(f)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Calcular
                  // Calcular
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _onCalculate,
    child: const Text('Calcular distribución de discos'),
  ),
),
const SizedBox(height: 8),

// ⬇️ NUEVO: botón historial (solo si hay movimiento)
if (widget.movementName != null) ...[
  SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: _openRmHistory,
      icon: const Icon(Icons.history),
      label: const Text('Historial RM'),
    ),
  ),
  const SizedBox(height: 8),
],

// Eliminar
if (widget.movementName != null)
  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      onPressed: _deleteMovement,
      child: Text('Eliminar ' + (widget.movementName ?? 'movimiento')),
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

            // Panel resultado
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
                                    width: 40, height: 4,
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
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: () {
                                        final entries = result!.used.entries.toList()
                                          ..sort((a, b) => b.key.compareTo(a.key));

                                        final baseStyle = Theme.of(context).textTheme.bodyMedium!
                                            .copyWith(color: Theme.of(context).colorScheme.onSurface);

                                        return entries.map((e) {
                                          final c = PlateVisual.color(settings.units, e.key);

                                          return Chip(
                                            // un borde con el color del disco para mejor legibilidad
                                            shape: StadiumBorder(side: BorderSide(color: c, width: 1.5)),
                                            backgroundColor:
                                                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.20),
                                            label: RichText(
                                              text: TextSpan(
                                                style: baseStyle,
                                                children: [
                                                  // 👉 número del peso con su color
                                                  TextSpan(
                                                    text: e.key.toString().replaceAll('.0', ''),
                                                    style: baseStyle.copyWith(
                                                      color: c,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  TextSpan(text: ' ${settings.units}  x${e.value}'),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList();
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


