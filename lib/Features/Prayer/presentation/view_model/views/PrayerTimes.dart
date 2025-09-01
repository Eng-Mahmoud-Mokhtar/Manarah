import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../Core/Const/Colors.dart';
import '../../../../../Core/Const/permission.dart';
import '../../../../Home/presentation/view_model/views/Home.dart';
import '../../../../Prayer/presentation/view_model/prayer_cubit.dart';
import '../../../../Prayer/presentation/view_model/prayer_state.dart';
import 'widgets/NextPrayerCountdownWithImage.dart';
import 'widgets/PrayerTimesList.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  SharedPreferences? _prefs;
  bool _permissionsGranted = false;
  bool _prayersScheduledToday = false;
  File? _adhanFile;
  Timer? _foregroundTimer;

  static const String _adhanChannelId = 'adhan_channel';
  static const String _adhanChannelName = 'Adhan';
  static const String _reminderChannelId = 'reminders_channel';
  static const String _reminderChannelName = 'Reminders';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSharedPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEverything();
    });
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedPrayerTimes();
  }

  Future<void> _initializeEverything() async {
    try {
      await AndroidAlarmManager.initialize();
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_getSafeTimeZoneName()));

      _permissionsGranted = await PermissionManager.requestPermissions();
      if (!_permissionsGranted) {
        print('⚠️ Permissions not granted. Notifications and alarms will not work.');
        return;
      }

      await _initializeNotifications();
      await _getAdhanFile(); // تحميل ملف الأذان
      _fetchNewPrayerTimes();
    } catch (e) {
      print('[INIT] error: $e');
    }
  }

  String _getSafeTimeZoneName() {
    final systemTz = DateTime.now().timeZoneName;
    const map = {
      'EET': 'Africa/Cairo',
      'UTC': 'UTC',
      'GMT': 'Etc/GMT',
      'PST': 'America/Los_Angeles',
      'EST': 'America/New_York',
    };
    return map[systemTz] ?? 'UTC';
  }

  Future<void> _initializeNotifications() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        _reminderChannelName,
        description: 'Reminders before prayer time',
        importance: Importance.high,
        playSound: false,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _adhanChannelId,
        _adhanChannelName,
        description: 'Azan playback at prayer time',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('mqa'),
      ),
    );

    print('[NOTIF] Notification channels created successfully');
  }

  Future<File?> _getAdhanFile() async {
    if (_adhanFile != null && await _adhanFile!.exists()) return _adhanFile;
    try {
      final byteData = await rootBundle.load('Assets/mqa.mp3');
      final file = File('${(await getTemporaryDirectory()).path}/mqa.mp3');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      _adhanFile = file;
      print('[AUDIO] Adhan file ready at ${file.path}');
      return file;
    } catch (e) {
      print('[AUDIO] Error loading adhan file: $e');
      return null;
    }
  }

  Future<void> _loadCachedPrayerTimes() async {
    if (_prefs == null) return;
    final cachedData = _prefs!.getString('prayer_times_data');
    final cachedDate = _prefs!.getString('prayer_times_date');
    if (cachedData != null && cachedDate != null) {
      final cachedDateTime = DateTime.tryParse(cachedDate);
      final now = DateTime.now();
      if (cachedDateTime != null &&
          cachedDateTime.year == now.year &&
          cachedDateTime.month == now.month &&
          cachedDateTime.day == now.day) {
        final Map<String, dynamic> data = json.decode(cachedData);
        final Map<String, String> prayerTimes = Map<String, String>.from(data['prayerTimes']);
        final String city = data['city'];
        final String country = data['country'];
        if (mounted) {
          context.read<PrayerCubit>().setCachedData(prayerTimes, city, country);
        }
        await _scheduleAllPrayers(prayerTimes);
        _startForegroundTimer(prayerTimes);
        _printStoredPrayerTimes();
      }
    }
  }

  Future<void> _fetchNewPrayerTimes() async {
    try {
      await context.read<PrayerCubit>().getPrayerTimes();
    } catch (e) {
      print('[API] error: $e');
      final cachedData = _prefs?.getString('prayer_times_data');
      if (cachedData == null && mounted) {
        context.read<PrayerCubit>().setErrorState("لا يوجد اتصال بالإنترنت");
      }
    }
  }

  Future<void> _cachePrayerTimes(Map<String, String> prayerTimes, String city, String country) async {
    if (_prefs == null) return;
    final data = {'prayerTimes': prayerTimes, 'city': city, 'country': country};
    await _prefs!.setString('prayer_times_data', json.encode(data));
    await _prefs!.setString('prayer_times_date', DateTime.now().toString());
    _printStoredPrayerTimes();
    _startForegroundTimer(prayerTimes); // Timer للتشغيل في الفورغراوند
  }

  void _startForegroundTimer(Map<String, String> prayerTimes) {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final now = TimeOfDay.now();
      final arabicNames = {
        'Fajr': 'الفجر',
        'Dhuhr': 'الظهر',
        'Asr': 'العصر',
        'Maghrib': 'المغرب',
        'Isha': 'العشاء',
      };
      for (var entry in prayerTimes.entries) {
        if (!arabicNames.containsKey(entry.key)) continue;
        final parts = entry.value.split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        if (now.hour == hour && now.minute == minute) {
          // إشعار فورغراوند
          await _notifications.show(
            entry.key.hashCode,
            'أذان ${arabicNames[entry.key]}',
            'حان الآن موعد ${arabicNames[entry.key]}',
            NotificationDetails(
              android: AndroidNotificationDetails(
                _adhanChannelId,
                _adhanChannelName,
                importance: Importance.max,
                playSound: true,
                sound: const RawResourceAndroidNotificationSound('mqa'),
                icon: '@mipmap/ic_launcher',
                color: KprimaryColor,
              ),
            ),
          );
          // تشغيل الصوت
          if (_adhanFile != null) {
            await _audioPlayer.play(DeviceFileSource(_adhanFile!.path));
          }
        }
      }
    });
  }

  Future<void> _printStoredPrayerTimes() async {
    if (_prefs == null) return; // حماية من null
    final data = _prefs!.getString('prayer_times_data');
    final date = _prefs!.getString('prayer_times_date');
    if (data != null && date != null) {
      final decoded = json.decode(data);
      print('🗓 آخر تحديث: $date');
      print('🌍 المدينة: ${decoded['city']}, الدولة: ${decoded['country']}');
      print('🕰 أوقات الصلاة:');
      final prayers = Map<String, String>.from(decoded['prayerTimes']);
      prayers.forEach((key, value) {
        print('   $key: $value');
      });
    } else {
      print('لا توجد بيانات مخزنة حالياً.');
    }
  }

  Future<void> _scheduleAllPrayers(Map<String, String> prayerTimes) async {
    if (!_permissionsGranted) {
      print('⏰ [SCHED] Permissions not granted, skipping scheduling');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastScheduledDate = _prefs?.getString('last_scheduled_date');
    if (lastScheduledDate == today.toString() && _prayersScheduledToday) {
      print('⏰ [SCHED] Already scheduled prayers for today');
      return;
    }

    final arabicNames = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    try {
      for (var entry in prayerTimes.entries) {
        if (!arabicNames.containsKey(entry.key)) continue;
        final parts = entry.value.split(':');
        if (parts.length < 2) continue;
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final tzPrayerTime = tz.TZDateTime(tz.local, today.year, today.month, today.day, hour, minute);
        if (tzPrayerTime.isBefore(tz.TZDateTime.now(tz.local))) continue;
        final tzBefore5Min = tzPrayerTime.subtract(const Duration(minutes: 5));

        // إشعار قبل الصلاة
        await _notifications.zonedSchedule(
          entry.key.hashCode + 10000,
          'تذكير قبل صلاة ${arabicNames[entry.key]}',
          'باقٍ 5 دقائق على ${arabicNames[entry.key]}',
          tzBefore5Min,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _reminderChannelId,
              _reminderChannelName,
              importance: Importance.high,
              icon: '@mipmap/ic_launcher',
              color: KprimaryColor,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );

        // إشعار الأذان
        await _notifications.zonedSchedule(
          entry.key.hashCode + 20000,
          'أذان ${arabicNames[entry.key]}',
          'حان الآن موعد ${arabicNames[entry.key]}',
          tzPrayerTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _adhanChannelId,
              _adhanChannelName,
              importance: Importance.max,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound('mqa'),
              icon: '@mipmap/ic_launcher',
              color: KprimaryColor,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );

        // تشغيل الأذان بالـ AlarmManager (لـ background)
        await AndroidAlarmManager.oneShotAt(
          tzPrayerTime,
          entry.key.hashCode + 50000,
          _playAdhanCallback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
          rescheduleOnReboot: true,
        );
      }

      _prayersScheduledToday = true;
      await _prefs?.setString('last_scheduled_date', today.toString());
      await _scheduleDailyUpdate();
      print('✅ [SCHED] All prayers scheduled successfully');
    } catch (e) {
      print('❌ [SCHED] Error scheduling prayers: $e');
    }
  }

  Future<void> _scheduleDailyUpdate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 5);
    await AndroidAlarmManager.oneShotAt(
      tomorrow,
      99999,
      _updatePrayerTimesCallbackStatic,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _updatePrayerTimesCallbackStatic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('prayer_times_data');
    await prefs.remove('prayer_times_date');
    await prefs.remove('last_scheduled_date');
    print('🗑 [UPDATE] Cleared cached prayer times');
  }

  @pragma('vm:entry-point')
  static Future<void> _playAdhanCallback() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mqa.mp3'); // **الباث كما هو**
      if (await file.exists()) {
        final player = AudioPlayer();
        await player.play(DeviceFileSource(file.path));
        await player.setReleaseMode(ReleaseMode.stop);
      } else {
        print('❌ [AUDIO] Adhan file not found at ${file.path}');
      }
    } catch (e) {
      print('❌ [AUDIO] Error playing adhan: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _foregroundTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_prayersScheduledToday && _prefs != null) {
        final cachedData = _prefs!.getString('prayer_times_data');
        if (cachedData != null) {
          final prayerTimes = Map<String, String>.from(json.decode(cachedData)['prayerTimes']);
          _scheduleAllPrayers(prayerTimes);
          _startForegroundTimer(prayerTimes); // تفعيل الفورغراوند فورًا
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final fontBig = width * 0.04;
    final fontNormal = width * 0.025;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('Assets/Login.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: KprimaryColor,
              elevation: 0,
              leading: IconButton(
                onPressed: () {
                  context.read<BottomNavCubit>().setIndex(0);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: width * 0.05,
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أوقات الصلاة',
                    style: TextStyle(
                      fontSize: fontBig,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 5),
                        Icon(
                          Icons.location_on,
                          color: Colors.orangeAccent,
                          size: width * 0.04,
                        ),
                        Text(
                          context.watch<PrayerCubit>().state is PrayerLoaded
                              ? '${(context.watch<PrayerCubit>().state as PrayerLoaded).city}, ${(context.watch<PrayerCubit>().state as PrayerLoaded).country}'
                              : 'تحميل..',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontNormal,
                            fontFamily: 'AmiriQuran-Regular',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              centerTitle: false,
            ),
            Expanded(
              child: BlocConsumer<PrayerCubit, PrayerState>(
                listener: (context, state) async {
                  if (state is PrayerLoaded) {
                    await _cachePrayerTimes(
                      state.prayerTimes,
                      state.city,
                      state.country,
                    );
                    await _scheduleAllPrayers(state.prayerTimes);
                  }
                },
                builder: (context, state) {
                  if (state is PrayerLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: KprimaryColor),
                    );
                  } else if (state is PrayerError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 50, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: fontBig,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'يتم استخدام آخر بيانات مخزنة',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: fontNormal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else if (state is PrayerLoaded) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: width * 0.04),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                            child: NextPrayerCountdownWithImage(
                              prayerTimes: state.prayerTimes,
                              fontBig: fontBig,
                              fontNormal: fontNormal,
                              height: height * 0.3,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.01),
                            child: PrayerTimesList(
                              context,
                              state,
                              fontBig,
                              width,
                              height,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: KprimaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تهيئة التطبيق...',
                            style: TextStyle(fontSize: fontBig),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
