import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:intl/date_symbol_data_local.dart';
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

final sl = GetIt.instance;
final FlutterLocalNotificationsPlugin globalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void setupServiceLocator() {
  sl.registerLazySingleton<Dio>(() => Dio());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "quarter_hourly_task") {
      try {
        final prefs = await SharedPreferences.getInstance();
        final notificationsEnabled =
            prefs.getBool('notifications_enabled') ?? true;

        if (notificationsEnabled) {
          final randomAyah =
          notificationMessages[Random().nextInt(
            notificationMessages.length,
          )];

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

          const NotificationDetails platformDetails = NotificationDetails(
            android: androidDetails,
          );

          await globalNotificationsPlugin.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            '',
            randomAyah,
            platformDetails,
          );
        }
        return true;
      } catch (e) {
        return false;
      }
    }

    if (task == "daily_prayer_reset_task") {
      try {
        final prefs = await SharedPreferences.getInstance();
        final prayers = ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"];
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterStr = yesterday.toString().split(" ")[0];
        for (var prayer in prayers) {
          bool done = prefs.getBool("$yesterStr-$prayer") ?? false;
          if (!done) {}
        }

        final todayStr = DateTime.now().toString().split(" ")[0];
        for (var prayer in prayers) {
          await prefs.setBool("$todayStr-$prayer", false);
        }

        return true;
      } catch (e) {
        return false;
      }
    }

    return true;
  });
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await globalNotificationsPlugin.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'quarter_hourly_channel',
    'تذكير بالقرآن الكريم',
    description: 'قناة لإرسال آيات مختارة من القرآن الكريم',
    importance: Importance.high,
  );

  await globalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
  >()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  tz.initializeTimeZones();
  await initializeDateFormatting('ar', null);
  setupServiceLocator();
  if (Platform.isAndroid) {
    await Permission.ignoreBatteryOptimizations.request();
    await Permission.notification.request();
  }

  await initializeNotifications();

  final prefs = await SharedPreferences.getInstance();
  final int? lastPage = prefs.getInt('last_page');

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  await Workmanager().cancelAll();

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

  await Workmanager().registerPeriodicTask(
    "daily_prayer_reset_task",
    "daily_prayer_reset_task",
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(seconds: 30),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresCharging: false,
      requiresDeviceIdle: false,
    ),
  );

  runApp(MyApp(lastPage: lastPage));
}

class MyApp extends StatelessWidget {
  final int? lastPage;
  const MyApp({super.key, this.lastPage});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DateCubit()),
        BlocProvider(
          create: (_) => BottomNavCubit(initialIndex: lastPage ?? 0),
        ),
        BlocProvider(create: (_) => PrayerCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true,
        builder:
            (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        theme: ThemeData(fontFamily: 'Almarai'),
        home: lastPage == null ? const SplashScreen() : const BottomBar(),
      ),
    );
  }
}