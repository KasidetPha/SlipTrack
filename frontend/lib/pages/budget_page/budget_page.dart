import 'package:flutter/material.dart';
import 'package:frontend/models/budget_model.dart';
import 'package:frontend/services/receipt_service.dart';

class BudgetPage extends StatefulWidget {
  final int month;
  final int year;

  const BudgetPage({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late Future<BudgetResponse> _future;
  BudgetResponse? budget;

  @override
  void initState() {
    super.initState();
    _future = ReceiptService().fetchBudgets(
      month: widget.month,
      year: widget.year,
    );
  }

  Future<void> _reload() async {
    final data = await ReceiptService().fetchBudgets(
      month: widget.month,
      year: widget.year,
    );
    setState(() {
      budget = data;
    });
  }

  Future<void> _save() async {
    if (budget == null) return;
    final updated = await ReceiptService().updateBudget(budget: budget!);

    setState(() {
      budget = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("บันทึกงบประมาณสำเร็จ")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget Settings"),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          budget ??= snapshot.data!;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSwitches(),
                const SizedBox(height: 16),
                const Text("Category Budgets",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._buildCategoryFields(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text("Save"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // -----------------------------
  // UI: switches
  // -----------------------------
  Widget _buildSwitches() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text("Enable Warning"),
          value: budget!.warningEnabled,
          onChanged: (v) {
            setState(() => budget!.warningEnabled = v);
          },
        ),
        SwitchListTile(
          title: const Text("Enable Overspending"),
          value: budget!.overspendingEnabled,
          onChanged: (v) {
            setState(() => budget!.overspendingEnabled = v);
          },
        )
      ],
    );
  }

  // -----------------------------
  // UI: category limit fields
  // -----------------------------
  List<Widget> _buildCategoryFields() {
    return budget!.items.map((item) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.category, color: Colors.black),
          ),
          title: Text(item.categoryName),
          subtitle: Text("Limit: ${item.limit.toStringAsFixed(2)} บาท"),
          trailing: SizedBox(
            width: 90,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Limit",
              ),
              onChanged: (value) {
                final newVal = double.tryParse(value) ?? 0.0;
                item.limit = newVal;
              },
            ),
          ),
        ),
      );
    }).toList();
  }
}
