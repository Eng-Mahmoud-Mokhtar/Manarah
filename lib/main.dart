import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:device_preview/device_preview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Features/Splash/presentation/view_model/views/SplashScreen.dart';
import 'Features/Home/presentation/view_model/views/widgets/BottomBar.dart';
import 'Features/Home/presentation/view_model/date_cubit.dart';
import 'Features/Prayer/presentation/view_model/prayer_cubit.dart';
import 'Features/Home/presentation/view_model/views/widgets/notificationMessages.dart';

// =========================
// Global instances
// =========================
final sl = GetIt.instance;
final FlutterLocalNotificationsPlugin globalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// =========================
// Service Locator
// =========================
void setupServiceLocator() {
  sl.registerLazySingleton<Dio>(() => Dio());
}

// =========================
// WorkManager callback
// =========================
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("🔵 [WORKMANAGER] بدء تنفيذ المهمة: $task");

    if (task == "quarter_hourly_task") {
      try {
        final prefs = await SharedPreferences.getInstance();
        final notificationsEnabled =
            prefs.getBool('notifications_enabled') ?? true;

        if (notificationsEnabled) {
          final randomAyah =
          notificationMessages[Random().nextInt(notificationMessages.length)];

          const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'quarter_hourly_channel',
            'تذكير بالقرآن الكريم',
            channelDescription: 'قناة لإرسال آيات مختارة من القرآن الكريم',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

          const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

          await globalNotificationsPlugin.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            '', // بدون عنوان
            randomAyah,
            platformDetails,
          );

          print("✅ [WORKMANAGER] تم إرسال إشعار قرآن من الخلفية");
        }

        return true;
      } catch (e) {
        print("❌ [WORKMANAGER] خطأ في إرسال الإشعار: $e");
        return false;
      }
    }

    return true;
  });
}

// =========================
// Initialize Notifications
// =========================
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
  InitializationSettings(android: androidInit);

  await globalNotificationsPlugin.initialize(initSettings);

  // إنشاء قناة الإشعارات
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'quarter_hourly_channel',
    'تذكير بالقرآن الكريم',
    description: 'قناة لإرسال آيات مختارة من القرآن الكريم',
    importance: Importance.high,
  );

  await globalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// =========================
// Main
// =========================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  tz.initializeTimeZones();
  await initializeDateFormatting('ar', null);
  setupServiceLocator();

  // طلب صلاحيات
  if (Platform.isAndroid) {
    await Permission.ignoreBatteryOptimizations.request();
    await Permission.notification.request();
  }

  await initializeNotifications();

  final prefs = await SharedPreferences.getInstance();
  final int? lastPage = prefs.getInt('last_page');

  // =========================
  // تهيئة WorkManager ومسح المهام القديمة
  // =========================
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // مسح أي مهام قديمة مسجلة
  await Workmanager().cancelAll();
  await prefs.setBool('task_registered', false);

  // تسجيل المهمة الدورية (ربع ساعة)
  await Workmanager().registerPeriodicTask(
    "quarter_hourly_task",
    "quarter_hourly_task",
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 10),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresCharging: false,
      requiresDeviceIdle: false,
    ),
  );
  await prefs.setBool('task_registered', true);

  // =========================
  // تشغيل التطبيق
  // =========================
  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MyApp(lastPage: lastPage),
    ),
  );
}

// =========================
// MyApp
// =========================
class MyApp extends StatelessWidget {
  final int? lastPage;
  const MyApp({super.key, this.lastPage});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DateCubit()),
        BlocProvider(create: (_) => BottomNavCubit(initialIndex: lastPage ?? 0)),
        BlocProvider(create: (_) => PrayerCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: (context, child) => DevicePreview.appBuilder(
          context,
          Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        theme: ThemeData(fontFamily: 'Almarai'),
        home: lastPage == null ? const SplashScreen() : const BottomBar(),
      ),
    );
  }
}
