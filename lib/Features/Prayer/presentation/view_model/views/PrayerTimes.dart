import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../Core/Const/Colors.dart';
import '../../../../Home/presentation/view_model/views/widgets/BottomBar.dart';
import '../../../../Prayer/presentation/view_model/prayer_cubit.dart';
import '../../../../Prayer/presentation/view_model/prayer_state.dart';
import 'widgets/NextPrayerCountdownWithImage.dart';
import 'widgets/PrayerTimesList.dart';

// ==========================
// Foreground Task Handler
// ==========================
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
          await _player.dispose();
          FlutterForegroundTask.stopService();
        }
      });
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
  }
}

// ==========================
// Background entry-point
// ==========================
@pragma('vm:entry-point')
void adhanAlarmCallback() {
  FlutterForegroundTask.startService(
    notificationTitle: 'الأذان',
    notificationText: 'حان وقت الصلاة',
    callback: () => AdhanTaskHandler(),
  );
}

// ==========================
// PrayerTimes Widget
// ==========================
class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  SharedPreferences? _prefs;
  Timer? _prayerTimer;
  Map<String, bool> _adhanPlayedToday = {};
  static String? adhanFilePathForeground;
  static AudioPlayer? _foregroundPlayer;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prepareAdhanFile();
      await _loadCachedPrayerTimes();
      await _fetchNewPrayerTimes();
      _startPrayerChecker();
      _resetAdhanFlagsDaily();
      await AndroidAlarmManager.initialize();
    } catch (e) {
      print('[ERROR] فشل تهيئة أوقات الصلاة: $e');
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
    final now = DateTime.now();
    int id = 1;

    prayerTimes.forEach((prayer, time) {
      final parts = time.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return;

      DateTime prayerDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (prayerDateTime.isBefore(now)) {
        prayerDateTime = prayerDateTime.add(const Duration(days: 1));
      }

      AndroidAlarmManager.oneShotAt(
        prayerDateTime,
        id,
        adhanAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      id++;
    });
  }

  Future<void> _loadCachedPrayerTimes() async {
    try {
      final cachedData = _prefs?.getString('prayer_times_data');
      if (cachedData != null) {
        final Map<String, dynamic> data = json.decode(cachedData);
        final Map<String, String> prayerTimes = Map<String, String>.from(data['prayerTimes']);
        final String city = data['city'];
        final String country = data['country'];
        if (mounted) {
          context.read<PrayerCubit>().setCachedData(prayerTimes, city, country);
        }
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
    }
  }

  Future<void> _cachePrayerTimes(Map<String, String> prayerTimes, String city, String country) async {
    try {
      final data = {'prayerTimes': prayerTimes, 'city': city, 'country': country};
      await _prefs?.setString('prayer_times_data', json.encode(data));
      await _prefs?.setString('prayer_times_date', DateTime.now().toString());
    } catch (e) {
      print('[ERROR] فشل تخزين أوقات الصلاة: $e');
    }
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
            final parts = time.split(':');
            if (parts.length != 2) continue;
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour == null || minute == null) continue;

            final prayerTime = DateTime(now.year, now.month, now.day, hour, minute);
            final startWindow = prayerTime.subtract(const Duration(minutes: 1));
            final endWindow = prayerTime.add(const Duration(minutes: 5));
            if (now.isAfter(startWindow) &&
                now.isBefore(endWindow) &&
                (_adhanPlayedToday[prayer] != true)) {
              _playForegroundAdhan();
              _adhanPlayedToday[prayer] = true;
              print('[INFO] الأذان شغال للواجهة للصلاة: $prayer');
            }
          }
        }
      } catch (e) {
        print('[ERROR] خطأ في مراقبة أوقات الصلاة للواجهة: $e');
      }
    });
  }

  void _resetAdhanFlagsDaily() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    Timer(nextMidnight.difference(now), () {
      _adhanPlayedToday.clear();
      _resetAdhanFlagsDaily();
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
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: width * 0.05),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أوقات الصلاة',
                    style: TextStyle(
                        fontSize: fontBig, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(width: 5),
                        Icon(Icons.location_on, color: Colors.orangeAccent, size: width * 0.04),
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
                    await _cachePrayerTimes(state.prayerTimes, state.city, state.country);
                    scheduleAllPrayers(state.prayerTimes);
                  }
                },
                builder: (context, state) {
                  if (state is PrayerLoading) {
                    return const Center(child: CircularProgressIndicator(color: KprimaryColor));
                  } else if (state is PrayerError) {
                    return Center(child: Text(state.message, textAlign: TextAlign.center));
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
                            child: PrayerTimesList(context, state, fontBig, width, height),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator(color: KprimaryColor));
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