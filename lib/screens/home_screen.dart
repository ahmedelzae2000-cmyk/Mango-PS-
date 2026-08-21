import 'dart:async';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDarkMode = true;

  // قائمة أجهزة افتراضية للتجربة
  List<Map<String, dynamic>> devices = [
    {
      'id': '1',
      'name': 'جهاز 1 - PS5',
      'isOccupied': false,
      'pricePerHour': 40.0,
      'startTime': null,
    },
    {
      'id': '2',
      'name': 'جهاز 2 - PS4',
      'isOccupied': false,
      'pricePerHour': 30.0,
      'startTime': null,
    },
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // تحديث العداد كل ثانية لتحديث الوقت والتكلفة حياً
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // حساب وقت الجلسة بالدقائق والثواني
  String _getDurationText(DateTime? startTime) {
    if (startTime == null) return '00:00:00';
    final diff = DateTime.now().difference(startTime);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // حساب التكلفة المبدئية بناءً على الوقت المنقضي
  double _calculateCost(DateTime? startTime, double pricePerHour) {
    if (startTime == null) return 0.0;
    final minutes = DateTime.now().difference(startTime).inMinutes;
    return (minutes / 60.0) * pricePerHour;
  }

  // نافذة إنهاء الجلسة (تعديل السعر + اختيار طريقة الدفع)
  void _showEndSessionDialog(Map<String, dynamic> device) {
    final startTime = device['startTime'] as DateTime?;
    final double initialCost = _calculateCost(startTime, device['pricePerHour']);
    
    final TextEditingController costController =
        TextEditingController(text: initialCost.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text(
                'إنهاء جلسة: ${device['name']}',
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الوقت المستغرق: ${_getDurationText(startTime)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  // تعديل السعر قبل الإنهاء
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'التكلفة النهائية (ج.م)',
                      border: OutlineInputBorder(),
                      suffixText: 'ج.م',
                    ),
                  ),
                  const SizedBox(height: 15),
                  // تحديد طريقة الدفع
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    dropdownColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                    ),
                    items: ['كاش', 'فيزا'].map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => paymentMethod = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    setState(() {
                      device['isOccupied'] = false;
                      device['startTime'] = null;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم تحصيل ${costController.text} ج.م (${paymentMethod}) بنجاح!',
                        ),
                      ),
                    );
                  },
                  child: const Text('تأكيد وإغلاق', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manga PS - الرئيسية'),
          centerTitle: true,
          actions: [
            // زر التبديل للوضع الداكن (Dark Mode)
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
            ),
          ],
        ),
        // الخلفية المختارة المخصصة
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
                  : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: devices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final dev = devices[index];
                final isOccupied = dev['isOccupied'] as bool;
                final startTime = dev['startTime'] as DateTime?;
                final currentCost = _calculateCost(startTime, dev['pricePerHour']);

                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dev['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Divider(color: isDarkMode ? Colors.white24 : Colors.black12),
                        // 1. إظهار وقت الجلسة والتكلفة حياً
                        if (isOccupied) ...[
                          Column(
                            children: [
                              const Text('الوقت المنقضي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                _getDurationText(startTime),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text('التكلفة الحالية', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                '${currentCost.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        ] else ...[
                          const Icon(Icons.sports_esports, size: 50, color: Colors.grey),
                          const Text('الجهاز متاح', style: TextStyle(color: Colors.grey)),
                        ],
                        // أزرار التشغيل والإنهاء
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOccupied ? Colors.red : Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (isOccupied) {
                                // فتح نافذة الإنهاء والدفع
                                _showEndSessionDialog(dev);
                              } else {
                                // بدء الجلسة
                                setState(() {
                                  dev['isOccupied'] = true;
                                  dev['startTime'] = DateTime.now();
                                });
                              }
                            },
                            child: Text(
                              isOccupied ? 'إنهاء الجلسة' : 'بدء الجلسة',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
 
