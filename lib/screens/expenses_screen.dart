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
          bottom: const TabBar(tabs: [Tab(text: 'المصاريف'), Tab(text: 'السلف')]),
        ),
        body: const TabBarView(
          children: [
            ExpenseListView(type: 'مصروف'),
            ExpenseListView(type: 'سلفة'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'مصروف';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('إضافة جديدة'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleController, decoration: const InputDecoration(labelText: 'البيان/الاسم')),
        TextField(controller: amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
        DropdownButtonFormField<String>(
          value: type,
          items: ['مصروف', 'سلفة'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => type = v!,
        )
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () {
          // هنا سيتم استدعاء الدالة من الـ Provider
          // Provider.of<DeviceProvider>(context, listen: false).addExpenseOrAdvance(...);
          Navigator.pop(ctx);
        }, child: const Text('حفظ')),
      ],
    ));
  }
}

// كلاس لعرض القائمة (مصروف أو سلفة)
class ExpenseListView extends StatelessWidget {
  final String type;
  const ExpenseListView({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    final items = provider.expenses.where((e) => e.type == type).toList();
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) => ListTile(
        title: Text(items[i].title),
        subtitle: Text(items[i].date.toString().substring(0, 16)),
        trailing: Text('${items[i].amount} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
