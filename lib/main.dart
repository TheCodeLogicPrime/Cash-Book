import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartCashBookApp());
}

class SmartCashBookApp extends StatelessWidget {
  const SmartCashBookApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cash Book Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
      ),
      home: const CashBookHomePage(),
    );
  }
}
class CashBookHomePage extends StatefulWidget {
  const CashBookHomePage({super.key});
  @override
  State<CashBookHomePage> createState() => _CashBookHomePageState();
}

class _CashBookHomePageState extends State<CashBookHomePage> {
  static const String storageKey = 'smart_cashbook_v2';
  Map<String, dynamic> db = {"Main Book": {"totalIn": 0.0, "totalOut": 0.0, "history": []}};
  String activeAcc = "Main Book";
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dbString = prefs.getString(storageKey);
    setState(() {
      if (dbString != null) {
        try { db = Map<String, dynamic>.from(jsonDecode(dbString)); } catch (_) {}
      }
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(db));
  }

  void _addTx(double amount, String type) {
    if (amount <= 0) return;
    final accData = db[activeAcc];
    if (type == 'in') accData['totalIn'] += amount;
    else accData['totalOut'] += amount;
    
    List history = accData['history'] ?? [];
    history.insert(0, {'id': DateTime.now().millisecondsSinceEpoch.toDouble(), 'amt': amount, 'type': type});
    accData['history'] = history;
    _saveState();
    setState(() {});
  }
    @override
  Widget build(BuildContext context) {
    final accData = db[activeAcc] ?? {"totalIn": 0.0, "totalOut": 0.0, "history": []};
    final double net = (accData['totalIn'] as num) - (accData['totalOut'] as num);
    final List history = accData['history'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Cash Book', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              children: [
                Text("NET BALANCE", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                Text((net >= 0 ? "+ ₹" : "- ₹") + net.abs().toStringAsFixed(2), style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: net >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final isOut = item['type'] == 'out';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: ListTile(
                    title: Text(isOut ? 'Cash Out' : 'Cash In', style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text((isOut ? "- ₹" : "+ ₹") + item['amt'].toString(), style: TextStyle(color: isOut ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            ),
          ),
                    Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => _addTx(100, 'out'),
                    child: const Text("CASH OUT (-100)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => _addTx(100, 'in'),
                    child: const Text("CASH IN (+100)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
