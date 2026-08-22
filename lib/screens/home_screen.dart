class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    final bool isManager = provider.userRole == 'مدير';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Manga PS 🎮',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: provider.devices.isEmpty
          ? const Center(
              child: Text(
                'لا يوجد أجهزة مضافة حالياً',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78, // نسبة طول الكارت لتناسب التصميم الاحترافي
              ),
              itemCount: provider.devices.length,
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return DeviceGridCard(device: device);
              },
            ),
      floatingActionButton: isManager
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddDeviceDialog(context),
            )
          : null,
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final sPriceController = TextEditingController(text: '30');
    final mPriceController = TextEditingController(text: '40');
    String deviceType = 'PS4';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جهاز جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الجهاز')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: deviceType,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: ['PS4', 'PS5'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => deviceType = v!,
              ),
              TextField(controller: sPriceController, decoration: const InputDecoration(labelText: 'سعر الفردي'), keyboardType: TextInputType.number),
              TextField(controller: mPriceController, decoration: const InputDecoration(labelText: 'سعر الزوجي'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              double s = double.tryParse(sPriceController.text) ?? 30.0;
              double m = double.tryParse(mPriceController.text) ?? 40.0;
              Provider.of<DeviceProvider>(context, listen: false)
                  .addDevice(nameController.text, deviceType, s, m);
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class DeviceGridCard extends StatefulWidget {
  final DeviceModel device;
  const DeviceGridCard({super.key, required this.device});

  @override
  State<DeviceGridCard> createState() => _DeviceGridCardState();
}

class _DeviceGridCardState extends State<DeviceGridCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.device.isOccupied && !widget.device.isPaused) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final provider = Provider.of<DeviceProvider>(context);
    final bool isManager = provider.userRole == 'مدير';
    
    double activePrice = device.mode == 'single' ? device.singlePrice : device.multiPrice;
    Duration elapsed = Duration.zero;
    double currentCost = 0.0;

    if (device.isOccupied && device.startTime != null) {
      DateTime now = DateTime.now();
      DateTime start = device.startTime!.toDate();
      
      int totalPausedSeconds = device.pausedDuration;
      if (device.isPaused && device.pauseStartTime != null) {
        totalPausedSeconds += now.difference(device.pauseStartTime!.toDate()).inSeconds;
      }

      int elapsedSeconds = now.difference(start).inSeconds - totalPausedSeconds;
      if (elapsedSeconds < 0) elapsedSeconds = 0;

      elapsed = Duration(seconds: elapsedSeconds);
      currentCost = (elapsedSeconds / 3600.0) * activePrice;
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String formattedTime = '${twoDigits(elapsed.inHours)}:${twoDigits(elapsed.inMinutes % 60)}:${twoDigits(elapsed.inSeconds % 60)}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF212121), // لون كرت داكن أنيق مطابق للصورة
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: device.isOccupied ? (device.isPaused ? Colors.orange : Colors.green) : Colors.transparent,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // السطر الأول: اسم الجهاز وأيقونة الحذف للمدير
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                device.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (isManager)
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('حذف الجهاز ${device.name}'),
                        content: const Text('هل أنت متأكد من حذف هذا الجهاز نهائياً؟'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              provider.deleteDevice(device.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                ),
            ],
          ),

          // نوع الجهاز (PS4 أو PS5) في المنتصف داخل إطار مخصص
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                device.type,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // العداد والمبلغ المالي
          Center(
            child: Column(
              children: [
                Text(
                  device.isOccupied ? formattedTime : '00:00:00',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: device.isOccupied 
                        ? (device.isPaused ? Colors.orangeAccent : Colors.greenAccent) 
                        : Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${currentCost.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),

          // أزرار التبديل (زوجي / فردي)
          Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => provider.toggleMode(device.id, 'multi'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: device.mode == 'multi' ? Colors.grey.shade800 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'زوجي',
                          style: TextStyle(
                            color: device.mode == 'multi' ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => provider.toggleMode(device.id, 'single'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: device.mode == 'single' ? Colors.grey.shade800 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'فردي',
                          style: TextStyle(
                            color: device.mode == 'single' ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // زر التشغيل أو الإيقاف الأخضر السفلي
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
              ),
              onPressed: () async {
                if (!device.isOccupied) {
                  bool success = await provider.startSession(device.id, device.mode);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا يمكن بدء الجلسة، يجب فتح وردية أولاً!')),
                    );
                  }
                } else {
                  _showFinishDialog(context, device, currentCost, provider);
                }
              },
              child: Text(
                device.isOccupied ? 'إيقاف / محاسبة' : 'تشغيل',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, DeviceModel device, double calculatedCost, DeviceProvider provider) {
    final costController = TextEditingController(text: calculatedCost.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('إنهاء جلسة: ${device.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الوقت المنقضي: ${costController.text.isNotEmpty ? "" : ""}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ النهائي (تعديل السعر ج.م)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              const Text('طريقة الدفع', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['كاش', 'فيزا'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => paymentMethod = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: device.isPaused ? Colors.green : Colors.orange,
              ),
              onPressed: () async {
                await provider.togglePauseSession(device.id, device.isPaused);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(device.isPaused ? 'استئناف' : 'إيقاف مؤقت'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                double parsedVal = double.tryParse(costController.text) ?? calculatedCost;
                await provider.stopSession(device.id, device.name, paymentMethod, parsedVal >= 0 ? parsedVal : calculatedCost);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ وتسجيل الفاتورة'),
            ),
          ],
        ),
      ),
    );
  }
}
 
