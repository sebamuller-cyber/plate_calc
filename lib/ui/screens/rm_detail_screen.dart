import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RmDetailScreen extends StatefulWidget {
  final String liftName; // e.g., "Front Squat"
  const RmDetailScreen({super.key, required this.liftName});

  @override
  State<RmDetailScreen> createState() => _RmDetailScreenState();
}

class _RmDetailScreenState extends State<RmDetailScreen> {
  final ctrlRm = TextEditingController();
  List<Map<String, dynamic>> records = []; // [{'rm': 150.0, 'date': '2025-11-07 15:20'}, ...]

  // === Claves de almacenamiento ===
  String get _historyKey => 'rm_history_${widget.liftName}';
  String get _rmKgKey => 'rm_kg_${widget.liftName}';
  String get _rmLbKey => 'rm_lb_${widget.liftName}';
  String get _customListKey => 'custom_lifts';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      setState(() => records = []);
      return;
    }
    try {
      final List list = jsonDecode(raw) as List;
      final parsed = list.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'rm': (m['rm'] is num) ? (m['rm'] as num).toDouble() : double.tryParse('${m['rm']}') ?? 0.0,
          'date': '${m['date'] ?? ''}',
        };
      }).toList();
      setState(() => records = parsed);
    } catch (_) {
      setState(() => records = []);
    }
  }

  Future<void> _saveRm() async {
    final text = ctrlRm.text.trim().replaceAll(',', '.');
    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un RM válido (> 0).')),
      );
      return;
    }

    final now = DateTime.now();
    final entry = {
      'rm': value,
      'date': '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}',
    };

    final newList = [entry, ...records];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(newList));

    // Opcional: también sincroniza “último RM” en kg o lb si tu app lo usa
    // Aquí no sabemos la unidad activa, así que no sobreescribimos por defecto.
    // Si quieres guardar en kg por defecto, descomenta:
    // await prefs.setDouble(_rmKgKey, value);

    setState(() {
      records = newList;
      ctrlRm.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('RM guardado.')),
    );
  }

  Future<void> _deleteMovement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text(
          '¿Deseas eliminar “${widget.liftName}” por completo?\n'
          'Se borrará de tu lista de movimientos personalizados y su historial/RM guardados.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();

    // 1) Quitar de la lista de movimientos personalizados
    final list = prefs.getStringList(_customListKey) ?? <String>[];
    list.removeWhere((e) => e.trim().toLowerCase() == widget.liftName.trim().toLowerCase());
    await prefs.setStringList(_customListKey, list);

    // 2) Borrar historial y últimos RM
    await prefs.remove(_historyKey);
    await prefs.remove(_rmKgKey);
    await prefs.remove(_rmLbKey);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Movimiento eliminado: ${widget.liftName}')),
    );

    // Devuelve al caller que se eliminó, para que actualice la lista
    Navigator.of(context).pop<bool>(true);
  }

  Future<void> _deleteRecord(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Eliminar este registro del historial?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final newList = [...records]..removeAt(index);
    await prefs.setString(_historyKey, jsonEncode(newList));
    setState(() => records = newList);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.liftName),
        actions: [
          IconButton(
            tooltip: 'Eliminar movimiento',
            onPressed: _deleteMovement,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrlRm,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo RM',
                      hintText: 'Ej: 150.5',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveRm,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historial',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: records.isEmpty
                  ? const Center(child: Text('Aún no tienes registros.'))
                  : ListView.separated(
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = records[index];
                        return ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text('${r['rm']}'),
                          subtitle: Text('${r['date']}'),
                          trailing: IconButton(
                            tooltip: 'Eliminar registro',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteRecord(index),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: d.width,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cleaning_services_outlined),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Limpiar historial'),
                      content: const Text('¿Eliminar todo el historial de este movimiento?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove(_historyKey);
                    setState(() => records = []);
                  }
                },
                label: const Text('Limpiar historial'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

