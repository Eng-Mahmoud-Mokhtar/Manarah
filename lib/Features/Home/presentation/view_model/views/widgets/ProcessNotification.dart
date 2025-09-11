import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'notificationMessages.dart';

final FlutterLocalNotificationsPlugin globalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("🔵 [WORKMANAGER] بدء تنفيذ المهمة: $task");

    if (task == "quarter_hourly_task") {
      try {
        print("🔵 [WORKMANAGER] تهيئة SharedPreferences والإشعارات");
        WidgetsFlutterBinding.ensureInitialized();

        const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        await globalNotificationsPlugin.initialize(initializationSettings);

        final prefs = await SharedPreferences.getInstance();
        final notificationsEnabled =
            prefs.getBool('notifications_enabled') ?? true;

        print("🔵 [WORKMANAGER] الإشعارات مفعلة: $notificationsEnabled");
        if (notificationsEnabled) {
          final randomMessage =
          notificationMessages[Random().nextInt(notificationMessages.length)];
          print(
            "🔵 [WORKMANAGER] تم اختيار آية عشوائية: ${randomMessage.substring(0, 30)}...",
          );

          final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'quarter_hourly_channel',
            '', // بدون عنوان
            channelDescription: 'تذكير بآيات من القرآن الكريم',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            timeoutAfter: 60000,
            styleInformation: BigTextStyleInformation(
              randomMessage, // 👈 خلي النص الكامل هنا
            ),
          );
           NotificationDetails platformDetails = NotificationDetails(
            android: androidDetails,
          );

          await globalNotificationsPlugin.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            '', // بدون عنوان
            randomMessage,
            platformDetails,

          );

          print("✅ [WORKMANAGER] تم إرسال إشعار ربع ساعي من الخلفية بنجاح");
        } else {
          print("🔴 [WORKMANAGER] الإشعارات معطلة، لم يتم إرسال أي إشعار");
        }
        return Future.value(true);
      } catch (e) {
        print("❌ [WORKMANAGER] خطأ في إرسال الإشعار: $e");
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

@pragma('vm:entry-point')
void alarmManagerCallback() {
  print("🔵 [ALARM_MANAGER] بدء تنفيذ المهمة الدورية");

  Future.microtask(() async {
    try {
      print("🔵 [ALARM_MANAGER] تهيئة SharedPreferences والإشعارات");
      WidgetsFlutterBinding.ensureInitialized();

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
      await globalNotificationsPlugin.initialize(initializationSettings);

      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;

      print("🔵 [ALARM_MANAGER] الإشعارات مفعلة: $notificationsEnabled");

      if (notificationsEnabled) {
        final randomMessage =
        notificationMessages[Random().nextInt(notificationMessages.length)];
        print(
          "🔵 [ALARM_MANAGER] تم اختيار آية عشوائية: ${randomMessage.substring(0, 30)}...",
        );

        AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'quarter_hourly_channel',
          '', // بدون عنوان
          channelDescription: 'تذكير بآيات من القرآن الكريم',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          timeoutAfter: 60000,
          styleInformation: BigTextStyleInformation(
            randomMessage, // 👈 خلي النص الكامل هنا
          ),
        );

        NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
        );

        await globalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          '', // بدون عنوان
          randomMessage,
          platformDetails,
        );
        print("✅ [ALARM_MANAGER] تم إرسال إشعار ربع ساعي من الخلفية بنجاح");
      } else {
        print("🔴 [ALARM_MANAGER] الإشعارات معطلة، لم يتم إرسال أي إشعار");
      }
    } catch (e) {
      print("❌ [ALARM_MANAGER] خطأ في إرسال الإشعار: $e");
    }
  });
}
