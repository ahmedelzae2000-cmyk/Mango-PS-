import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // طلب صلاحيات الإشعارات
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // الاشتراك في موضوع عام لتصل الإشعارات للجميع (صاحب المحل والموظفين)
    await _fcm.subscribeToTopic('manga_ps_updates');

    // الاستماع للإشعارات أثناء فتح التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("إشعار جديد: ${message.notification?.title} - ${message.notification?.body}");
    });
  }
}
