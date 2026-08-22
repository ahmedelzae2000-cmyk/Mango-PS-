import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المصاريف والسلف'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المصاريف'),
              Tab(text: 'السلف'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ExpenseListView(type: 'مصروف'),
            ExpenseListView(type: 'سلفة'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          onPressed: () => _showAddDialog(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'مصروف';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'البيان أو الاسم'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: ['مصروف', 'سلفة'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => type = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0.0;
                if (titleController.text.isNotEmpty && amount > 0) {
                  Provider.of<DeviceProvider>(context, listen: false)
                      .addExpenseOrAdvance(titleController.text, amount, type);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseListView extends StatelessWidget {
  final String type;
  const ExpenseListView({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    final items = provider.expenses.where((e) => e.type == type).toList();

    if (items.isEmpty) {
      return Center(child: Text('لا توجد سجلات لـ $type'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item.date != null ? item.date!.toDate().toString().substring(0, 16) : 'جاري الحفظ...'),
            trailing: Text(
              '${item.amount.toStringAsFixed(2)} ج.م',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: type == 'مصروف' ? Colors.red : Colors.orange,
              ),
            ),
          ),
        );
      },
    );
  }
}
