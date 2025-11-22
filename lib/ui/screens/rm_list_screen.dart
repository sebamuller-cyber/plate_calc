import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/presets.dart';
import '../../models/settings.dart';
import '../../services/rm_storage.dart';
import 'home_screen.dart';
import 'package:plate_calc/l10n/app_localizations.dart';
import 'dart:convert';
import '../../models/plate.dart';



class RmListScreen extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const RmListScreen({super.key, this.onOpenSettings});

  @override
  State<RmListScreen> createState() => _RmListScreenState();
}

    Future<Settings> _loadSettingsForUnits(String units) async {
    // Partimos SIEMPRE de los presets (traen barra/collares por defecto)
    Settings base =
        (units == 'lb') ? Presets.comercialLb() : Presets.halteroKg();

    final prefs = await SharedPreferences.getInstance();
    final key =
        (units == 'lb') ? 'inventory_settings_lb' : 'inventory_settings_kg';
    final raw = prefs.getString(key);

    if (raw == null) {
      return base; // no hay inventario guardado, usamos preset completo
    }

    try {
      final decoded = jsonDecode(raw);

      // Soportar tanto formato nuevo (lista) como viejo ({plates: [...]})
      List<dynamic> platesJson;
      if (decoded is List) {
        platesJson = decoded;
      } else if (decoded is Map && decoded['plates'] is List) {
        platesJson = decoded['plates'] as List;
      } else {
        return base;
      }

      final customPlates = platesJson
          .map(
            (e) => Plate(
              weight: (e['weight'] as num).toDouble(),
              count: (e['count'] as num).toInt(),
            ),
          )
          .toList();

      // 👇 SOLO sobreescribimos los discos; barra/collares quedan de los presets
      return base.copyWith(plates: customPlates);
    } catch (_) {
      return base;
    }
  }


class _RmListScreenState extends State<RmListScreen> {
  final List<String> _baseLifts = const ['Deadlift', 'Snatch', 'Clean', 'Jerk'];
  List<String> _allLifts = [];
  String _units = 'lb'; // selector de unidades para ver y abrir cálculo

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final custom = await RmStorage.loadCustomLifts();
    setState(() => _allLifts = [..._baseLifts, ...custom]);
  }

  Future<void> _addLiftDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addLiftTitle),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.addLiftHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.deleteMovementCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                await RmStorage.addCustomLift(name);
                await _load();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.saveLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _openLift(String lift) async {
  // Carga el último RM guardado para estas unidades
  final last = await RmStorage.loadLastRm(lift, _units);

  // 👇 NUEVO: cargamos Settings desde inventario (o preset si no hay nada)
  final Settings initialSettings = await _loadSettingsForUnits(_units);

  if (!context.mounted) return;

  final res = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HomeScreen(
        initial: initialSettings,
        movementName: lift,
        initialRm: last,
        forceUnits: _units,
      ),
    ),
  );

  // resto igual que antes...
  if (res is Map && res['deleted'] == true) {
    await _load();
    if (context.mounted) setState(() {});
    return;
  }

  if (context.mounted) setState(() {});
}


  Widget _liftTile(String lift) {
    return FutureBuilder<double?>(
      future: RmStorage.loadLastRm(lift, _units),
      builder: (context, snap) {
        final lastRm = snap.data;
        return InkWell(
          onTap: () => _openLift(lift),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    lift,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (lastRm == null)
                        ? AppLocalizations.of(context)!.noRmLabel
                        : AppLocalizations.of(context)!.historyRowRm(
                            lastRm.toStringAsFixed(1),
                            _units,
                          ),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cols = MediaQuery.of(context).size.width ~/ 160; // responsivo simple
    final crossAxisCount = cols.clamp(2, 4);

    return Scaffold(
      appBar: AppBar(
  title: Text(AppLocalizations.of(context)!.yourLiftsTitle),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: Text(AppLocalizations.of(context)!.unitsLabel),
      ),
    ),
    DropdownButton<String>(
      value: _units,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'kg', child: Text('kg')),
        DropdownMenuItem(value: 'lb', child: Text('lb')),
      ],
      onChanged: (v) => setState(() => _units = v ?? 'kg'),
    ),
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: widget.onOpenSettings,
    ),
  ],
),

      floatingActionButton: FloatingActionButton(
        onPressed: _addLiftDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: _allLifts.map(_liftTile).toList(),
        ),
      ),
    );
  }
}
