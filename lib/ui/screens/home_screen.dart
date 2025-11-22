import 'package:flutter/material.dart';
import 'package:plate_calc/ui/widgets/plate_colors.dart';
import '../../models/settings.dart';
import '../../models/plate.dart';
import '../../services/plate_calculator.dart';
import '../widgets/barbell_visual.dart';
import '../../services/rm_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plate_calc/l10n/app_localizations.dart';

enum TargetInputMode { totalInclBar, perSideWithoutBar }

class HomeScreen extends StatefulWidget {
  final Settings initial;
  final String? movementName; // nombre del movimiento (para guardar RM)
  final double? initialRm; // RM inicial precargado (opcional)
  final String? forceUnits; // 'kg' | 'lb' (opcional)

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

  final rmCtrl = TextEditingController();
  final pctCtrl = TextEditingController(text: '100');

  TargetInputMode mode = TargetInputMode.perSideWithoutBar;

  PlateResult? result;
  String? error;
  bool _showPanel = false;
  bool _wasDeleted = false;

  @override
  void initState() {
    super.initState();
    settings = widget.initial;

    // Forzar unidades si vienen de la pantalla anterior
    if (widget.forceUnits != null && widget.forceUnits != settings.units) {
      settings = settings.copyWith(units: widget.forceUnits);
      settings =
          settings.copyWith(barWeight: settings.units == 'lb' ? 45 : 20);
    }

    _initRm();
  }

  String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _initRm() async {
    if (widget.initialRm != null) {
      rmCtrl.text = _fmt(widget.initialRm!);
      return;
    }
    if (widget.movementName != null) {
      final last =
          await RmStorage.loadLastRm(widget.movementName!, settings.units);
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

    List<Map<String, dynamic>> entries =
        await RmStorage.loadRmHistory(name, unit);

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
                setSheetState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.historyClearedSnack,
                      ),
                    ),
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
                      width: 40,
                      height: 4,
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
                            AppLocalizations.of(context)!.historySheetTitle(
                              name,
                              unit,
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: entries.isEmpty ? null : _clear,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(
                            AppLocalizations.of(context)!.historyClear,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          AppLocalizations.of(context)!.historyEmpty,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 420),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = entries[i];
                            final rm = (e['rm'] as num).toDouble();
                            final ts = DateTime.tryParse(
                                      e['ts'] as String? ?? '',
                                    ) ??
                                DateTime.now();
                            return ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(
                                AppLocalizations.of(context)!.historyRowRm(
                                  rm.toStringAsFixed(1),
                                  unit,
                                ),
                              ),
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

  String _fmt(double v) =>
      v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  List<double> _barOptions() =>
      settings.units == 'lb' ? [45, 33] : [20, 15];

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
    final cleaned =
        raw.trim().replaceAll('%', '').replaceAll(',', '.');
    final v = double.tryParse(cleaned) ?? 0.0;
    return (v / 100.0).clamp(0.0, 1.2);
  }

