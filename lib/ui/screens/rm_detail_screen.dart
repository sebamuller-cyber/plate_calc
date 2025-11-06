import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RmDetailScreen extends StatefulWidget {
  final String liftName;
  const RmDetailScreen({super.key, required this.liftName});

  @override
  State<RmDetailScreen> createState() => _RmDetailScreenState();
}

class _RmDetailScreenState extends State<RmDetailScreen> {
  final ctrlRm = TextEditingController();
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final sp = await SharedPreferences.getInstance();
    final key = 'rm_${widget.liftName}';
    final list = sp.getStringList(key) ?? [];
    setState(() {
      records = list
          .map((s) {
            final parts = s.split('|');
            return {'rm': parts[0], 'date': parts[1]};
          })
          .toList();
    });
  }

  Future<void> _saveRecord() async {
    final rmValue = ctrlRm.text.trim();
    if (rmValue.isEmpty) return;

    final sp = await SharedPreferences.getInstance();
    final key = 'rm_${widget.liftName}';
    final date = DateTime.now().toIso8601String().substring(0, 10);

    final list = sp.getStringList(key) ?? [];
    list.add('$rmValue|$date');
    await sp.setStringList(key, list);

    ctrlRm.clear();
    await _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.liftName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ctrlRm,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nuevo 1RM',
                hintText: 'Ej: 100 kg',
              ),
              onSubmitted: (_) => _saveRecord(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRecord,
                child: const Text('Guardar registro'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: records.isEmpty
                  ? const Center(child: Text('Sin registros aún'))
                  : ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, i) {
                        final r = records[i];
                        return ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text('${r['rm']}'),
                          subtitle: Text(r['date']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
