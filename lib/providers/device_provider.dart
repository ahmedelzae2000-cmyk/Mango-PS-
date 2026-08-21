  Future<void> stopSession(String deviceId, String paymentMethod, double finalCost) async {
    final batch = _db.batch();

    // 1. تحديث حالة الجهاز ليكون متاحاً
    final deviceRef = _db.collection('devices').doc(deviceId);
    batch.update(deviceRef, {
      'isOccupied': false,
      'startTime': null,
      'mode': 'single',
    });

    // 2. البحث عن الوردية النشطة حالياً
    final activeShiftQuery = await _db.collection('shifts')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    
    if (activeShiftQuery.docs.isNotEmpty) {
      final shiftDoc = activeShiftQuery.docs.first;
      final shiftRef = shiftDoc.reference;
      
      // الحصول على القيم الحالية أو البدء من صفر
      final data = shiftDoc.data();
      double currentTotal = (data['totalRevenue'] ?? 0.0).toDouble();
      double currentCash = (data['cashRevenue'] ?? 0.0).toDouble();
      double currentVisa = (data['visaRevenue'] ?? 0.0).toDouble();

      // إضافة المبلغ الجديد
      currentTotal += finalCost;
      if (paymentMethod == 'كاش') {
        currentCash += finalCost;
      } else {
        currentVisa += finalCost;
      }

      // تحديث الوردية
      batch.update(shiftRef, {
        'totalRevenue': currentTotal,
        'cashRevenue': currentCash,
        'visaRevenue': currentVisa,
      });
    }

    // تنفيذ التحديثات معاً
    await batch.commit();
    notifyListeners();
  }
