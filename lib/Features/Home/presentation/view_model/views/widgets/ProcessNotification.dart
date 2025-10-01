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
    if (task == "quarter_hourly_task") {
      try {
        WidgetsFlutterBinding.ensureInitialized();

        const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
        await globalNotificationsPlugin.initialize(initializationSettings);

        final prefs = await SharedPreferences.getInstance();
        final notificationsEnabled =
            prefs.getBool('notifications_enabled') ?? true;
        if (notificationsEnabled) {
          final randomMessage =
          notificationMessages[Random().nextInt(notificationMessages.length)];
          final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'quarter_hourly_channel',
            '',
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
        } else {
          print("الإشعارات معطلة، لم يتم إرسال أي إشعار");
        }
        return Future.value(true);
      } catch (e) {
        print(" خطأ في إرسال الإشعار$e");
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

@pragma('vm:entry-point')
void alarmManagerCallback() {
  Future.microtask(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
      await globalNotificationsPlugin.initialize(initializationSettings);

      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      if (notificationsEnabled) {
        final randomMessage =
        notificationMessages[Random().nextInt(notificationMessages.length)];
        AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'quarter_hourly_channel',
          '',
          channelDescription: 'تذكير بآيات من القرآن الكريم',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          timeoutAfter: 60000,
          styleInformation: BigTextStyleInformation(
            randomMessage,
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
      } else {
        print(" الإشعارات معطلة، لم يتم إرسال أي إشعار");
      }
    } catch (e) {
      print("خطأ في إرسال الإشعار$e");
    }
  });
}
