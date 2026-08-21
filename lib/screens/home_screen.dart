import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDarkMode = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // تحديث الشاشة كل ثانية لحساب الوقت المباشر
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getDurationText(Timestamp? startTimestamp) {
    if (startTimestamp == null) return '00:00:00';
    final startTime = startTimestamp.toDate();
    final diff = DateTime.now().difference(startTime);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  double _calculateCost(Timestamp? startTimestamp, double pricePerHour) {
    if (startTimestamp == null) return 0.0;
    final minutes = DateTime.now().difference(startTimestamp.toDate()).inMinutes;
    return (minutes / 60.0) * pricePerHour;
  }

  // نافذة بدء الجلسة مع ضبط ألوان النصوص ووضوحها
  void _showStartSessionDialog(String docId, String deviceName, double singlePrice, double multiPrice) {
    String selectedMode = 'sgl';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textColor = isDarkMode ? Colors.white : Colors.black;
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF222222) : Colors.white,
              title: Text(
                'بدء جلسة: $deviceName',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Text('اختر نوع الجلسة:', style: TextStyle(color: textColor, fontSize: 16)),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    activeColor: Colors.green,
                    title: Text(
                      'فردي (Single) - $singlePrice ج.م/ساعة',
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                    value: 'sgl',
                    groupValue: selectedMode,
                    onChanged: (val) => setDialogState(() => selectedMode = val!),
                  ),
                  RadioListTile<String>(
                    activeColor: Colors.green,
                    title: Text(
                      'زوجي (Multi) - $multiPrice ج.م/ساعة',
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                    value: 'mlt',
                    groupValue: selectedMode,
                    onChanged: (val) => setDialogState(() => selectedMode = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    final currentPrice = selectedMode == 'sgl' ? singlePrice : multiPrice;
                    await FirebaseFirestore.instance.collection('devices').doc(docId).update({
                      'isOccupied': true,
                      'startTime': FieldValue.serverTimestamp(),
                      'sessionType': selectedMode == 'sgl' ? 'سنجل' : 'ملتي',
                      'activePrice': currentPrice,
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('بدء الجلسة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // نافذة إنهاء الجلسة
  void _showEndSessionDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startTimestamp = data['startTime'] as Timestamp?;
    final double activePrice = (data['activePrice'] ?? 0.0).toDouble();
    final double initialCost = _calculateCost(startTimestamp, activePrice);

    final TextEditingController costController =
        TextEditingController(text: initialCost.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textColor = isDarkMode ? Colors.white : Colors.black;
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF222222) : Colors.white,
              title: Text('إنهاء جلسة: ${data['name']}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Text('النوع: ${data['sessionType'] ?? 'غير محدد'}', style: TextStyle(color: textColor)),
                  Text('الوقت: ${_getDurationText(startTimestamp)}', style: TextStyle(color: textColor)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'التكلفة النهائية (ج.م)',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.5))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    dropdownColor: isDarkMode ? const Color(0xFF333333) : Colors.white,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'طريقة الدفع',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.5))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                    ),
                    items: ['كاش', 'فيزا'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(color: textColor)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => paymentMethod = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('devices').doc(doc.id).update({
                      'isOccupied': false,
                      'startTime': null,
                      'sessionType': null,
                      'activePrice': 0.0,
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('إغلاق وحفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.jpg',
                height: 35,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_esports),
              ),
              const SizedBox(width: 8),
              const Text('Manga PS'),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => isDarkMode = !isDarkMode),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('devices').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد أجهزة مضافة في قاعدة البيانات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final bool isOccupied = data['isOccupied'] ?? false;
                final Timestamp? startTimestamp = data['startTime'] as Timestamp?;
                final double activePrice = (data['activePrice'] ?? 0.0).toDouble();
                final double singlePrice = (data['singlePrice'] ?? 30.0).toDouble();
                final double multiPrice = (data['multiPrice'] ?? 40.0).toDouble();

                final currentCost = _calculateCost(startTimestamp, activePrice);

                return Card(
                  elevation: 6,
                  color: isDarkMode ? const Color(0xCC1E1E2C) : Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['name'] ?? 'جهاز',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        if (isOccupied) ...[
                          Text(
                            'النوع: ${data['sessionType'] ?? 'سنجل'}',
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _getDurationText(startTimestamp),
                            style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${currentCost.toStringAsFixed(2)} ج.م',
                            style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ] else ...[
                          const Icon(Icons.sports_esports, size: 45, color: Colors.grey),
                          Text('سنجل: $singlePrice | ملتي: $multiPrice', style: const TextStyle(fontSize: 11)),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOccupied ? Colors.red : Colors.green,
                            ),
                            onPressed: () {
                              if (isOccupied) {
                                _showEndSessionDialog(doc);
                              } else {
                                _showStartSessionDialog(doc.id, data['name'] ?? '', singlePrice, multiPrice);
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
            );
          },
        ),
      ),
    );
  }
}
 
