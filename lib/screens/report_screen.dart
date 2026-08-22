import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    
    // حساب المبالغ
    double totalSales = provider.getCurrentShiftTotalSales(); // دالة في البروفايدر
    double totalExpenses = provider.getExpensesTotalByType('مصروف');
    double totalAdvances = provider.getExpensesTotalByType('سلفة');
    double netProfit = totalSales - totalExpenses;

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير الوردية')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildReportCard('إجمالي المبيعات', totalSales, Colors.green),
            _buildReportCard('المصاريف', totalExpenses, Colors.red),
            _buildReportCard('السلف', totalAdvances, Colors.orange),
            const Divider(),
            _buildReportCard('صافي الربح', netProfit, Colors.deepPurple, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, double amount, Color color, {bool isBold = false}) {
    return Card(
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        trailing: Text('${amount.toStringAsFixed(2)} ج.م', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
