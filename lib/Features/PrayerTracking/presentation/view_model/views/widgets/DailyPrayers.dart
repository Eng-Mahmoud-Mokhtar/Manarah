import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../Core/Const/Colors.dart';
import 'resetDailyPrayers.dart';

class DailyPrayers extends StatefulWidget {
  const DailyPrayers({super.key});

  @override
  State<DailyPrayers> createState() => _DailyPrayersState();
}

class _DailyPrayersState extends State<DailyPrayers> {
  Map<String, bool> prayers = {
    "الفجر": false,
    "الظهر": false,
    "العصر": false,
    "المغرب": false,
    "العشاء": false,
  };

  @override
  void initState() {
    super.initState();
    _initializeDailyPrayers();
    _scheduleDailyReset();
  }

  Future<void> _initializeDailyPrayers() async {
    final prefs = await SharedPreferences.getInstance();
    String todayStr = DateTime.now().toString().split(" ")[0];

    // أول تشغيل: كل الصلوات اليوم false
    bool isFirstRun = prefs.getBool("is_first_run_daily") ?? true;
    if (isFirstRun) {
      for (var prayer in prayers.keys) {
        await prefs.setBool("$todayStr-$prayer", false);
        prayers[prayer] = false;
      }
      await prefs.setBool("is_first_run_daily", false);
    } else {
      // تحميل الحالة الحالية للصلاة من SharedPreferences
      for (var prayer in prayers.keys) {
        prayers[prayer] = prefs.getBool("$todayStr-$prayer") ?? false;
      }
    }

    setState(() {});
  }

  Future<void> _scheduleDailyReset() async {
    await AndroidAlarmManager.initialize();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      1,
      resetDailyPrayers,
      startAt: midnight,
      exact: true,
      wakeup: true,
    );
  }

  Future<void> _savePrayer(String prayer, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    String todayStr = DateTime.now().toString().split(" ")[0];
    await prefs.setBool("$todayStr-$prayer", value);
    setState(() {
      prayers[prayer] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        image: DecorationImage(
          image: AssetImage('Assets/Login.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: ListView(
        padding: EdgeInsets.all(width * 0.04),
        children: prayers.keys.map((prayer) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            decoration: BoxDecoration(
              color: KprimaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: Colors.transparent,
                checkboxTheme: CheckboxThemeData(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: MaterialStateBorderSide.resolveWith((states) {
                    return const BorderSide(color: Colors.white, width: 2);
                  }),
                  fillColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white;
                    }
                    return Colors.transparent;
                  }),
                  checkColor: MaterialStateProperty.all(KprimaryColor),
                ),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.only(left: 0),
                title: Text(
                  prayer,
                  style: TextStyle(
                    fontSize: fontBig,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: prayers[prayer],
                onChanged: (value) => _savePrayer(prayer, value ?? false),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
