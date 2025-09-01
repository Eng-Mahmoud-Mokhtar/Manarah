import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:device_preview/device_preview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Features/Splash/presentation/view_model/views/SplashScreen.dart';
import 'Features/Home/presentation/view_model/views/Home.dart';
import 'Features/Home/presentation/view_model/date_cubit.dart';
import 'Features/Prayer/presentation/view_model/prayer_cubit.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<Dio>(() => Dio());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  if (Platform.isAndroid) {
    await Permission.ignoreBatteryOptimizations.request();
    await Permission.notification.request();
  }

  await initializeDateFormatting('ar', null);
  setupServiceLocator();

  // استرجاع آخر صفحة
  final prefs = await SharedPreferences.getInstance();
  final int? lastPage = prefs.getInt('last_page');

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MyApp(lastPage: lastPage),
    ),
  );
}

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
        home:
          lastPage == null ? const SplashScreen() : const HomeScreen(),
      ),
    );
  }
}
