import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/presets.dart';
import '../../models/settings.dart';
import '../../services/rm_storage.dart';
import 'home_screen.dart';
import 'package:plate_calc/l10n/app_localizations.dart';

class RmListScreen extends StatefulWidget {
  const RmListScreen({super.key});

  @override
  State<RmListScreen> createState() => _RmListScreenState();
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
    // Crea Settings según unidades elegidas en esta pantalla
    final Settings initialSettings =
        (_units == 'lb') ? Presets.comercialLb() : Presets.halteroKg();

    if (!context.mounted) return;

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          initial: initialSettings,
          movementName: lift,
          initialRm: last,       // puede ser null: HomeScreen lo maneja
          forceUnits: _units,    // asegura las unidades
        ),
      ),
    );

    // 🔑 Si HomeScreen devolvió que se eliminó, recargamos la lista completa
    if (res is Map && res['deleted'] == true) {
      await _load();           // vuelve a leer custom lifts desde RmStorage
      if (context.mounted) setState(() {});
      return;
    }

    // Si no hubo eliminación, refrescamos para que los FutureBuilder re-lean el último RM
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
          const SizedBox(width: 8),
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
