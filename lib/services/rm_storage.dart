import 'package:shared_preferences/shared_preferences.dart';

class RmStorage {
  static const _kCustomLifts = 'custom_lifts';

  static String _rmKey(String lift, String units) => 'rm_${lift}_$units';

  static Future<double?> loadLastRm(String lift, String units) async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getDouble(_rmKey(lift, units));
    return v;
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
}