  Map<String, double> _targetsForPct(double pct) {
    final rm =
        double.tryParse(rmCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final bar = settings.barWeight;
    final col = settings.collarsWeight;

    if (mode == TargetInputMode.totalInclBar) {
      final total = rm * pct;
      final perSide =
          ((total - bar - col) / 2.0).clamp(0.0, double.infinity);
      return {'total': total, 'perSide': perSide};
    } else {
      final perSide = rm * pct;
      final total = bar + col + 2.0 * perSide;
      return {'total': total, 'perSide': perSide};
    }
  }

  double _targetTotalFromPct(double pct) =>
      _targetsForPct(pct)['total']!;

  Future<void> _saveRmManually() async {
    if (widget.movementName == null) return;
    final rm =
        double.tryParse(rmCtrl.text.replaceAll(',', '.'));
    if (rm == null || rm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.saveRmInvalidSnack,
          ),
        ),
      );
      return;
    }

    await RmStorage.saveLastRm(
      widget.movementName!,
      settings.units,
      rm,
    );

    await RmStorage.appendRmHistory(
      widget.movementName!,
      settings.units,
      rm,
      DateTime.now(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.saveRmOkSnack(
            widget.movementName!,
            settings.units,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMovement() async {
    if (widget.movementName == null) return;
    final name = widget.movementName!.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteMovementDialogTitle,
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteMovementDialogContent(
            name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.of(context)!.deleteMovementCancel,
            ),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalizations.of(context)!.deleteMovementConfirm,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final ok = await RmStorage.deleteMovement(name);
      if (!mounted) return;

      if (ok) {
        _wasDeleted = true;
        rmCtrl.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.deleteMovementOkSnack(
                name,
              ),
            ),
          ),
        );

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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.deleteMovementFailSnack,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.deleteMovementFailSnack,
          ),
        ),
      );
    }
  }

  void _onCalculate() {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      error = null;
    });

    final pct = _parsePct(pctCtrl.text);
    if (pct <= 0) {
      setState(() {
        error = AppLocalizations.of(context)!.errorPercentInvalid;
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
      plates: settings.plates
          .map((p) => Plate(weight: p.weight, count: p.count))
          .toList(),
    );

    if (r == null) {
      setState(() {
        error = AppLocalizations.of(context)!.errorTargetTooLow;
        result = null;
        _showPanel = false;
      });
      return;
    }

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
        pctCtrl.text =
            (fraction * 100).round().toString();
        _onCalculate();
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: 56, child: Text(percentLabel)),
            Expanded(
              child: Text(t['total']!.toStringAsFixed(1)),
            ),
            Expanded(
              child: Text(t['perSide']!.toStringAsFixed(1)),
            ),
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
    final tableRows =
        List<double>.generate(10, (i) => (i + 1) * 0.10);
    final panelHeight = size.height * 0.65;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async {
        if (_showPanel) {
          setState(() => _showPanel = false);
          return false;
        }
        if (_wasDeleted) {
          Navigator.of(context)
              .pop(<String, dynamic>{'deleted': true});
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.movementName ??
                AppLocalizations.of(context)!.appTitle,
          ),
          actions: [
            if (widget.movementName != null)
              IconButton(
                tooltip:
                    AppLocalizations.of(context)!.saveRmTooltip,
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Unidades
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.unitsLabel,
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: settings.units,
                        items: const [
                          DropdownMenuItem(
                            value: 'kg',
                            child: Text('kg'),
                          ),
                          DropdownMenuItem(
                            value: 'lb',
                            child: Text('lb'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          final newBar =
                              _mapBarBetweenUnits(
                            settings.barWeight,
                            settings.units,
                            v,
                          );
                          setState(() {
                            settings = settings.copyWith(
                              units: v,
                              barWeight: newBar,
                            );
                          });
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .barLabel,
                            ),
                            DropdownButton<double>(
                              isExpanded: true,
                              value: _barOptions().contains(
                                      settings.barWeight)
                                  ? settings.barWeight
                                  : _barOptions().first,
                              items: _barOptions()
                                  .map(
                                    (w) => DropdownMenuItem(
                                      value: w,
                                      child: Text(
                                        '${w.toStringAsFixed(0)} ${settings.units}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (w) {
                                if (w == null) return;
                                setState(() {
                                  settings =
                                      settings.copyWith(
                                          barWeight: w);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: settings
                              .collarsWeight
                              .toString(),
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!
                                    .collarsLabel,
                          ),
                          keyboardType:
                              TextInputType.number,
                          onChanged: (v) {
                            setState(() {
                              settings = settings.copyWith(
                                collarsWeight:
                                    double.tryParse(v) ??
                                        settings
                                            .collarsWeight,
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Interpretación
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .interpretRmAs,
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<TargetInputMode>(
                        value: mode,
                        items: [
                          DropdownMenuItem(
                            value: TargetInputMode
                                .totalInclBar,
                            child: Text(
                              AppLocalizations.of(context)!
                                  .modeTotalInclBar,
                            ),
                          ),
                          DropdownMenuItem(
                            value: TargetInputMode
                                .perSideWithoutBar,
                            child: Text(
                              AppLocalizations.of(context)!
                                  .modePerSide,
                            ),
                          ),
                        ],
                        onChanged: (m) => setState(
                          () => mode = m ?? mode,
                        ),
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
                          keyboardType:
                              TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                widget.movementName ==
                                        null
                                    ? AppLocalizations.of(
                                            context)!
                                        .rmFieldNoMovement
                                    : AppLocalizations.of(
                                            context)!
                                        .rmFieldWithMovement(
                                          widget
                                              .movementName!,
                                        ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: pctCtrl,
                          keyboardType:
                              TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(
                                        context)!
                                    .percentLabel,
                            suffixText: '%',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Vista derivada
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!
                            .derivedTargetLabel(
                          (pct * 100)
                              .toStringAsFixed(1),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode ==
                                TargetInputMode
                                    .totalInclBar
                            ? AppLocalizations.of(
                                    context)!
                                .derivedTotal(
                                  totalFromPct
                                      .toStringAsFixed(
                                          1),
                                  settings.units,
                                )
                            : AppLocalizations.of(
                                    context)!
                                .derivedPerSide(
                                  perSideFromPct
                                      .toStringAsFixed(
                                          1),
                                  settings.units,
                                ),
                        style:
                            theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tabla de % clickeable
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceVariant
                        .withOpacity(0.35),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .percentTableTitle,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 56,
                                  child: Text(
                                    AppLocalizations.of(
                                            context)!
                                        .percentTableHeaderPercent,
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                            context)!
                                        .percentTableHeaderTotal,
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                            context)!
                                        .percentTableHeaderPerSide,
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: tableRows
                                .map(_percentRow)
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón calcular
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onCalculate,
                      child: Text(
                        AppLocalizations.of(context)!
                            .calculateButton,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Botón historial RM (si hay movimiento)
                  if (widget.movementName != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openRmHistory,
                        icon: const Icon(Icons.history),
                        label: Text(
                          AppLocalizations.of(context)!
                              .historyButton,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Botón eliminar movimiento
                  if (widget.movementName != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context)
                                  .colorScheme
                                  .error,
                          foregroundColor:
                              Theme.of(context)
                                  .colorScheme
                                  .onError,
                        ),
                        onPressed: _deleteMovement,
                        child: Text(
                          AppLocalizations.of(context)!
                              .deleteMovementButton(
                            widget.movementName ?? '',
                          ),
                        ),
                      ),
                    ),

                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
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
                  onTap: () =>
                      setState(() => _showPanel = false),
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
              height:
                  panelHeight + (bottomInset > 0 ? 12 : 0),
              child: SafeArea(
                top: false,
                child: Material(
                  elevation: 12,
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: result == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(
                                      16, 10, 8, 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .grey.shade400,
                                      borderRadius:
                                          BorderRadius
                                              .circular(2),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip:
                                        AppLocalizations.of(
                                                context)!
                                            .panelCloseTooltip,
                                    onPressed: () =>
                                        setState(() =>
                                            _showPanel =
                                                false),
                                    icon: const Icon(
                                      Icons.close,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      result!.exact
                                          ? AppLocalizations.of(
                                                  context)!
                                              .resultExact(
                                                result!
                                                    .totalAchieved
                                                    .toStringAsFixed(
                                                        2),
                                                settings
                                                    .units,
                                              )
                                          : AppLocalizations.of(
                                                  context)!
                                              .resultApprox(
                                                result!
                                                    .totalAchieved
                                                    .toStringAsFixed(
                                                        2),
                                                result!
                                                    .shortfall
                                                    .toStringAsFixed(
                                                        2),
                                                settings
                                                    .units,
                                              ),
                                      style: theme.textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(
                                        height: 12),
                                    Expanded(
                                      child: Center(
                                        child: BarbellView(
                                          perSide:
                                              result!.perSide,
                                          units:
                                              settings.units,
                                          height: 200,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                        height: 12),
                                    Text(
                                      AppLocalizations.of(
                                              context)!
                                          .chosenDiscsTitle,
                                      style: theme.textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(
                                        height: 6),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: () {
                                        final entries = result!
                                            .used.entries
                                            .toList()
                                          ..sort((a, b) => b
                                              .key
                                              .compareTo(
                                                  a.key));

                                        final baseStyle = Theme.of(
                                                context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: Theme.of(
                                                      context)
                                                  .colorScheme
                                                  .onSurface,
                                            );

                                        return entries
                                            .map((e) {
                                          final c =
                                              PlateVisual
                                                  .color(
                                            settings.units,
                                            e.key,
                                          );

                                          return Chip(
                                            shape:
                                                StadiumBorder(
                                              side:
                                                  BorderSide(
                                                color: c,
                                                width: 1.5,
                                              ),
                                            ),
                                            backgroundColor:
                                                Theme.of(
                                                        context)
                                                    .colorScheme
                                                    .surfaceVariant
                                                    .withOpacity(
                                                        0.20),
                                            label: RichText(
                                              text:
                                                  TextSpan(
                                                style:
                                                    baseStyle,
                                                children: [
                                                  TextSpan(
                                                    text: e.key
                                                        .toString()
                                                        .replaceAll(
                                                            '.0',
                                                            ''),
                                                    style:
                                                        baseStyle
                                                            .copyWith(
                                                      color:
                                                          c,
                                                      fontWeight:
                                                          FontWeight
                                                              .w700,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        ' ${settings.units}  x${e.value}',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList();
                                      }(),
                                    ),
                                    const SizedBox(
                                        height: 10),
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
