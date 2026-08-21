class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('إدارة الأجهزة (Manga PS)'),
        elevation: 0,
      ),
      body: provider.devices.isEmpty
          ? const Center(child: Text('لا يوجد أجهزة، قم بإضافة جهاز جديد.'))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // عرض جهازين في كل صف (مربعات بجانب بعضها)
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85, // تحكم في طول وعرض المربع
              ),
              itemCount: provider.devices.length,
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return DeviceGridCard(device: device);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showAddDeviceDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    // (نفس دالة إضافة الجهاز القديمة بدون تغيير)
    final nameController = TextEditingController();
    final sPriceController = TextEditingController(text: '30');
    final mPriceController = TextEditingController(text: '40');
    String deviceType = 'PS4';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جهاز'),
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
              TextField(controller: sPriceController, decoration: const InputDecoration(labelText: 'سعر السنجل'), keyboardType: TextInputType.number),
              TextField(controller: mPriceController, decoration: const InputDecoration(labelText: 'سعر الملتي'), keyboardType: TextInputType.number),
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

// --- تصميم الكارت المربع الصغير للأجهزة ---
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
      if (widget.device.isOccupied) {
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    double activePrice = device.mode == 'single' ? device.singlePrice : device.multiPrice;
    Duration elapsed = Duration.zero;
    double currentCost = 0.0;

    if (device.isOccupied && device.startTime != null) {
      elapsed = DateTime.now().difference(device.startTime!.toDate());
      currentCost = (elapsed.inSeconds / 3600.0) * activePrice;
    }

    String formattedTime = '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        // لو الجهاز متاح، اضغط لبدء الجلسة، لو مشغول اضغط لإنهاء أو إدارة
        if (!device.isOccupied) {
          _showStartDialog(context, device);
        } else {
          _showFinishDialog(context, device, currentCost);
        }
      },
      child: Card(
        elevation: 4,
        color: isDark ? Colors.grey.shade900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: device.isOccupied ? Colors.red.shade400 : Colors.green.shade400,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: device.type == 'PS5' ? Colors.black : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(device.type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    device.isOccupied ? (device.mode == 'single' ? 'سنجل' : 'ملتي') : 'متاح',
                    style: TextStyle(
                      color: device.isOccupied ? Colors.red.shade400 : Colors.green.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                device.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              if (device.isOccupied) ...[
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 2),
                Text(
                  '${currentCost.toStringAsFixed(1)} ج.م',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ] else ...[
                const Text(
                  'انقر للبدء',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _showStartDialog(BuildContext context, DeviceModel device) {
    String mode = 'single';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('بدء جلسة ${device.name}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(title: const Text('سنجل'), value: 'single', groupValue: mode, onChanged: (v) => setState(() => mode = v!)),
              RadioListTile(title: const Text('ملتي'), value: 'multi', groupValue: mode, onChanged: (v) => setState(() => mode = v!)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Provider.of<DeviceProvider>(context, listen: false).startSession(device.id, mode);
              Navigator.pop(ctx);
            },
            child: const Text('بدء'),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, DeviceModel device, double calculatedCost) {
    final costController = TextEditingController(text: calculatedCost.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('إنهاء حساب ${device.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ الإجمالي (ج.م)'),
              ),
              const SizedBox(height: 15),
              DropdownButton<String>(
                value: paymentMethod,
                isExpanded: true,
                items: ['كاش', 'فيزا'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => paymentMethod = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // زر للتحويل السريع بين سنجل و ملتي أثناء التشغيل
                Provider.of<DeviceProvider>(context, listen: false).toggleMode(device.id, device.mode);
                Navigator.pop(ctx);
              },
              child: Text(device.mode == 'single' ? 'تحويل لملتي' : 'تحويل لسنجل'),
            ),
            ElevatedButton(
              onPressed: () async {
                double finalAmount = double.tryParse(costController.text) ?? calculatedCost;
                await Provider.of<DeviceProvider>(context, listen: false)
                    .stopSession(device.id, device.name, paymentMethod, finalAmount);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('إنهاء ودفع'),
            ),
          ],
        ),
      ),
    );
  }
}
 
