import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RmStorage {
  static const _kCustomLifts = 'custom_lifts';

  static String _rmKey(String lift, String units) => 'rm_${lift}_$units';

  static Future<double?> loadLastRm(String lift, String units) async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getDouble(_rmKey(lift, units));
    return v;
  }
static String _historyKey(String name, String units) => 'history_${name}_$units';

/// Agrega una entrada al historial: {rm, ts}
static Future<void> appendRmHistory(String name, String units, double rm, DateTime ts) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _historyKey(name, units);
  final raw = prefs.getString(key);
  final List<Map<String, dynamic>> list = raw == null
      ? []
      : List<Map<String, dynamic>>.from(jsonDecode(raw) as List);

  list.add({
    'rm': rm,
    'ts': ts.toIso8601String(),
  });

  await prefs.setString(key, jsonEncode(list));
}

/// Devuelve la lista de entradas ordenadas desc por fecha
static Future<List<Map<String, dynamic>>> loadRmHistory(String name, String units) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_historyKey(name, units));
  if (raw == null) return [];
  final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  list.sort((a, b) => (b['ts'] as String).compareTo(a['ts'] as String));
  return list;
}

/// Limpia el historial (solo de esas unidades)
static Future<bool> clearRmHistory(String name, String units) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.remove(_historyKey(name, units));
}

static Future<void> deleteLastRm(String movementName, String units) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'rm_${units}_$movementName';
    await prefs.remove(key);
  }
  static Future<void> saveLastRm(String lift, String units, double rm) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_rmKey(lift, units), rm);
  }

  static Future<List<String>> loadCustomLifts() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(_kCustomLifts) ?? <String>[];
  }

  static Future<void> addCustomLift(String name) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_kCustomLifts) ?? <String>[];
    if (!list.contains(name)) {
      list.add(name);
      await sp.setStringList(_kCustomLifts, list);
    }
  }
  static Future<bool> deleteMovement(String movementName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = movementName.trim();

      // 1) Remover de la lista de personalizados
      final list = prefs.getStringList('custom_lifts') ?? <String>[];
      final newList = List<String>.from(list)
        ..removeWhere((e) => e.trim().toLowerCase() == name.toLowerCase());
      await prefs.setStringList('custom_lifts', newList);

      // 2) Borrar claves de RM/Historial (cubriendo esquemas posibles)
      final keys = <String>[
        'rm_kg_$name',
        'rm_lb_$name',
        'rm_history_$name',
        // Si usas el esquema por unidades dinámicas:
        'rm_kg_$name',
        'rm_lb_$name',
      ];

      // Por compatibilidad: borra también `rm_<units>_<name>` si existiera
      for (final units in const ['kg', 'lb']) {
        keys.add('rm_${units}_$name');
      }

      for (final k in keys) {
        await prefs.remove(k);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
