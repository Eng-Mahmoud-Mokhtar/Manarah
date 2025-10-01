import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../../Core/Const/Colors.dart';
import '../../../../Home/presentation/view_model/views/widgets/BottomBar.dart';
import '../../../../Prayer/presentation/view_model/prayer_cubit.dart';
import '../../../../Prayer/presentation/view_model/prayer_state.dart';
import 'widgets/NextPrayerCountdownWithImage.dart';
import 'widgets/PrayerTimesList.dart';

/// TaskHandler للأذان في الخلفية
class AdhanTaskHandler extends TaskHandler {
  static String? adhanFilePath;
  late final AudioPlayer _player;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (adhanFilePath == null) return;
    _player = AudioPlayer();
    try {
      await _player.setFilePath(adhanFilePath!);
      await _player.play();

      _player.playerStateStream.listen((state) async {
        if (state.processingState == ProcessingState.completed) {
          print('[INFO] الأذان خلص وتم تشغيل الخدمة بنجاح');
        }
      });

      print('[INFO] الأذان الخلفية شغال');
    } catch (e) {
      print('[ERROR] تشغيل الأذان في الخلفية: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _player.stop();
    await _player.dispose();
    Future.delayed(const Duration(seconds: 5), () {
      FlutterForegroundTask.startService(
        notificationTitle: 'خدمة الأذان تعمل الآن',
        notificationText: 'مراقبة أوقات الصلاة',
        callback: () {
          FlutterForegroundTask.setTaskHandler(AdhanTaskHandler());
        },
      );
      print('[INFO] إعادة تشغيل خدمة الأذان تلقائي بعد الإغلاق');
    });
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
const Map<String, String> prayerNamesArabic = {
  'Fajr': 'الفجر',
  'Sunrise': 'الشروق',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

@pragma('vm:entry-point')
Future<void> sendNotificationCallback(int id, Map<String, dynamic> params) async {
  String prayer = params['prayer'] ?? 'غير معروف';
  String prayerArabic = prayerNamesArabic[prayer] ?? prayer;

  try {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'Adhan Notifications',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      ticker: 'وقت الصلاة',
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id,
      'صلاة $prayerArabic',
      'الأذان بعد قليل، استعد للصلاة',
      notificationDetails,
    );
    print('[NOTIFICATION] تم إرسال إشعار لصلاة $prayerArabic');
  } catch (e) {
    print('[ERROR] فشل إرسال الإشعار: $e');
  }
}


@pragma('vm:entry-point')
Future<void> adhanAlarmCallback(int id, Map<String, dynamic> params) async {
  String prayer = params['prayer'] ?? 'غير معروف';
  final player = AudioPlayer();
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/azan.mp3');
    if (!await file.exists()) {
      final byteData = await rootBundle.load('Assets/audio/azan.mp3');
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }

    await player.setFilePath(file.path);
    await player.play();
    print('[ADHAN] تم تشغيل الأذان لصلاة $prayer');
  } catch (e) {
    print('[ERROR] فشل تشغيل الأذان: $e');
  } finally {
    await player.dispose();
  }
}

/// PrayerTimes Widget
class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});
  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  SharedPreferences? _prefs;
  Timer? _prayerTimer;
  static String? adhanFilePathForeground;
  static AudioPlayer? _foregroundPlayer;
  Map<String, bool> _adhanEnabled = {
    'Fajr': true,
    'Sunrise': true,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
  };

  Map<String, bool> _adhanPlayedToday = {
    'Fajr': false,
    'Sunrise': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  static const Map<String, int> _prayerIds = {
    'Fajr': 0,
    'Sunrise': 1,
    'Dhuhr': 2,
    'Asr': 3,
    'Maghrib': 4,
    'Isha': 5,
  };

  @override
  void initState() {
    super.initState();
    _initAll();

    // تشغيل الخدمة الدائمة
    FlutterForegroundTask.startService(
      notificationTitle: 'خدمة الأذان تعمل الآن',
      notificationText: 'مراقبة أوقات الصلاة',
      callback: startCallback,
    );
  }

  @pragma('vm:entry-point')
  void startCallback() {
    FlutterForegroundTask.setTaskHandler(AdhanTaskHandler());
  }

  Future<void> _initAll() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadAdhanSettings();
      await _prepareAdhanFile();
      await _loadCachedPrayerTimes();
      await _fetchNewPrayerTimes();
      _startPrayerChecker();
      _startDailyResetTimer();
      await AndroidAlarmManager.initialize();
    } catch (e) {
      print('[ERROR] فشل تهيئة أوقات الصلاة: $e');
    }
  }

  Future<void> _loadAdhanSettings() async {
    try {
      final settings = _prefs?.getString('adhan_settings');
      if (settings != null) {
        final Map<String, dynamic> data = json.decode(settings);
        setState(() {
          _adhanEnabled = Map<String, bool>.from(data);
        });
      }
    } catch (e) {
      print('[ERROR] فشل تحميل إعدادات الأذان: $e');
    }
  }

  Future<void> _saveAdhanSettings() async {
    try {
      await _prefs?.setString('adhan_settings', json.encode(_adhanEnabled));
    } catch (e) {
      print('[ERROR] فشل حفظ إعدادات الأذان: $e');
    }
  }

  void _toggleAdhanForPrayer(String prayer) {
    setState(() {
      _adhanEnabled[prayer] = !_adhanEnabled[prayer]!;
    });
    _saveAdhanSettings();

    if (!_adhanEnabled[prayer]!) {
      _cancelScheduledPrayer(prayer);
    } else {
      final state = context.read<PrayerCubit>().state;
      if (state is PrayerLoaded) {
        _scheduleSinglePrayer(prayer, state.prayerTimes[prayer]!);
      }
    }
  }

  Future<void> _cancelScheduledPrayer(String prayer) async {
    try {
      if (_prayerIds.containsKey(prayer)) {
        int prayerId = _prayerIds[prayer]!;
        int notificationId = prayerId + 100;
        await AndroidAlarmManager.cancel(prayerId);
        await AndroidAlarmManager.cancel(notificationId);
        print('[CANCELLED] تم إلغاء منبه وإشعار الأذان لصلاة $prayer');
      }
    } catch (e) {
      print('[ERROR] فشل إلغاء منبه الأذان أو الإشعار: $e');
    }
  }

  Future<void> _scheduleSinglePrayer(String prayer, String time) async {
    try {
      if (!_prayerIds.containsKey(prayer)) return;

      final now = DateTime.now();
      final parts = time.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return;

      DateTime prayerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (prayerDateTime.isBefore(now)) {
        prayerDateTime = prayerDateTime.add(const Duration(days: 1));
      }

      // وقت الإشعار (قبل الصلاة بخمس دقائق)
      DateTime notificationTime = prayerDateTime.subtract(const Duration(minutes: 3));

      int prayerId = _prayerIds[prayer]!;
      int notificationId = prayerId + 100; // معرف مختلف للإشعار

      // إلغاء أي إشعارات أو أذانات مجدولة سابقًا
      await AndroidAlarmManager.cancel(prayerId);
      await AndroidAlarmManager.cancel(notificationId);

      // جدولة الإشعار قبل خمس دقائق
      await AndroidAlarmManager.oneShotAt(
        notificationTime,
        notificationId,
        sendNotificationCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {'prayer': prayer},
      );

      // جدولة الأذان في وقت الصلاة
      await AndroidAlarmManager.oneShotAt(
        prayerDateTime,
        prayerId,
        adhanAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        params: {'prayer': prayer},
      );

      print(
        '[SCHEDULED] تم جدولة إشعار $prayer في ${notificationTime.toLocal()} (ID: $notificationId)',
      );
      print(
        '[SCHEDULED] تم جدولة أذان $prayer في ${prayerDateTime.toLocal()} (ID: $prayerId)',
      );
    } catch (e) {
      print('[ERROR] فشل جدولة الإشعار أو الأذان: $e');
    }
  }

  Future<void> _prepareAdhanFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/azan.mp3');
      if (!await file.exists()) {
        final byteData = await rootBundle.load('Assets/audio/azan.mp3');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
      adhanFilePathForeground = file.path;
      AdhanTaskHandler.adhanFilePath = file.path;
      print('[INFO] تم تحضير ملف الأذان');
    } catch (e) {
      print('[ERROR] فشل تحضير ملف الأذان: $e');
    }
  }

  void scheduleAllPrayers(Map<String, String> prayerTimes) {
    prayerTimes.forEach((prayer, time) {
      if (_adhanEnabled[prayer] != true) return;
      _scheduleSinglePrayer(prayer, time);
    });
  }

  Future<void> _loadCachedPrayerTimes() async {
    try {
      final cachedData = _prefs?.getString('prayer_times_data');
      if (cachedData != null) {
        final Map<String, dynamic> data = json.decode(cachedData);
        final Map<String, String> prayerTimes = Map<String, String>.from(
          data['prayerTimes'],
        );
        final String city = data['city'];
        final String country = data['country'];

        if (mounted) {
          context.read<PrayerCubit>().setCachedData(prayerTimes, city, country);
        }
        scheduleAllPrayers(prayerTimes);
      }
    } catch (e) {
      print('[ERROR] فشل تحميل أوقات الصلاة المخزنة: $e');
    }
  }

  Future<void> _fetchNewPrayerTimes() async {
    try {
      await context.read<PrayerCubit>().getPrayerTimes();
      final state = context.read<PrayerCubit>().state;
      if (state is PrayerLoaded) {
        await _cachePrayerTimes(state.prayerTimes, state.city, state.country);
        scheduleAllPrayers(state.prayerTimes);
      }
    } catch (e) {
      print('[ERROR] فشل جلب أوقات الصلاة الجديدة: $e');
      await _loadCachedPrayerTimes();
    }
  }

  Future<void> _cachePrayerTimes(
      Map<String, String> prayerTimes, String city, String country) async {
    try {
      final data = {
        'prayerTimes': prayerTimes,
        'city': city,
        'country': country,
        'date': DateTime.now().toIso8601String(),
      };
      await _prefs?.setString('prayer_times_data', json.encode(data));
    } catch (e) {
      print('[ERROR] فشل تخزين أوقات الصلاة: $e');
    }
  }

  void _startDailyResetTimer() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    Timer(durationUntilMidnight, () {
      setState(() {
        _adhanPlayedToday.updateAll((key, value) => false);
      });
      final state = context.read<PrayerCubit>().state;
      if (state is PrayerLoaded) {
        scheduleAllPrayers(state.prayerTimes);
      }
      _startDailyResetTimer();
    });
  }

  void _startPrayerChecker() {
    _prayerTimer?.cancel();
    _prayerTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final state = context.read<PrayerCubit>().state;
        if (state is PrayerLoaded) {
          final now = DateTime.now();
          for (var entry in state.prayerTimes.entries) {
            final prayer = entry.key;
            final time = entry.value;

            if (_adhanEnabled[prayer] != true) continue;

            final parts = time.split(':');
            if (parts.length != 2) continue;
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour == null || minute == null) continue;

            final prayerTime = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );

            // إذا كان الوقت قد فات، جدول الصلاة لليوم التالي
            if (prayerTime.isBefore(now) && !_adhanPlayedToday[prayer]!) {
              final nextPrayerTime = prayerTime.add(const Duration(days: 1));
              _scheduleSinglePrayer(prayer, time);
            }
          }
        }
      } catch (e) {
        print('[ERROR] خطأ في مراقبة أوقات الصلاة: $e');
      }
    });
  }

  Future<void> _playForegroundAdhan() async {
    if (adhanFilePathForeground == null) return;
    try {
      _foregroundPlayer?.stop();
      _foregroundPlayer = AudioPlayer();
      await _foregroundPlayer!.setFilePath(adhanFilePathForeground!);
      await _foregroundPlayer!.play();
    } catch (e) {
      print('[ERROR] فشل تشغيل الأذان في الواجهة: $e');
    }
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    _foregroundPlayer?.stop();
    super.dispose();
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
                onPressed: () => context.read<BottomNavCubit>().setIndex(0),
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
                    scheduleAllPrayers(state.prayerTimes);
                  }
                },
                builder: (context, state) {
                  if (state is PrayerLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: KprimaryColor),
                    );
                  } else if (state is PrayerError) {
                    if (_prefs?.containsKey('prayer_times_data') ?? false) {
                      _loadCachedPrayerTimes();
                      return const Center(
                        child: Text(
                          'عرض آخر أوقات الصلاة المخزنة',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Center(
                      child: Text(state.message, textAlign: TextAlign.center),
                    );
                  } else if (state is PrayerLoaded) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: width * 0.04),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.04,
                            ),
                            child: NextPrayerCountdownWithImage(
                              prayerTimes: state.prayerTimes,
                              fontBig: fontBig,
                              fontNormal: fontNormal,
                              height: height * 0.3,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.03,
                              vertical: height * 0.01,
                            ),
                            child: PrayerTimesList(
                              context,
                              state,
                              fontBig,
                              width,
                              height,
                              _adhanEnabled,
                              _toggleAdhanForPrayer,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(color: KprimaryColor),
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