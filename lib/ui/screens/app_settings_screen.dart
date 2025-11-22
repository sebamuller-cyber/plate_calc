import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plate_calc/l10n/app_localizations.dart';
import 'package:plate_calc/models/settings.dart';
import 'package:plate_calc/models/plate.dart';
import 'package:plate_calc/ui/widgets/plate_colors.dart';

class AppSettingsScreen extends StatefulWidget {
  final String? currentLocaleCode;                 // 'es', 'en', 'fr' o null (sistema)
  final Future<void> Function(String? code) onLocaleChanged;

  const AppSettingsScreen({
    super.key,
    required this.currentLocaleCode,
    required this.onLocaleChanged,
  });

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen>
    with SingleTickerProviderStateMixin {
  String? _localeCode;
  late TabController _tabController;

  Settings? _kgSettings;
  Settings? _lbSettings;
  bool _loadingInventory = true;

  @override
  void initState() {
    super.initState();
    _localeCode = widget.currentLocaleCode;
    _tabController = TabController(length: 2, vsync: this);
    _loadInventory();
  }

  // ---------- INVENTARIO: cargar / guardar SOLO discos ----------

  Future<void> _loadInventory() async {
    final prefs = await SharedPreferences.getInstance();

    Settings _defaultKg() => Settings(
          units: 'kg',
          barWeight: 20,
          collarsWeight: 0,
          plates: [
            Plate(weight: 25, count: 2),
            Plate(weight: 20, count: 2),
            Plate(weight: 15, count: 2),
            Plate(weight: 10, count: 2),
            Plate(weight: 5, count: 2),
            Plate(weight: 2.5, count: 2),
            Plate(weight: 2, count: 2),
            Plate(weight: 1.5, count: 2),
            Plate(weight: 1, count: 2),
          ],
        );

    Settings _defaultLb() => Settings(
          units: 'lb',
          barWeight: 45,
          collarsWeight: 0,
          plates: [
            Plate(weight: 45, count: 2),
            Plate(weight: 35, count: 2),
            Plate(weight: 25, count: 2),
            Plate(weight: 10, count: 2),
            Plate(weight: 5, count: 2),
            Plate(weight: 2.5, count: 2),
            Plate(weight: 2, count: 2),
            Plate(weight: 1.25, count: 2),
            Plate(weight: 0.5, count: 2),
          ],
        );

    Settings _decode(String units, String? raw, Settings fallback) {
      if (raw == null) return fallback;
      try {
        final decoded = jsonDecode(raw);
        List<dynamic> platesJson;
        if (decoded is List) {
          platesJson = decoded;
        } else if (decoded is Map && decoded['plates'] is List) {
          platesJson = decoded['plates'] as List;
        } else {
          return fallback;
        }

        final plates = platesJson
            .map(
              (e) => Plate(
                weight: (e['weight'] as num).toDouble(),
                count: (e['count'] as num).toInt(),
              ),
            )
            .toList();

        // solo sobreescribimos discos, barra/collares quedan del default
        return fallback.copyWith(plates: plates);
      } catch (_) {
        return fallback;
      }
    }

    final kgRaw = prefs.getString('inventory_settings_kg');
    final lbRaw = prefs.getString('inventory_settings_lb');

    setState(() {
      _kgSettings = _decode('kg', kgRaw, _defaultKg());
      _lbSettings = _decode('lb', lbRaw, _defaultLb());
      _loadingInventory = false;
    });
  }

  Future<void> _saveInventory() async {
    if (_kgSettings == null || _lbSettings == null) return;
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> _encodePlates(Settings s) => s.plates
        .map((p) => {'weight': p.weight, 'count': p.count})
        .toList();

    await prefs.setString(
      'inventory_settings_kg',
      jsonEncode(_encodePlates(_kgSettings!)),
    );
    await prefs.setString(
      'inventory_settings_lb',
      jsonEncode(_encodePlates(_lbSettings!)),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.inventorySaveButton)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.settingsTabLanguage),
            Tab(text: loc.settingsTabInventory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // -------- TAB IDIOMA --------
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                loc.settingsLanguageTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RadioListTile<String?>(
                title: Text(loc.settingsLanguageSystem),
                value: null,
                groupValue: _localeCode,
                onChanged: (v) async {
                  setState(() => _localeCode = v);
                  await widget.onLocaleChanged(null);
                },
              ),
              RadioListTile<String?>(
                title: Text(loc.settingsLanguageSpanish),
                value: 'es',
                groupValue: _localeCode,
                onChanged: (v) async {
                  setState(() => _localeCode = v);
                  await widget.onLocaleChanged('es');
                },
              ),
              RadioListTile<String?>(
                title: Text(loc.settingsLanguageEnglish),
                value: 'en',
                groupValue: _localeCode,
                onChanged: (v) async {
                  setState(() => _localeCode = v);
                  await widget.onLocaleChanged('en');
                },
              ),
              RadioListTile<String?>(
                title: Text(loc.settingsLanguageFrench),
                value: 'fr',
                groupValue: _localeCode,
                onChanged: (v) async {
                  setState(() => _localeCode = v);
                  await widget.onLocaleChanged('fr');
                },
              ),
            ],
          ),

          // -------- TAB INVENTARIO --------
          _loadingInventory
              ? const Center(child: CircularProgressIndicator())
              : _InventoryEditor(
                  kg: _kgSettings!,
                  lb: _lbSettings!,
                  onChangedKg: (s) => setState(() => _kgSettings = s),
                  onChangedLb: (s) => setState(() => _lbSettings = s),
                  onSave: _saveInventory,
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INVENTORY EDITOR (KG / LB con grid 3x3)
// ─────────────────────────────────────────────

class _InventoryEditor extends StatelessWidget {
  final Settings kg;
  final Settings lb;
  final ValueChanged<Settings> onChangedKg;
  final ValueChanged<Settings> onChangedLb;
  final Future<void> Function() onSave;

  const _InventoryEditor({
    required this.kg,
    required this.lb,
    required this.onChangedKg,
    required this.onChangedLb,
    required this.onSave,
  });

  Widget _buildGridForUnits(
    BuildContext context,
    Settings s,
    ValueChanged<Settings> onChanged,
  ) {
    final plates = s.plates;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: plates.length,
      itemBuilder: (context, idx) {
        final p = plates[idx];
        final color = PlateVisual.color(s.units, p.weight);

        void updateCount(int delta) {
          final newCount = (p.count + delta).clamp(0, 999);
          final newPlates = [...plates];
          newPlates[idx] =
              newPlates[idx].copyWith(count: newCount);
          onChanged(s.copyWith(plates: newPlates));
        }

        String labelWeight(double w) {
          final txt =
              w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1);
          return '$txt ${s.units}';
        }

        return Column(
          children: [
            // Disco "realista"
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withOpacity(0.95),
                            color.withOpacity(0.65),
                          ],
                          center: const Alignment(-0.3, -0.3),
                          radius: 0.95,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(2, 3),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.45),
                          width: 3,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Text(
                        labelWeight(p.weight),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          shadows: [
                            Shadow(
                              blurRadius: 3,
                              color: Colors.black54,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  onPressed: () => updateCount(-1),
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  p.count.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  onPressed: () => updateCount(1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: loc.inventoryKgTitle),
              Tab(text: loc.inventoryLbTitle),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // KG
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildGridForUnits(context, kg, onChangedKg),
                ),
                // LB
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildGridForUnits(context, lb, onChangedLb),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: Text(loc.inventorySaveButton),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

